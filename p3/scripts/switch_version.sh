#!/usr/bin/env bash
# =============================================================================
# Inception-of-Things - Part 3
# Demo helper: switches the deployed image tag (v1 <-> v2) THROUGH GIT.
#
# It only edits + commits + pushes the manifest. Nothing is applied to the
# cluster by hand: Argo CD notices the new commit and rolls the change out.
#
# Usage:  ./switch_version.sh v2
# =============================================================================
set -euo pipefail

VERSION="${1:-}"
IMAGE_REPO="wil42/playground"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT="${SCRIPT_DIR}/../confs/app/deployment.yaml"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[x]${NC} $*" >&2; exit 1; }

[[ "${VERSION}" =~ ^v[0-9]+$ ]] || die "usage: $0 <v1|v2>"
[[ -f "${DEPLOYMENT}" ]] || die "manifest not found: ${DEPLOYMENT}"

CURRENT="$(grep -oE "${IMAGE_REPO}:v[0-9]+" "${DEPLOYMENT}" | head -n1 | cut -d: -f2)"
if [[ "${CURRENT}" == "${VERSION}" ]]; then
  warn "Already pinned to ${VERSION} in Git, nothing to commit"
else
  log "Bumping ${IMAGE_REPO}: ${CURRENT} -> ${VERSION}"
  sed -i "s#${IMAGE_REPO}:v[0-9]\+#${IMAGE_REPO}:${VERSION}#g" "${DEPLOYMENT}"
  git -C "${SCRIPT_DIR}/.." add "$(basename "$(dirname "${DEPLOYMENT}")")/$(basename "${DEPLOYMENT}")" 2>/dev/null \
    || git add "${DEPLOYMENT}"
  git commit -m "p3: deploy playground ${VERSION}"
  git push
  log "Pushed. Argo CD polls the repository every 3 minutes."
fi

log "Force an immediate sync (optional):"
echo "    kubectl patch application playground -n argocd --type merge \\"
echo "      -p '{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{\"revision\":\"HEAD\"}}}'"
echo
log "Then watch the rollout:"
echo "    kubectl rollout status deployment/ooulcaid-playground -n dev"
echo "    curl http://localhost:8888/"
