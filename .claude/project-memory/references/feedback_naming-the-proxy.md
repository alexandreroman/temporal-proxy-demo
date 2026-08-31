---
name: "Naming the proxy outside the Go code"
description: "Docs, Makefile and Kubernetes manifests call the component temporal-proxy, and how its port variable is named"
type: feedback
---

# Naming the proxy outside the Go code

Everywhere the demo is free to name the component —
README, Makefile, the manifests and chart values under `k8s/`,
`.env.example` — it is called `temporal-proxy`, its own
name. A generic word for a network intermediary is vaguer
than the name and describes any proxy equally well, so it
earns no place in prose or in identifiers. The Go code is
the one place that names nothing at all: see
[Application code stays endpoint-agnostic](feedback_agnostic-app-code.md).

`temporal-proxy` is a proper name and takes no article:
"temporal-proxy validates its config on startup", never
"the temporal-proxy validates". Where repeating the name
weighs a sentence down, recast the sentence.

Make variables holding a host port are qualified by what
they publish: `TRAEFIK_PORT`, the one port this deployment
publishes, named for what it publishes rather than left
bare.

**Why:** the component's own name is precise and
searchable, and a demo built to show temporal-proxy should
say what it is showing. Qualifying `TRAEFIK_PORT` by what
it publishes keeps it readable next to the application's
own `PORT` environment variable — a separate, unqualified
contract that `cmd/app` reads directly for its listen
address, and that no Make variable needs to mirror.

**How to apply:** name the component in documentation, in
Makefile, manifest and values comments, and in target
descriptions. Qualify a Make variable that publishes a
port by what it publishes. See
[Casper workspace integration](feedback_casper-workspace-integration.md)
for the port variable `.casper.json` passes in.
