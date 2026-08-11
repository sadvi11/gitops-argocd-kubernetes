# Local equivalent of what CI does. Run `make help` to list targets.
CLUSTER    ?= gitops
ARGOCD_VER ?= v2.13.2

.PHONY: help up argocd bootstrap status drift prune-test ui password down validate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Create the local kind cluster (3 nodes)
	kind create cluster --config kind/cluster.yaml --name $(CLUSTER)

argocd: ## Install Argo CD into the cluster
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f \
	  https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VER)/manifests/install.yaml
	kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

bootstrap: ## Apply the root app -- everything else comes from git
	kubectl apply -f apps/root-app.yaml

status: ## Show Applications and workloads
	kubectl get applications -n argocd
	kubectl get deploy,pod -n podinfo-dev
	kubectl get deploy,pdb,pod -n podinfo-prod

drift: ## Break prod by hand and watch Argo CD put it back
	kubectl -n podinfo-prod scale deploy/podinfo --replicas=1
	@echo "Scaled to 1. Watching for self-heal (Ctrl-C to stop)..."
	kubectl -n podinfo-prod get deploy podinfo -w

ui: ## Port-forward the Argo CD UI to https://localhost:8080
	@echo "user: admin   password: run 'make password'"
	kubectl port-forward -n argocd svc/argocd-server 8080:443

password: ## Print the initial Argo CD admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret \
	  -o jsonpath='{.data.password}' | base64 -d; echo

validate: ## Build every overlay locally (same as CI)
	@for o in workloads/*/overlays/*; do echo "== $$o"; kustomize build $$o > /dev/null && echo "ok"; done

down: ## Delete the cluster
	kind delete cluster --name $(CLUSTER)
