#!/usr/bin/env bash
# =============================================================================
# Inception-of-Things - Part 3
# Prints the Argo CD admin credentials and opens a port-forward to the UI.
#
# Usage:  ./argocd_ui.sh          -> https://localhost:8080  (admin / <printed>)
# =============================================================================
set -euo pipefail

UI_PORT="${UI_PORT:-8080}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret \
              -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"

echo "-------------------------------------------------------------------"
echo " Argo CD UI : https://localhost:${UI_PORT}"
echo " user       : admin"
echo " password   : ${PASSWORD:-<initial secret deleted - password was changed>}"
echo "-------------------------------------------------------------------"
warn "The certificate is self-signed: accept the browser warning."
echo
log "CLI login:  argocd login localhost:${UI_PORT} --username admin --password '${PASSWORD}' --insecure"
echo
log "Port-forwarding argocd-server, press Ctrl+C to stop"
kubectl port-forward svc/argocd-server -n argocd "${UI_PORT}:443"
