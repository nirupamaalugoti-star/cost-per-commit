# Results log (fill from files in results/ only)

Experiment dates (UTC): ______   Region: ______   Kubernetes: ______   Karpenter: ______

| Phase | Commit | Start (UTC) | End (UTC) | Avg replicas | Avg Karpenter nodes | OpenCost namespace cost (24h) | AWS Cost Explorer (24h) | Failed requests |
|---|---|---|---|---|---|---|---|---|
| A baseline (on-demand, 500m/512Mi) | | | | | | | | |
| B right-sized | | | | | | | | |
| C spot | | | | | | | | |
| D spot + KEDA | | | | | | | | |

## Notes
- Traffic pattern identical across phases? yes / no (explain)
- Weekday vs weekend differences?
- Anything that invalidates a comparison:
- What broke (with the real error message):
- Spot interruption test: time to recover ____, failed requests ____
