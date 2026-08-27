---
name: "Per-worktree configuration lives on disk"
description: "Why a worktree's ports and Compose project name are frozen in a generated compose.override.yaml"
type: feedback
---

# Per-worktree configuration lives on disk

A worktree's published host ports and its Compose
project name are frozen in a generated
`compose.override.yaml`, git-ignored and written
by `make worktree-init`. The repository carries no
generated environment file. Commands that need a
port ask Compose for it with `docker compose port`
and fall back to the documented default when the
service is down.

**Why:** a bare `docker compose` typed inside a
worktree then behaves exactly like the same
command run through `make`, and one file holds the
whole per-worktree configuration. Ports carried by
the environment are invisible to anyone bypassing
the Makefile, and drift as soon as two places
compute them.

**How to apply:** when a worktree needs a setting
of its own, write it into the generated override
file rather than an environment file, and read
values back from Compose instead of recomputing
them.
