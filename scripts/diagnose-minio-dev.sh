#!/usr/bin/env bash
# Diagnose MinIO + Nginx on dev (certificates, PUT, 520). Run on dev server:
#   ssh dev
#   cd /home/ssf/Documents/Github/minio-microservice  # or /srv/minio
#   ./scripts/diagnose-minio-dev.sh
# Or: ssh dev 'bash -s' < scripts/diagnose-minio-dev.sh

set -e

MINIO_HOST="${MINIO_HOST:-minio.alfares.cz}"
echo "=== MinIO/Nginx diagnosis on dev (host: $MINIO_HOST) ==="

# 1) MinIO process and port
echo ""
echo "--- 1) MinIO service ---"
if systemctl is-active --quiet minio 2>/dev/null; then
    echo "minio: active"
else
    echo "minio: NOT active"
fi
ss -tlnp 2>/dev/null | grep -E ':9000|:9001' || true

# 2) Direct PUT to MinIO (no Nginx) - no auth will get 403 but proves MinIO accepts PUT
echo ""
echo "--- 2) Direct PUT to MinIO (127.0.0.1:9000, no Nginx) ---"
CODE=$(curl -s -o /tmp/minio-diag-$$.out -w "%{http_code}" --connect-timeout 3 -X PUT -d "test" "http://127.0.0.1:9000/records/diag-$$.txt" -H "Host: localhost" 2>/dev/null || echo "000")
echo "HTTP code: $CODE (403/404/405 = MinIO saw request; 000 = connection failed)"
rm -f /tmp/minio-diag-$$.out

# 3) Nginx config that proxies to MinIO
echo ""
echo "--- 3) Nginx server blocks mentioning minio/9000/alfares ---"
grep -r "9000\|minio\|alfares" /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null | grep -v "^Binary" | head -40 || true

# 4) PUT through Nginx to MinIO (localhost, same as prod path)
echo ""
echo "--- 4) PUT via Nginx (request to 127.0.0.1 with Host: $MINIO_HOST) ---"
# Use HTTP if Nginx listens 80 for this host; otherwise HTTPS (may need -k if self-signed)
CODE=$(curl -s -o /tmp/minio-diag-$$.out -w "%{http_code}" --connect-timeout 5 -X PUT -d "test" "http://127.0.0.1/records/diag-nginx-$$.txt" -H "Host: $MINIO_HOST" 2>/dev/null || echo "000")
echo "HTTP (port 80) code: $CODE"
rm -f /tmp/minio-diag-$$.out

# 5) HTTPS to public hostname (cert + full path - from dev to itself)
echo ""
echo "--- 5) HTTPS to $MINIO_HOST (from dev, checks cert and response) ---"
CODE=$(curl -s -o /tmp/minio-diag-$$.out -w "%{http_code}" --connect-timeout 10 -k -X PUT -d "test" "https://$MINIO_HOST/records/diag-https-$$.txt" 2>/dev/null || echo "000")
echo "HTTPS PUT code: $CODE (520 = origin/nginx issue, 403 = auth, 200 = success)"
if [ -f /tmp/minio-diag-$$.out ] && [ -s /tmp/minio-diag-$$.out ]; then
    echo "Response body (first 3 lines):"
    head -3 /tmp/minio-diag-$$.out
fi
rm -f /tmp/minio-diag-$$.out

# 6) SSL certificate (if Nginx serves HTTPS for this host)
echo ""
echo "--- 6) SSL cert for $MINIO_HOST (from dev) ---"
echo | openssl s_client -servername "$MINIO_HOST" -connect "${MINIO_HOST}:443" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "Could not fetch cert (openssl or DNS failure)"

# 7) Nginx error log (last lines)
echo ""
echo "--- 7) Last Nginx errors ---"
tail -5 /var/log/nginx/error.log 2>/dev/null || true

echo ""
echo "=== Done ==="
