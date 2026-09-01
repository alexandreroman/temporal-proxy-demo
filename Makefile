# Developer task runner. Run `make` (or `make help`) to
# list the available targets.

.DEFAULT_GOAL := help

# app-up's correctness rests entirely on its prerequisites running in the
# order they are listed, so a parallel make would race them.
.NOTPARALLEL:

# Configuration for every target, read from .env, so every target sees the
# same values. A missing .env file is not an error.
ifneq (,$(wildcard .env))
include .env
endif

# Who `make demo` greets.
NAME ?= Temporal

# The Kind cluster name is this worktree's directory name, so two
# worktrees never share a cluster.
CLUSTER ?= $(notdir $(CURDIR))

# The single host port this cluster publishes, into Traefik. Frozen into
# k8s/kind-config.yaml by `worktree-init`, because Kind reads no
# environment variable of its own.
TRAEFIK_PORT ?= 8080

# The CLI that builds the image and runs the cluster's nodes. A Podman user
# overrides this one variable; everything else Podman needs (the
# KIND_EXPERIMENTAL_PROVIDER kind reads, and a docker-compatible CLI on PATH)
# lives outside this Makefile.
CONTAINER_TOOL ?= docker

# Ask the runtime what it actually published rather than recomputing it, so a
# command typed without TRAEFIK_PORT still reaches this worktree's cluster.
# awk takes the last colon-separated field of the first line, which is right
# for an IPv4 and an IPv6 binding alike. An empty answer means the cluster is
# down, and the documented default is then the right one. TRAEFIK_PORT is what
# `worktree-init` freezes into the cluster config, and once the cluster is up it
# is only this fallback: an explicit TRAEFIK_PORT= on a later command line does
# not move the published port.
published-traefik-port = $$($(CONTAINER_TOOL) port '$(CLUSTER)-worker' 30080 2>/dev/null | awk -F: 'NR==1 {print $$NF}')

##@ Develop

# Kind reads no environment variable of its own, so this worktree's host
# port has to be frozen into a generated config file. CLUSTER, the
# directory name, is what stops two worktrees from sharing a cluster.
.PHONY: worktree-init
worktree-init: ## Fetch dependencies and pin this worktree's port (overwrites k8s/kind-config.yaml)
	go mod download
	sed 's/@TRAEFIK_PORT@/$(TRAEFIK_PORT)/' k8s/kind-config.yaml.in > k8s/kind-config.yaml

.PHONY: demo
demo: ## Trigger one Workflow through the HTTP API
	@port=$(published-traefik-port); \
		curl -fsS -X POST "http://hello.127-0-0-1.nip.io:$${port:-$(TRAEFIK_PORT)}/hello" \
			-H 'Content-Type: application/json' \
			-d '{"name": "$(NAME)"}'

