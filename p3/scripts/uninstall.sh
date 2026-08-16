#!/bin/bash
# Removes everything that install.sh installed: k3d, kubectl and Docker.
#
# WARNING: removing Docker deletes ALL containers, images and volumes on this
#          machine, not only the ones of this project.
#
# For Debian / Ubuntu. Run it as a normal user (it calls sudo itself).

set -e

echo "This will remove k3d, kubectl and Docker from this machine."
echo "All Docker containers, images and volumes will be lost."
read -p "Type 'yes' to continue: " ANSWER

if [ "$ANSWER" != "yes" ]; then
  echo "Cancelled, nothing was removed."
  exit 0
fi

echo "==> 1/5  Deleting the k3d clusters"
# Done first, while k3d and Docker still work.
if command -v k3d > /dev/null; then
  k3d cluster delete --all || true
fi

echo "==> 2/5  Removing k3d"
sudo rm -f /usr/local/bin/k3d

echo "==> 3/5  Removing kubectl"
sudo rm -f /usr/local/bin/kubectl
rm -rf ~/.kube

echo "==> 4/5  Removing Docker"
sudo systemctl stop docker || true
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true
sudo apt-get autoremove -y
# The images, containers and volumes, then the apt repository added by Docker.
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc

echo "==> 5/5  Removing my user from the docker group"
sudo gpasswd -d $USER docker || true
sudo groupdel docker || true

echo
echo "Uninstall finished."
echo "Note: curl was NOT removed, because other programs need it."
