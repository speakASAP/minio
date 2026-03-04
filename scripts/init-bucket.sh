#!/usr/bin/env bash
# Create bucket 'records' and disable public access.
# Run on dev after MinIO is running. Requires: mc (MinIO Client), .env with MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET.

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

# shellcheck source=/dev/null
source "$ENV_FILE"

BUCKET="${RECORDS_BUCKET:-records}"
ALIAS=minio-local
# MinIO on dev: default API port 9000 (localhost)
ENDPOINT="${MINIO_ENDPOINT:-http://127.0.0.1:9000}"

if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ]; then
    echo "Error: MINIO_ROOT_USER and MINIO_ROOT_PASSWORD must be set in .env"
    exit 1
fi

if ! command -v mc >/dev/null 2>&1; then
    echo "Error: MinIO Client (mc) not found. Install: https://min.io/docs/minio/linux/reference/minio-mc.html"
    exit 1
fi

echo "[minio] Configuring mc alias ${ALIAS}..."
mc alias set "${ALIAS}" "${ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

echo "[minio] Creating bucket ${BUCKET}..."
mc mb "${ALIAS}/${BUCKET}" --ignore-existing 2>/dev/null || true

echo "[minio] Disabling public access on bucket ${BUCKET}..."
mc anonymous set none "${ALIAS}/${BUCKET}" 2>/dev/null || true

echo "[minio] Bucket ${BUCKET} is ready. All access via presigned URLs or IAM only."
