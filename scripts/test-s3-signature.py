#!/usr/bin/env python3
"""
Test S3 SigV4 PUT to MinIO (same signing as portal). Uses endpoint without trailing slash.
Env: S3_ENDPOINT_URL, S3_ACCESS_KEY, S3_SECRET_KEY, S3_BUCKET (default records).
"""
import os
import sys

try:
    import boto3
    from botocore.config import Config
except ImportError as e:
    print("ERROR: boto3 required: pip install boto3", file=sys.stderr)
    sys.exit(1)

def main():
    endpoint = (os.environ.get("S3_ENDPOINT_URL") or "").strip().rstrip("/")
    access = (os.environ.get("S3_ACCESS_KEY") or os.environ.get("MINIO_ROOT_USER") or "").strip()
    secret = (os.environ.get("S3_SECRET_KEY") or os.environ.get("MINIO_ROOT_PASSWORD") or "").strip()
    bucket = (os.environ.get("S3_BUCKET") or os.environ.get("RECORDS_BUCKET") or "records").strip()
    region = os.environ.get("AWS_REGION", "us-east-1")

    if not endpoint or not access or not secret:
        print("ERROR: Set S3_ENDPOINT_URL, S3_ACCESS_KEY, S3_SECRET_KEY (or MINIO_ROOT_*)", file=sys.stderr)
        sys.exit(1)

    cfg = Config(signature_version="s3v4", s3={"addressing_style": "path"})
    client = boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=access,
        aws_secret_access_key=secret,
        region_name=region,
        config=cfg,
    )
    key = "test-signature-check.txt"
    body = b"test-s3-signature script OK\n"
    try:
        client.put_object(Bucket=bucket, Key=key, Body=body, ContentType="text/plain")
        print("PUT OK: %s/%s (SigV4, path-style)" % (bucket, key))
        # Optional: delete test object
        try:
            client.delete_object(Bucket=bucket, Key=key)
            print("DELETE OK: test object removed")
        except Exception:
            pass
    except Exception as e:
        print("PUT FAILED: %s" % e, file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
