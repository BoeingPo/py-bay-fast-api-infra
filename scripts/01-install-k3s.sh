#!/bin/bash
set -euo pipefail

K3S_VERSION="${1:-v1.30.0+k3s1}"

echo "==> Installing k3s ${K3S_VERSION} (Traefik disabled)"

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="${K3S_VERSION}" \
  INSTALL_K3S_EXEC="--disable traefik" \
  sh -

# Wait for node to be ready
echo "==> Waiting for k3s node to be ready..."
until kubectl get node 2>/dev/null | grep -q " Ready"; do sleep 3; done

echo "==> k3s installed successfully"
kubectl get node
