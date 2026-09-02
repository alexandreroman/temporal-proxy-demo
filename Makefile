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
NAME ?= John Doe

# The Kind cluster name is this worktree's directory name, so two
# worktrees never share a cluster.
CLUSTER ?= $(notdir $(CURDIR))

# The single host port this cluster publishes, into Traefik. It reaches Kind
# through k8s/kind-config.yaml, generated at this default by `cluster-create`
# and overwritten by `worktree-init` to pin a port per worktree.
TRAEFIK_PORT ?= 8080

# The host name the demo answers on, matched by k8s/app/httproute.yaml. A
# manifest cannot read a make variable, so that file spells it out too.
DEMO_HOST = hello.127-0-0-1.nip.io

# The CLI that builds the image and runs the cluster's nodes. A Podman user
# overrides this one variable; kind detects Podman on its own, and needs
# KIND_EXPERIMENTAL_PROVIDER=podman only when a docker CLI is on PATH too,
# which kind would otherwise pick.
CONTAINER_TOOL ?= docker

# Ask the runtime what it actually published rather than recomputing it, so a
# command typed without TRAEFIK_PORT still reaches this worktree's cluster. An
# empty answer means the cluster is down, and TRAEFIK_PORT is then the right
# default. Once the cluster is up that is all it is: an explicit TRAEFIK_PORT=
# on a later command line does not move an already-published port.
traefik-port = $$(p=$$($(CONTAINER_TOOL) port '$(CLUSTER)-worker' 30080 2>/dev/null | \
    awk -F: 'NR==1 {print $$NF}'); echo $${p:-$(TRAEFIK_PORT)})

##@ Develop

# Kind reads no environment variable of its own, so this worktree's host
# port has to be frozen into a generated config file. CLUSTER, the
# directory name, is what stops two worktrees from sharing a cluster. The
# module download rides along as a convenience, to warm the build cache.
.PHONY: worktree-init
worktree-init: ## Fetch dependencies and pin this worktree's port (overwrites k8s/kind-config.yaml)
	go mod download
	sed 's/@TRAEFIK_PORT@/$(TRAEFIK_PORT)/' k8s/kind-config.yaml.in > k8s/kind-config.yaml

.PHONY: demo
demo: ## Trigger one Workflow through the HTTP API
	@port=$(traefik-port); \
		curl -fsS -X POST "http://$(DEMO_HOST):$$port/hello" \
			-H 'Content-Type: application/json' \
			-d '{"name": "$(NAME)"}'

# Markdown on stdout, so the answer to "where is this worktree listening?" can
# be read in a terminal or piped into `casper info set`. The Cloud link is built
# from the two Cloud values, so without them that row names what to set instead
# of linking to a Namespace nothing can name.
.PHONY: endpoints
endpoints: ## Print this worktree's published endpoints as Markdown
	@port=$(traefik-port); \
	if [ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] && [ -n '$(TEMPORAL_ACCOUNT)' ]; then \
		web_ui="<https://cloud.temporal.io/namespaces/$(TEMPORAL_CLOUD_NAMESPACE).$(TEMPORAL_ACCOUNT)>"; \
	else \
		web_ui='Set TEMPORAL_CLOUD_NAMESPACE and TEMPORAL_ACCOUNT in .env'; \
	fi; \
	printf '%s\n' '# Temporal Proxy Demo' '' \
		'| Service | Address |' '| --- | --- |' \
		"| Demo App | <http://$(DEMO_HOST):$$port> |" \
		"| Temporal Web UI (Cloud) | $$web_ui |"

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

##@ Kubernetes

