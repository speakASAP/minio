#!/usr/bin/env bash
# Create bucket 'speakasap-records' and disable public access.
# Run on dev after MinIO is running. Requires: minio-mc (MinIO Client), .env with MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-${REPO_ROOT}/.env}"
if [ -f "/srv/minio/.env" ]; then
    ENV_FILE=/srv/minio/.env
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env not found. Copy .env.example to .env and set MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET."
    exit 1
fi

# Load .env without sourcing (safe for passwords with ), $, ", etc.)
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

BUCKET="${RECORDS_BUCKET:-speakasap-records}"
echo "[minio] BUCKET=${BUCKET}"

ALIAS=minio-local
# MinIO on dev: default API port 9000 (localhost)
ENDPOINT="${MINIO_ENDPOINT:-http://127.0.0.1:9000}"

if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ]; then
    echo "Error: MINIO_ROOT_USER and MINIO_ROOT_PASSWORD must be set in .env"
    exit 1
fi

# Prefer MinIO Client over Midnight Commander (both use 'mc'). Use minio-mc or verify mc is MinIO.
MC_CMD=""
if command -v minio-mc >/dev/null 2>&1; then
    MC_CMD=minio-mc
elif command -v mc >/dev/null 2>&1; then
    if mc --version 2>&1 | grep -qi minio; then
        MC_CMD=mc
    fi
fi
if [ -z "$MC_CMD" ]; then
    echo "Error: MinIO Client not found. Install from https://min.io/docs/minio/linux/reference/minio-mc.html"
    echo "  Install as 'minio-mc' to avoid conflict with Midnight Commander:"
    echo "  wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/minio-mc && chmod +x /usr/local/bin/minio-mc"
    exit 1
fi

echo "[minio] Configuring mc alias ${ALIAS}..."
"$MC_CMD" alias set "${ALIAS}" "${ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

echo "[minio] Creating bucket ${BUCKET}..."
"$MC_CMD" mb "${ALIAS}/${BUCKET}" --ignore-existing 2>/dev/null || true

echo "[minio] Disabling public access on bucket ${BUCKET}..."
"$MC_CMD" anonymous set none "${ALIAS}/${BUCKET}" 2>/dev/null || true

echo "[minio] Bucket ${BUCKET} is ready. All access via presigned URLs or IAM only."
