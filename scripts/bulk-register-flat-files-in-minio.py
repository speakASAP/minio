#!/usr/bin/env python3
"""
Bulk register flat record files into MinIO so GetObject works for all of them.

Run inside a container that has:
  - MinIO data volume mounted at /data (read-write), e.g. -v /srv/speakasap-records:/data
  - Network access to MinIO (--network nginx-network), endpoint MINIO_ENDPOINT (default
    http://minio-microservice-blue:9000)
  - Env: MINIO_ROOT_USER, MINIO_ROOT_PASSWORD

For each .mp3 under /data/speakasap-records/: move to .bak, PutObject from .bak, remove .bak.
This populates MinIO's namespace so the portal helper can serve the file.

Usage:
  docker run --rm --network nginx-network \\
    -v /srv/speakasap-records:/data \\
    -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=... \\
    -e MINIO_ENDPOINT=http://minio-microservice-blue:9000 \\
    <image> [--dry-run] [--limit N] [--resume state.txt]

  --dry-run       Only list files that would be processed (no move/put/delete).
  --limit N       Process at most N files (for testing or chunked runs).
  --resume F      Skip keys listed in F (one key per line). Append to F after each success.
"""
from __future__ import print_function

import os
import sys
import time
import argparse

try:
    import boto3
    from botocore.config import Config
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


def object_exists(client, key):
    try:
        client.head_object(Bucket=BUCKET, Key=key)
        return True
    except Exception:
        return False


def register_one(key, client, dry_run, resume_done, skip_existing):
    """Move flat file to .bak, PutObject from .bak, remove .bak. Returns True on success."""
    path = os.path.join(BUCKET_ROOT, key)
    if not os.path.isfile(path):
        return False, "not a file"
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
            body = f.read()
        client.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=body,
            ContentType=CONTENT_TYPE_MP3,
        )
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

    client = get_s3_client(endpoint, access, secret)
    if args.dry_run:
        for k in keys[:20]:
            print(k)
        if len(keys) > 20:
            print("... and %d more" % (len(keys) - 20), file=sys.stderr)
        return 0

    done = 0
    failed = 0
    start = time.time()
    resume_f = open(args.resume, "a") if args.resume else None

    for i, key in enumerate(keys):
        ok, msg = register_one(key, client, False, resume_done, args.skip_existing)
        if ok:
            done += 1
            if msg == "ok":
                resume_done.add(key)
                if resume_f:
                    resume_f.write(key + "\n")
                    resume_f.flush()
        else:
            failed += 1
            print("FAIL %s: %s" % (key, msg), file=sys.stderr)
        if (i + 1) % 500 == 0:
            elapsed = time.time() - start
            print("Progress: %d done, %d failed, %.1f/s" % (done, failed, (i + 1) / elapsed if elapsed else 0), file=sys.stderr)

    if resume_f:
        resume_f.close()
    elapsed = time.time() - start
    print("Done: %d ok, %d failed in %.1fs (%.1f/s)" % (done, failed, elapsed, done / elapsed if elapsed else 0), file=sys.stderr)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
