#!/usr/bin/env bash
# Prints p95 CPU and memory actually used by the web pods over the last 24h (via Prometheus).
# Use this to choose right-sized requests for phase B, with a margin you can defend.
set -euo pipefail
kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 9090:9090 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF' EXIT
sleep 3
q() { curl -s -G localhost:9090/api/v1/query --data-urlencode "query=$1" | jq -r '.data.result[] | [.metric.pod, .value[1]] | @tsv'; }
echo "p95 CPU (cores) per pod, 24h:"
q 'quantile_over_time(0.95, rate(container_cpu_usage_seconds_total{namespace="shop",container="web"}[5m])[24h:1m])'
echo "p95 memory (bytes) per pod, 24h:"
q 'quantile_over_time(0.95, container_memory_working_set_bytes{namespace="shop",container="web"}[24h])'
