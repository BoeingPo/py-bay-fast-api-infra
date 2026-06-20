#!/bin/bash
set -euo pipefail

echo "==> Installing ArgoCD"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

echo "==> ArgoCD initial admin password:"
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "==> ArgoCD installed. Access via: kubectl port-forward svc/argocd-server -n argocd 8080:443"
