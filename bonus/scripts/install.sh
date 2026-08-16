#!/bin/bash
# Same as the p3 install, plus Helm (needed to install GitLab).
# For Debian / Ubuntu. Run it once, as a normal user (it calls sudo itself).

set -e

exist() {
    command -v "$1" >/dev/null 2>&1
}

if ! exist curl; then
    echo "==> 1/5  Installing curl"
    sudo apt-get update
    sudo apt-get install -y curl
fi

if ! exist docker; then
    echo "==> 2/5  Installing Docker"
    curl -fsSL https://get.docker.com | sudo sh
    # Let my user talk to Docker without sudo (k3d needs this).
    sudo usermod -aG docker $USER
fi

if ! exist kubectl; then
    echo "==> 3/5  Installing kubectl"
    KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
    curl -Lo kubectl "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    sudo install -m 755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

if ! exist k3d; then
    echo "==> 4/5  Installing k3d"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash
fi

if ! exist helm; then
    echo "==> 5/5  Installing Helm"
    curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash
fi

echo "Installation finished:"
docker --version
kubectl version --client
k3d version
helm version
echo
echo "IMPORTANT: log out and log back in so the docker group applies."
echo "           (or, just for this terminal, run: newgrp docker)"
echo
