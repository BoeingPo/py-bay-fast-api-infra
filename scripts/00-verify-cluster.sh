#!/bin/bash
set -euo pipefail

# Read-only pre-flight check for join_existing_cluster = true.
# Confirms k3s + ArgoCD are already running before we register a new Application —
# never installs or restarts anything itself.

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "==> Verifying existing k3s + ArgoCD cluster..."

if ! kubectl get nodes 2>/dev/null | grep -q " Ready"; then
  echo "ERROR: no Ready k3s node found. This doesn't look like an already-bootstrapped cluster." >&2
  echo "       Set join_existing_cluster = false in terraform.tfvars to bootstrap a fresh VPS instead." >&2
  exit 1
fi

if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
  echo "ERROR: argocd-server deployment not found in the argocd namespace — ArgoCD isn't installed here." >&2
  echo "       Set join_existing_cluster = false in terraform.tfvars to bootstrap a fresh VPS instead." >&2
  exit 1
fi

echo "==> Verified: k3s node Ready, ArgoCD already installed. Safe to register py-bay-fast-api-app-of-apps."
