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

# Who `make demo` greets. Plain text only, with no quotes: the recipe pastes it
# into a JSON string that sits inside single quotes.
NAME ?= John Doe

# The Kind cluster name is this worktree's directory name, so two
# worktrees never share a cluster.
CLUSTER ?= $(notdir $(CURDIR))

# Every recipe addresses this cluster by name, never whichever context
# happens to be current.
kubectl = kubectl --context kind-$(CLUSTER)
helm = helm --kube-context kind-$(CLUSTER)

# The single host port this cluster publishes, into Traefik.
TRAEFIK_PORT ?= 8080

# kind's config file cannot read environment variables and no kind flag sets a
# port mapping, so the host port is frozen into k8s/kind-config.yaml, rendered
# from k8s/kind-config.yaml.in. `worktree-init` overwrites it to pin this
# worktree's own port. `cluster-create` renders it at the default only when it
# is absent, so `make app-up` works on a fresh clone and a pinned port stays.
render-kind-config = sed '/hostPort:/s/@TRAEFIK_PORT@/$(TRAEFIK_PORT)/' k8s/kind-config.yaml.in > k8s/kind-config.yaml

# The host name the demo answers on. Every host name in this file matches the
# `hostnames:` of a k8s/*/httproute.yaml, which cannot read a make variable.
DEMO_HOST = hello.127-0-0-1.nip.io

# The CLI that builds the image and runs the cluster's node. A Podman user
# overrides this one variable; kind detects Podman on its own, and needs
# KIND_EXPERIMENTAL_PROVIDER=podman only when a docker CLI is on PATH too,
# which kind would otherwise pick.
CONTAINER_TOOL ?= docker

# Ask the runtime what it actually published rather than recomputing it, so a
# command typed without TRAEFIK_PORT still reaches this worktree's cluster. An
# empty answer means the cluster is down, and TRAEFIK_PORT is then the right
# default. Once the cluster is up that is all it is: an explicit TRAEFIK_PORT=
# on a later command line does not move an already-published port.
traefik-port = $$(p=$$($(CONTAINER_TOOL) port '$(CLUSTER)-control-plane' 30080 2>/dev/null | \
    awk -F: 'NR==1 {print $$NF}'); echo $${p:-$(TRAEFIK_PORT)})

##@ Develop

.PHONY: worktree-init
worktree-init: ## Pin this worktree's port (overwrites k8s/kind-config.yaml)
	$(render-kind-config)

.PHONY: demo
demo: ## Trigger one Workflow through the HTTP API
	@port=$(traefik-port); \
		curl -fsS -X POST "http://$(DEMO_HOST):$$port/hello" \
			-H 'Content-Type: application/json' \
			-d '{"name": "$(NAME)"}'

# Succeeds when Deployment $(2) exists in namespace $(1), and fails quietly
# otherwise, a missing cluster included.
deployed = $(kubectl) -n $(1) get deploy $(2) >/dev/null 2>&1

# Markdown on stdout, so the answer to "where is this worktree listening?" can
# be read in a terminal or piped into `casper info set`. An in-cluster address
# is listed only while the Deployment behind it exists, so after `app-down` the
# rows it removed are gone, and with the cluster down only the Cloud row is
# left. That row is always printed, since Cloud is not in the cluster. Its link
# is built from the two Cloud values, so without them it names what to set
# instead of linking to a Namespace nothing can name.
.PHONY: endpoints
endpoints: ## Print this worktree's published endpoints as Markdown
	@port=$(traefik-port); \
	if [ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] && [ -n '$(TEMPORAL_ACCOUNT)' ]; then \
		web_ui="<https://cloud.temporal.io/namespaces/$(TEMPORAL_CLOUD_NAMESPACE).$(TEMPORAL_ACCOUNT)>"; \
	else \
		web_ui='Set TEMPORAL_CLOUD_NAMESPACE and TEMPORAL_ACCOUNT in .env'; \
	fi; \
	printf '%s\n' '# Temporal Proxy Demo' '' '| Service | Address |' '| --- | --- |'; \
	if $(call deployed,hello,app); then \
		echo "| Demo App | <http://$(DEMO_HOST):$$port> |"; \
	fi; \
	echo "| Temporal Web UI (Cloud) | $$web_ui |"; \
	if $(call deployed,temporal,temporal); then \
		echo "| Temporal Web UI (self-hosted) | <http://temporal.127-0-0-1.nip.io:$$port> |"; \
	fi; \
	if $(call deployed,temporal-ui,ui); then \
		echo "| Temporal Web UI (through temporal-proxy) | <http://temporal-webui.127-0-0-1.nip.io:$$port> |"; \
	fi

