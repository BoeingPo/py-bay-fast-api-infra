variable "vps_ip" {
  description = "Public IP address of the VPS/server"
  type        = string
}

variable "ssh_user" {
  description = "SSH username (usually root or ubuntu)"
  type        = string
  default     = "root"
}

variable "ssh_private_key_path" {
  description = "Path to your SSH private key, e.g. ~/.ssh/id_rsa. Leave empty if using ssh_password instead."
  type        = string
  default     = ""
}

variable "ssh_password" {
  description = "SSH password for the VPS. Leave empty if using ssh_private_key_path instead."
  type        = string
  default     = ""
  sensitive   = true
}

variable "k3s_version" {
  description = "k3s version to install, e.g. v1.30.0+k3s1"
  type        = string
  default     = "v1.30.0+k3s1"
}

variable "argocd_gitops_repo" {
  description = "HTTPS URL of py-bay-fast-api-gitops repo, e.g. https://github.com/BoeingPo/py-bay-fast-api-gitops"
  type        = string
}

variable "join_existing_cluster" {
  description = <<-EOT
    true (default): this VPS already runs k3s + ArgoCD (e.g. bootstrapped earlier by go-ledger-x-infra).
    Terraform only verifies the cluster is healthy and registers one new Application
    (py-bay-fast-api-app-of-apps) — it never touches k3s/Helm/ArgoCD or any other project's resources.

    false: bootstrap a brand-new VPS from scratch (installs k3s, Helm, ArgoCD, then seeds the app-of-apps).
    Only use this for a separate, not-yet-provisioned server.
  EOT
  type        = bool
  default     = true
}

variable "setup_github_creds" {
  description = "Only used when join_existing_cluster = false. Set true if py-bay-fast-api-gitops/py-bay-fast-api are private repos and ArgoCD needs git credentials to pull them. Not needed for public repos."
  type        = bool
  default     = false
}

variable "github_username" {
  description = "GitHub username or org, e.g. BoeingPo. Only used if setup_github_creds = true."
  type        = string
  default     = "BoeingPo"
}

variable "github_token" {
  description = "GitHub personal access token with repo scope. Only used if setup_github_creds = true."
  type        = string
  default     = ""
  sensitive   = true
}
