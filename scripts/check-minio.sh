#!/usr/bin/env bash
# Check MinIO service, bucket, and access. Run on alfares: ssh alfares 'cd minio-microservice && ./scripts/check-minio.sh'
# Helps diagnose AllAccessDisabled and connectivity issues.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-${REPO_ROOT}/.env}"
if [ -f "/srv/minio/.env" ]; then
    ENV_FILE=/srv/minio/.env
fi

echo "=== MinIO check (dev) ==="
echo "ENV_FILE=$ENV_FILE"

# 1) Process / Docker
echo ""
echo "--- 1) MinIO process / Docker ---"
if systemctl is-active --quiet minio 2>/dev/null; then
    echo "systemd: minio is running"
    systemctl status minio --no-pager 2>/dev/null | head -5
elif docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q minio; then
    echo "Docker: MinIO container(s)"
    docker ps -a --filter "name=minio" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "WARNING: No MinIO systemd unit or Docker container found."
fi

# 2) Listen port
echo ""
echo "--- 2) Port 9000 (API) ---"
if command -v ss >/dev/null 2>&1; then
    ss -tlnp 2>/dev/null | grep -E ':9000|:9001' || true
elif command -v netstat >/dev/null 2>&1; then
    netstat -tlnp 2>/dev/null | grep -E '9000|9001' || true
fi

# 3) .env
echo ""
echo "--- 3) .env (keys only) ---"
if [ -f "$ENV_FILE" ]; then
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" 2>/dev/null | sed 's/=.*/=***/' || true
else
    echo "WARNING: $ENV_FILE not found."
fi

# 4) MinIO Client + bucket
echo ""
echo "--- 4) Bucket (minio-mc) ---"
BUCKET="${RECORDS_BUCKET:-records}"
ALIAS=minio-local
ENDPOINT="${MINIO_ENDPOINT:-http://127.0.0.1:9000}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Skip: no .env"
    exit 0
fi

# Load MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET
export MINIO_ROOT_USER= MINIO_ROOT_PASSWORD= RECORDS_BUCKET=records
while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="${line%%#*}"
    [[ -z "$line" || "$line" != *=* ]] && continue
    key="${line%%=*}"; key="${key%"${key##*[![:space:]]}"}"
    val="${line#*=}"; val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    val="${val%$'\r'}"; [[ "$val" == \"*\" ]] && val="${val%\"}"; val="${val#\"}"
    [[ "$val" == \'*\' ]] && val="${val%\'}"; val="${val#\'}"
    printf -v "$key" %s "$val"
    export "$key"
done < "$ENV_FILE"

RECORDS_BUCKET="${RECORDS_BUCKET:-records}"
if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ]; then
    echo "Skip: MINIO_ROOT_USER or MINIO_ROOT_PASSWORD not set in .env"
    exit 0
fi

MC_CMD=""
if command -v minio-mc >/dev/null 2>&1; then
    MC_CMD=minio-mc
elif command -v mc >/dev/null 2>&1; then
    mc --version 2>&1 | grep -qi minio && MC_CMD=mc
fi
if [ -z "$MC_CMD" ]; then
    echo "Skip: MinIO Client (minio-mc) not installed."
    exit 0
fi

"$MC_CMD" alias set "${ALIAS}" "${ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" 2>/dev/null || true
echo "Bucket list:"
"$MC_CMD" ls "${ALIAS}/" 2>/dev/null || echo "Failed to list buckets (check MinIO is up and credentials)."
echo ""
echo "Anonymous policy for ${ALIAS}/${RECORDS_BUCKET}:"
"$MC_CMD" anonymous get "${ALIAS}/${RECORDS_BUCKET}" 2>/dev/null || echo " (get failed)"
echo ""
echo "Test PUT (small file):"
TMPF="/tmp/minio-check-$$.txt"
echo "check" > "$TMPF"
if "$MC_CMD" cp "$TMPF" "${ALIAS}/${RECORDS_BUCKET}/check-$$.txt" 2>/dev/null; then
    echo "  PUT OK. Removing test object."
    "$MC_CMD" rm "${ALIAS}/${RECORDS_BUCKET}/check-$$.txt" 2>/dev/null || true
else
    echo "  PUT FAILED (this may explain AllAccessDisabled from portal)."
fi
rm -f "$TMPF"

echo ""
echo "=== Done ==="
