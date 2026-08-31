---
name: "How an HTTPRoute binds to the Traefik chart's Gateway"
description: "What the Gateway's name and namespace actually depend on, and why a default Gateway is not available"
type: reference
---

# How an HTTPRoute binds to the Traefik chart's Gateway

Four facts govern how a route in this repository reaches
Traefik, and the first two are the opposite of what the
chart's shape suggests:

- The Gateway's **name** comes from `gateway.name`,
  defaulting to the literal `traefik-gateway` in
  `templates/gateway.yaml`. It is not derived from the Helm
  release name: rendering the same values under a release
  named `edge` still produces `traefik-gateway`. Neither
  `fullnameOverride` nor `nameOverride` touches it.
- The Gateway's **namespace** is release-derived — it is
  `namespaceOverride` or the install namespace, which is
  what `gateway.namespace` overrides. That, not the name,
  is what an `HTTPRoute`'s `parentRefs` couples to.
- `parentRefs` is optional in the Gateway API v1.6.1
  standard CRD, but omitting it attaches the route to
  nothing rather than to a default, and a `parentRefs`
  naming an absent Gateway fails the same silent way: a 404
  with no error anywhere.
- A cluster-default Gateway is **not available**. GEP-3793
  adds `Gateway.spec.defaultScope` and
  `HTTPRoute.spec.useDefaultGateways`, but both are
  experimental-channel only in v1.6.1, and Traefik v3.7.x
  never reads either field — its provider package does not
  reference them. The chart does expose
  `gateway.defaultScope`, so setting it writes the field and
  changes nothing, which is worse than leaving it unset.

**Why:** naming the Gateway in a route looks like a coupling
to the release name and is not, so the mitigation people
reach for — pinning the release name, or `fullnameOverride`
— guards nothing. Pinning `gateway.name` is what makes the
name a contract. And a route that binds to nothing produces
no event and no condition worth alerting on, so the failure
surfaces only as a 404.

**How to access:** render the chart and read the Gateway
object rather than reasoning from the values file:
`helm template <release> traefik --repo
https://traefik.github.io/charts --version <pinned>
--namespace <ns> -f k8s/charts/traefik.yaml`. Rendering it
twice under different release names settles any question
about what the release name reaches. See
[temporal-proxy's Helm chart](reference_proxy-helm-chart.md).
