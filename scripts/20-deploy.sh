#!/usr/bin/env bash
# usage: ./scripts/20-deploy.sh <phase>   e.g. a-baseline | b-rightsized | c-spot | d-spot-keda
# Commit your phase file change first, so the commit SHA identifies the phase in cost data.
set -euo pipefail
cd "$(dirname "$0")/.."
PHASE="${1:?phase name required, e.g. a-baseline}"

if [ -n "$(git status --porcelain phases/)" ]; then
  echo "Uncommitted changes in phases/. Commit first so the commit label is meaningful."; exit 1
fi

set -a
# shellcheck disable=SC1090
source "phases/${PHASE}.env"
set +a
GIT_SHA=$(git rev-parse --short HEAD)
export GIT_SHA

kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -
envsubst '${TEAM} ${GIT_SHA} ${REPLICAS} ${CAPACITY} ${CPU_REQ} ${MEM_REQ}' < k8s/app.yaml.tpl | kubectl apply -f -

if [ "$ENABLE_KEDA" = "true" ]; then
  kubectl apply -f k8s/keda-scaledobject.yaml
else
  kubectl -n shop delete scaledobject web-scaler --ignore-not-found
  kubectl -n shop scale deploy/web --replicas="$REPLICAS"
fi

mkdir -p results
date -u +"%Y-%m-%dT%H:%M:%SZ phase=${PHASE} commit=${GIT_SHA}" | tee -a results/phase-log.txt
kubectl -n shop get pods -o wide
