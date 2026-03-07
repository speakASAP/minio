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

def _normalize_endpoint(url):
    """Strip /minio or /minio/ so S3 requests go to root (same as portal)."""
    if not url:
        return url
    u = url.rstrip("/")
    if u.lower().endswith("/minio"):
        u = u[:-6]
    return u or url

def main():
    raw = (os.environ.get("S3_ENDPOINT_URL") or "").strip()
    endpoint = _normalize_endpoint(raw).rstrip("/") if raw else ""
    access = (os.environ.get("S3_ACCESS_KEY") or os.environ.get("MINIO_ROOT_USER") or "").strip()
    secret = (os.environ.get("S3_SECRET_KEY") or os.environ.get("MINIO_ROOT_PASSWORD") or "").strip()
    bucket = (os.environ.get("S3_BUCKET") or os.environ.get("RECORDS_BUCKET") or "records").strip()
    region = os.environ.get("AWS_REGION", "us-east-1")

    if not endpoint or not access or not secret:
        print("ERROR: Set S3_ENDPOINT_URL, S3_ACCESS_KEY, S3_SECRET_KEY (or MINIO_ROOT_*)", file=sys.stderr)
        sys.exit(1)

    if os.environ.get("S3_TEST_VERBOSE"):
        print("endpoint=%s bucket=%s (SigV4 path-style)" % (endpoint, bucket), flush=True)

    # Disable SSL verify when testing against local hostnames (cert is for minio.alfares.cz) or S3_TEST_INSECURE=1
    use_verify = True
    if os.environ.get("S3_TEST_INSECURE") or "127.0.0.1" in endpoint or "nginx-microservice" in endpoint:
        use_verify = False

    cfg = Config(signature_version="s3v4", s3={"addressing_style": "path"})
    client = boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=access,
        aws_secret_access_key=secret,
        region_name=region,
        config=cfg,
        verify=use_verify,
    )
    key = "test-signature-check.txt"
    body = b"test-s3-signature script OK\n"
    try:
        client.put_object(Bucket=bucket, Key=key, Body=body, ContentType="text/plain")
        print("PUT OK: %s/%s (SigV4, path-style)" % (bucket, key))
        # GET: verify two-way communication
        resp = client.get_object(Bucket=bucket, Key=key)
        got = resp["Body"].read()
        if got != body:
            print("GET FAILED: body mismatch (got %d bytes, expected %d)" % (len(got), len(body)), file=sys.stderr)
            sys.exit(1)
        print("GET OK: %s/%s (read back %d bytes)" % (bucket, key, len(got)))
        # Clean up test object
        try:
            client.delete_object(Bucket=bucket, Key=key)
            print("DELETE OK: test object removed")
        except Exception:
            pass
    except Exception as e:
        print("FAILED: %s" % e, file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
