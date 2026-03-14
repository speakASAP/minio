#!/usr/bin/env python3
"""
One-off: register an existing record file into MinIO so GetObject works.
Files on disk under /srv/speakasap-records/speakasap-records/ may not be
visible to MinIO API if they were created outside MinIO (flat files).
This script reads the file and does PutObject so MinIO creates the correct object.

If PutObject fails with AccessDenied (e.g. flat file already at that path),
move the file aside inside the container first, then re-run:
  docker exec minio-microservice-blue mv /data/speakasap-records/KEY KEY.bak
  python3 scripts/register-record-in-minio.py KEY
Then use aws s3api put-object from host with body from docker cp of the .bak file.
See docs/MINIO_RECORDS_FLAT_FILE_FIX.md for the full procedure.

Usage (on alfares, from minio-microservice dir; requires boto3):
  python3 scripts/register-record-in-minio.py [object_key]
  Example: python3 scripts/register-record-in-minio.py 2025/10/20/lesson_0cdbeeea-a6fe-432f-af69-cc0aba3bcfda.mp3

Env: load .env for MINIO_ROOT_USER, MINIO_ROOT_PASSWORD; MINIO_API_PORT (default 9002).
"""
import os
import sys

# Load .env from project root (parent of scripts/)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ENV_PATH = os.path.join(PROJECT_ROOT, ".env")
if os.path.isfile(ENV_PATH):
    with open(ENV_PATH) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k not in os.environ:
                    os.environ[k] = v

try:
    import boto3
    from botocore.config import Config
except ImportError:
    print("ERROR: boto3 required", file=sys.stderr)
    sys.exit(1)

DATA_ROOT = "/srv/speakasap-records"
BUCKET = "speakasap-records"


def main():
    key = (sys.argv[1] if len(sys.argv) > 1 else "2025/10/20/lesson_0cdbeeea-a6fe-432f-af69-cc0aba3bcfda.mp3").strip()
    if ".." in key or not key.endswith(".mp3"):
        print("ERROR: key must be like YYYY/MM/DD/lesson_<uuid>.mp3", file=sys.stderr)
        sys.exit(1)

    local_path = os.path.join(DATA_ROOT, BUCKET, key)
    if not os.path.isfile(local_path):
        print("ERROR: file not found: %s" % local_path, file=sys.stderr)
        sys.exit(1)

    port = os.environ.get("MINIO_API_PORT", "9002")
    endpoint = "http://127.0.0.1:%s" % port
    access = (os.environ.get("MINIO_ROOT_USER") or "").strip()
    secret = (os.environ.get("MINIO_ROOT_PASSWORD") or "").strip()
    if not access or not secret:
        print("ERROR: set MINIO_ROOT_USER and MINIO_ROOT_PASSWORD in .env", file=sys.stderr)
        sys.exit(1)

    cfg = Config(signature_version="s3v4", s3={"addressing_style": "path"})
    client = boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=access,
        aws_secret_access_key=secret,
        region_name="us-east-1",
        config=cfg,
    )

    with open(local_path, "rb") as f:
        body = f.read()

    try:
        client.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=body,
            ContentType="audio/mpeg",
        )
        print("PutObject OK: %s/%s (%d bytes)" % (BUCKET, key, len(body)))
        # Verify
        resp = client.get_object(Bucket=BUCKET, Key=key)
        got = resp["Body"].read()
        if len(got) != len(body):
            print("WARNING: GET returned %d bytes, expected %d" % (len(got), len(body)), file=sys.stderr)
        else:
            print("GetObject OK: object is readable")
    except Exception as e:
        print("FAILED: %s" % e, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
