#!/bin/bash
set -euo pipefail

# Saves the kubeconfig to /root/kubeconfig.yaml with the server IP substituted.
# After terraform apply completes, run the output command to copy it locally.

SERVER_IP=$(curl -s ifconfig.me)

cp /etc/rancher/k3s/k3s.yaml /root/kubeconfig.yaml
sed -i "s/127.0.0.1/${SERVER_IP}/g" /root/kubeconfig.yaml

echo "==> kubeconfig saved to /root/kubeconfig.yaml"
echo "==> To copy to your local machine run:"
echo "    scp root@${SERVER_IP}:/root/kubeconfig.yaml ~/.kube/config"
