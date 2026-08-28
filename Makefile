# Developer task runner. Run `make` (or `make help`) to
# list the available targets.

.DEFAULT_GOAL := help

# Environment for every target, read from .env.
# A missing .env file is not an error.
ifneq (,$(wildcard .env))
include .env
export
endif

# The port the API binds to under `make dev`, and who `make demo` greets.
PORT ?= 8080
NAME ?= Temporal

# Fallback host port for temporal-proxy, used only when it is not running and
# `published-port` below reports nothing. PORT above is part of the same
# family, unqualified because it is the variable the API itself reads from
# its environment. TEMPORAL_WEB_UI_PORT keeps the same shape for
# `.casper.json`, which still reserves a port for it.
TEMPORAL_PROXY_PORT ?= 7233
TEMPORAL_WEB_UI_PORT ?= 8233

# The Kind cluster name is this worktree's directory name, so two
# worktrees never share a cluster — the same rule the Compose project
# name followed.
CLUSTER ?= $(notdir $(CURDIR))

# The single host port this cluster publishes, into Traefik. Frozen into
# k8s/kind-config.yaml by `worktree-init`, because Kind reads no
# environment variable of its own.
TRAEFIK_PORT ?= 8080

# Gateway API CRDs are not shipped by the Traefik chart, so they are
# applied from the pinned upstream release before it.
GATEWAY_API_VERSION ?= v1.6.1

# Which scenario to deploy to the cluster. Each one is a directory under
# k8s/scenarios/: a Kustomize overlay and one temporal-proxy values
# file. Switch with `make apply K8S_SCENARIO=<name>`.
#
# Named apart from the Compose `SCENARIO`, computed from PROXY_CONFIG
# with a plain `=`, which would silently overwrite a `?=` default of
# the same name in either order.
K8S_SCENARIO ?= credentials

# What a running stack publishes is whatever Compose bound, so ask Compose
# rather than guess — the answer already accounts for compose.override.yaml.
# An empty answer means the service is down, and the default above is then the
# right one: `make dev` runs the API on the host, on PORT.
published-port = $$(docker compose port $(1) $(2) 2>/dev/null | cut -d: -f2)

# Ask the runtime what it actually published rather than recomputing it, so a
# command typed without TRAEFIK_PORT still reaches this worktree's cluster.
# awk takes the last colon-separated field of the first line, which is right
# for an IPv4 and an IPv6 binding alike. An empty answer means the cluster is
# down, and the documented default is then the right one.
published-traefik-port = $$(docker port '$(CLUSTER)-worker' 30080 2>/dev/null | awk -F: 'NR==1 {print $$NF}')

##@ Infra

.PHONY: infra-up
infra-up: ## Start the Temporal dev server and the proxy
	docker compose up -d temporal temporal-proxy

.PHONY: infra-down
infra-down: ## Stop the Temporal dev server and the proxy
	docker compose stop temporal temporal-proxy
	@$(clear-endpoints)

##@ Scenarios

# Which configuration Compose mounts into temporal-proxy, and the plain name
# derived from it — ./proxy/cloud.yaml gives `cloud`. Every scenario is one
# file in ./proxy named after it, so the name alone identifies it.
#
# The choice is stored in .env rather than in the environment because .env is
# the only file `docker compose` reads on its own: a bare `docker compose up`
# typed in this worktree then runs the same scenario as any `make` target.
# Same rule as compose.override.yaml, which holds this worktree's ports.
PROXY_CONFIG ?= ./proxy/local.yaml
SCENARIO = $(basename $(notdir $(PROXY_CONFIG)))

# The cloud scenario needs two values and a client certificate, all of which
# temporal-proxy validates on startup: with any of them missing it recreates
# and then crash-loops on a configuration error, far from the command that
# caused it. Refuse before touching .env, and name everything that is missing
# rather than only the first thing. A .env that does not exist yet leaves
# these variables empty, which counts as missing here.
define require-cloud-setup
missing=''; \
[ -n '$(TEMPORAL_CLOUD_NAMESPACE)' ] || missing="$$missing TEMPORAL_CLOUD_NAMESPACE"; \
[ -n '$(TEMPORAL_ACCOUNT)' ] || missing="$$missing TEMPORAL_ACCOUNT"; \
[ -f proxy/certs/client.pem ] || missing="$$missing proxy/certs/client.pem"; \
[ -f proxy/certs/client.key ] || missing="$$missing proxy/certs/client.key"; \
if [ -n "$$missing" ]; then \
  echo "Cannot switch to the cloud scenario, these are missing:$$missing"; \
  echo "The values go in .env (copy .env.example); the certificate goes in proxy/certs/"; \
  echo "as client.pem and client.key. Then run make use-cloud again."; \
  exit 1; \
fi
endef

