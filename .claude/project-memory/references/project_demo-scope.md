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

Payload encryption is an intended direction and an open
question: wrapping a data encryption key per payload so
that Temporal Cloud stores ciphertext only, rendered
readable again by a codec server in the Cloud Web UI.
Which KMS backs it, and whether it needs an extension
server at all, is undecided: `crypto.DefaultSchemes()`
includes `testing`, which temporal-proxy resolves to
gocloud's local `base64key://` keeper, so one shape of it
needs no additional component — at the cost of a scheme
that upstream marks as unfit for anything but local runs.

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
[[reference-proxy-encryption-constraints]].
