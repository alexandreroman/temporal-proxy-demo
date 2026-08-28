---
name: "Demo scope and scenarios"
description: "What Temporal Proxy Demo demonstrates, for whom, and which scenarios are in scope"
type: project
---

# Demo scope and scenarios

The project is a teaching demo, not a product: it shows
how a Temporal Worker and HTTP API run against
temporal-proxy on Kubernetes while carrying no upstream
connection details of their own. Temporal Cloud is the
demo's one upstream. The scenario axis is what
temporal-proxy is configured to do:

1. **`credentials`** — temporal-proxy reaches Temporal
   Cloud with a client certificate mounted from a
   Kubernetes Secret that Kustomize generates, its name
   carrying a content hash so that replacing the
   certificate rolls the Deployment.
2. **`encryption`** — an open question: an encryption
   scenario is intended, wrapping a data encryption key
   per payload so that Temporal Cloud stores ciphertext
   only, rendered readable again by a codec server in the
   Cloud Web UI. Which KMS backs it, and whether it needs
   an extension server at all, is undecided:
   `crypto.DefaultSchemes()` includes `testing`, which
   temporal-proxy resolves to gocloud's local
   `base64key://` keeper, so one shape of the scenario
   needs no additional component — at the cost of a scheme
   that upstream marks as unfit for anything but local runs.

Inbound authentication and authorization (static token,
JWKS, authorizer extension server) are deliberately out of
scope.

**Why:** the audience is developers and platform teams
evaluating temporal-proxy; a demo that covers everything
teaches nothing. These two scenarios are the ones that
change how temporal-proxy is configured, not how Worker
code is written — the Worker and the API stay
byte-identical across both.

**How to apply:** when adding material, ask which scenario
it serves, or whether it changes how temporal-proxy is
configured at all. Anything that serves neither belongs in
a different repository.
