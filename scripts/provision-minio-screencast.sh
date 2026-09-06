#!/usr/bin/env bash
# Provision the screencast-sessions bucket with a scoped, non-root identity.
#
# Root credentials are used exactly once, here, because MinIO admin operations
# require them. Nothing at runtime uses root: the service authenticates as a
# service account whose policy cannot address any other bucket -- notably not
# speakasap-records, which holds ~618G of live lesson audio.
#
# The real `mc` exists only inside the MinIO pod. On the host, `mc` is GNU
# Midnight Commander, so every step here runs via `kubectl exec`.
set -euo pipefail

NS=statex-apps
DEPLOY=deploy/minio-microservice
BUCKET=screencast-sessions
POLICY=screencast-rw
MINIO_USER=screencast-recorder

mck() { kubectl exec -n "$NS" "$DEPLOY" -- mc "$@"; }

# The pod's `local` alias carries no stored credentials; set it from the running
# MinIO's own root environment so the secret never crosses the host boundary.
kubectl exec -n "$NS" "$DEPLOY" -- sh -c \
  'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null'

mck mb --ignore-existing "local/${BUCKET}"

kubectl exec -i -n "$NS" "$DEPLOY" -- sh -c "cat > /tmp/${POLICY}.json" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${BUCKET}"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": ["arn:aws:s3:::${BUCKET}/*"]
    }
  ]
}
EOF

mck admin policy create local "$POLICY" "/tmp/${POLICY}.json" 2>/dev/null \
  || echo "policy ${POLICY} already exists; continuing"

echo "Bucket ${BUCKET} and policy ${POLICY} ready."
echo "User ${MINIO_USER} and its service account are created by the caller,"
echo "which stages the generated keys straight into Vault without printing them."
