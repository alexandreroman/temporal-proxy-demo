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
chart's `appVersion` trails the published image.

Five of the chart's behaviours decide what a values file has
to say:

- `config` is copied into the ConfigMap verbatim, without
  Helm's `tpl`, so `${VAR}` references and temporal-proxy's
  own `{{ }}` per-request templates pass through untouched
  and are expanded by the proxy itself.
- `service.port` sets the Service's port and, unless
  `config.hostPort` says otherwise, the gateway's listen
  address — one number for both.
- An upstream's `tls.secretName` mounts that Secret at
  `/etc/temporal-proxy/certs/upstream-<name>` and writes
  `cert` and `key` into the rendered config, from the keys
  `tls.crt` and `tls.key`. `ca` is written only from a
  `caKey`, and an explicit `ca` survives alongside
  `secretName` — which is how an upstream takes its client
  pair from a Secret and its trust anchor from a file the
  image already carries.
- The chart's default probes are `httpGet` on `/`. Helm
  merges maps, so a `grpc` probe has to set `httpGet: null`
  in the same block. Otherwise the rendered probe carries
  two handlers, which `helm template` prints without
  complaint and the API server rejects.
- The pod template carries no checksum of the ConfigMap, and
  the ConfigMap and the mounted Secrets have fixed names, so
  editing a configuration or replacing a certificate leaves
  the template untouched and nothing rolls on its own.
  temporal-proxy reads both once, at startup, so the restart
  is `make apply`'s to issue.

**Why:** the first four turn a values file that looks valid
into a proxy that refuses to start or a Service nothing can
reach; the last one leaves a pod serving a configuration
that is not the one on disk.

**How to access:** read the value tree with `helm show values
temporal-proxy --repo https://go.temporal.io/helm-charts
--version <pinned>`, and the chart's own README — its
config-supply model — from `helm pull --untar`. Render with
`helm template ... -f k8s/charts/temporal-proxy.yaml` and
read the output before applying it. See
[temporal-proxy upstream resources](reference_temporal-proxy-upstream.md) and
[Outbound TLS rules](reference_proxy-outbound-tls.md).
