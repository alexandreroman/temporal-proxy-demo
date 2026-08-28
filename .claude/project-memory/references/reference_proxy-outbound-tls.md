---
name: "Outbound TLS rules for a temporal-proxy upstream"
description: "Why an upstream with a client certificate also needs a ca, and what that ca actually verifies"
type: reference
---

# Outbound TLS rules for a temporal-proxy upstream

Three rules govern an upstream's `tls` block, and
none of them is visible from the config structs
alone:

- An upstream that sets `cert` and `key` must also
  set `ca`. The proxy refuses to start otherwise:
  `ca: certificate authority is required when a
  client certificate is set`.
- That `ca` is the trust anchor for verifying **the
  upstream's own server certificate**. It is not
  related to the authority that signed `cert`.
- The file **replaces** the default roots rather
  than extending them, because the pool is built
  fresh from that file alone.

An upstream whose server certificate is publicly
signed — Temporal Cloud among them — therefore
takes a public bundle as its `ca`. The proxy
container image carries one at
`/etc/ssl/certs/ca-certificates.crt`.

**Why:** the option builder adds `ca` only when it
is non-empty, so reading it suggests the field is
optional. The requirement lives in a validator in
another package, and the replace-not-extend
behaviour is visible only in the pool loader.
Deriving the rules from the wrong file yields a
configuration temporal-proxy refuses to start on,
or one that cannot verify a public upstream.

**How to access:** at the pinned release tag, read
`internal/transport/creds/options.go`
(`validateClient`),
`internal/transport/creds/material.go`
(`loadCAPool`), and
`internal/transport/creds/dialer.go`, where the
pool becomes `tls.Config.RootCAs`. See
[[reference-temporal-proxy-upstream]] and
[[feedback-scenario-switch]].