# Records the chosen scenario in .env, then applies it: temporal-proxy is
# recreated on the new configuration and the application containers restart
# behind it.
#
# awk rewrites the PROXY_CONFIG line where it stands, so the comment above it
# keeps describing the line below it, and appends the line only when the file
# has none. It writes through a temporary file rather than using `sed -i`,
# whose syntax differs between BSD and GNU. Exporting the new value first
# means the `docker compose` calls below see it: the value make exported at
# startup is the previous one, and Compose lets the environment win over .env.
#
# The switch needs no guard on what is running: `up -d --force-recreate` starts
# temporal-proxy when it is down as readily as it replaces a live one, and
# `restart` is a silent no-op that exits 0 on a container that does not exist.
define set-scenario
export PROXY_CONFIG='./proxy/$(1).yaml'; \
[ -f .env ] || cp .env.example .env; \
tmp=$$(mktemp); \
awk -v line="PROXY_CONFIG=$$PROXY_CONFIG" \
  '/^PROXY_CONFIG=/ { print line; found = 1; next } { print } END { if (!found) print line }' \
  .env > $$tmp; \
mv $$tmp .env; \
docker compose up -d --force-recreate temporal-proxy; \
$(publish-endpoints); \
docker compose restart worker app; \
echo "Scenario '$(1)' is live: temporal-proxy serves it, and Workers and Clients connect through it."
endef

.PHONY: use-local
use-local: ## Route temporal-proxy to the Temporal dev server in Compose
	@$(call set-scenario,local)

.PHONY: use-cloud
use-cloud: ## Route temporal-proxy to Temporal Cloud
	@$(require-cloud-setup)
	@$(call set-scenario,cloud)

.PHONY: scenario
scenario: ## Print the scenario temporal-proxy is configured for
	@echo $(SCENARIO)

##@ Develop

.PHONY: dev
dev: infra-up ## Start infra, then run the Worker and the HTTP API
	@$(publish-endpoints)
	# Trap reaps the whole process group (kill 0) on exit or signal, so no
	# orphaned processes survive Ctrl-C. Each child calls kill 0 on exit so
	# one crashing process tears the other down instead of leaving a half
	# stack running.
	@temporal_proxy=$(call published-port,temporal-proxy,7233); \
		export TEMPORAL_ADDRESS="$${TEMPORAL_ADDRESS:-localhost:$${temporal_proxy:-$(TEMPORAL_PROXY_PORT)}}"; \
		trap 'kill 0' EXIT INT TERM; \
		( go run ./cmd/worker; kill 0 ) & \
		( go run ./cmd/app; kill 0 ) & \
		wait

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
# be read in a terminal or piped into whatever renders it.
.PHONY: endpoints
endpoints: ## Print this worktree's published endpoints as Markdown
	@port=$(published-traefik-port); port=$${port:-$(TRAEFIK_PORT)}; \
	printf '%s\n' \
		'# Temporal Proxy Demo' \
		'' \
		'| Service | Address |' \
		'| --- | --- |' \
		"| Demo App | <http://hello.127-0-0-1.nip.io:$$port> |" \
		"| Temporal Web UI (Cloud) | <https://cloud.temporal.io/namespaces/\
$(TEMPORAL_CLOUD_NAMESPACE).$(TEMPORAL_ACCOUNT)> |" \
		"| Scenario | \`$(K8S_SCENARIO)\` |" \
		'' \
		'Trigger a Workflow with `make demo`.'

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

##@ Stack

.PHONY: app-up
app-up: ## Bring up the full stack in containers (build + start)
	docker compose up -d --build
	@$(publish-endpoints)

.PHONY: app-down
app-down: ## Tear down the full stack (removes containers and network)
	docker compose down
	@$(clear-endpoints)

##@ Quality

.PHONY: test
test: ## Run the test suite
	go test ./...

.PHONY: check
check: test ## Run tests and static checks
	go vet ./...

##@ Build

.PHONY: build
build: ## Build the production artifact
	go build -o bin/worker ./cmd/worker
	go build -o bin/app ./cmd/app

##@ Helpers

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(firstword $(MAKEFILE_LIST))

##@ Kubernetes

.PHONY: cluster-create
cluster-create: ## Create the Kind cluster
	@kind get clusters | grep -qx '$(CLUSTER)' || \
		kind create cluster --name '$(CLUSTER)' --config k8s/kind-config.yaml
	kubectl --context kind-$(CLUSTER) wait --for=condition=Ready nodes --all --timeout=120s

