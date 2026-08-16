#!/bin/bash
# Changes the version of the application (v1 or v2).
#
# The important idea: this script does NOT touch the cluster.
# It only changes the file in Git and pushes it to GitHub.
# Argo CD reads GitHub and updates the cluster by itself.
#
# Usage:  ./switch_version.sh v1
#         ./switch_version.sh v2

set -e

cd "$(dirname "$0")"   # always work from the scripts/ folder

VERSION=$1

if [ "$VERSION" != "v1" ] && [ "$VERSION" != "v2" ]; then
  echo "Usage: ./switch_version.sh v1"
  echo "       ./switch_version.sh v2"
  exit 1
fi

FILE=../confs/app/deployment.yaml

echo "==> 1/4  Writing wil42/playground:$VERSION into $FILE"
sed -i "s|wil42/playground:v.|wil42/playground:$VERSION|" $FILE
grep "image:" $FILE

echo "==> 2/4  Sending the change to GitHub"
git add $FILE
git commit -m "deploy playground $VERSION"
git push

echo "==> 3/4  Asking Argo CD to look at GitHub right now"
# Without this, Argo CD would find the change on its own, but only
# within 3 minutes (that is how often it checks the repository).
kubectl annotate application playground -n argocd argocd.argoproj.io/refresh=hard --overwrite

echo "==> 4/4  Waiting for the new version to be running"
sleep 10
kubectl rollout status deployment/ooulcaid-playground -n dev

echo
echo "The application now answers:"
curl http://localhost:8888/
echo
