---
name: "Per-worktree configuration lives on disk"
description: "Why a worktree's published port is frozen in a generated k8s/kind-config.yaml"
type: feedback
---

# Per-worktree configuration lives on disk

A worktree's published host port lives in a generated
`k8s/kind-config.yaml`, git-ignored and rendered from the
template `k8s/kind-config.yaml.in`. Kind's config file
cannot read environment variables and no kind flag sets a
port mapping, so the file is the only way the port reaches
cluster creation. Commands that need the port afterwards
read it back from the running cluster's node.

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
them. The Makefile comments describe when the file is
rendered and how the port is read back.
