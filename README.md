# py-bay-fast-api-infra

Terraform for getting [py-bay-fast-api](https://github.com/BoeingPo/py-bay-fast-api) running on a k3s + ArgoCD
cluster, via [`py-bay-fast-api-gitops`](https://github.com/BoeingPo/py-bay-fast-api-gitops).

**This VPS already runs `go-ledger-x` in production**, bootstrapped separately by `go-ledger-x-infra`. k3s,
ArgoCD, cert-manager, nginx-ingress, and sealed-secrets are already installed and serving real traffic on it.
`go-ledger-x` and `py-bay-fast-api` use **two separate, unrelated GitHub accounts** (`boeing-po` vs `BoeingPo`)
— this repo never reads, writes, or restarts anything that belongs to go-ledger-x-infra/gitops.

## Default behavior: join the existing cluster (`join_existing_cluster = true`)

`terraform apply` with default vars does exactly two things over SSH, both safe to re-run:

1. **Verify** (`scripts/00-verify-cluster.sh`, read-only) — confirms a k3s node is `Ready` and `argocd-server`
   is already deployed. Fails fast with a clear error if either assumption is wrong, instead of silently
   falling through to an install.
2. **Register** (`scripts/04-bootstrap-argocd.sh <repo> py-bay-fast-api-app-of-apps`) — one idempotent
   `kubectl apply` of a new ArgoCD Application named **`py-bay-fast-api-app-of-apps`** (deliberately not
   `app-of-apps`, which is the name go-ledger-x-infra's root Application already uses in the same `argocd`
   namespace — using the same name would collide with/overwrite it).

That's it. **k3s, Helm, ArgoCD, and go-ledger-x's `argocd-github-creds` secret are never touched.** No service
restarts, no reinstalls.

py-bay-fast-api and py-bay-fast-api-gitops are public repos, so ArgoCD needs no git credentials to pull them
— `setup_github_creds`/`github_token` are unused in this path.

```bash
cp terraform.tfvars.example terraform.tfvars
# fill in vps_ip, ssh_private_key_path (or ssh_password) — same VPS as go-ledger-x-infra
# leave join_existing_cluster = true (the default)

terraform init
terraform apply
```

Then watch ArgoCD pick it up:
```bash
kubectl get applications -n argocd
```
You should see `py-bay-fast-api-app-of-apps`, then its children (`py-bay-fast-api`, `postgres`,
`dynamodb-local`) appear and go `Synced`/`Healthy`.

### Resource headroom

The VPS is documented (in go-ledger-x-infra's planning notes) as a minimum 2 vCPU / 4GB RAM box, and already
carries roughly 900m CPU / 1.3GB RAM in requests from go-ledger-x's services plus cluster infra (cert-manager,
nginx-ingress, sealed-secrets) — before counting ArgoCD's own control-plane pods. py-bay-fast-api + Postgres +
DynamoDB Local add roughly another 300-400m CPU / 700Mi-1Gi RAM in requests on top of that. Headroom is tight.
Before applying, check actual usage:
```bash
kubectl top nodes        # needs metrics-server
kubectl describe node | tail -20   # Allocated resources section, works without metrics-server
```
If it's too tight, trim the `resources.requests` in `py-bay-fast-api-gitops/postgres/postgres.yaml` and
`dynamodb-local/dynamodb-local.yaml`, or in `py-bay-fast-api/k8s/deployment.yaml`, before syncing.

## Bootstrapping a different, fresh VPS instead (`join_existing_cluster = false`)

Only relevant if you ever stand up py-bay-fast-api on its own separate server. Set
`join_existing_cluster = false` and Terraform falls back to the original from-scratch chain: install k3s →
Helm → ArgoCD → seed the app-of-apps (named plain `app-of-apps`, fine on a standalone cluster) → export
kubeconfig. Set `setup_github_creds = true` (plus `github_username`/`github_token`) only if the repos are
private at that point — irrelevant while they stay public.

After that one apply succeeds, never run `terraform apply` again for day-to-day ops — ArgoCD owns all
subsequent deployments either way.

## What this does NOT cover

- Ingress / TLS / a public domain — not set up yet, services are ClusterIP-only for now. When ready, reuse
  the existing nginx-ingress controller + `letsencrypt-prod` ClusterIssuer already running on this cluster
  and pick a new, non-colliding subdomain — no need to install a second ingress controller or issuer.
- Redis, Kafka — you're adding those yourself; the fresh-bootstrap path's `02-install-helm.sh` adds the
  `bitnami` Helm repo so they're one `helm install` (or a new gitops Application) away.
