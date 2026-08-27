# temporal-proxy-demo

A hands-on demo showing how Temporal Workers written with the Go SDK
run against [temporal-proxy](https://github.com/temporalio/temporal-proxy)
without carrying any upstream connection, TLS, credential, or Namespace
configuration of their own.

See [README.md](README.md) for full documentation.

## Tech stack

- Go — Temporal Go SDK (Worker) and net/http (API)
- temporal-proxy — gRPC gateway in front of every upstream
- Docker Compose — Temporal dev server and proxy
- Temporal Cloud — one of the demo upstreams (TLS + API key)

## Build & run

```bash
make                # list every target
make infra-up       # Temporal dev server + proxy in Compose
make dev            # infra, then the Worker and the API on the host
make demo           # curl the API to start one Workflow
make check          # tests and static checks
```

## Modules

- `cmd/worker` — Temporal Worker, polling through the proxy
- `cmd/api` — HTTP API that starts one Workflow Execution
- `internal/hello` — the hello-workflow Workflow and its Activity
- `internal/temporalclient` — the shared client: plaintext, no credentials
- `proxy` — temporal-proxy configuration, one per scenario

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

Use the **project-memory** skill (from the
[skillbox](https://github.com/alexandreroman/skillbox)
plugin) proactively — without being asked — whenever
the conversation reveals project decisions, deadlines,
team context, external references, workflow preferences,
or corrective feedback worth persisting across
conversations.

**Important:** Always use the **project-memory**
skill to persist information. Never use the built-in
auto-memory system (`~/.claude/projects/.../memory/`)
for project decisions or context — it is local and
not shared with the team.

## Conventions

- Line length limits for readability:
  - Text / Markdown: 80 columns max
  - Code: 120 columns max
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
- temporal-proxy is **pre-release**. Pin its version
  explicitly and re-check its config schema against
  the upstream repo before changing `proxy/`.
