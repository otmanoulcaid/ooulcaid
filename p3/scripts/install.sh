#!/bin/bash
# Installs everything Part 3 needs: Docker, kubectl and k3d.
# For Debian / Ubuntu. Run it once, as a normal user (it calls sudo itself).

set -e   # stop the script as soon as a command fails

echo "==> 1/4  Installing curl"
sudo apt-get update
sudo apt-get install -y curl

echo "==> 2/4  Installing Docker"
curl -fsSL https://get.docker.com | sudo sh
# Let my user talk to Docker without sudo (k3d needs this).
sudo usermod -aG docker $USER

echo "==> 3/4  Installing kubectl"
KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
curl -Lo kubectl "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
sudo install -m 755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "==> 4/4  Installing k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash

echo
echo "Installation finished:"
docker --version
kubectl version --client
k3d version
echo
echo "IMPORTANT: log out and log back in so the docker group applies."
echo "           (or, just for this terminal, run: newgrp docker)"
echo
echo "Next step:  ./create_cluster.sh"
