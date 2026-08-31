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

- [Demo scope](references/project_demo-scope.md) — what the demo teaches, and what is deliberately out of it
- [Founding technical choices](references/project_founding-choices.md) — why Go, Kubernetes on Kind and Apache-2.0
- [temporal-proxy upstream resources](references/reference_temporal-proxy-upstream.md) — source, docs, examples, image and Helm chart
- [Shape of the hello-workflow demo app](references/project_hello-workflow-app.md) — HTTP trigger, two binaries, and the two-second Activity
- [Application code stays endpoint-agnostic](references/feedback_agnostic-app-code.md) — no proxy vocabulary in Go code, not even in comments
- [Casper workspace integration](references/feedback_casper-workspace-integration.md) — where the wiring lives, and what stays neutral
- [Per-worktree configuration lives on disk](references/feedback_worktree-config-on-disk.md) — a generated kind-config.yaml, and the port read back
- [Naming the proxy outside the Go code](references/feedback_naming-the-proxy.md) — call it `temporal-proxy`, and how the port variable is named
- [Outbound TLS for an upstream](references/reference_proxy-outbound-tls.md) — a client certificate also requires a `ca`, which verifies the server
- [One environment file, loaded for every target](references/feedback_single-env-file.md) — a single `.env` for every target, no per-target tier
- [The API tolerates unknown request fields](references/project_lenient-request-decoding.md) — extra JSON fields are ignored
- [Local development needs no cluster](references/project_local-development.md) — the Go inner loop runs against an ephemeral Temporal dev server
- [temporal-proxy encryption constraints](references/reference_proxy-encryption-constraints.md) — what payload encryption must satisfy
- [temporal-proxy's Helm chart](references/reference_proxy-helm-chart.md) — where it lives, and the behaviours its values file answers to
- [No tenant is called default](references/feedback_namespace-identifies-the-tenant.md) — the app asks for `demo`, the proxy maps it
- [Pinned versions are literals in the recipe](references/feedback_pinned-versions-inline.md) — no `make` variable, and where the rationale lives
- [Manifests state only what differs from the default](references/feedback_manifests-omit-defaults.md) — no restated API defaults
- [The Makefile's help listing is its public surface](references/feedback_help-is-the-public-surface.md) — `##` marks a target a reader types
- [A template placeholder appears exactly once](references/feedback_template-placeholder-appears-once.md) — on the `hostPort:` line, never in prose
- [How an HTTPRoute binds to Traefik's Gateway](references/reference_traefik-gateway-binding.md) — no default Gateway is available
- [A rollout overlaps only where traffic arrives](references/feedback_overlapping-rollout.md) — the API needs it, the Worker does not
