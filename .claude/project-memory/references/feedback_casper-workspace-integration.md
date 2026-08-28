---
name: "Casper workspace integration"
description: "Where the Casper wiring lives in this repository, and what stays tool-agnostic"
type: feedback
---

# Casper workspace integration

`.casper.json` maps the three Casper lifecycle hooks onto
ordinary Make targets: `setup` runs `make worktree-init
TRAEFIK_PORT=$CASPER_PORT`, `run` runs `make deploy`, and
`teardown` runs `make cluster-down`. One port,
`TRAEFIK_PORT`, carries the workspace's assigned port
straight into the Make variable Traefik's published port
is built from, so that variable name is a contract between
the two files. `.casper.json` also copies `.env`,
`client.pem` and `client.key` into a fresh workspace —
matched by basename, so the certificate pair lands back
under `k8s/base/proxy/certs/` — and a workspace deploys
the whole demo as soon as `.env` holds valid Temporal
Cloud values and that certificate pair is present.

The Make targets it calls are neutral: they are named for
what they do and are useful without any workspace tool.
The only Casper-aware part of the Makefile is the guarded
pair that publishes and clears the info panel. That guard
tests both `CASPER_WORKSPACE_ID` and the presence of the
`casper` CLI, and it belongs in the Makefile —
`.casper.json` is read by Casper alone, so a check for the
CLI there is noise.

The info panel mirrors the stack at the two ends of its
lifecycle: `deploy` publishes `make endpoints` once the
rollout is up, and `cluster-down` clears the panel once the
cluster is gone. Targets in between, such as `cluster-up`
and `apply`, touch neither the panel nor
`make endpoints`.

**Why:** the demo has to read as an ordinary Temporal demo
to someone who has never heard of the workspace tool, and
the panel is worth trusting only if it tells the truth
whatever command was typed.

**How to apply:** put workspace-specific wiring in
`.casper.json` and keep the repository's own files
tool-agnostic. A new target that starts or stops the
cluster publishes or clears the panel too.
