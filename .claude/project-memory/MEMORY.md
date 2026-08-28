# Project Memory

> When a new decision **contradicts** an existing
> memory note, do NOT silently override it.
> Instead: surface the conflict, quote the
> existing memory, explain how the new decision
> differs, and ask for explicit confirmation
> before updating. **Do NOT take any action** —
> no tool calls, no file writes — until confirmed.

> **Note wording** — state permanent facts in the
> present tense. A note read out of context must
> not reveal what it replaces or what just
> happened. Ban narration markers: "now", "no
> longer", "previously / used to", "reverses /
> replaces", "kept", "changed to", "reintroduce",
> "the user asked to". Phrase prohibitions
> positively ("the API is versioned under /v2"),
> not as the negation of a former state. Test:
> remove the note from its context — if a sentence
> only makes sense knowing the prior state,
> rewrite it.

- [Demo scope and scenarios](references/project_demo-scope.md) — the two Vault scenarios in scope, and what is not
- [Founding technical choices](references/project_founding-choices.md) — why Go, Kubernetes on Kind and Apache-2.0
- [temporal-proxy upstream resources](references/reference_temporal-proxy-upstream.md) — source, docs, examples, image and Helm chart
- [Shape of the hello-workflow demo app](references/project_hello-workflow-app.md) — HTTP trigger, two binaries, and the two-second Activity
- [Application code stays endpoint-agnostic](references/feedback_agnostic-app-code.md) — no proxy vocabulary in Go code, not even in comments
- [Casper workspace integration](references/feedback_casper-workspace-integration.md) — where the workspace wiring lives, and what stays tool-agnostic
- [Per-worktree configuration lives on disk](references/feedback_worktree-config-on-disk.md) — a generated k8s/kind-config.yaml, and the port read back from the cluster
- [Switching upstreams is a proxy-config change](references/feedback_scenario-switch.md) — one Kustomize overlay and Helm values file per scenario, selected by `SCENARIO`
- [Naming the proxy outside the Go code](references/feedback_naming-the-proxy.md) — call it `temporal-proxy`, and how the port variable is named
- [Outbound TLS rules for a temporal-proxy upstream](references/reference_proxy-outbound-tls.md) — a client certificate also requires a `ca`, and that `ca` verifies the server
- [One environment file, loaded for every target](references/feedback_single-env-file.md) — a single `.env` for every target, no per-target tier
- [The API tolerates unknown request fields](references/project_lenient-request-decoding.md) — extra JSON fields are ignored, so the contract can grow
- [Local development needs no cluster](references/project_local-development.md) — the Go inner loop runs against an ephemeral Temporal dev server
- [temporal-proxy encryption constraints](references/reference_proxy-encryption-constraints.md) — what a Vault Transit-backed encryption scenario must satisfy
