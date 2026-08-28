---
name: "Demo scope and scenarios"
description: "What temporal-proxy-demo demonstrates, for whom, and which proxy scenarios are in scope"
type: project
---

# Demo scope and scenarios

The project is a teaching demo, not a product: it
shows how Temporal Workers run against
temporal-proxy while carrying no upstream
connection details of their own. Three scenarios
are in scope:

1. **Multi-upstream routing** — one plaintext
   Worker endpoint, requests routed by Namespace
   to several upstreams.
2. **Temporal Cloud** — the proxy owns TLS, the
   client certificate, and the Namespace rewrite;
   the Worker knows nothing about Cloud.
3. **Payload encryption (KMS)** — envelope
   encryption on the hop to the upstream, so the
   Temporal Service only ever stores ciphertext.

Inbound authentication and authorization
(static token, JWKS, authorizer extension server)
are deliberately out of scope.

**Why:** the audience is developers and platform
teams evaluating temporal-proxy; a demo that
covers everything teaches nothing. These three
scenarios are the ones that change how Worker
code is written.

**How to apply:** when adding material, ask which
of the three scenarios it serves. Anything that
serves none belongs in a different repository.
