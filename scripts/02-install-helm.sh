#!/bin/bash
set -euo pipefail

echo "==> Installing Helm"

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

# bitnami is here for when you add Redis/Kafka/etc. via Helm later
echo "==> Adding Helm repos"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

echo "==> Helm ready"
