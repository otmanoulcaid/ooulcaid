#!/bin/bash
# Run this AFTER the 'playground' project exists in GitLab and the
# application files have been pushed into it.
#
# It tells Argo CD to deploy from the local GitLab, then opens Argo CD.

set -e

cd "$(dirname "$0")"   # always work from the scripts/ folder

echo "==> 1/2  Telling Argo CD to deploy our app from the local GitLab"
kubectl apply -f ../confs/argocd-application.yaml

echo "==> 2/2  Waiting for Argo CD to synchronize the application"
kubectl wait \
  --for=jsonpath='{.status.sync.status}'=Synced \
  application/playground \
  -n argocd \
  --timeout=600s

kubectl wait \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application/playground \
  -n argocd \
  --timeout=600s

echo
echo "-----------------------------------------"
kubectl get namespace argocd dev gitlab
echo
kubectl get pods -n dev
echo
echo " The application : curl http://localhost:8888/"
echo " GitLab          : http://localhost:8929"
echo "-----------------------------------------"
echo " Argo CD Address : https://localhost:8080"
echo " Username : admin"
echo -n " Password : "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
echo "-----------------------------------------"
echo
echo "Keep this terminal open. Press Ctrl+C to close the interface."
echo

kubectl port-forward svc/argocd-server -n argocd 8080:443
