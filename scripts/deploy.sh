#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# shellcheck disable=SC1091
source "$(dirname "$PROJECT_ROOT")/shared/scripts/load-deploy-phase-timing.sh" "$PROJECT_ROOT" 2>/dev/null \
  || source "$HOME/Documents/Github/shared/scripts/load-deploy-phase-timing.sh" "$PROJECT_ROOT" \
  || { echo "Error: deploy timing library not found" >&2; exit 1; }
deploy_timing_init "minio-microservice"

SERVICE_NAME="minio-microservice"
REGISTRY="localhost:5000"
NAMESPACE="statex-apps"
PORT="9000"
DEFAULT_TAG="$(
  cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null \
    || echo "build-$(date -u +%Y%m%d%H%M%S)"
)"
IMAGE_TAG="${1:-$DEFAULT_TAG}"
IMAGE="${REGISTRY}/${SERVICE_NAME}:${IMAGE_TAG}"
IMAGE_LATEST="${REGISTRY}/${SERVICE_NAME}:latest"
BUILD_IMAGE="${BUILD_IMAGE:-0}"

preflight_service_health() {
  echo -e "${YELLOW}Preflight: checking Kubernetes and current service health...${NC}"

  if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo -e "${RED}Namespace not found: $NAMESPACE${NC}"
    exit 1
  fi

  if ! kubectl get nodes >/dev/null 2>&1; then
    echo -e "${RED}kubectl cannot reach cluster${NC}"
    exit 1
  fi

  BAD_PODS=$(kubectl get pods -n "$NAMESPACE" -l "app=${SERVICE_NAME},!job-name" --no-headers 2>/dev/null | awk '$3 ~ /Error|CrashLoopBackOff|ImagePullBackOff|CreateContainerConfigError|CreateContainerError|ErrImagePull/ {print $1}')
  if [ -n "$BAD_PODS" ]; then
    echo -e "${RED}Service has unhealthy pods before deploy:${NC}"
    kubectl get pods -n "$NAMESPACE" -l "app=${SERVICE_NAME},!job-name" -o wide || true
    for pod in $BAD_PODS; do
      echo -e "${YELLOW}--- describe pod/$pod ---${NC}"
      kubectl describe pod -n "$NAMESPACE" "$pod" || true
      echo -e "${YELLOW}--- logs pod/$pod (tail 80) ---${NC}"
      kubectl logs -n "$NAMESPACE" "$pod" --tail=80 || true
    done
    echo -e "${RED}Fix pod errors first, then redeploy.${NC}"
    exit 1
  fi

  echo -e "${GREEN}Preflight passed${NC}"
}

echo -e "${BLUE}"
echo "=========================================================="
echo "  MinIO Microservice - Kubernetes Deployment"
echo "=========================================================="
echo -e "${NC}"

deploy_timing_run_phase "Preflight" preflight_service_health

if [ "$BUILD_IMAGE" = "1" ]; then
  deploy_timing_phase_start "Build images"
  docker build -t "$IMAGE" -t "$IMAGE_LATEST" "$PROJECT_ROOT"
  deploy_timing_phase_end "Build images"
  deploy_timing_phase_start "Push images"
  docker push "$IMAGE"
  docker push "$IMAGE_LATEST"
  deploy_timing_phase_end "Push images"
fi

deploy_timing_phase_start "Apply Kubernetes manifests"
kubectl apply -f "$PROJECT_ROOT/k8s/configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/external-secret.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/service.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/ingress.yaml"
deploy_timing_phase_end "Apply Kubernetes manifests"

deploy_timing_phase_start "Trigger deployment update"
if [ "$BUILD_IMAGE" = "1" ]; then
  kubectl set image deployment/${SERVICE_NAME} app="${IMAGE}" -n "${NAMESPACE}"
else
  kubectl rollout restart deployment/${SERVICE_NAME} -n "${NAMESPACE}"
fi
deploy_timing_phase_end "Trigger deployment update"

deploy_timing_phase_start "Wait for rollout"
deploy_timing_k8s_rollout_wait kubectl "$SERVICE_NAME" "$NAMESPACE"
deploy_timing_phase_end "Wait for rollout"

deploy_timing_phase_start "Health check"
POD_READY="$(kubectl get pods -n "${NAMESPACE}" -l app=${SERVICE_NAME} --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].status.containerStatuses[0].ready}')"
if [ "${POD_READY}" != "true" ]; then
  kubectl get pods -n "${NAMESPACE}" -l app=${SERVICE_NAME}
  exit 1
fi
deploy_timing_phase_end "Health check"

deploy_timing_finish_success "MinIO Microservice"
echo "Image: ${IMAGE}"
DEPLOY_TIMING_FINISHED=1
exit 0
