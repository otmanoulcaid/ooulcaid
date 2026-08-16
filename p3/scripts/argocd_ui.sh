#!/bin/bash
# Opens the Argo CD web interface and prints the password to log in.

set -e

echo "-----------------------------------------"
echo " Address  : https://localhost:8080"
echo " Username : admin"
echo -n " Password : "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
echo "-----------------------------------------"
echo
echo "The browser will complain about the certificate (it is self-signed)."
echo "Click 'Advanced' then 'Continue' - it is normal."
echo
echo "Keep this terminal open. Press Ctrl+C to close the interface."
echo

# This is what makes https://localhost:8080 reach Argo CD inside the cluster.
kubectl port-forward svc/argocd-server -n argocd 8080:443
