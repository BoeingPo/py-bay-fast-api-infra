#!/bin/bash
set -euo pipefail

GITHUB_USERNAME="${1:?usage: $0 <github-username> <github-token>}"
GITHUB_TOKEN="${2:?usage: $0 <github-username> <github-token>}"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "==> Setting up ArgoCD GitHub credentials"

kubectl create secret generic argocd-github-creds \
  --namespace argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/${GITHUB_USERNAME} \
  --from-literal=username=${GITHUB_USERNAME} \
  --from-literal=password=${GITHUB_TOKEN} \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl label secret argocd-github-creds \
  -n argocd \
  argocd.argoproj.io/secret-type=repo-creds \
  --overwrite

kubectl rollout restart deployment/argocd-repo-server -n argocd

echo "==> ArgoCD GitHub credentials configured"
