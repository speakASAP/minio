#!/usr/bin/env bash
# Setup MinIO on a DEV machine: create user, data dir, systemd unit.
#
# NOT FOR PRODUCTION. Production MinIO runs as the Kubernetes deployment
# `minio-microservice` in namespace `statex-apps` (see SYSTEM.md); deploy it
# with ./scripts/deploy.sh. A guard below refuses to run where that deployment
# exists or where /srv/speakasap-records already holds data.
# Prerequisite: MinIO binary at /usr/local/bin/minio (install manually or via script).

set -e

MINIO_USER=minio
MINIO_GROUP=minio
# MinIO stores under <data-dir>/<bucket>/<key>. Bind mount <data-dir>/records to /srv/speakasap-records so files appear at /srv/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3
DATA_DIR=/var/lib/minio-data
SPEAKASAP_RECORDS_MOUNT=/srv/speakasap-records
INSTALL_DIR=/srv/minio
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# ---------------------------------------------------------------------------
# GUARD: refuse to run against the production (Kubernetes) MinIO deployment.
#
# This script provisions a HOST-LEVEL MinIO (systemd unit on port 9000 + a bind
# mount over /srv/speakasap-records). Production MinIO runs as the k8s
# deployment `minio-microservice` in namespace `statex-apps`, serving the same
# port and hostPath. Running this script on that host would:
#   - install a systemd unit racing the pod for port 9000,
#   - bind an EMPTY dir over /srv/speakasap-records, hiding all live recordings,
#   - chown/chmod the live data directory.
# Override only for a genuine dev box: MINIO_SETUP_ALLOW_PROD=1
# ---------------------------------------------------------------------------
if [ "${MINIO_SETUP_ALLOW_PROD:-0}" != "1" ]; then
    if command -v kubectl >/dev/null 2>&1 \
       && kubectl get deployment minio-microservice -n statex-apps >/dev/null 2>&1; then
        echo "[minio] ERROR: k8s deployment 'minio-microservice' exists in namespace 'statex-apps'." >&2
        echo "[minio] This is the PRODUCTION MinIO host. Refusing to install the host-level" >&2
        echo "[minio] systemd unit: it would race the pod on port 9000 and mask live data at" >&2
        echo "[minio] ${SPEAKASAP_RECORDS_MOUNT}." >&2
        echo "[minio] Deploy production with ./scripts/deploy.sh instead." >&2
        echo "[minio] To override on a real dev machine: MINIO_SETUP_ALLOW_PROD=1 $0" >&2
        exit 1
    fi

    # Second check: existing data at the records path means this is not a clean dev box.
    if [ -d "${SPEAKASAP_RECORDS_MOUNT}" ] && [ -n "$(ls -A "${SPEAKASAP_RECORDS_MOUNT}" 2>/dev/null)" ]; then
        echo "[minio] ERROR: ${SPEAKASAP_RECORDS_MOUNT} already contains data." >&2
        echo "[minio] Refusing to proceed: this script would chown it and later instruct a" >&2
        echo "[minio] bind mount that hides the existing contents." >&2
        echo "[minio] To override on a real dev machine: MINIO_SETUP_ALLOW_PROD=1 $0" >&2
        exit 1
    fi
fi


echo "[minio] Creating group and user ${MINIO_USER}..."
if ! getent group "${MINIO_GROUP}" >/dev/null 2>&1; then
    groupadd -r "${MINIO_GROUP}"
fi
if ! id -u "${MINIO_USER}" >/dev/null 2>&1; then
    useradd -r -g "${MINIO_GROUP}" -s /sbin/nologin -d "${DATA_DIR}" "${MINIO_USER}"
fi

echo "[minio] Creating data directory ${DATA_DIR}..."
mkdir -p "${DATA_DIR}"
chown -R "${MINIO_USER}:${MINIO_GROUP}" "${DATA_DIR}"
chmod 750 "${DATA_DIR}"

echo "[minio] Creating install/config directory ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"
cp -a "${REPO_ROOT}/.env.example" "${INSTALL_DIR}/.env.example" 2>/dev/null || true
if [ ! -f "${INSTALL_DIR}/.env" ]; then
    echo "[minio] No ${INSTALL_DIR}/.env found. Copy .env.example to .env and set MINIO_ROOT_USER, MINIO_ROOT_PASSWORD."
    cp -a "${REPO_ROOT}/.env.example" "${INSTALL_DIR}/.env"
fi
# Ensure Unix line endings (no CRLF) so MinIO and init-bucket.sh use the same credentials
if [ -f "${INSTALL_DIR}/.env" ]; then
    sed -i 's/\r$//' "${INSTALL_DIR}/.env"
fi

echo "[minio] Installing systemd unit..."
cp "${REPO_ROOT}/systemd/minio.service" /etc/systemd/system/minio.service
# Unit expects EnvironmentFile (path to .env on alfares)
if ! grep -q "EnvironmentFile=${INSTALL_DIR}/.env" /etc/systemd/system/minio.service 2>/dev/null; then
    sed -i "s|EnvironmentFile=.*|EnvironmentFile=${INSTALL_DIR}/.env|" /etc/systemd/system/minio.service
fi
systemctl daemon-reload

echo "[minio] Checking MinIO binary..."
if [ ! -x /usr/local/bin/minio ]; then
    echo "[minio] WARNING: /usr/local/bin/minio not found. Install MinIO:"
    echo "  wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio"
    echo "  chmod +x /usr/local/bin/minio"
    echo "  chown minio:minio /usr/local/bin/minio"
fi

echo "[minio] Creating mount point for records (bind mount after bucket exists): ${SPEAKASAP_RECORDS_MOUNT}"
mkdir -p "${SPEAKASAP_RECORDS_MOUNT}"

echo "[minio] Setup done. Next:"
echo "  1. Edit ${INSTALL_DIR}/.env and set MINIO_ROOT_USER, MINIO_ROOT_PASSWORD"
echo "  2. systemctl enable minio && systemctl start minio"
echo "  3. Run ./scripts/init-bucket.sh to create bucket 'records'"
echo ""
echo "[minio] NOTE: no bind mount is needed or wanted."
echo "[minio] Point MinIO's data root directly at ${SPEAKASAP_RECORDS_MOUNT}; the bucket"
echo "[minio] then lives at ${SPEAKASAP_RECORDS_MOUNT}/<bucket>/YYYY/MM/DD/."
echo "[minio] Never bind another directory over ${SPEAKASAP_RECORDS_MOUNT} - it would hide"
echo "[minio] whatever is already stored there from MinIO and every consumer."
