---
name: "Codec server candidate: loopback, port-forward, no auth"
description: "The candidate design for reading sealed payloads in the Cloud and self-hosted Web UIs: a loopback codec server reached by port-forward, with no auth"
type: project
---

# Codec server candidate: loopback, port-forward, no auth

The demo ships no codec server. temporal-proxy has one built
in (`codecServer`, from v0.8.0), and adding it is an open,
unscheduled candidate. Any version of it supports both the
Temporal Cloud Web UI and the self-hosted Web UI: one UI
alone does not qualify. The Web UI in `k8s/ui` reads through
temporal-proxy, sees cleartext, and needs no codec server.

The design that meets that requirement:

- the codec server binds `127.0.0.1:8081` inside the
  temporal-proxy pod, `insecure: true`, with no `auth`;
- a reader reaches it with `kubectl port-forward` on
  `127.0.0.1:<TRAEFIK_PORT+1>`, the next port in the band
  Casper reserves per workspace, from a foreground
  `make codec` that re-establishes the forward whenever
  temporal-proxy restarts;
- `cors.origins` lists `https://cloud.temporal.io` and the
  self-hosted UI's origin, whose Traefik port reaches the
  config as `${TRAEFIK_PORT}` from a ConfigMap `make apply`
  builds from the port read back from the cluster;
- the self-hosted UI is preconfigured with
  `--ui-codec-endpoint=http://localhost:$(CODEC_PORT)`; the
  Cloud UI takes the same address as its browser-level
  endpoint, never the Namespace-level one.

Decryption reads the Namespace recorded in the wrapped key
material, so the fully-qualified name the Cloud UI sends
needs no mapping and the KMS server is untouched.

**Why:** temporal-proxy refuses a codec server bound beyond
loopback without `auth`, and refuses `auth` there without
`tls`, because an open `/decode` is a decryption oracle.
Auth gains nothing here. The Cloud UI sends only its own
access token, which requires `jwks` against Temporal Cloud's
issuer and an `https` endpoint the browser trusts. The
self-hosted UI has no login, so it has no token to send.
Publishing the codec server through Traefik forces that same
non-loopback bind, and the Cloud UI, served over HTTPS,
cannot call a plain-HTTP `nip.io` host, though it can call
`http://localhost`. Inbound authentication also stays out of
the demo's scope.

**How to apply:** build the codec server only on this
loopback and port-forward design, and validate it in both
UIs before calling it done: the self-hosted one in a
browser, the Cloud one in a session the user is logged into.
Chrome may ask once for local network access from the Cloud
UI. See [Demo scope](project_demo-scope.md) and
[Per-worktree configuration lives on
disk](feedback_worktree-config-on-disk.md).
