#!/usr/bin/env bash
# Log diagnostics for S3 requests (SignatureDoesNotMatch, 405, etc.).
# Run on alfares server after reproducing the error, to see what MinIO and Nginx saw.
#   ssh alfares
#   cd /path/to/minio-microservice && ./scripts/log-request-diagnostics.sh
# Use for: portal PutObject failures; compare Host/path on MinIO side with portal logs.

set -e

echo "=== MinIO request diagnostics (run after reproducing upload error) ==="
echo ""

# 1) MinIO container logs (last 80 lines) - shows S3 API errors and request path
echo "--- 1) MinIO container logs (last 80 lines) ---"
for name in minio-microservice-blue minio-microservice-green; do
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"; then
        echo "Container: $name"
        docker logs "$name" 2>&1 | tail -80
        break
    fi
done
echo ""

# 2) Nginx access log: requests to minio.alfares.cz /records/ (Host and path MinIO receives)
echo "--- 2) Nginx access log: recent requests to minio.alfares.cz /records/ ---"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^nginx-microservice$'; then
    docker exec nginx-microservice sh -c 'tail -100 /var/log/nginx/access.log 2>/dev/null | grep -E "minio\.alfares|/records/" || true' 2>/dev/null || echo "(no access.log or no matches)"
else
    echo "nginx-microservice container not running; skip Nginx access log"
fi
echo ""

# 3) Nginx error log (last 20 lines)
echo "--- 3) Nginx error log (last 20 lines) ---"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^nginx-microservice$'; then
    docker exec nginx-microservice tail -20 /var/log/nginx/error.log 2>/dev/null || echo "(no error.log)"
else
    echo "nginx-microservice container not running"
fi
echo ""

echo "=== Compare with portal logs (speakasap): grep RECORDS_S3 ~/speakasap-portal/logs/app.log ==="
echo "Check: portal endpoint vs Nginx Host; portal path /records/bucket/key vs Nginx path."
