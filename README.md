# cost-per-commit

A real-cloud FinOps experiment: attribute Kubernetes cost to the git commit that deployed it, then cut it with
right-sizing, spot capacity (Karpenter) and scale-to-zero (KEDA). Measured with OpenCost and verified against
the AWS bill.

**Stack:** AWS EKS, Terraform, Karpenter, KEDA, kube-prometheus-stack, OpenCost, podinfo as the demo app.

## Cost warning
This creates billable AWS resources: an EKS control plane, a NAT gateway, two `t3.large` system nodes, plus
Karpenter-launched nodes. Expect roughly $7 to $10 per day before app nodes (verify with the AWS Pricing
Calculator for your region). Four phases of 24h is therefore tens of dollars. Set `budget_email` so AWS alerts
you, and run `scripts/99-teardown.sh` when finished.

## Prerequisites
AWS account and credentials, `terraform >= 1.5`, `aws` CLI v2, `kubectl`, `helm`, `jq`, `envsubst` (gettext), `git`.

## Quick start
```bash
cd terraform
terraform init
terraform apply -var="budget_email=you@example.com"
cd ..
./scripts/10-install-addons.sh
```
Activate the `Project` cost allocation tag in AWS Billing now, so it has data when you need it.

## Experiment protocol
Run each phase for the same length of time (24h or a full weekday) with the same load pattern.
1. Phase A: `git add -A && git commit -m "phase A baseline"` then `./scripts/20-deploy.sh a-baseline`
2. After 24h: `./scripts/recommend-requests.sh` and `./scripts/40-collect.sh a-baseline 24h`
3. Edit `phases/b-rightsized.env` using the real p95 numbers (keep a margin), commit, deploy `b-rightsized`, repeat.
4. Phase C (spot), then phase D (spot + KEDA). During C or D run `./scripts/30-spot-interrupt.sh` while traffic runs.
5. Two days later: `./scripts/50-aws-cost.sh <start> <end>` for each phase window.
6. Fill `docs/RESULTS_TEMPLATE.md` from `results/` only.

## Cost per commit in Grafana
`kubectl -n monitoring port-forward svc/kps-grafana 3000:80`, then graph `commit:hourly_cost:sum`.
Each deploy is a new commit label, so you see cost step at the exact commit.

## Known limits (state these in your write-up)
- OpenCost uses AWS list prices unless you configure the spot data feed or CUR integration, so it may overstate
  spot cost. The Cost Explorer script is the source of truth for dollars; OpenCost gives per-workload attribution.
- Per-pod cost is based on requested CPU and memory, not usage.
- `30-spot-interrupt.sh` is a drain, not a real EC2 interruption. Use AWS FIS for the real event.
- Pin and verify chart and module versions; they change often. Versions here are starting points and untested.
- Single NAT gateway and two AZs: fine for a lab, not for production.
