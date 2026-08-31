---
name: "A shared temporal-proxy means no tenant is called default"
description: "Why the application asks for the short Namespace name demo, and temporal-proxy maps it onto the upstream's own name"
type: feedback
---

# A shared temporal-proxy means no tenant is called default

temporal-proxy is a multi-tenant deployment: one instance
fronts several applications, so the short Namespace name an
application asks for is what identifies that application.
This demo's application asks for `demo`, and an override
under the upstream's `namespaces.rules` in
`k8s/charts/temporal-proxy.yaml` maps it to the
fully-qualified Temporal Cloud Namespace. `default` names no
tenant, and would collide with every other application
behind the same proxy.

`internal/temporalclient` falls back to `default` when
`TEMPORAL_NAMESPACE` is unset. That fallback serves the
local dev-server loop, which offers exactly that Namespace,
and it never reaches temporal-proxy — the deployment always
sets the variable. See
[Local development needs no cluster](project_local-development.md).

**Why:** a shared proxy can only route on a name that says
which application is asking; `default` says "whatever this
endpoint happens to serve" and gives temporal-proxy nothing
to key on. The mapping is also the demo's point: the
application's name for a Namespace and the upstream's name
for it are different strings, and temporal-proxy is the only
component that knows both.

**How to apply:** give each application its own short
Namespace name, and add one override per application under
the upstream's `namespaces.rules`. The fully-qualified name
stays out of the application in every case — see
[Application code stays endpoint-agnostic](feedback_agnostic-app-code.md) and
[temporal-proxy's Helm chart](reference_proxy-helm-chart.md).
