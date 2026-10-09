#!/usr/bin/env bash
# usage: ./scripts/50-aws-cost.sh 2026-10-10 2026-10-11   (end date is exclusive)
# Real AWS spend for the lab, grouped by usage type (BoxUsage = on-demand, SpotUsage = spot).
# Prerequisite: activate the cost allocation tag "Project" in Billing > Cost allocation tags
# (it can take up to ~24h to appear). Each Cost Explorer API call costs about $0.01.
set -euo pipefail
START="${1:?start YYYY-MM-DD}"
END="${2:?end YYYY-MM-DD}"
mkdir -p results
aws ce get-cost-and-usage \
  --time-period "Start=${START},End=${END}" \
  --granularity DAILY \
  --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["cost-per-commit"]}}' \
  --group-by Type=DIMENSION,Key=USAGE_TYPE \
  --output json | tee "results/aws-cost-${START}_${END}.json" | \
  jq -r '.ResultsByTime[] | .TimePeriod.Start as $d | .Groups[] | [$d, .Keys[0], .Metrics.UnblendedCost.Amount] | @tsv'
