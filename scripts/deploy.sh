#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo -e "${BLUE}"
echo "=========================================================="
echo "  MinIO Microservice - Kubernetes Deployment"
echo "=========================================================="
echo -e "${NC}"

if [ "$BUILD_IMAGE" = "1" ]; then
  echo -e "${YELLOW}[1/6] Building images: ${IMAGE} and ${IMAGE_LATEST}...${NC}"
  docker build -t "$IMAGE" -t "$IMAGE_LATEST" "$PROJECT_ROOT"
  echo -e "${GREEN}OK Images built${NC}"

  echo -e "${YELLOW}[2/6] Pushing to registry...${NC}"
  docker push "$IMAGE"
  docker push "$IMAGE_LATEST"
  echo -e "${GREEN}OK Images pushed: ${IMAGE}, ${IMAGE_LATEST}${NC}"
else
  echo -e "${YELLOW}[1/6] Skipping Docker build/push (BUILD_IMAGE=${BUILD_IMAGE})${NC}"
fi

echo -e "${YELLOW}[3/6] Applying Kubernetes manifests...${NC}"
kubectl apply -f "$PROJECT_ROOT/k8s/configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/external-secret.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/service.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/ingress.yaml"
echo -e "${GREEN}OK Kubernetes manifests applied${NC}"

echo -e "${YELLOW}[4/6] Triggering deployment update...${NC}"
if [ "$BUILD_IMAGE" = "1" ]; then
  kubectl set image deployment/${SERVICE_NAME} \
    app="${IMAGE}" \
    -n "${NAMESPACE}"
  echo -e "${GREEN}OK Deployment updated (app=${IMAGE})${NC}"
else
  kubectl rollout restart deployment/${SERVICE_NAME} -n "${NAMESPACE}"
  echo -e "${GREEN}OK Deployment rollout restart triggered${NC}"
fi

echo -e "${YELLOW}[5/6] Waiting for rollout...${NC}"
kubectl rollout status deployment/${SERVICE_NAME} -n "${NAMESPACE}" --timeout=120s
echo -e "${GREEN}OK Rollout complete${NC}"

echo -e "${YELLOW}[6/6] Health check...${NC}"
POD_READY="$(kubectl get pods -n "${NAMESPACE}" -l app=${SERVICE_NAME} --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].status.containerStatuses[0].ready}')"
if [ "${POD_READY}" != "true" ]; then
  echo -e "${RED}ERROR Pod is not ready${NC}"
  kubectl get pods -n "${NAMESPACE}" -l app=${SERVICE_NAME}
  exit 1
fi
echo -e "\n${GREEN}OK Health check passed${NC}"

echo -e "${GREEN}"
echo "=========================================================="
echo "  Deployment successful"
echo "  Image: ${IMAGE}"
echo "=========================================================="
echo -e "${NC}"
