---
name: "Per-worktree configuration lives on disk"
description: "Why a worktree's published port is frozen in a generated k8s/kind-config.yaml"
type: feedback
---

# Per-worktree configuration lives on disk

A worktree's published host port is frozen in a generated
`k8s/kind-config.yaml`, git-ignored and written by `make
worktree-init` from the template `k8s/kind-config.yaml.in`.
Kind reads no environment variable of its own, so the port
has no other way to reach cluster creation. Commands that
need the port ask the running cluster's node for it,
through whichever container CLI `CONTAINER_TOOL` names, and
fall back to the documented default, `8080`, when the
cluster is down.

**Why:** the cluster name is the worktree's own directory
name, so two worktrees never share a cluster, and one
generated file holds this worktree's whole per-worktree
configuration. A port carried by the environment is
invisible to anyone bypassing the Makefile, and drifts as
soon as two places compute it.

**How to apply:** when a worktree needs a setting of its
own, write it into the generated `kind-config.yaml` (or
its `.in` template) rather than an environment file, and
read values back from the cluster instead of recomputing
them.
