#!/bin/bash
# Installs K3s in agent mode on ooulcaidSW and joins it to the server.

set -e

IP=192.168.56.111
SERVER_IP=192.168.56.110

IFACE=$(ip -o -4 addr show | grep "$IP" | awk '{print $2}')

echo "==> 1/2  Waiting for the token written by the server"
while [ ! -f /vagrant/node-token ]; do
  sleep 5
done

echo "==> 2/2  Installing K3s (agent) on $IFACE"
curl -sfL https://get.k3s.io | \
  K3S_URL="https://$SERVER_IP:6443" \
  K3S_TOKEN="$(cat /vagrant/node-token)" \
  INSTALL_K3S_EXEC="--node-ip=$IP --flannel-iface=$IFACE" sh -

echo "Done. Check from the server with:  kubectl get nodes"