# The workspace info panel mirrors `make endpoints`, so whichever command
# brought the stack up or down leaves it telling the truth. The CLI is on PATH
# outside a workspace too, hence the CASPER_WORKSPACE_ID test alongside it, and
# `|| true` keeps a panel update from ever failing the target that asked for it.
in-casper-workspace = [ -n "$$CASPER_WORKSPACE_ID" ] && command -v casper >/dev/null 2>&1

publish-endpoints = $(in-casper-workspace) && $(MAKE) -s endpoints | casper info set - >/dev/null || true

clear-endpoints = $(in-casper-workspace) && casper info clear >/dev/null || true

##@ Quality

.PHONY: check
check: ## Run tests and static checks
	go test ./...
	go vet ./...

##@ Kubernetes

# The node image is pinned like every other version here, because the
# application's preStop lifecycle sleep needs a recent Kubernetes: an older
# node drops that field silently and takes the overlapping rollout with it.
# The cluster this target creates carries no ingress until cluster-up has
# finished with it, so cluster-up is the name a reader types and this one
# exists only as its prerequisite, without a help description.
.PHONY: cluster-create
cluster-create:
	@test -f k8s/kind-config.yaml || $(render-kind-config)
	@kind get clusters | grep -qx '$(CLUSTER)' || \
		kind create cluster --name '$(CLUSTER)' --config k8s/kind-config.yaml \
			--image kindest/node:v1.37.0

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
	$(kubectl) apply -f \
		https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml
	$(helm) upgrade --install traefik traefik \
		--repo https://traefik.github.io/charts --version 42.1.1 \
		--namespace traefik --create-namespace \
		-f k8s/charts/traefik.yaml --hide-notes --wait
	$(helm) upgrade --install cert-manager cert-manager \
		--repo https://charts.jetstack.io --version v1.21.2 \
		--namespace cert-manager --create-namespace \
		-f k8s/charts/cert-manager.yaml --hide-notes --wait
	$(kubectl) apply -f \
		https://github.com/carvel-dev/secretgen-controller/releases/download/v0.21.4/release.yml
	$(kubectl) -n secretgen-controller rollout status \
		deploy/secretgen-controller --timeout=120s

# Paired with cluster-up.
.PHONY: cluster-down
cluster-down: ## Delete the Kind cluster
	kind delete cluster --name '$(CLUSTER)'
	@$(clear-endpoints)

# Fully qualified, as the manifests write it: podman tags an unqualified build
# `localhost/...`, a name the cluster never looks up.
IMAGE = docker.io/library/temporal-proxy-demo:dev

# `kind load docker-image` always shells out to docker, so the image travels as
# an archive saved by CONTAINER_TOOL instead. kind opens the path itself, once
# per node, so a pipe would break as soon as a node is added: the archive is a
# temporary file.
.PHONY: image
image: ## Build the image and load it into the cluster (after cluster-up)
	$(CONTAINER_TOOL) build -t $(IMAGE) .
	archive=$$(mktemp) && trap 'rm -f "$$archive"' EXIT && \
		$(CONTAINER_TOOL) save -o "$$archive" $(IMAGE) && \
		kind load image-archive "$$archive" --name '$(CLUSTER)'

# temporal-proxy and the KMS server both validate their configuration on
# startup, so anything missing here crash-loops far from the command that
# caused it: refuse before touching the cluster, and name everything that is
# missing rather than only the first thing. `apply` and `app-up` depend on this
# guard rather than a reader invoking it, so it carries no help description.
.PHONY: require-setup
require-setup:
	@missing=''; \
	[ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] || missing="$$missing TEMPORAL_CLOUD_NAMESPACE"; \
	[ -n '$(TEMPORAL_ACCOUNT)' ] || missing="$$missing TEMPORAL_ACCOUNT"; \
	[ -n '$(TEMPORAL_CLOUD_API_KEY)' ] || missing="$$missing TEMPORAL_CLOUD_API_KEY"; \
	[ -n '$(KMS_MASTER_SECRET)' ] || missing="$$missing KMS_MASTER_SECRET"; \
	if [ -n "$$missing" ]; then \
	  echo "Cannot deploy, these are missing:$$missing"; \
	  echo "They go in .env (copy .env.example). Then run the command again."; \
	  exit 1; \
	fi

# `kubectl create secret` refuses to overwrite a Secret that already exists, so
# every one of them is rendered client-side and piped into `apply` instead:
# that is what makes `make apply` runnable a second time. Every Secret this
# builds is generic and belongs to temporal-proxy's namespace, so both are part
# of this shared shape; each call supplies only the name and the sources.
define apply-secret
$(kubectl) -n temporal-proxy create secret generic $(1) \
	--dry-run=client -o yaml | $(kubectl) apply -f -
endef

