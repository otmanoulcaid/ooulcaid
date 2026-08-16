#!/bin/bash
# Deletes the cluster. Everything inside it disappears with it.

set -e

echo "==> Deleting the cluster 'ooulcaid-iot'"
k3d cluster delete ooulcaid-iot

echo "Done."
