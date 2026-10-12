---
name: "temporal-proxy's Helm chart"
description: "Where the temporal-proxy chart lives, and the five chart behaviours its values file has to account for"
type: reference
---

# temporal-proxy's Helm chart

temporal-proxy is deployed from the upstream
`temporal-proxy` chart in the Temporal Helm repo,
<https://go.temporal.io/helm-charts>, with this demo's
values in `k8s/charts/temporal-proxy.yaml`. Both the chart
version and `image.tag` are pinned explicitly, because the
chart's `appVersion` trails the published image. With
`image.tag: v0.8.0` against an `appVersion` of `v0.5.0`, every
rendered object carries `app.kubernetes.io/version: "v0.5.0"`:
the label reports the chart's version, not the running image's,
and it is cosmetic.

Five of the chart's behaviours decide what a values file has
to say:

- `config` is copied into the ConfigMap verbatim, without
  Helm's `tpl`, so `${VAR}` references and temporal-proxy's
  own `{{ }}` per-request templates pass through untouched
  and are expanded by the proxy itself.
- `service.port` sets the Service's port and, unless
  `config.hostPort` says otherwise, the gateway's listen
  address — one number for both.
- An upstream's `credentials.static.apiKey.secretKeyRef`
  adds the env var `TP_UPSTREAM_<NAME>_API_KEY` from that
  Secret and writes `${TP_UPSTREAM_<NAME>_API_KEY}` into the
  rendered config, so the key never sits in the ConfigMap.
  The chart wires this for upstreams, the gateway and
  `auth.staticToken` only, never for an extension server,
  whose CA and token reach the container through the
  chart's top-level `volumes`, `volumeMounts` and `envFrom`.
- The chart's default probes are `httpGet` on `/`. Helm
  merges maps, so a `grpc` probe has to set `httpGet: null`
  in the same block. Otherwise the rendered probe carries
  two handlers, which `helm template` prints without
  complaint and the API server rejects.
- The pod template carries no checksum of the ConfigMap, and
  the ConfigMap and the Secrets it reads have fixed names, so
  editing the configuration or rotating the API key leaves
  the template untouched and nothing rolls on its own.
  temporal-proxy reads both once, at startup, so the restart
  is `make apply`'s to issue.

**Why:** each of these turns a values file that looks
valid into a proxy that refuses to start, a Service nothing
can reach, or a pod serving a configuration that is not the
one on disk. The values file comments each key with the
rule it answers to; this note is where the rules are
sourced.

**How to access:** read the value tree with `helm show values
temporal-proxy --repo https://go.temporal.io/helm-charts
--version <pinned>`, and the chart's own README — its
config-supply model — from `helm pull --untar`. Render with
`helm template ... -f k8s/charts/temporal-proxy.yaml` and
read the output before applying it. See
[temporal-proxy upstream resources](reference_temporal-proxy-upstream.md).
