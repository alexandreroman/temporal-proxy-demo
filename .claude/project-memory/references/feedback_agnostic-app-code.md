---
name: "Application code stays endpoint-agnostic"
description: "The Go code never names a proxy — it only knows a local Temporal endpoint"
type: feedback
---

# Application code stays endpoint-agnostic

The Go code knows exactly one thing about where it
connects: a local Temporal endpoint it dials in
plaintext with a short Namespace name. What backs
that endpoint — a dev server, a proxy, a
self-hosted frontend, Temporal Cloud — is a
deployment concern the code has no opinion about.

The rule covers vocabulary, not just configuration.
Comments, doc comments, log messages, error
messages and identifiers avoid `temporal-proxy` by
name and avoid proxy vocabulary in general:
"upstream", "gateway", and "the proxy handles X"
all presuppose the thing the code is meant to be
ignorant of.

Stating what is deliberately **absent** from the
client options stays welcome — no TLS material, no
credentials, no fully-qualified Namespace — as long
as it does not name who supplies it.

**Why:** the same binaries must run unchanged
across every scenario. A comment naming a proxy is
a claim about the deployment, and it is exactly the
claim the demo exists to disprove.

**How to apply:** review new Go code with
`grep -rniE "proxy|gateway|upstream" --include='*.go' .`
— only import paths carrying the repository name
should match. See [[project-demo-scope]].