# The Namespaces are applied first, because every Secret has to land in one of
# them before the chart's Deployment reads them. temporal-proxy is pre-release,
# so the chart version pinned below is deliberate: an unpinned upgrade would
# pick up a configuration schema this repository has not been checked against.
.PHONY: apply
apply: require-setup ## Deploy the demo's workloads into the cluster (after image)
	$(kubectl) apply -f k8s/namespaces.yaml
	$(call apply-secret,temporal-cloud-config \
		--from-literal=TEMPORAL_CLOUD_NAMESPACE='$(TEMPORAL_CLOUD_NAMESPACE)' \
		--from-literal=TEMPORAL_ACCOUNT='$(TEMPORAL_ACCOUNT)')
# A Secret of its own: temporal-cloud-config above is loaded whole with envFrom,
# so a key there would reach the container a second time. This line and the
# next are silenced with @: each expands to a secret, and make echoes every
# recipe line not prefixed with @.
	@$(call apply-secret,temporal-cloud-api-key \
		--from-literal=TEMPORAL_CLOUD_API_KEY='$(TEMPORAL_CLOUD_API_KEY)')
	@$(call apply-secret,kms-master-secret \
		--from-literal=KMS_MASTER_SECRET='$(KMS_MASTER_SECRET)')
	$(kubectl) apply -k k8s/kms
# Unconditional, because a rebuilt image or a changed KMS_MASTER_SECRET reaches
# the KMS server only through a restart, and neither changes its pod template.
	$(kubectl) -n temporal-proxy rollout restart deploy/kms
	$(kubectl) -n temporal-proxy rollout status deploy/kms --timeout=120s
# The self-hosted Temporal Service, the demo's second upstream, has to be up
# before temporal-proxy starts, as does the KMS server above: temporal-proxy
# dials every upstream with a fixed address, and every extension server, at
# startup, and refuses to start if one is unreachable. A Kind node is a
# container, so every image pulled from a public registry is pulled cold after
# a `cluster-down`; Helm's `--wait` covers Traefik's and cert-manager's, and a
# `rollout status` every other one. This one's is the longest, for a whole
# Temporal Service.
	$(kubectl) apply -k k8s/temporal
	$(kubectl) -n temporal rollout status deploy/temporal --timeout=300s
	$(helm) upgrade --install temporal-proxy temporal-proxy \
		--repo https://go.temporal.io/helm-charts --version 0.2.2 \
		--namespace temporal-proxy \
		-f k8s/charts/temporal-proxy.yaml --hide-notes
# Unconditional, because nothing above changes the pod template: temporal-proxy
# reads its configuration and its API key only at startup, so this restart is
# what makes `make apply` a working key rotation. The wait paired with it keeps
# a proxy that refuses to start from being reported as a success. A key Cloud
# rejects still lets it start: it fails the first request, not the startup.
	$(kubectl) -n temporal-proxy rollout restart deploy/temporal-proxy
	$(kubectl) -n temporal-proxy rollout status deploy/temporal-proxy --timeout=120s
	$(kubectl) apply -k k8s/app
	$(kubectl) apply -k k8s/ui

# The image tag is fixed, so a rebuild is invisible to Kubernetes
# until the pods are told to restart.
.PHONY: app-up
app-up: require-setup cluster-up image apply ## Bring up the cluster and everything the demo runs on
	$(kubectl) -n hello rollout restart deploy/app deploy/worker
	$(kubectl) -n hello rollout status deploy/app --timeout=120s
	$(kubectl) -n hello rollout status deploy/worker --timeout=120s
	@$(publish-endpoints)

# Removes the stateless clients of temporal-proxy, the application and the Web
# UI reading through it, and leaves the platform, the KMS server and the
# self-hosted Temporal Service up, so `app-up` returns quickly. The panel is
# republished rather than cleared: `make endpoints` then lists only what still
# answers. A teardown never fails over something already being gone, which
# takes two guards: `--ignore-not-found` for a resource a kustomization names,
# and the `kind get clusters` test for the cluster itself, whose absence
# kubectl reports as an unknown context. No require-setup guard either: a
# teardown needs none of those values.
.PHONY: app-down
app-down: ## Remove the Worker, the API and the Web UI reading through temporal-proxy
	@if kind get clusters 2>/dev/null | grep -qx '$(CLUSTER)'; then \
		$(kubectl) delete -k k8s/app --ignore-not-found && \
		$(kubectl) delete -k k8s/ui --ignore-not-found; \
	else \
		echo 'No cluster named $(CLUSTER), so the application is already gone'; \
	fi
	@$(publish-endpoints)

# Listed last, because the help listing follows this file's own order and the
# demo's commands should reach a reader before its plumbing does.
##@ Helpers

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(firstword $(MAKEFILE_LIST))
