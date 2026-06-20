output "argocd_url" {
  description = "ArgoCD UI — port-forward to access: kubectl port-forward svc/argocd-server -n argocd 8080:443"
  value       = "https://${var.vps_ip} (after port-forward or NodePort)"
}

output "kubeconfig_note" {
  description = "How to get kubeconfig from the server"
  value       = "scp ${var.ssh_user}@${var.vps_ip}:/root/kubeconfig.yaml ~/.kube/config"
}

output "mode" {
  description = "Which path this apply took"
  value = var.join_existing_cluster ? (
    "joined existing cluster — only registered Application 'py-bay-fast-api-app-of-apps' (no k3s/Helm/ArgoCD changes)"
    ) : (
    "fresh cluster bootstrap — installed k3s, Helm, ArgoCD, then seeded the app-of-apps"
  )
}

output "watch_command" {
  description = "Command to watch sync status after apply"
  value       = "kubectl get applications -n argocd"
}
