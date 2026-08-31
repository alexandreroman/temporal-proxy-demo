---
name: "One environment file, loaded for every target"
description: "Why the Makefile reads a single .env for every target, with no per-target include tier"
type: feedback
---

# One environment file, loaded for every target

The project uses one environment file, `.env`, and
no per-target include tier: every target sees the
same values.

**Why:** the configuration behind a target is
simply what `.env` holds, readable without working
out which includes the named goal activates.
Selecting environment files from `MAKECMDGOALS`
makes the effective values depend on the target
typed on the command line — invisible in the file
itself, and a detour in a demo where every file
has to be explainable on a slide.

**How to apply:** put shared configuration in
`.env`, documented in `.env.example`, and
per-worktree settings in the generated
`k8s/kind-config.yaml` — see
[Per-worktree configuration](feedback_worktree-config-on-disk.md).
For a one-off value, pass it on the command line
(`make demo NAME=Alex`, which wins over the
Makefile's default) or set it in the calling
environment, rather than introducing another
environment file.
