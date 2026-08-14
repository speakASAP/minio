# deploy.config.sh — declaration consumed by shared/scripts/deploy.sh.
# See shared/docs/DEPLOY_STANDARD.md for the config format.
#
# Migrated from scripts/deploy.sh on 2026-08-14 so this service can take part in
# the automatic deploy queue (shared/scripts/deploy-queue/).
#
# This service builds NOTHING. All three deployments run upstream images:
#   minio-microservice -> minio/minio          (object store itself)
#   minio-admin-api    -> python:3.11-alpine   (runs backend/wrapper_api.py from a ConfigMap)
#   minio-web          -> nginx:1.27-alpine    (static UI from k8s/web/configmap.yaml)
# The legacy script had a BUILD_IMAGE=1 path that built $PROJECT_ROOT, but there
# is no Dockerfile in this repo, so that path could never have worked; it is not
# carried over. Code ships as ConfigMap content, which is why deploy_post_manifests
# below regenerates the wrapper ConfigMap on every deploy.

SERVICE_NAME="minio-microservice"
PORT="9000"

# Empty: nothing is built or pushed for this service.
IMAGES=()

# Empty image-name => the runner skips `kubectl set image` (there is no
# registry image to point at) but still waits for the rollout. The restart
# itself is triggered in deploy_post_manifests, matching the legacy script.
#
# minio-web is deliberately absent: the legacy script applied its manifests but
# never restarted it, because the nginx pod picks up k8s/web/configmap.yaml via
# a volume mount rather than at container start. Adding it here would change
# deploy behaviour, not just its mechanics.
DEPLOYMENTS=(
  "minio-microservice|app|"
  "minio-admin-api|api|"
)

MANIFESTS=(configmap.yaml external-secret.yaml deployment.yaml service.yaml ingress.yaml)

# The admin API's source lives in the repo but runs from a ConfigMap mounted
# into a stock python image, so the ConfigMap must be rewritten from the working
# tree before the pod restarts — otherwise a code change deploys as a no-op.
# The sub-manifests under k8s/admin-api and k8s/web are applied here because the
# runner's MANIFESTS list is flat and covers only the top-level k8s dir.
deploy_post_manifests() {
  if [ -d "${PROJECT_ROOT}/k8s/admin-api" ]; then
    kubectl create configmap minio-admin-api \
      --from-file=wrapper_api.py="${PROJECT_ROOT}/backend/wrapper_api.py" \
      -n "$NAMESPACE" \
      --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f "${PROJECT_ROOT}/k8s/admin-api/deployment.yaml" -n "$NAMESPACE"
    kubectl apply -f "${PROJECT_ROOT}/k8s/admin-api/service.yaml" -n "$NAMESPACE"
  fi

  if [ -d "${PROJECT_ROOT}/k8s/web" ]; then
    kubectl apply -f "${PROJECT_ROOT}/k8s/web/configmap.yaml" -n "$NAMESPACE"
    kubectl apply -f "${PROJECT_ROOT}/k8s/web/deployment.yaml" -n "$NAMESPACE"
    kubectl apply -f "${PROJECT_ROOT}/k8s/web/service.yaml" -n "$NAMESPACE"
    kubectl apply -f "${PROJECT_ROOT}/k8s/web/ingress.yaml" -n "$NAMESPACE"
  fi

  # Nothing is built, so no tag changes and `kubectl set image` has nothing to
  # do; an explicit restart is the only way a ConfigMap change reaches a pod.
  kubectl rollout restart "deployment/${SERVICE_NAME}" -n "$NAMESPACE"
  if [ -d "${PROJECT_ROOT}/k8s/admin-api" ]; then
    kubectl rollout restart deployment/minio-admin-api -n "$NAMESPACE"
  fi
}
