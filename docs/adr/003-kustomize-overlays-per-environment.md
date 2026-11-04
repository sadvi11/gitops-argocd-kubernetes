# ADR 003: Kustomize base and overlays for environments

- Status: Accepted
- Related: `workloads/podinfo/base`, `workloads/podinfo/overlays/{dev,prod}`

## Context

Dev and prod should run the same workload but differ in a few deliberate ways.
Copy-pasted YAML drifts; templating adds a second language to review.

## Options considered

| Option | Trade-off |
|---|---|
| Duplicate manifests per environment | Easy to read, but differences hide among accidental divergence |
| Helm values per environment | Powerful, but templates make rendered output harder to review |
| Kustomize base + overlays (chosen) | Environment differences are small, readable patches over one hardened base |

## Decision

The base holds the hardened Deployment, Service and NetworkPolicy. Overlays set
only what differs: `dev` runs one replica; `prod` runs three replicas and adds a
`PodDisruptionBudget` with `minAvailable: 2`.

## Consequences

- The difference between environments is a short diff.
- Security settings (`runAsNonRoot`, `allowPrivilegeEscalation: false`,
  `readOnlyRootFilesystem`, dropped capabilities, no `:latest`) live in the base,
  and CI asserts them against rendered output so an overlay cannot silently
  remove them.
- The NetworkPolicy allows ingress to port 9898 from any namespace
  (`namespaceSelector: {}`) and does not restrict egress. It is a baseline, not a
  complete segmentation design; see "What I'd change for production" in the README.
- The image is pinned by tag only, not digest.

## References

- Kustomize: <https://kubectl.docs.kubernetes.io/references/kustomize/>
- PodDisruptionBudget: <https://kubernetes.io/docs/tasks/run-application/configure-pdb/>
- NetworkPolicy: <https://kubernetes.io/docs/concepts/services-networking/network-policies/>
- Pod Security Standards: <https://kubernetes.io/docs/concepts/security/pod-security-standards/>
