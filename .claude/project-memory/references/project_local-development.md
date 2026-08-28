---
name: "Local development needs no cluster"
description: "The Workflow and Activity inner loop runs against an ephemeral Temporal dev server, not the cluster"
type: project
---

# Local development needs no cluster

Developing the `hello-workflow` Workflow and Activity code
needs neither Kubernetes nor temporal-proxy. An ephemeral
`temporal server start-dev`, plus `go run ./cmd/worker`
and `go run ./cmd/app` run directly against it: the dev
server listens on `localhost:7233` with a Namespace named
`default`, exactly `internal/temporalclient`'s defaults, so
no environment variable needs setting.

**Why:** the Kind cluster demonstrates the deployment
story — Traefik, Vault, the Vault Secrets Operator and
temporal-proxy wired together — and rebuilding an image
and restarting pods on every change is the wrong inner
loop for editing Go. The Worker and the API are the same
binaries either way, so nothing about the dev-server loop
diverges from what the cluster runs.

**How to apply:** run `temporal server start-dev` in one
terminal, then `go run ./cmd/worker` and `go run
./cmd/app` in others, with no `.env` and no cluster
required. Reach for `make deploy` only to demonstrate or
verify the Kubernetes deployment itself. See
[[project-hello-workflow-app]].
