#!/usr/bin/env bash
# =============================================================================
# Inception-of-Things - Part 3
# Creates the K3d cluster, installs Argo CD and registers the GitOps
# Application that deploys wil42/playground into the `dev` namespace.
#
# Idempotent: re-running reuses an existing cluster instead of failing.
#
# Usage:  ./create_cluster.sh
# =============================================================================
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-ooulcaid-iot}"
APP_HOST_PORT="${APP_HOST_PORT:-8888}"   # localhost:8888 -> NodePort 30888
APP_NODE_PORT=30888
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="${SCRIPT_DIR}/../confs"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[x]${NC} $*" >&2; exit 1; }

# ---------------------------- prerequisites ----------------------------------
for bin in docker k3d kubectl; do
  command -v "$bin" >/dev/null 2>&1 || die "'$bin' is missing - run ./install.sh first"
done
docker info >/dev/null 2>&1 || die "the docker daemon is unreachable (start it, or check your 'docker' group membership)"

# ------------------------------- cluster -------------------------------------
if k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  log "Cluster '${CLUSTER_NAME}' already exists, reusing it"
  k3d cluster start "${CLUSTER_NAME}" >/dev/null 2>&1 || true
else
  log "Creating the K3d cluster '${CLUSTER_NAME}' (1 server + 1 agent)"
  k3d cluster create "${CLUSTER_NAME}" \
    --servers 1 \
    --agents 1 \
    --port "${APP_HOST_PORT}:${APP_NODE_PORT}@loadbalancer" \
    --k3s-arg "--disable=traefik@server:0" \
    --wait
fi

kubectl config use-context "k3d-${CLUSTER_NAME}" >/dev/null
log "kubectl context: $(kubectl config current-context)"
kubectl wait --for=condition=Ready nodes --all --timeout=180s >/dev/null
log "Nodes ready:"
kubectl get nodes

# ------------------------------ namespaces -----------------------------------
log "Creating the 'argocd' and 'dev' namespaces"
kubectl apply -f "${CONFS_DIR}/namespaces.yaml"

# ------------------------------- argo cd -------------------------------------
log "Installing Argo CD (this pulls a fair amount of images, be patient)"
# Server-side apply: the Argo CD CRDs are larger than the 262 kB annotation
# limit that client-side apply would run into.
kubectl apply -n argocd --server-side --force-conflicts -f "${ARGOCD_MANIFEST}"

log "Waiting for the Argo CD control plane to become available"
for deploy in argocd-redis argocd-repo-server argocd-server argocd-applicationset-controller argocd-dex-server; do
  kubectl rollout status -n argocd "deployment/${deploy}" --timeout=600s
done
kubectl rollout status -n argocd statefulset/argocd-application-controller --timeout=600s

# ---------------------------- GitOps application -----------------------------
log "Registering the Argo CD Application (source of truth: GitHub)"
kubectl apply -f "${CONFS_DIR}/argocd-application.yaml"

log "Waiting for Argo CD to deploy the application into 'dev'"
for _ in $(seq 1 60); do
  if kubectl get deployment ooulcaid-playground -n dev >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

if kubectl get deployment ooulcaid-playground -n dev >/dev/null 2>&1; then
  kubectl rollout status -n dev deployment/ooulcaid-playground --timeout=300s
else
  warn "The application has not been synced yet."
  warn "Check it with: kubectl describe application playground -n argocd"
fi

# ------------------------------- summary -------------------------------------
ARGO_PWD="$(kubectl -n argocd get secret argocd-initial-admin-secret \
              -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo '<already rotated>')"

echo
log "Cluster is up."
kubectl get ns argocd dev
echo
kubectl get pods -n dev
echo
echo "-------------------------------------------------------------------"
echo " Application  : http://localhost:${APP_HOST_PORT}/"
echo " Argo CD UI   : ./argocd_ui.sh   (then https://localhost:8080)"
echo " Argo login   : admin / ${ARGO_PWD}"
echo "-------------------------------------------------------------------"
echo
log "Test it:  curl http://localhost:${APP_HOST_PORT}/"
