#!/bin/bash
set -euo pipefail

GITOPS_REPO="${1:?usage: $0 <gitops-repo-url> [app-name]}"
APP_NAME="${2:-app-of-apps}"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "==> Bootstrapping ArgoCD app-of-apps '${APP_NAME}' from ${GITOPS_REPO}"

# Apply the root Application manifest directly from the gitops repo
kubectl apply -n argocd -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GITOPS_REPO}
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "==> ${APP_NAME} applied. ArgoCD will now deploy everything automatically."
echo "    Watch progress: kubectl get applications -n argocd"
