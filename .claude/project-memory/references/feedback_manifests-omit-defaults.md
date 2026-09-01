---
name: "Manifests state only what differs from the default"
description: "Kubernetes and Kind configuration carries a field only when its value overrides the API's own default"
type: feedback
---

# Manifests state only what differs from the default

A Kubernetes manifest under `k8s/app/` and the Kind
cluster template carry a field only when its value
differs from the API's own default. `replicas`,
`imagePullPolicy` on a tag other than `latest`, an
HTTPRoute rule's `matches` where it would be the
default path prefix, and `protocol` in a Kind port
mapping are all absent for that reason.

The values files under `k8s/charts/` read inverted:
a field there exists because it overrides a chart
default, and the comment above it names which
default and why. One of them restates a chart
default on purpose: `gateway.name`, which
`k8s/app/httproute.yaml` names in its `parentRefs`.
A chart default is not a contract across chart
versions, so a name another file depends on is
pinned rather than inherited.

A field that does earn its place because the demo
depends on it — the app Deployment's readiness
probe, since the API connects to Temporal before it
listens — carries the reason next to it.

**Why:** a restated default is a line a reader has
to check against the API before trusting it, and it
teaches nothing about this demo. What is left in a
file is then exactly what the demo chose.

**How to apply:** before adding a field, look up
the default; if they match, leave it out. When a
field does override one, say which in a comment
above it. See
[Pinned versions](feedback_pinned-versions-inline.md).
