# Temporal Proxy Demo

A hands-on demo showing how Temporal Workers written with the Go SDK
run against [temporal-proxy](https://github.com/temporalio/temporal-proxy)
without carrying any upstream connection, TLS, credential, or Namespace
configuration of their own.

See [README.md](README.md) for full documentation.

## Tech stack

- Go — Temporal Go SDK (Worker) and net/http (API)
- Tailwind CSS and Alpine.js — the embedded page, both from a CDN
- temporal-proxy — one gRPC endpoint in front of every upstream
- Kubernetes on Kind — the local cluster the demo runs in
- Kustomize — the Worker, the API and the KMS server
- Helm — Traefik, cert-manager and temporal-proxy, from their upstream charts
- cert-manager — issues the KMS server's certificate
- secretgen-controller — generates the KMS server's bearer token
- Traefik — the cluster's only published entrypoint
- Temporal Cloud — the demo's upstream (TLS + client certificate)

## Build & run

```bash
make worktree-init  # generate this worktree's cluster config
make                # list every target
make app-up         # cluster, KMS server, temporal-proxy, Worker and API
make demo           # curl the API to start one Workflow
make check          # tests and static checks
make cluster-down   # delete the cluster
```

`.env` also needs `KMS_MASTER_SECRET`; `require-setup`
refuses to deploy without it.

## Modules

- `cmd/worker` — Temporal Worker, polling a Task Queue
- `cmd/app` — HTTP API that starts one Workflow Execution,
  and the embedded page that drives it
- `internal/hello` — the hello-workflow Workflow and its Activity
- `internal/temporalclient` — the shared client: plaintext, no credentials
- `cmd/kms` — gRPC server wrapping and unwrapping payload keys
- `internal/kms` — derives one AES-256-GCM key per Namespace
- `k8s` — the cluster configuration: the application's manifests in
  `app`, the KMS server's in `kms`, the charts' values in `charts`,
  the client certificate in `certs`, plus `namespaces.yaml`, applied
  on its own, and `kind-config.yaml.in`, the template `worktree-init`
  renders

## Agents

Use the following agents (from the
[skillbox](https://github.com/alexandreroman/skillbox)
plugin) for all code tasks:

- **code-writer** — for ANY task that writes,
  modifies, or refactors code. This includes
  one-line fixes, import changes, visibility
  tweaks, and adding assertions. Never edit
  source files directly — always delegate to
  this agent.
- **code-reviewer** — for read-only code review
  before merging or when investigating issues.

## Memory

At the start of every conversation, read
`.claude/project-memory/MEMORY.md` to load
project context from previous conversations.

Persist anything worth keeping with the
**project-memory** skill (from the
[skillbox](https://github.com/alexandreroman/skillbox)
plugin), which carries its own triggers. Never use the
built-in auto-memory system
(`~/.claude/projects/.../memory/`) for project
decisions or context — it is local and not shared with
the team.

## Conventions

- Line length limits for readability:
  - Text / Markdown: 80 columns max
  - Code: 120 columns max
  - Exempt, single lines by format: the
    `.claude/project-memory` index's entries and each note's
    frontmatter `description:`; the notes' prose bodies keep
    the 80-column limit
- Follow standard Markdown conventions: blank line
  before and after headings, blank line before and
  after lists, fenced code blocks with a language tag
- Always use the latest LTS or stable version of
  languages, frameworks, and libraries. Check the
  official documentation or use available tools
  (e.g. context7) to verify current versions before
  choosing a dependency.
- This is a **demo**: readability beats cleverness.
  Every file should be explainable on a slide.
- The Go code stays agnostic about what backs its
  Temporal endpoint. It dials a local endpoint in
  plaintext with a short Namespace name, and carries
  no TLS material, no credentials, and no
  fully-qualified Namespace. Never name temporal-proxy
  — nor imply a proxy at all — in comments, log
  messages, errors, or identifiers. That neutrality is
  the whole point of the demo; anything that leaks
  into the code is a bug.
- temporal-proxy is **pre-release**. Its chart version
  and its image tag are both pinned explicitly;
  re-check its config schema against the upstream repo
  before changing `k8s/charts/temporal-proxy.yaml`.
