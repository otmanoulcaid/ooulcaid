#!/usr/bin/env bash
# =============================================================================
# Inception-of-Things - Part 3
# Installs every tool required to run the K3d + Argo CD lab.
#
# Target: Debian / Ubuntu (latest stable), amd64 or arm64.
# Idempotent: safe to re-run, already-installed tools are skipped.
#
# Usage:  ./install.sh          (run as a normal user, sudo is used internally)
# =============================================================================
set -euo pipefail

# ------------------------------- helpers -------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[x]${NC} $*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

[[ $EUID -eq 0 ]] && SUDO="" || SUDO="sudo"

case "$(uname -m)" in
  x86_64|amd64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

# --------------------------- base packages -----------------------------------
log "Updating apt cache and installing base packages"
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq \
  ca-certificates curl gnupg lsb-release git jq apt-transport-https

# ------------------------------- docker --------------------------------------
if has docker; then
  log "docker already installed ($(docker --version))"
else
  log "Installing Docker Engine from the official repository"
  $SUDO install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg" \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
$(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

log "Enabling the docker service"
$SUDO systemctl enable --now docker >/dev/null 2>&1 || warn "systemd not available, start docker manually"

# k3d talks to the docker socket: the current user must be in the docker group.
if ! id -nG "$USER" | grep -qw docker; then
  log "Adding '$USER' to the docker group"
  $SUDO usermod -aG docker "$USER"
  warn "Group change needs a new session: log out/in, or run 'newgrp docker'"
fi

# ------------------------------- kubectl -------------------------------------
if has kubectl; then
  log "kubectl already installed ($(kubectl version --client -o json 2>/dev/null | jq -r .clientVersion.gitVersion))"
else
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  log "Installing kubectl ${KUBECTL_VERSION}"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
  $SUDO install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
fi

# --------------------------------- k3d ---------------------------------------
if has k3d; then
  log "k3d already installed ($(k3d version | head -n1))"
else
  log "Installing k3d"
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | $SUDO bash
fi

# ------------------------------ argocd CLI -----------------------------------
if has argocd; then
  log "argocd CLI already installed ($(argocd version --client --short 2>/dev/null))"
else
  log "Installing the Argo CD CLI"
  ARGOCD_VERSION="$(curl -fsSL https://api.github.com/repos/argoproj/argo-cd/releases/latest | jq -r .tag_name)"
  curl -fsSLo /tmp/argocd \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}"
  $SUDO install -o root -g root -m 0755 /tmp/argocd /usr/local/bin/argocd
  rm -f /tmp/argocd
fi

# ------------------------------- summary -------------------------------------
echo
log "Installation complete:"
printf '    docker  : %s\n' "$(docker --version 2>/dev/null || echo 'n/a')"
printf '    kubectl : %s\n' "$(kubectl version --client -o json 2>/dev/null | jq -r .clientVersion.gitVersion || echo 'n/a')"
printf '    k3d     : %s\n' "$(k3d version 2>/dev/null | head -n1 || echo 'n/a')"
printf '    argocd  : %s\n' "$(argocd version --client --short 2>/dev/null || echo 'n/a')"
echo
log "Next step: ./create_cluster.sh"
