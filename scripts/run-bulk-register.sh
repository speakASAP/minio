#!/bin/bash
# Run bulk-register-flat-files-in-minio.py inside a container with MinIO data and network.
# Usage (on alfares, from minio-microservice dir):
#   ./scripts/run-bulk-register.sh [--dry-run] [--limit N] [--resume state.txt]
#
# Load MINIO_ROOT_USER and MINIO_ROOT_PASSWORD from .env
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

: "${MINIO_ROOT_USER:=}"
: "${MINIO_ROOT_PASSWORD:=}"
if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ]; then
  echo "ERROR: set MINIO_ROOT_USER and MINIO_ROOT_PASSWORD in .env" >&2
  exit 1
fi

docker run --rm \
  --network nginx-network \
  -v "/srv/speakasap-records:/data" \
  -v "$PROJECT_ROOT/scripts/bulk-register-flat-files-in-minio.py:/script/bulk-register-flat-files-in-minio.py:ro" \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  -e MINIO_ENDPOINT="http://minio-microservice-blue:9000" \
  python:3.11-slim \
  bash -c "pip install -q boto3 && python /script/bulk-register-flat-files-in-minio.py $*"
