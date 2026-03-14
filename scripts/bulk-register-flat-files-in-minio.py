#!/usr/bin/env python3
"""
Bulk register flat record files into MinIO so GetObject works for all of them.

Run inside a container that has:
  - MinIO data volume mounted at /data (read-write), e.g. -v /srv/speakasap-records:/data
  - Network access to MinIO (--network nginx-network), endpoint MINIO_ENDPOINT (default
    http://minio-microservice-blue:9000)
  - Env: MINIO_ROOT_USER, MINIO_ROOT_PASSWORD

For each .mp3 under /data/speakasap-records/: move file to .bak, PutObject from .bak, remove .bak.
Required because MinIO writes to the same path; the flat file must be moved aside so MinIO can create
the object there. Populates MinIO's namespace for the portal.

Usage:
  docker run --rm --network nginx-network \\
    -v /srv/speakasap-records:/data \\
    -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=... \\
    -e MINIO_ENDPOINT=http://minio-microservice-blue:9000 \\
    <image> [--dry-run] [--limit N] [--resume state.txt]

  --dry-run       Only list files that would be processed (no move/put/delete).
  --limit N       Process at most N files (for testing or chunked runs).
  --resume F      Skip keys listed in F (one key per line). Append to F after each success.
  --workers N     Parallel uploads per month (default 32). Higher = faster, more load on MinIO.
"""
from __future__ import print_function

import os
import sys
import time
import argparse
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
except ImportError:
    print("ERROR: boto3 required (pip install boto3)", file=sys.stderr)
    sys.exit(1)

BUCKET = "speakasap-records"
DATA_ROOT = "/data"
BUCKET_ROOT = os.path.join(DATA_ROOT, BUCKET)
CONTENT_TYPE_MP3 = "audio/mpeg"


def get_s3_client(endpoint, access, secret):
    cfg = Config(signature_version="s3v4", s3={"addressing_style": "path"})
    return boto3.client(
        "s3",
        endpoint_url=endpoint.rstrip("/"),
        aws_access_key_id=access,
        aws_secret_access_key=secret,
        region_name="us-east-1",
        config=cfg,
    )


def ensure_bucket(client):
    """Create bucket if it does not exist (avoids AccessDenied on first PutObject)."""
    try:
        client.head_bucket(Bucket=BUCKET)
        return
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        if code in ("404", "NoSuchBucket", "AccessDenied"):
            try:
                client.create_bucket(Bucket=BUCKET)
                print("Created bucket %s" % BUCKET, file=sys.stderr)
            except ClientError as e2:
                code2 = e2.response.get("Error", {}).get("Code", "")
                if code2 in ("BucketAlreadyExists", "BucketAlreadyOwnedByYou"):
                    return
                print("ERROR: create_bucket: %s" % e2, file=sys.stderr)
                raise
            return
        raise


def object_exists(client, key):
    try:
        client.head_object(Bucket=BUCKET, Key=key)
        return True
    except Exception:
        return False


def register_one(key, client, dry_run, resume_done, skip_existing):
    """Move flat file to .bak, PutObject from .bak, remove .bak. Required so MinIO can create object at that path."""
    path = os.path.join(BUCKET_ROOT, key)
    if not os.path.isfile(path):
        return True, "skipped (not a file)"
    path_bak = path + ".bak"
    if dry_run:
        return True, "dry-run"
    if resume_done and key in resume_done:
        return True, "skipped (resume)"
    if skip_existing and object_exists(client, key):
        return True, "skipped (exists)"
    try:
        os.rename(path, path_bak)
    except OSError as e:
        return False, "rename: %s" % e
    try:
        with open(path_bak, "rb") as f:
            client.put_object(
                Bucket=BUCKET,
                Key=key,
                Body=f,
                ContentType=CONTENT_TYPE_MP3,
            )
    except ClientError as e:
        try:
            os.rename(path_bak, path)
        except OSError:
            pass
        code = e.response.get("Error", {}).get("Code", "")
        if code == "AccessDenied":
            return False, "put_object: AccessDenied (ensure bucket exists: run init-bucket.sh on the MinIO host)"
        return False, "put_object: %s" % e
    except Exception as e:
        try:
            os.rename(path_bak, path)
        except OSError:
            pass
        return False, "put_object: %s" % e
    try:
        os.remove(path_bak)
    except OSError as e:
        return False, "remove .bak: %s" % e
    return True, "ok"


