# ADR 002: App-of-apps bootstrap with ordered sync waves

- Status: Accepted
- Related: `apps/root-app.yaml`, `apps/podinfo-dev.yaml`, `apps/podinfo-prod.yaml`

## Context

Argo CD Applications are themselves Kubernetes objects. If each one is applied by
hand, the cluster's contents are no longer fully described by Git, which weakens
the point of GitOps. We also want dev to be deployed before prod.

## Options considered

1. **Apply every Application manually.** Simple, but each new environment is a
   command someone has to remember to run.
2. **App of apps (chosen).** One `root` Application points at `apps/`, which
   holds the child Applications. Adding an environment is a file in Git.
3. **ApplicationSet.** Generates Applications from templates and generators. It
   pays off with many clusters or environments; for two environments in one
   cluster it adds a concept without removing much YAML.

## Decision

Apply only `apps/root-app.yaml` by hand (`make bootstrap`). The root excludes
itself from the directory it syncs. Children carry
`argocd.argoproj.io/sync-wave` annotations: dev is wave `"1"`, prod is wave `"2"`.
All Applications use the `resources-finalizer.argocd.argoproj.io` finalizer so
deleting an Application removes what it created.

## Consequences

- One bootstrap command, then Git is the only input.
- Deleting `root` cascades to the children and their workloads because of the
  finalizer. That is deliberate for a demo cluster; in production it is a large
  blast radius and would warrant tighter RBAC on who can delete Applications.
- All Applications use the built-in `default` AppProject, which does not restrict
  source repositories or destinations. A production setup should define
  dedicated AppProjects.
- Children track `targetRevision: main`, so any merge to `main` reaches the
  cluster. Pinning to a tag or protected branch would add a release gate.

## References

- Cluster bootstrapping (app of apps): <https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/>
- Sync phases and waves: <https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/>
- Projects: <https://argo-cd.readthedocs.io/en/stable/user-guide/projects/>
