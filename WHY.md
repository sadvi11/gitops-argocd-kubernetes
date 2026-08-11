# WHY I Built This Project

## The problem with how most teams deploy to Kubernetes

A CI pipeline that ends in `kubectl apply` has to hold cluster-admin credentials.
Those credentials sit in the CI system, which is a system outside the cluster's
security boundary, frequently with broad access to every repository in the org.
Steal the CI token, own the cluster.

It also cannot answer the question that matters during an incident: *what is
actually running right now?* The pipeline logs tell you what was applied, not
what survived — someone's emergency `kubectl edit` at 2am is invisible until the
next deploy quietly reverts or entrenches it.

## Why pull-based GitOps

Argo CD runs **inside** the cluster and pulls. Nothing outside holds cluster
credentials, so there is no cluster access to steal from CI. The repository is
the answer to "what is running", because anything that disagrees with it gets
corrected automatically.

That last part is the claim people make and rarely demonstrate, so this repo's
pipeline breaks production on purpose — scaling it down by hand — and fails the
build unless Argo CD puts it back without a human.

## Why this shows up in real Canadian job postings

Every mid-size platform team I see hiring for lists Argo CD or Flux. The reason
is usually audit rather than fashion: a regulated environment needs to show that
production changes went through review, and a pull-based model makes that true
by construction instead of by policy.

## The telecom connection

At Nokia I ran 5G core network functions as containers on Kubernetes under a
99.9% SLA, where a rolling upgrade going wrong meant dropped calls rather than a
red build. The habit that came from that: never trust that the cluster matches
what you think you deployed — prove it. Self-healing and a drift test in CI are
that same instinct written down.

## What I would add for real production use

- **Sealed Secrets or External Secrets Operator** — this repo deliberately has no
  secrets at all rather than showing a bad pattern for handling them.
- **Progressive delivery** with Argo Rollouts — canary and automated rollback on
  metric regression.
- **Multi-cluster** — one Argo CD managing several clusters via ApplicationSets.
- **Notifications** — Slack on sync failure and on self-heal, because silent
  self-healing hides a human who keeps making manual changes.

## Target roles

Platform Engineer · DevOps Engineer · SRE · Cloud Engineer (Kubernetes)

## Author

Sadhvi Sharma · Cloud & AI Engineer · Calgary, Alberta
[github.com/sadvi11](https://github.com/sadvi11)
