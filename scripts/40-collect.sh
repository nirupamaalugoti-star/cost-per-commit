#!/usr/bin/env bash
# usage: ./scripts/40-collect.sh <phase> [window]   default window 24h
# Saves raw measurements to results/<phase>-<timestamp>/ so every number in your post is traceable.
set -euo pipefail
cd "$(dirname "$0")/.."
PHASE="${1:?phase}"
WINDOW="${2:-24h}"
OUT="results/${PHASE}-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"

kubectl -n opencost port-forward svc/opencost 9003:9003 >/dev/null 2>&1 &
PF1=$!
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090 >/dev/null 2>&1 &
PF2=$!
trap 'kill $PF1 $PF2 2>/dev/null || true' EXIT
sleep 4

echo "OpenCost allocation, window=$WINDOW"
curl -s "http://localhost:9003/allocation/compute?window=${WINDOW}&aggregate=namespace&accumulate=true" > "$OUT/opencost-namespace.json"
curl -s "http://localhost:9003/allocation/compute?window=${WINDOW}&aggregate=label:team&accumulate=true" > "$OUT/opencost-team.json"

echo "Prometheus: average modeled hourly cost per commit, nodes, replicas"
curl -s -G localhost:9090/api/v1/query \
  --data-urlencode "query=avg_over_time(commit:hourly_cost:sum[${WINDOW}])" > "$OUT/prom-cost-per-commit.json"
curl -s -G localhost:9090/api/v1/query \
  --data-urlencode "query=avg_over_time(count(kube_node_labels{label_karpenter_sh_capacity_type!=\"\"})[${WINDOW}:5m])" > "$OUT/prom-avg-karpenter-nodes.json"
curl -s -G localhost:9090/api/v1/query \
  --data-urlencode "query=avg_over_time(kube_deployment_status_replicas_available{namespace=\"shop\",deployment=\"web\"}[${WINDOW}])" > "$OUT/prom-avg-replicas.json"

echo "Load generator output (status codes, latency)"
kubectl -n loadgen logs -l app=loadgen --tail=-1 --prefix > "$OUT/loadgen.log" 2>/dev/null || true

kubectl get nodes -L karpenter.sh/capacity-type,node.kubernetes.io/instance-type > "$OUT/nodes.txt"
kubectl get events -A --sort-by=.lastTimestamp > "$OUT/events.txt" || true
cp results/phase-log.txt "$OUT/" 2>/dev/null || true

echo "Saved to $OUT"
echo "For the real AWS bill, wait ~24h for Cost Explorer, then run ./scripts/50-aws-cost.sh <start> <end>"
