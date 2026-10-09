#!/usr/bin/env bash
# Installs Karpenter, kube-prometheus-stack, OpenCost, KEDA. Run after `terraform apply`.
set -euo pipefail
cd "$(dirname "$0")/.."

# Pin versions here. Check the latest stable releases before running.
KARPENTER_VERSION="${KARPENTER_VERSION:-1.3.3}"

CLUSTER=$(terraform -chdir=terraform output -raw cluster_name)
REGION=$(terraform -chdir=terraform output -raw region)
QUEUE=$(terraform -chdir=terraform output -raw karpenter_queue_name)
NODE_ROLE=$(terraform -chdir=terraform output -raw karpenter_node_role_name)

aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"

echo "==> Karpenter $KARPENTER_VERSION"
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "$KARPENTER_VERSION" -n kube-system \
  --set "settings.clusterName=$CLUSTER" \
  --set "settings.interruptionQueue=$QUEUE" \
  --set controller.resources.requests.cpu=250m \
  --set controller.resources.requests.memory=512Mi \
  --wait

export CLUSTER NODE_ROLE
envsubst '${CLUSTER} ${NODE_ROLE}' < k8s/karpenter-nodepool.yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

echo "==> kube-prometheus-stack"
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/values-kps.yaml --wait --timeout 10m

echo "==> OpenCost (check 'helm show values opencost/opencost' if keys are rejected)"
helm upgrade --install opencost opencost/opencost -n opencost --create-namespace \
  --set opencost.prometheus.internal.enabled=true \
  --set opencost.prometheus.internal.serviceName=kps-kube-prometheus-stack-prometheus \
  --set opencost.prometheus.internal.namespaceName=monitoring \
  --set opencost.prometheus.internal.port=9090 \
  --set opencost.metrics.serviceMonitor.enabled=true \
  --wait

echo "==> KEDA"
helm upgrade --install keda kedacore/keda -n keda --create-namespace --wait

kubectl apply -f monitoring/cost-rules.yaml
kubectl apply -f k8s/loadgen.yaml
echo "Done. Next: ./scripts/20-deploy.sh a-baseline"
