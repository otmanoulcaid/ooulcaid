#!/bin/bash
# Builds the whole Part 3 setup:
#   1. a K3d cluster
#   2. the two namespaces: argocd and dev
#   3. Argo CD inside the argocd namespace
#   4. the Application, which tells Argo CD to deploy our app from GitHub
#
# Run it after ./install.sh. It takes a few minutes the first time
# (it downloads the Argo CD images).

set -e

# cd "$(dirname "$0")"   # always work from the scripts/ folder

# echo "==> 1/5  Creating the cluster 'ooulcaid-iot'"
# # --port publishes port 8888 of my machine to the NodePort 30888 of the cluster,
# # so http://localhost:8888 reaches the application.
# # --k3s-arg disables Traefik: we do not need an Ingress in this part.
# k3d cluster create ooulcaid-iot \
#   --servers 1 \
#   --agents 1 \
#   --port "8888:30888@loadbalancer" \
#   --k3s-arg "--disable=traefik@server:0" \
#   --wait

# echo "==> 2/5  Creating the namespaces argocd and dev"
# kubectl apply -f ../confs/namespaces.yaml

# echo "==> 3/5  Installing Argo CD"
# # --server-side is needed because the Argo CD file is too big for a normal apply.
# kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# echo "==> 4/5  Waiting for Argo CD to start (this is the long part)"
# kubectl wait --for=condition=Available deployment --all -n argocd --timeout=900s

# echo "==> 5/5  Telling Argo CD to deploy our app from GitHub"
# kubectl apply -f ../confs/argocd-application.yaml

echo
echo
echo "Waiting for Argo CD to synchronize the application..."

kubectl wait \
  --for=jsonpath='{.status.sync.status}'=Synced \
  application/playground \
  -n argocd \
  --timeout=300s

echo "Application synchronized."

kubectl wait \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application/playground \
  -n argocd \
  --timeout=300s

echo "Application is healthy."

echo
echo "-----------------------------------------"
echo " Everything is ready."
echo
kubectl get namespace argocd dev
echo
kubectl get pods -n dev
echo
echo " The application : curl http://localhost:8888/"
echo " Argo CD website : ./argocd_ui.sh"
echo "-----------------------------------------"
