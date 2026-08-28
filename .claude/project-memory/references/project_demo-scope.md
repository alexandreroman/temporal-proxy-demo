---
name: "Demo scope and scenarios"
description: "What Temporal Proxy Demo demonstrates, for whom, and which Vault scenarios are in scope"
type: project
---

# Demo scope and scenarios

The project is a teaching demo, not a product: it shows
how a Temporal Worker and HTTP API run against
temporal-proxy on Kubernetes while carrying no upstream
connection details of their own. Temporal Cloud is the
demo's one upstream. The scenario axis is what Vault is
used for:

1. **`credentials`** — Vault as a vault: custodian of the
   Temporal Cloud client certificate, synced into a
   Kubernetes Secret by the Vault Secrets Operator and
   mounted by temporal-proxy.
2. **`encryption`** — Vault as a KMS: Vault's Transit
   engine wraps a data encryption key per payload through
   an extension server, so Temporal Cloud stores
   ciphertext only, rendered readable again by a codec
   server in the Cloud Web UI.

Inbound authentication and authorization (static token,
JWKS, authorizer extension server) are deliberately out of
scope.

**Why:** the audience is developers and platform teams
evaluating temporal-proxy; a demo that covers everything
teaches nothing. These two scenarios are the ones that
change how Vault is used, not how Worker code is written —
the Worker and the API stay byte-identical across both.

**How to apply:** when adding material, ask which scenario
it serves, or whether it changes how Vault is used at all.
Anything that serves neither belongs in a different
repository.