.PHONY: cluster-up
cluster-up: cluster-create ## Create the cluster and install its platform components
	kubectl --context kind-$(CLUSTER) apply -f \
		https://github.com/kubernetes-sigs/gateway-api/releases/download/$(GATEWAY_API_VERSION)/standard-install.yaml
	helm --kube-context kind-$(CLUSTER) upgrade --install traefik traefik \
		--repo https://traefik.github.io/charts --version 41.4.0 \
		--namespace traefik --create-namespace \
		-f k8s/charts/traefik.yaml --wait
	kubectl --context kind-$(CLUSTER) apply -k k8s/vault
	helm --kube-context kind-$(CLUSTER) upgrade --install vault vault \
		--repo https://helm.releases.hashicorp.com --version 0.34.1 \
		--namespace vault \
		-f k8s/charts/vault.yaml --wait
	# Runs on the chart's own defaults: the Vault address lives in the
	# VaultConnection under k8s/base/vault-secrets, next to the
	# resources that use it, so there is nothing to override here.
	helm --kube-context kind-$(CLUSTER) upgrade --install \
		vault-secrets-operator vault-secrets-operator \
		--repo https://helm.releases.hashicorp.com --version 1.5.1 \
		--namespace vault-secrets-operator --create-namespace --wait

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
image: ## Build the image and load it into the cluster
	docker build -t $(IMAGE) .
	kind load docker-image $(IMAGE) --name '$(CLUSTER)'

# Vault is the certificate's custodian, not its origin: this pushes the
# repository's own certificate in. That is what makes the demo
# self-contained, and it is the one step that cannot be declarative —
# the material lives in the working directory, not in the cluster.
#
# Each file is streamed on stdin into a temporary file in the pod, then
# read back by `vault kv put key=@file`. Streaming rather than passing
# the contents as arguments keeps the private key out of the pod's
# process table; `cat` rather than `kubectl cp` keeps the step free of
# any dependency beyond kubectl. The KV keys are named tls.crt and
# tls.key because that is exactly what a kubernetes.io/tls Secret
# requires, so the operator's Secret sync needs no transformation.
KUBECTL_VAULT = kubectl --context kind-$(CLUSTER) -n vault

.PHONY: vault-cert
vault-cert: ## Load the Temporal Cloud client certificate into Vault
	@$(require-cloud-setup)
	@$(KUBECTL_VAULT) exec -i vault-0 -- sh -c 'cat > /tmp/tls.crt' < proxy/certs/client.pem
	@$(KUBECTL_VAULT) exec -i vault-0 -- sh -c 'cat > /tmp/tls.key' < proxy/certs/client.key
	@$(KUBECTL_VAULT) exec vault-0 -- sh -c 'VAULT_TOKEN=root \
		vault kv put secret/temporal-cloud tls.crt=@/tmp/tls.crt tls.key=@/tmp/tls.key; \
		rm -f /tmp/tls.crt /tmp/tls.key'

.PHONY: apply
apply: ## Apply the scenario's Kustomize overlay
	kubectl --context kind-$(CLUSTER) apply -k k8s/scenarios/$(K8S_SCENARIO)

# The Namespace and account id are account-specific, so they are kept out of
# the committed values file and supplied as a Secret instead, built here from
# .env. temporal-proxy's envFrom then expands them into the ${VAR} references
# left literal in its ConfigMap.
.PHONY: proxy-up
proxy-up: ## Install temporal-proxy for K8S_SCENARIO
	@$(require-cloud-setup)
	kubectl --context kind-$(CLUSTER) -n temporal-proxy \
		create secret generic temporal-cloud-config \
		--from-literal=TEMPORAL_CLOUD_NAMESPACE='$(TEMPORAL_CLOUD_NAMESPACE)' \
		--from-literal=TEMPORAL_ACCOUNT='$(TEMPORAL_ACCOUNT)' \
		--dry-run=client -o yaml | kubectl --context kind-$(CLUSTER) apply -f -
	helm --kube-context kind-$(CLUSTER) upgrade --install temporal-proxy temporal-proxy \
		--repo https://go.temporal.io/helm-charts --version 0.2.1 \
		--namespace temporal-proxy \
		-f k8s/scenarios/$(K8S_SCENARIO)/proxy-values.yaml --wait

.PHONY: proxy-down
proxy-down: ## Uninstall temporal-proxy
	helm --kube-context kind-$(CLUSTER) uninstall temporal-proxy \
		--namespace temporal-proxy --ignore-not-found

.PHONY: deploy
deploy: cluster-up image vault-cert apply proxy-up ## Bring up the whole demo
	# The image tag is fixed, so a rebuild is invisible to Kubernetes
	# until the pods are told to restart.
	kubectl --context kind-$(CLUSTER) -n hello rollout restart deploy/app deploy/worker
	kubectl --context kind-$(CLUSTER) -n hello rollout status deploy/app --timeout=120s
	kubectl --context kind-$(CLUSTER) -n hello rollout status deploy/worker --timeout=120s
	@$(publish-endpoints)
