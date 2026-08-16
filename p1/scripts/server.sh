#!/bin/bash
# Installs K3s in controller (server) mode on ooulcaidS.

set -e

IP=192.168.56.110

# The machine has two network cards: the one Vagrant needs, and the one with
# our IP. K3s must use ours, so we look up its name (enp0s8, eth1, ...).
IFACE=$(ip -o -4 addr show | grep "$IP" | awk '{print $2}')

echo "==> 1/3  Installing K3s (server) on $IFACE"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  --node-ip=$IP \
  --advertise-address=$IP \
  --flannel-iface=$IFACE \
  --write-kubeconfig-mode=644" sh -

echo "==> 2/3  Sharing the token so the worker can join"
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

echo "==> 3/3  Making kubectl work for the vagrant user"
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc

kubectl get nodes