def main():
    ap = argparse.ArgumentParser(description="Bulk register flat MP3 files into MinIO")
    ap.add_argument("--dry-run", action="store_true", help="Only list files, do not change")
    ap.add_argument("--limit", type=int, default=0, help="Max number of files to process (0 = all)")
    ap.add_argument("--resume", type=str, default="", help="Resume file: skip keys in this file, append success keys")
    ap.add_argument("--skip-existing", action="store_true", help="Skip keys that already exist in MinIO (head_object)")
    ap.add_argument("--workers", type=int, default=32, help="Parallel uploads (default 32)")
    args = ap.parse_args()

    endpoint = os.environ.get("MINIO_ENDPOINT", "http://minio-microservice-blue:9000")
    access = (os.environ.get("MINIO_ROOT_USER") or "").strip()
    secret = (os.environ.get("MINIO_ROOT_PASSWORD") or "").strip()
    if not access or not secret:
        print("ERROR: set MINIO_ROOT_USER and MINIO_ROOT_PASSWORD", file=sys.stderr)
        sys.exit(1)

    if not os.path.isdir(BUCKET_ROOT):
        print("ERROR: bucket root not found: %s" % BUCKET_ROOT, file=sys.stderr)
        sys.exit(1)

    # Collect all keys (relative paths under bucket)
    keys = []
    for root, _dirs, files in os.walk(BUCKET_ROOT):
        for f in files:
            if f.endswith(".mp3") and not f.endswith(".bak"):
                abs_path = os.path.join(root, f)
                rel = os.path.relpath(abs_path, BUCKET_ROOT)
                keys.append(rel)
    keys.sort()
    total = len(keys)
    if args.limit and args.limit > 0:
        keys = keys[: args.limit]
    print("Found %d .mp3 files (processing %d)" % (total, len(keys)), file=sys.stderr)

    resume_done = set()
    if args.resume and os.path.isfile(args.resume):
        with open(args.resume) as rf:
            for line in rf:
                k = line.strip()
                if k:
                    resume_done.add(k)
        print("Resume: %d keys already done" % len(resume_done), file=sys.stderr)

    if args.dry_run:
        for k in keys[:20]:
            print(k)
        if len(keys) > 20:
            print("... and %d more" % (len(keys) - 20), file=sys.stderr)
        return 0

    client = get_s3_client(endpoint, access, secret)
    ensure_bucket(client)

    # Group keys by month (YYYY/MM) for progress and parallel batch processing
    by_month = defaultdict(list)
    for key in keys:
        parts = key.split("/")
        month = "/".join(parts[:2]) if len(parts) >= 2 else key
        by_month[month].append(key)
    months = sorted(by_month.keys())
    workers = max(1, min(args.workers, 128))
    print("Using %d workers" % workers, file=sys.stderr)

    done = 0
    skipped = 0
    failed = 0
    start = time.time()
    resume_f = open(args.resume, "a") if args.resume else None

    def do_one(key):
        ok, msg = register_one(key, client, False, set(), args.skip_existing)
        return (key, ok, msg)

    for month in months:
        month_keys = [k for k in by_month[month] if k not in resume_done]
        if not month_keys:
            continue
        elapsed = time.time() - start
        rate = (done + skipped + failed) / elapsed if elapsed else 0
        print("%s: %d done, %d skipped, %d failed so far (%.1f/s) -> processing %d files" % (
            month, done, skipped, failed, rate, len(month_keys)), file=sys.stderr)
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futures = {ex.submit(do_one, k): k for k in month_keys}
            for fut in as_completed(futures):
                key, ok, msg = fut.result()
                if ok:
                    if msg == "ok":
                        done += 1
                        resume_done.add(key)
                        if resume_f:
                            resume_f.write(key + "\n")
                            resume_f.flush()
                    else:
                        skipped += 1
                else:
                    failed += 1
                    print("FAIL %s: %s" % (key, msg), file=sys.stderr)

    if resume_f:
        resume_f.close()
    elapsed = time.time() - start
    print("Done: %d ok, %d skipped, %d failed in %.1fs (%.1f/s)" % (
        done, skipped, failed, elapsed, done / elapsed if elapsed else 0), file=sys.stderr)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
