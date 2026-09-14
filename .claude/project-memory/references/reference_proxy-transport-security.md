---
name: "Transport security is stated, not inferred"
description: "Why every address temporal-proxy dials defaults to TLS, and what a plaintext one has to write down"
type: reference
---

# Transport security is stated, not inferred

`ListenConfig` in `internal/config/listen.go` backs every address in a
temporal-proxy configuration — the gateway's own listener, each upstream,
and each extension server — and it reads differently by direction:

- **Anything the proxy dials defaults to TLS.** An upstream or an
  extension server with no `tls` block is dialled over TLS and verified
  against the system root pool. Silence asks for TLS.
- **Plaintext is a field.** `insecure: true` is the only way to dial a
  cleartext endpoint, so an in-cluster frontend that serves no TLS has to
  say so on the upstream that names it.
- **`insecure` and `tls` are mutually exclusive.**
  `ListenConfig.insecureRule` rejects a target carrying both, because the
  two state opposite intents and honouring either silently would leave an
  operator believing the other.
- **A listener stays plaintext until a `tls` block gives it a
  certificate.** A listener has nothing to present, so it has no TLS
  default, and the gateway serves cleartext without a field of its own.

**Why:** an upstream silent about its transport is the failure this shape
produces. It passes validation, the proxy starts cleanly, and the error
surfaces only when the first request reaches a frontend that answers no
TLS handshake — far from the configuration that caused it. Reading an
absent `tls` block as plaintext yields a proxy that cannot reach its own
upstream.

**How to access:** at the pinned release tag, read
`internal/config/listen.go` for `ListenConfig.Insecure`, `Dialer` and
`Listener`, then `internal/config/upstream.go` and
`internal/config/extensions.go` for the `insecureRule` each applies and
for the credentials rule that rides on it. See
[temporal-proxy upstream resources](reference_temporal-proxy-upstream.md),
[Outbound TLS rules](reference_proxy-outbound-tls.md),
[temporal-proxy encryption
constraints](reference_proxy-encryption-constraints.md)
and [Two upstreams](project_two-upstreams-one-word.md).