# Markdown on stdout, so the answer to "where is this worktree listening?" can
# be read in a terminal or piped into whatever renders it. Both readers are
# served by padding every cell to its column's width, dashes included: the pipes
# line up and the rule reads as a rule in a terminal, while a renderer collapses
# that whitespace and sees the same table either way. The Service column is 23,
# the width of `Temporal Web UI (Cloud)`, its widest cell; the Address column is
# measured from the two values it is about to print, because the port comes from
# the running cluster and the Cloud row is either a link or a longer sentence.
# That link is built from the two Cloud values, so without them the row names
# what to set instead of linking to a Namespace nothing can name. This target
# reports what is there, whatever state the setup is in, so it carries no
# require-cloud guard.
.PHONY: endpoints
endpoints: ## Print this worktree's published endpoints as Markdown
	@port=$(published-traefik-port); port=$${port:-$(TRAEFIK_PORT)}; \
	demo_app="<http://hello.127-0-0-1.nip.io:$$port>"; \
	if [ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] && [ -n '$(TEMPORAL_ACCOUNT)' ]; then \
		web_ui="<https://cloud.temporal.io/namespaces/$(TEMPORAL_CLOUD_NAMESPACE).$(TEMPORAL_ACCOUNT)>"; \
	else \
		web_ui='Set TEMPORAL_CLOUD_NAMESPACE and TEMPORAL_ACCOUNT in .env'; \
	fi; \
	service_width=23; \
	address_width=$${#demo_app}; \
	[ $${#web_ui} -le $$address_width ] || address_width=$${#web_ui}; \
	service_rule=$$(printf '%*s' "$$service_width" '' | tr ' ' '-'); \
	address_rule=$$(printf '%*s' "$$address_width" '' | tr ' ' '-'); \
	printf '%s\n' '# Temporal Proxy Demo' ''; \
	printf '| %-*s | %-*s |\n' \
		"$$service_width" 'Service' "$$address_width" 'Address' \
		"$$service_width" "$$service_rule" "$$address_width" "$$address_rule" \
		"$$service_width" 'Demo App' "$$address_width" "$$demo_app" \
		"$$service_width" 'Temporal Web UI (Cloud)' "$$address_width" "$$web_ui"

# The workspace info panel mirrors `make endpoints`, so whichever command
# brought the stack up or down leaves it telling the truth. The CLI is on PATH
# outside a workspace too, hence the CASPER_WORKSPACE_ID test alongside it, and
# `|| true` keeps a panel update from ever failing the target that asked for it.
in-casper-workspace = [ -n "$$CASPER_WORKSPACE_ID" ] && command -v casper >/dev/null 2>&1

define publish-endpoints
$(in-casper-workspace) && $(MAKE) -s endpoints | casper info set - >/dev/null || true
endef

define clear-endpoints
$(in-casper-workspace) && casper info clear >/dev/null || true
endef

##@ Quality

.PHONY: check
check: ## Run tests and static checks
	go test ./...
	go vet ./...

##@ Helpers

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(firstword $(MAKEFILE_LIST))

##@ Kubernetes

# The node image is pinned like every other version here, because the
# application's preStop lifecycle sleep needs a recent Kubernetes: an older node
# drops that field silently and takes the overlapping rollout with it. The
# cluster this target creates carries no ingress until cluster-up has finished
# with it, so cluster-up is the name a reader types and this one exists only as
# its prerequisite, without a help description.
.PHONY: cluster-create
cluster-create:
	@test -f k8s/kind-config.yaml || { echo "Run make worktree-init first"; exit 1; }
	@kind get clusters | grep -qx '$(CLUSTER)' || \
		kind create cluster --name '$(CLUSTER)' --config k8s/kind-config.yaml \
			--image kindest/node:v1.37.0
	kubectl --context kind-$(CLUSTER) wait --for=condition=Ready nodes --all --timeout=120s

# Gateway API CRDs are not shipped by the Traefik chart, so they come from the
# pinned upstream release, applied before it: an HTTPRoute or a Gateway has no
# API to land on otherwise. cert-manager issues the certificate the KMS server
# presents, and secretgen-controller generates the bearer token that server
# reads at runtime; its controller is waited for, because nothing answers a
# request for a generated Secret until it is running.
.PHONY: cluster-up
cluster-up: cluster-create ## Create the cluster and install its platform components
	kubectl --context kind-$(CLUSTER) apply -f \
		https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml
	helm --kube-context kind-$(CLUSTER) upgrade --install traefik traefik \
		--repo https://traefik.github.io/charts --version 41.4.0 \
		--namespace traefik --create-namespace \
		-f k8s/charts/traefik.yaml --wait
	helm --kube-context kind-$(CLUSTER) upgrade --install cert-manager cert-manager \
		--repo https://charts.jetstack.io --version v1.21.1 \
		--namespace cert-manager --create-namespace \
		-f k8s/charts/cert-manager.yaml --wait
	kubectl --context kind-$(CLUSTER) apply -f \
		https://github.com/carvel-dev/secretgen-controller/releases/download/v0.21.2/release.yml
	kubectl --context kind-$(CLUSTER) -n secretgen-controller rollout status \
		deploy/secretgen-controller --timeout=120s

# Paired with cluster-up.
.PHONY: cluster-down
cluster-down: ## Delete the Kind cluster
	kind delete cluster --name '$(CLUSTER)'
	@$(clear-endpoints)

# Tagged with the registry Kubernetes assumes for an unqualified name,
# so the Deployments' plain `temporal-proxy-demo:dev` resolves to the
# image this target built rather than triggering a pull. Building with
# a container tool whose default namespace differs from that assumption
# (podman tags an unqualified build `localhost/...`) would otherwise
# load a name the cluster never looks up.
IMAGE = docker.io/library/temporal-proxy-demo:dev

.PHONY: image
image: ## Build the image and load it into the cluster (after cluster-up)
	$(CONTAINER_TOOL) build -t $(IMAGE) .
	kind load docker-image $(IMAGE) --name '$(CLUSTER)'

# The Temporal Cloud upstream needs two values and a client certificate, all
# of which temporal-proxy validates on startup: with any of them missing it
# crash-loops on a configuration error, far from the command that caused it.
# Refuse before touching the cluster, and name everything that is missing
# rather than only the first thing. A .env that does not exist yet leaves
# these variables empty, which counts as missing here. `apply` and `app-up`
# depend on this guard rather than a reader invoking it, so it carries no help
# description.
define require-cloud-setup
missing=''; \
[ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] || missing="$$missing TEMPORAL_CLOUD_NAMESPACE"; \
[ -n '$(TEMPORAL_ACCOUNT)' ] || missing="$$missing TEMPORAL_ACCOUNT"; \
[ -f k8s/certs/client.pem ] || missing="$$missing k8s/certs/client.pem"; \
[ -f k8s/certs/client.key ] || missing="$$missing k8s/certs/client.key"; \
if [ -n "$$missing" ]; then \
  echo "Cannot deploy, these are missing:$$missing"; \
  echo "The values go in .env (copy .env.example); the certificate goes in"; \
  echo "k8s/certs/ as client.pem and client.key. Then run the command again."; \
  exit 1; \
fi
endef

.PHONY: require-cloud
require-cloud:
	@$(require-cloud-setup)

# `kubectl create secret` refuses to overwrite a Secret that already exists, so
# every one of them is rendered client-side and piped into `apply` instead:
# that is what makes `make apply` runnable a second time. Both Secrets belong
# to temporal-proxy's namespace, so it is part of this shared shape; each call
# supplies only the kind, the name and the sources.
define apply-secret
kubectl --context kind-$(CLUSTER) -n temporal-proxy create secret $(1) \
	--dry-run=client -o yaml | kubectl --context kind-$(CLUSTER) apply -f -
endef

# The Namespace and account identifiers are not credentials, but they are
# account-specific, so they stay out of the committed configuration and reach
# temporal-proxy as a Secret built here from .env. Its envFrom expands them
# into the ${VAR} references left literal in the rendered ConfigMap. The
# client certificate reaches it the same way, as a Secret built from the two
# files in k8s/certs/: `create secret tls` gives it exactly the tls.crt and
# tls.key keys the chart expects. The Namespaces are applied first, because
# both Secrets have to land in one of them before the chart's Deployment
# reads them. temporal-proxy is pre-release, so its chart version and its
# image tag in k8s/charts/temporal-proxy.yaml are both pinned: an unpinned
# upgrade would pick up a configuration schema this repository has not been
# checked against.
.PHONY: apply
apply: require-cloud ## Deploy temporal-proxy and the application (after cluster-up)
	kubectl --context kind-$(CLUSTER) apply -f k8s/namespaces.yaml
	$(call apply-secret,generic temporal-cloud-config \
		--from-literal=TEMPORAL_CLOUD_NAMESPACE='$(TEMPORAL_CLOUD_NAMESPACE)' \
		--from-literal=TEMPORAL_ACCOUNT='$(TEMPORAL_ACCOUNT)')
	$(call apply-secret,tls temporal-cloud-client \
		--cert=k8s/certs/client.pem --key=k8s/certs/client.key)
	helm --kube-context kind-$(CLUSTER) upgrade --install temporal-proxy temporal-proxy \
		--repo https://go.temporal.io/helm-charts --version 0.2.1 \
		--namespace temporal-proxy \
		-f k8s/charts/temporal-proxy.yaml
# Unconditional, because nothing above changes the pod template: the chart's
# ConfigMap and both Secrets keep fixed names, whatever their content, and
# temporal-proxy reads its configuration and its certificate only at startup.
# This restart is what makes `make apply` a working certificate rotation, and
# the wait paired with it is what keeps a certificate or an account id the
# proxy rejects from being reported as a success.
	kubectl --context kind-$(CLUSTER) -n temporal-proxy rollout restart deploy/temporal-proxy
	kubectl --context kind-$(CLUSTER) -n temporal-proxy rollout status deploy/temporal-proxy --timeout=120s
	kubectl --context kind-$(CLUSTER) apply -k k8s/app

# The image tag is fixed, so a rebuild is invisible to Kubernetes
# until the pods are told to restart. `apply` has already restarted
# temporal-proxy and waited for it, its pod template being just as
# blind to a changed configuration or certificate.
.PHONY: app-up
app-up: require-cloud cluster-up image apply ## Bring the demo up: the cluster, temporal-proxy and the application
	kubectl --context kind-$(CLUSTER) -n hello rollout restart deploy/app deploy/worker
	kubectl --context kind-$(CLUSTER) -n hello rollout status deploy/app --timeout=120s
	kubectl --context kind-$(CLUSTER) -n hello rollout status deploy/worker --timeout=120s
	@$(publish-endpoints)

# Paired with app-up, and it removes only what k8s/app holds: the cluster,
# Traefik and temporal-proxy stay standing, so app-up is quick to run again.
# A teardown never fails over something already being gone, which takes two
# guards: `--ignore-not-found` for a resource the kustomization names, and the
# `kind get clusters` test, borrowed from cluster-create, for the cluster
# itself, whose absence kubectl reports as an unknown context. No require-cloud
# guard either: removing workloads needs neither the Cloud values nor the
# certificate, and demanding them would fail the one command someone reaches
# for when those are the problem. The published Demo App address stops
# answering whichever way the application went, so the info panel goes with it.
.PHONY: app-down
app-down: ## Remove the application, leaving the cluster and temporal-proxy up
	@if kind get clusters 2>/dev/null | grep -qx '$(CLUSTER)'; then \
		kubectl --context kind-$(CLUSTER) delete -k k8s/app --ignore-not-found; \
	else \
		echo 'No cluster named $(CLUSTER), so the application is already gone'; \
	fi
	@$(clear-endpoints)
