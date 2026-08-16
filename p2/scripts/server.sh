#!/bin/bash
# Installs K3s in server mode and deploys the three applications.

set -e

IP=192.168.56.110

IFACE=$(ip -o -4 addr show | grep "$IP" | awk '{print $2}')

echo "==> 1/3  Installing K3s (server) on $IFACE"
# Traefik is kept this time: it is the Ingress that routes app1/app2/app3.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  --node-ip=$IP \
  --advertise-address=$IP \
  --flannel-iface=$IFACE \
  --write-kubeconfig-mode=644" sh -

echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc

echo "==> 2/3  Waiting for the node to be ready"
kubectl wait --for=condition=Ready node --all --timeout=300s

echo "==> 3/3  Deploying the three applications and the Ingress"
kubectl apply -f /vagrant/confs/

kubectl get pods
kubectl get ingress
