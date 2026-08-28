# Developer task runner. Run `make` (or `make help`) to
# list the available targets.

.DEFAULT_GOAL := help

# Environment for every target, read from .env.
# A missing .env file is not an error.
ifneq (,$(wildcard .env))
include .env
export
endif

# Where `make demo` sends its request, and who it greets.
PORT ?= 8080
NAME ?= Temporal

# Default host ports: what `worktree-init` writes unless told otherwise, and
# the fallback for a service that is not running. PORT above is part of the
# same trio, unqualified because it is the variable the API itself reads from
# its environment.
TEMPORAL_PROXY_PORT ?= 7233
TEMPORAL_WEB_UI_PORT ?= 8233

# What a running stack publishes is whatever Compose bound, so ask Compose
# rather than guess — the answer already accounts for compose.override.yaml.
# An empty answer means the service is down, and the default above is then the
# right one: `make dev` runs the API on the host, on PORT.
published-port = $$(docker compose port $(1) $(2) 2>/dev/null | cut -d: -f2)

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

# Compose merges compose.override.yaml automatically, so freezing this
# worktree's ports there — rather than in the environment — makes a bare
# `docker compose up` publish exactly what `make app-up` does. The project
# name is the directory name, unique per worktree, which is what stops two
# worktrees from sharing containers.
.PHONY: worktree-init
worktree-init: ## Fetch dependencies and pin this worktree's ports (overwrites compose.override.yaml)
	go mod download
	@printf '%s\n' \
		'# Host ports and project name for this worktree, generated by' \
		'# `make worktree-init`. Compose merges this file automatically.' \
		'# Not committed.' \
		'#' \
		'# `!override` replaces the port list of a service instead of' \
		'# appending to it, so only the port below is published.' \
		'name: $(notdir $(CURDIR))' \
		'' \
		'services:' \
		'  app:' \
		'    ports: !override' \
		'      - "$(PORT):8080"' \
		'  temporal-proxy:' \
		'    ports: !override' \
		'      - "$(TEMPORAL_PROXY_PORT):7233"' \
		'  temporal:' \
		'    ports: !override' \
		'      - "$(TEMPORAL_WEB_UI_PORT):8233"' \
		> compose.override.yaml

.PHONY: demo
demo: ## Trigger one Workflow through the HTTP API
	@app=$(call published-port,app,8080); \
		curl -fsS -X POST "http://localhost:$${app:-$(PORT)}/hello?name=$(NAME)"

# Which Web UI is worth linking depends on the scenario: in `cloud` the local
# dev server is still running, but every Workflow lands in Temporal Cloud, so
# the local UI would only ever show an empty Namespace.
cloud-namespace = $(TEMPORAL_CLOUD_NAMESPACE).$(TEMPORAL_ACCOUNT)
ifeq ($(SCENARIO),cloud)
web-ui-row = "| Temporal Web UI (Cloud) | <https://cloud.temporal.io/namespaces/$(cloud-namespace)> |"
else
web-ui-row = "| Temporal Web UI (local) | <http://localhost:$${web_ui:-$(TEMPORAL_WEB_UI_PORT)}> |"
endif

# Markdown on stdout, so the answer to "where is this worktree listening?" can
# be read in a terminal or piped into whatever renders it.
.PHONY: endpoints
endpoints: ## Print this worktree's published endpoints as Markdown
	@app=$(call published-port,app,8080); \
	web_ui=$(call published-port,temporal,8233); \
	temporal_proxy=$(call published-port,temporal-proxy,7233); \
	printf '%s\n' \
		'# Temporal Proxy Demo' \
		'' \
		'| Service | Address |' \
		'| --- | --- |' \
		"| Demo App | <http://localhost:$${app:-$(PORT)}> |" \
		$(web-ui-row) \
		"| Temporal gRPC Proxy | \`localhost:$${temporal_proxy:-$(TEMPORAL_PROXY_PORT)}\` |" \
		"| Scenario | \`$(SCENARIO)\` |" \
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
