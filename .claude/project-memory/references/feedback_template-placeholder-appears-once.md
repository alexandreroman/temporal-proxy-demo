---
name: "A template placeholder appears exactly once"
description: "Why prose in k8s/kind-config.yaml.in never spells out the token worktree-init substitutes"
type: feedback
---

# A template placeholder appears exactly once

In `k8s/kind-config.yaml.in`, the literal `@TRAEFIK_PORT@` belongs
on the `hostPort:` line and nowhere else. Comments that need to
mention the port name the `make` variable, `TRAEFIK_PORT`, without
the surrounding `@` markers.

**Why:** `worktree-init` renders the template with a plain
`sed 's/@TRAEFIK_PORT@/<port>/'`, which is unanchored and matches
the token wherever it sits — a comment included. A second
occurrence is substituted too, so the generated
`k8s/kind-config.yaml` carries a bare port number in prose that
reads as if it were configuration.

**How to apply:** keep every placeholder to a single occurrence,
on the line that actually needs the value. A header comment in a
template is also read in the file generated from it, so word it so
it stays true in both: name the generated file as the thing being
rendered, and never call it a template.
