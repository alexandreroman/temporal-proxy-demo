# Developer task runner. Run `make` (or `make help`) to
# list the available targets.

.DEFAULT_GOAL := help

# Canonical environment, loaded for every target.
# A missing .env file is not an error.
ifneq (,$(wildcard .env))
include .env
export
endif

# Local overrides, loaded only for dev/test targets so that
# deploy/release targets see the canonical .env values only.
# Sequential include means later assignments win.
DEV_TARGETS := dev test check infra-up infra-down demo
GOALS := $(or $(MAKECMDGOALS),$(.DEFAULT_GOAL))
ifneq (,$(filter $(DEV_TARGETS),$(GOALS)))
ifneq (,$(wildcard .env.local))
include .env.local
export
endif
endif

# Where `make demo` sends its request, and who it greets.
PORT ?= 8080
NAME ?= Temporal

##@ Infra

.PHONY: infra-up
infra-up: ## Start the Temporal dev server and the proxy
	docker compose up -d temporal temporal-proxy

.PHONY: infra-down
infra-down: ## Stop the Temporal dev server and the proxy
	docker compose stop temporal temporal-proxy

##@ Develop

.PHONY: dev
dev: infra-up ## Start infra, then run the Worker and the HTTP API
	# Trap reaps the whole process group (kill 0) on exit or signal, so no
	# orphaned processes survive Ctrl-C. Each child calls kill 0 on exit so
	# one crashing process tears the other down instead of leaving a half
	# stack running.
	@trap 'kill 0' EXIT INT TERM; \
		( go run ./cmd/worker; kill 0 ) & \
		( go run ./cmd/api; kill 0 ) & \
		wait

.PHONY: demo
demo: ## Trigger one Workflow through the HTTP API
	curl -fsS -X POST "http://localhost:$(PORT)/hello?name=$(NAME)"

##@ Stack

.PHONY: app-up
app-up: ## Bring up the full stack in containers (build + start)
	docker compose up -d --build

.PHONY: app-down
app-down: ## Tear down the full stack (removes containers and network)
	docker compose down

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
	go build -o bin/api ./cmd/api

##@ Helpers

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(firstword $(MAKEFILE_LIST))
