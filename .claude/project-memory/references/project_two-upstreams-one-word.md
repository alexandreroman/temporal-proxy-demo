---
name: "Two upstreams, and the one word that selects between them"
description: "How the demo routes Workers at either Temporal Cloud or the self-hosted Temporal Service, and why the switch is a single key"
type: project
---

# Two upstreams, and the one word that selects between them

`k8s/charts/temporal-proxy.yaml` declares both of the demo's
upstreams side by side, and `config.routing.default` names
the one that serves every request. Writing `selfhosted` in
place of `cloud` and running `make apply` is the whole of
the switch: the Worker and the API are not rebuilt, not
restarted and not reconfigured, and their pods keep the same
names and the same Deployment revision across it.

Four properties make that possible:

- `routing.system` is omitted, so a request carrying no
  Namespace — the `GetSystemInfo` a Client sends on
  connect — falls through to `routing.default` and there is
  only one name to change. This is safe because the `cloud`
  upstream's `hostPort` is statically expanded from the
  environment; the upstream chart's own example pairs
  `system` with a dedicated upstream only because its
  `hostPort` is templated on the remote Namespace, which
  cannot resolve for a Namespace-less request.
- An upstream nothing routes to is never dialled, so both
  stand declared and neither costs anything.
- The self-hosted upstream carries no `tls`, because its
  endpoint is dialled in plaintext inside the cluster, and
  no `namespaces.rules`, because its Service registers the
  Namespace under `demo` — the same string the application
  asks for, so there is nothing to rewrite. The Cloud
  upstream needs both.
- Payload encryption is orthogonal to the choice:
  temporal-proxy seals every payload whichever upstream it
  forwards to, so the self-hosted Web UI shows sealed
  payloads exactly as Temporal Cloud does.

**Why:** the demo's claim is that the application is
untouched by where Temporal lives, and a switch that costs
one word is the shortest proof of it. Anything the switch
also required — a second key, a rebuild, a restart — would
weaken the claim it exists to make.

**How to apply:** add an upstream as a declared entry rather
than a commented one, and let `routing.default` carry the
choice. `routing.rules` matches on the Namespace a request
asks for, so serving several upstreams at once is a rule per
Namespace rather than a second copy of this arrangement. The
fallback and the rule evaluation are in `internal/router/mux.go`
(`Mux.Switch`) and `internal/config/routing.go` at v0.5.2. See
[Demo scope](project_demo-scope.md),
[temporal-proxy's Helm chart](reference_proxy-helm-chart.md),
[Outbound TLS rules](reference_proxy-outbound-tls.md) and
[The short Namespace name identifies the
tenant](feedback_namespace-identifies-the-tenant.md).
