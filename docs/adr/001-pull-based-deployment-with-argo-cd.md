# ADR 001: Pull-based deployment with Argo CD

- Status: Accepted
- Related: [WHY.md](../../WHY.md), `apps/root-app.yaml`

## Context

Something has to get manifests from Git into the cluster. The usual approach is
a CI job that finishes with `kubectl apply`. That job needs standing credentials
for the cluster, stored in a system outside the cluster's boundary, and it only
records what it *applied*, not what is *currently running*.

## Options considered

| Option | Cluster credentials live in | Manual `kubectl` change | Rollback |
|---|---|---|---|
| CI push (`kubectl apply` in a pipeline) | The CI system | Persists until the next deploy | Re-run an older pipeline |
| Pull, Argo CD in the cluster (chosen) | The cluster only | Reverted when `selfHeal` is on | `git revert` |
| Pull, Flux | The cluster only | Reverted | `git revert` |

Flux was not evaluated hands-on for this repository; it is listed because it is
the other mainstream pull-based option, not because it was rejected on evidence.

## Decision

Use Argo CD running inside the cluster, with `syncPolicy.automated` set to
`prune: true` and `selfHeal: true` on every Application. CI in this repository
validates manifests and runs a drift test, but never deploys.

## Consequences

- No cluster credentials are needed by CI, so there are none to leak from it.
- The repository answers "what should be running", and Argo CD reports
  differences from it.
- `selfHeal` means an emergency manual change is silently undone. Teams need an
  agreed break-glass process (e.g. pause auto-sync on that Application first).
- `prune: true` means deleting a file from Git deletes the resource. This is
  intended and is exercised by the CI prune test, but it raises the cost of a
  mistaken merge.
- Argo CD itself becomes a critical component that must be upgraded and
  monitored. This repo pins it (`ARGOCD_VER` in the `Makefile`).

## References

- Argo CD automated sync, prune and self-heal: <https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/>
- Kubernetes Deployments: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>
