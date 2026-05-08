#!/usr/bin/env bash
# Apply S3 bucket CORS on RECORDS_BUCKET so browsers can:
#   - GET presigned URLs (audio playback)
#   - PUT presigned uploads from speakasap.com (teacher dashboard)
# Run on the host that runs MinIO (alfares), after init-bucket.sh.
# Requires: minio-mc or mc (MinIO client), same .env as init-bucket.sh (MINIO_ROOT_*, RECORDS_BUCKET).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-${REPO_ROOT}/.env}"
if [ -f "/srv/minio/.env" ]; then
    ENV_FILE=/srv/minio/.env
fi

if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" ]] && continue
        if [[ "$line" == *=* ]]; then
            key="${line%%=*}"
            key="${key%"${key##*[![:space:]]}"}"
            val="${line#*=}"
            val="${val#"${val%%[![:space:]]*}"}"
            val="${val%"${val##*[![:space:]]}"}"
            val="${val%$'\r'}"
            if [[ "$val" == \"*\" ]]; then val="${val%\"}"; val="${val#\"}"; fi
            if [[ "$val" == \'*\' ]]; then val="${val%\'}"; val="${val#\'}"; fi
            printf -v "$key" %s "$val"
            export "$key"
        fi
    done < "$ENV_FILE"
fi

BUCKET="${RECORDS_BUCKET:-speakasap-records}"
# Comma-separated list of allowed Origins for browser PUT/GET (HTTPS).
ORIGINS_RAW="${RECORDS_CORS_ORIGINS:-https://speakasap.com,https://www.speakasap.com}"

ENDPOINT="${MINIO_ENDPOINT:-http://127.0.0.1:9000}"

if [ -z "${MINIO_ROOT_USER:-}" ] || [ -z "${MINIO_ROOT_PASSWORD:-}" ]; then
    echo "Error: MINIO_ROOT_USER and MINIO_ROOT_PASSWORD must be set via environment or .env"
    exit 1
fi

MC_CMD=""
if command -v minio-mc >/dev/null 2>&1; then
    MC_CMD=minio-mc
elif command -v mc >/dev/null 2>&1; then
    if mc --version 2>&1 | grep -qi minio; then
        MC_CMD=mc
    fi
fi
if [ -z "$MC_CMD" ]; then
    echo "Error: MinIO Client not found. Install minio-mc (see README)."
    exit 1
fi

ALIAS=minio-local
"$MC_CMD" alias set "${ALIAS}" "${ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null

TMP_XML="$(mktemp /tmp/minio-cors-XXXXXX.xml)"
trap 'rm -f "$TMP_XML"' EXIT

{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
    echo '  <CORSRule>'
    IFS=',' read -ra ORIG_ARR <<< "$ORIGINS_RAW"
    for o in "${ORIG_ARR[@]}"; do
        o="${o#"${o%%[![:space:]]*}"}"
        o="${o%"${o##*[![:space:]]}"}"
        if [ -n "$o" ]; then
            echo "    <AllowedOrigin>${o}</AllowedOrigin>"
        fi
    done
    echo '    <AllowedMethod>GET</AllowedMethod>'
    echo '    <AllowedMethod>PUT</AllowedMethod>'
    echo '    <AllowedMethod>HEAD</AllowedMethod>'
    echo '    <AllowedHeader>*</AllowedHeader>'
    echo '    <ExposeHeader>ETag</ExposeHeader>'
    echo '    <ExposeHeader>Content-Length</ExposeHeader>'
    echo '    <ExposeHeader>Content-Type</ExposeHeader>'
    echo '    <ExposeHeader>x-amz-request-id</ExposeHeader>'
    echo '    <MaxAgeSeconds>3600</MaxAgeSeconds>'
    echo '  </CORSRule>'
    echo '</CORSConfiguration>'
} > "$TMP_XML"

echo "[minio] Applying CORS origins for OSS MinIO (global api.cors_allow_origin) ..."
"$MC_CMD" admin config set "${ALIAS}" api cors_allow_origin="${ORIGINS_RAW}"
echo "[minio] Applied api.cors_allow_origin=${ORIGINS_RAW}"
echo "[minio] Note: OSS MinIO does not support bucket-level PutBucketCors; this sets global API CORS."
