#!/usr/bin/env bash
# Removes everything. Order matters: delete workloads and Karpenter nodes first,
# otherwise EC2 instances can be left behind and keep billing.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl delete namespace shop loadgen --ignore-not-found
kubectl delete nodepool default --ignore-not-found --wait=true
kubectl delete ec2nodeclass default --ignore-not-found
helm uninstall kps -n monitoring || true
helm uninstall opencost -n opencost || true
helm uninstall keda -n keda || true
helm uninstall karpenter -n kube-system || true
sleep 60
terraform -chdir=terraform destroy
echo "Check the EC2 console for leftover instances, volumes and load balancers tagged Project=cost-per-commit."
