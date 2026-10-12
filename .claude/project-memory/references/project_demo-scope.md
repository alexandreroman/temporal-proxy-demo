---
name: "Demo scope"
description: "What Temporal Proxy Demo demonstrates, for whom, and what is deliberately left out"
type: project
---

# Demo scope

The project is a teaching demo, not a product: it shows
how a Temporal Worker and HTTP API run against
temporal-proxy on Kubernetes while carrying no upstream
connection details of their own. It declares two upstreams:
Temporal Cloud, reached with an API key temporal-proxy reads
from a Kubernetes Secret, is the one the demo ships routed
at, and a self-hosted Temporal Service in the cluster's
`temporal` namespace is the second.

Everything the demo teaches sits in temporal-proxy's
configuration, so the Worker and the API are
byte-identical whatever that configuration says.

Payload encryption seals every payload before it
leaves the cluster — Search Attribute values stay in
the clear, so the upstream can index them — under data
encryption keys
temporal-proxy caches and reuses across payloads for
their configured lifetime. A KMS extension server this
repository runs (`cmd/kms`) wraps those keys, because
temporal-proxy's built-in schemes cover only clouds this
demo does not use. `internal/kms` supplies nothing but
the key lookup — one AES-256 key per Namespace, derived
from a master secret via HKDF-SHA256 — and `cmd/kms`
hands it to temporal-proxy's `ext.NewKeyWrapper`, which
seals and frames each wrapped key.

Inbound authentication and authorization (static token,
JWKS, authorizer extension server) are deliberately out of
scope.

**Why:** the audience is developers and platform teams
evaluating temporal-proxy; a demo that covers everything
teaches nothing. What earns a place is what changes how
temporal-proxy is configured, not how Worker code is
written.

**How to apply:** when adding material, ask whether it
changes how temporal-proxy is configured. Anything that
does not belongs in a different repository. See
[temporal-proxy encryption
constraints](reference_proxy-encryption-constraints.md)
and [Two upstreams, and the one
word](project_two-upstreams-one-word.md).
