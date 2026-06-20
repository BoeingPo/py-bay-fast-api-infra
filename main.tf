terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

locals {
  ssh_auth_valid = var.ssh_private_key_path != "" || var.ssh_password != ""
}

resource "null_resource" "ssh_auth_check" {
  count = local.ssh_auth_valid ? 0 : 1
  provisioner "local-exec" {
    command = "echo 'ERROR: provide either ssh_private_key_path or ssh_password in terraform.tfvars' && exit 1"
  }
}

locals {
  ssh_connection = {
    type        = "ssh"
    host        = var.vps_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key_path != "" ? file(var.ssh_private_key_path) : null
    password    = var.ssh_password != "" ? var.ssh_password : null
    timeout     = "5m"
  }
}

# --- join_existing_cluster = true (default): reuse an already-bootstrapped cluster ---
# Only ever runs a read-only health check, then one additive `kubectl apply` of a
# uniquely-named Application. Never touches k3s, Helm, ArgoCD, or any other project's resources.

resource "null_resource" "verify_existing_cluster" {
  count = var.join_existing_cluster ? 1 : 0

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    password    = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = ["rm -rf /tmp/py-bay-fast-api-scripts && mkdir -p /tmp/py-bay-fast-api-scripts"]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/tmp/py-bay-fast-api-scripts"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/py-bay-fast-api-scripts/*.sh",
      "bash /tmp/py-bay-fast-api-scripts/00-verify-cluster.sh",
    ]
  }
}

resource "null_resource" "register_app_of_apps" {
  count      = var.join_existing_cluster ? 1 : 0
  depends_on = [null_resource.verify_existing_cluster]

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    password    = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = [
      "bash /tmp/py-bay-fast-api-scripts/04-bootstrap-argocd.sh ${var.argocd_gitops_repo} py-bay-fast-api-app-of-apps",
    ]
  }
}

# --- join_existing_cluster = false: bootstrap a brand-new VPS from scratch ---
# Run once: terraform apply
# After that, ArgoCD owns all deployments — never run terraform apply again for day-to-day ops.

resource "null_resource" "fresh_cluster_bootstrap" {
  count = var.join_existing_cluster ? 0 : 1

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    password    = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = ["rm -rf /tmp/py-bay-fast-api-scripts && mkdir -p /tmp/py-bay-fast-api-scripts"]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/tmp/py-bay-fast-api-scripts"
  }

  provisioner "remote-exec" {
    inline = concat(
      [
        "chmod +x /tmp/py-bay-fast-api-scripts/*.sh",
        "bash /tmp/py-bay-fast-api-scripts/01-install-k3s.sh ${var.k3s_version}",
        "bash /tmp/py-bay-fast-api-scripts/02-install-helm.sh",
        "bash /tmp/py-bay-fast-api-scripts/03-install-argocd.sh",
        "bash /tmp/py-bay-fast-api-scripts/04-bootstrap-argocd.sh ${var.argocd_gitops_repo}",
        "bash /tmp/py-bay-fast-api-scripts/05-get-kubeconfig.sh",
      ],
      var.setup_github_creds ? ["bash /tmp/py-bay-fast-api-scripts/06-setup-argocd-github-creds.sh ${var.github_username} ${var.github_token}"] : []
    )
  }
}
