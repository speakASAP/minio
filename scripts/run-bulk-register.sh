#!/bin/bash
# Run bulk-register-flat-files-in-minio.py inside a container with MinIO data and network.
# Usage (on alfares, from minio-microservice dir):
#   ./scripts/run-bulk-register.sh [--dry-run] [--limit N] [--resume state.txt]
#
# Works with both blue and green: if MINIO_ENDPOINT is not set, detects active color from
# nginx-microservice state (minio-microservice.json) or from which container is running.
# Load MINIO_ROOT_USER and MINIO_ROOT_PASSWORD from .env.
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

# Endpoint: from .env, or detect active blue/green from nginx-microservice state, or from running container.
if [ -z "${MINIO_ENDPOINT:-}" ]; then
  ACTIVE_COLOR=""
  # Prefer nginx-microservice state (same logic as deploy.sh paths)
  for NGINX_STATE in "/home/statex/nginx-microservice/state/minio-microservice.json" \
                     "/home/alfares/nginx-microservice/state/minio-microservice.json" \
                     "/home/belunga/nginx-microservice/state/minio-microservice.json" \
                     "$HOME/nginx-microservice/state/minio-microservice.json" \
                     "$(dirname "$PROJECT_ROOT")/nginx-microservice/state/minio-microservice.json"; do
    if [ -f "$NGINX_STATE" ] && command -v jq >/dev/null 2>&1; then
      ACTIVE_COLOR=$(jq -r '.active_color // empty' "$NGINX_STATE" 2>/dev/null)
      [ "$ACTIVE_COLOR" = "blue" ] || [ "$ACTIVE_COLOR" = "green" ] && break
      ACTIVE_COLOR=""
    fi
  done
  # Fallback: which MinIO container is running
  if [ -z "$ACTIVE_COLOR" ]; then
    if docker ps -q -f "name=minio-microservice-blue" 2>/dev/null | grep -q .; then
      ACTIVE_COLOR="blue"
    elif docker ps -q -f "name=minio-microservice-green" 2>/dev/null | grep -q .; then
      ACTIVE_COLOR="green"
    fi
  fi
  if [ -n "$ACTIVE_COLOR" ]; then
    MINIO_ENDPOINT="http://minio-microservice-${ACTIVE_COLOR}:9000"
  else
    MINIO_ENDPOINT="http://minio-microservice-blue:9000"
  fi
fi
: "${BULK_REGISTER_NETWORK:=nginx-network}"

NET_OPT="--network $BULK_REGISTER_NETWORK"
[ "$BULK_REGISTER_NETWORK" = "host" ] && NET_OPT="--network host"

docker run --rm \
  $NET_OPT \
  -v "/srv/speakasap-records:/data" \
  -v "$PROJECT_ROOT/scripts/bulk-register-flat-files-in-minio.py:/script/bulk-register-flat-files-in-minio.py:ro" \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  -e MINIO_ENDPOINT="$MINIO_ENDPOINT" \
  python:3.11-slim \
  bash -c "pip install -q --upgrade pip && pip install -q boto3 && python /script/bulk-register-flat-files-in-minio.py $*"
