#!/usr/bin/env bash
# Approximates a spot interruption by cordoning and draining one node that hosts web pods.
# This is NOT a true interruption (no 2-minute EC2 notice).
# For the real thing, use AWS Fault Injection Service: action aws:ec2:send-spot-instance-interruptions.
set -euo pipefail
NODE=$(kubectl -n shop get pods -l app=web -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
[ -n "$NODE" ] || { echo "no web pods found"; exit 1; }
echo "$(date -u +%FT%TZ) draining $NODE"
kubectl cordon "$NODE"
kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data --timeout=120s
echo "$(date -u +%FT%TZ) drained; Karpenter should replace capacity"