# The node image is pinned like every other version here, because the
# application's preStop lifecycle sleep needs a recent Kubernetes: an older
# node drops that field silently and takes the overlapping rollout with it.
# Kind reads no environment variable of its own, so the host port lives in a
# generated config file, rendered here at the default TRAEFIK_PORT when it
# is absent: `make app-up` then works on a fresh clone with no preliminary
# step. An existing file is left alone, because it holds the port a running
# worktree already published. The cluster this target creates carries no
# ingress until cluster-up has finished with it, so cluster-up is the name a
# reader types and this one exists only as its prerequisite, without a help
# description.
.PHONY: cluster-create
cluster-create:
	@test -f k8s/kind-config.yaml || \
		sed 's/@TRAEFIK_PORT@/$(TRAEFIK_PORT)/' k8s/kind-config.yaml.in > k8s/kind-config.yaml
	@kind get clusters | grep -qx '$(CLUSTER)' || \
		kind create cluster --name '$(CLUSTER)' --config k8s/kind-config.yaml \
			--image kindest/node:v1.37.0
	kubectl --context kind-$(CLUSTER) wait --for=condition=Ready nodes --all --timeout=120s

# Gateway API CRDs are not shipped by the Traefik chart, so they come from the
# pinned upstream release, applied before it: an HTTPRoute or a Gateway has no
# API to land on otherwise. cert-manager issues the certificate the KMS server
# presents, and secretgen-controller generates the bearer token that server
# reads at runtime; its controller is waited for, because nothing answers a
# request for a generated Secret until it is running. Every chart install
# hides its notes: they are advisory, and Traefik's ask the reader to install
# the Gateway API CRDs this recipe has already applied.
.PHONY: cluster-up
cluster-up: cluster-create ## Create the cluster and install its platform components
	kubectl --context kind-$(CLUSTER) apply -f \
		https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml
	helm --kube-context kind-$(CLUSTER) upgrade --install traefik traefik \
		--repo https://traefik.github.io/charts --version 41.4.0 \
		--namespace traefik --create-namespace \
		-f k8s/charts/traefik.yaml --hide-notes --wait
	helm --kube-context kind-$(CLUSTER) upgrade --install cert-manager cert-manager \
		--repo https://charts.jetstack.io --version v1.21.1 \
		--namespace cert-manager --create-namespace \
		-f k8s/charts/cert-manager.yaml --hide-notes --wait
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

# temporal-proxy and the KMS server both validate their configuration on
# startup, so anything missing here crash-loops far from the command that
# caused it: refuse before touching the cluster, and name everything that is
# missing rather than only the first thing. `apply` and `app-up` depend on this
# guard rather than a reader invoking it, so it carries no help description.
define require-setup-check
missing=''; \
[ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] || missing="$$missing TEMPORAL_CLOUD_NAMESPACE"; \
[ -n '$(TEMPORAL_ACCOUNT)' ] || missing="$$missing TEMPORAL_ACCOUNT"; \
[ -f k8s/certs/client.pem ] || missing="$$missing k8s/certs/client.pem"; \
[ -f k8s/certs/client.key ] || missing="$$missing k8s/certs/client.key"; \
[ -n '$(KMS_MASTER_SECRET)' ] || missing="$$missing KMS_MASTER_SECRET"; \
if [ -n "$$missing" ]; then \
  echo "Cannot deploy, these are missing:$$missing"; \
  echo "The values go in .env (copy .env.example); the certificate goes in"; \
  echo "k8s/certs/ as client.pem and client.key. Then run the command again."; \
  exit 1; \
fi
endef

.PHONY: require-setup
require-setup:
	@$(require-setup-check)

# `kubectl create secret` refuses to overwrite a Secret that already exists, so
# every one of them is rendered client-side and piped into `apply` instead:
# that is what makes `make apply` runnable a second time. Every Secret this
# builds belongs to temporal-proxy's namespace, so it is part of this shared
# shape; each call supplies only the kind, the name and the sources.
define apply-secret
kubectl --context kind-$(CLUSTER) -n temporal-proxy create secret $(1) \
	--dry-run=client -o yaml | kubectl --context kind-$(CLUSTER) apply -f -
endef

