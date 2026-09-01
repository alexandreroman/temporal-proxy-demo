---
name: "Demo scope"
description: "What Temporal Proxy Demo demonstrates, for whom, and what is deliberately left out"
type: project
---

# Demo scope

The project is a teaching demo, not a product: it shows
how a Temporal Worker and HTTP API run against
temporal-proxy on Kubernetes while carrying no upstream
connection details of their own. Temporal Cloud is the
demo's one upstream, reached with a client certificate
mounted from a Kubernetes Secret.

Everything the demo teaches sits in temporal-proxy's
configuration: the Cloud host name, the TLS material, and
the rewrite from the short Namespace name the application
asks for to the fully-qualified name Cloud knows. The
Worker and the API are byte-identical whatever that
configuration says.

Payload encryption wraps a data encryption key per
payload so temporal-proxy seals every payload before it
leaves the cluster. A KMS extension server this
repository runs (`cmd/kms`, deriving one AES-256-GCM key
per Namespace from a master secret via HKDF-SHA256) wraps
that key, because temporal-proxy's built-in schemes
(`awskms`, `azurekeyvault`, `gcpkms`, `testing`) cover
only clouds this demo does not use, plus a scheme upstream
marks unfit for anything but local runs. Per-request
selectivity is not in temporal-proxy's model:
`Encryption.Enabled` is one boolean for the whole proxy
instance, so a payload is sealed or not for everything it
forwards, never chosen call by call.

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
[encryption constraints](reference_proxy-encryption-constraints.md).
