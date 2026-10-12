---
name: "One environment file, loaded for every target"
description: "Why every Make target reads the same .env file"
type: feedback
---

# One environment file, loaded for every target

Every Make target reads the same environment file,
`.env`, so the values behind a target are exactly
what that file holds.

**Why:** a reader can tell the configuration of any
command by reading one file, whatever target was
typed — which a demo where every file has to be
explainable on a slide depends on.

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