# The Namespaces are applied first, because both Secrets have to land in one of
# them before the chart's Deployment reads them. temporal-proxy is pre-release,
# so the chart version pinned below is deliberate: an unpinned upgrade would
# pick up a configuration schema this repository has not been checked against.
.PHONY: apply
apply: require-setup ## Deploy the KMS server, temporal-proxy and the application (after cluster-up)
	kubectl --context kind-$(CLUSTER) apply -f k8s/namespaces.yaml
	$(call apply-secret,generic temporal-cloud-config \
		--from-literal=TEMPORAL_CLOUD_NAMESPACE='$(TEMPORAL_CLOUD_NAMESPACE)' \
		--from-literal=TEMPORAL_ACCOUNT='$(TEMPORAL_ACCOUNT)')
	$(call apply-secret,tls temporal-cloud-client \
		--cert=k8s/certs/client.pem --key=k8s/certs/client.key)
# Silenced with @, unlike its two neighbours above: this recipe line expands to
# the master secret itself, and make echoes a recipe line it does not run
# quietly. The @echo below names the Secret instead of the value.
	@$(call apply-secret,generic kms-master-secret \
		--from-literal=KMS_MASTER_SECRET='$(KMS_MASTER_SECRET)')
	@echo 'Secret kms-master-secret updated'
	kubectl --context kind-$(CLUSTER) apply -k k8s/kms
	kubectl --context kind-$(CLUSTER) -n temporal-proxy wait --for=condition=Ready \
		certificate/kms-tls --timeout=120s
	kubectl --context kind-$(CLUSTER) -n temporal-proxy rollout status deploy/kms --timeout=120s
	helm --kube-context kind-$(CLUSTER) upgrade --install temporal-proxy temporal-proxy \
		--repo https://go.temporal.io/helm-charts --version 0.2.1 \
		--namespace temporal-proxy \
		-f k8s/charts/temporal-proxy.yaml --hide-notes
# Unconditional, because nothing above changes the pod template: temporal-proxy
# reads its configuration and its certificate only at startup, so this restart
# is what makes `make apply` a working certificate rotation. The wait paired
# with it keeps a rejected certificate from being reported as a success.
	kubectl --context kind-$(CLUSTER) -n temporal-proxy rollout restart deploy/temporal-proxy
	kubectl --context kind-$(CLUSTER) -n temporal-proxy rollout status deploy/temporal-proxy --timeout=120s
	kubectl --context kind-$(CLUSTER) apply -k k8s/app

# The image tag is fixed, so a rebuild is invisible to Kubernetes
# until the pods are told to restart. `apply` has already restarted
# temporal-proxy and waited for it, its pod template being just as
# blind to a changed configuration or certificate.
.PHONY: app-up
app-up: require-setup cluster-up image apply ## Bring up the cluster, the KMS server, temporal-proxy and the application
	kubectl --context kind-$(CLUSTER) -n hello rollout restart deploy/app deploy/worker
	kubectl --context kind-$(CLUSTER) -n hello rollout status deploy/app --timeout=120s
	kubectl --context kind-$(CLUSTER) -n hello rollout status deploy/worker --timeout=120s
	@$(publish-endpoints)

# A teardown never fails over something already being gone, which takes two
# guards: `--ignore-not-found` for a resource the kustomization names, and the
# `kind get clusters` test for the cluster itself, whose absence kubectl
# reports as an unknown context. No require-setup guard either: a teardown
# needs none of those values.
.PHONY: app-down
app-down: ## Remove the application, leaving the cluster, temporal-proxy and the KMS server up
	@if kind get clusters 2>/dev/null | grep -qx '$(CLUSTER)'; then \
		kubectl --context kind-$(CLUSTER) delete -k k8s/app --ignore-not-found; \
	else \
		echo 'No cluster named $(CLUSTER), so the application is already gone'; \
	fi
	@$(clear-endpoints)

# Listed last, because the help listing follows this file's own order and the
# demo's commands should reach a reader before its plumbing does.
##@ Helpers

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(firstword $(MAKEFILE_LIST))
