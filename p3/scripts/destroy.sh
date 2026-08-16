#!/usr/bin/env bash
# =============================================================================
# Inception-of-Things - Part 3
# Deletes the K3d cluster created by create_cluster.sh.
#
# Usage:  ./destroy.sh
# =============================================================================
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-ooulcaid-iot}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  echo -e "${GREEN}[+]${NC} Deleting the cluster '${CLUSTER_NAME}'"
  k3d cluster delete "${CLUSTER_NAME}"
else
  echo -e "${YELLOW}[!]${NC} No cluster named '${CLUSTER_NAME}'"
fi
