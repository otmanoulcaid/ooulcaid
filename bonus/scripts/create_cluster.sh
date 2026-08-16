#!/bin/bash

set -e

cd "$(dirname "$0")"   # always work from the scripts/ folder

echo "==> 1/6  Creating the cluster 'ooulcaid-bonus'"
# 8888 -> the application, 8929 -> GitLab.
k3d cluster create ooulcaid-bonus \
  --servers 1 \
  --agents 1 \
  --port "8888:30888@loadbalancer" \
  --port "8929:30929@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" \
  --wait

echo "==> 2/6  Creating the namespaces argocd, dev and gitlab"
kubectl apply -f ../confs/namespaces.yaml

echo "==> 3/6  Installing GitLab with Helm (this takes 10 to 20 minutes)"
# Chart 9.11.10 = GitLab 18.11.9. This chart still ships its own PostgreSQL,
# Redis and MinIO, so GitLab runs on its own. Since chart 10 those have to be
# installed and configured separately, which this lab does not need.
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --version 9.11.10 \
  --namespace gitlab \
  --values ../confs/gitlab-values.yaml \
  --timeout 1800s \
  --wait
kubectl apply -f ../confs/gitlab-service.yaml

echo "==> 4/6  Installing Argo CD"
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> 5/6  Waiting for Argo CD to start"
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=900s

echo "==> 6/6  Reading the GitLab root password"
echo
echo "-----------------------------------------"
echo " GitLab   : http://localhost:8929"
echo " Username : root"
echo -n " Password : "
kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d
echo
echo "-----------------------------------------"
echo
echo "Now do this once, in the GitLab web interface:"
echo "  1. log in with the user and password above"
echo "  2. create a PUBLIC project named 'playground'"
echo "  3. push the application files into it:"
echo
echo "       cd ../confs/app"
echo "       git init"
echo "       git remote add origin http://localhost:8929/root/playground.git"
echo "       git add . && git commit -m 'first version'"
echo "       git push -u origin master"
echo
echo "  4. then run:  ./deploy_app.sh"
echo
