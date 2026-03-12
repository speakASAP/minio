#!/usr/bin/env bash
# Setup MinIO on dev server: create user, data dir, systemd unit.
# Run with sudo on dev (85.163.140.109).
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
# Unit expects EnvironmentFile (path to .env on dev)
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
echo "  4. Bind mount so files appear at ${SPEAKASAP_RECORDS_MOUNT}/YYYY/MM/DD/:"
echo "     sudo mount --bind ${DATA_DIR}/records ${SPEAKASAP_RECORDS_MOUNT}"
echo "     Add to /etc/fstab for boot: ${DATA_DIR}/records  ${SPEAKASAP_RECORDS_MOUNT}  none  bind  0  0"
