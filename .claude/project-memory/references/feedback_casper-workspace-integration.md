---
name: "Casper workspace integration"
description: "Where the Casper wiring lives in this repository, and what stays tool-agnostic"
type: feedback
---

# Casper workspace integration

`.casper.json` maps the three Casper lifecycle
hooks onto ordinary Make targets and holds the
port arithmetic: `CASPER_PORT` + 0 for the HTTP
API, + 1 for the gRPC gateway, + 2 for the
Temporal Web UI. The workspace's default command
brings the stack up in containers, so a fresh
workspace is self-contained.

The Make targets it calls are neutral: they are
named for what they do and are useful without any
workspace tool. The only Casper-aware part of the
Makefile is the guarded pair that publishes and
clears the info panel. That guard tests both
`CASPER_WORKSPACE_ID` and the presence of the
`casper` CLI, and it belongs in the Makefile —
`.casper.json` is read by Casper alone, so a
check for the CLI there is noise.

The info panel mirrors the stack: every target
that starts it publishes `make endpoints`, every
target that stops it clears the panel.

**Why:** the demo has to read as an ordinary
Temporal demo to someone who has never heard of
the workspace tool, and the panel is worth
trusting only if it tells the truth whatever
command was typed.

**How to apply:** put workspace-specific wiring
in `.casper.json` and keep the repository's own
files tool-agnostic. A new target that starts or
stops the stack publishes or clears the panel too.
