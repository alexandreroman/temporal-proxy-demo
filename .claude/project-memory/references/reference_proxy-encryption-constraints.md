---
name: "temporal-proxy encryption constraints"
description: "What governs a Vault Transit-backed encryption scenario, verified against the temporal-proxy source"
type: reference
---

# temporal-proxy encryption constraints

Six facts govern an `encryption` scenario built on Vault's
Transit engine, none of them visible from the Helm values
alone:

- `crypto.DefaultSchemes()` returns `awskms`,
  `azurekeyvault`, `gcpkms` and `testing`. Vault Transit is
  not one of them, so it reaches temporal-proxy only
  through an extension server implementing
  `api.kms.v1.EncryptionService`.
- `ext.KMS` (`Wrap`/`Unwrap`) and `crypto.KEK`
  (`Encrypt`/`Decrypt` plus `ID()` and `Close()`) are the
  same pair of operations, so one Transit-backed type
  serves as both the extension server and a codec server's
  key.
- A `crypto.KEKRegistry` selects its decryption key by
  `ID()`. A key whose `ID()` returns the same identifier
  temporal-proxy recorded in a payload's
  `encryption-key-id` metadata resolves with no
  `KeyFactory` and no scheme registration.
- `Decrypt` receives only the ciphertext, with no
  namespace and no context, so `Wrap` has to frame the key
  identifier into the ciphertext it returns.
- `internal/config/extensions.go` requires TLS to an
  extension server only when credentials are set on it, so
  an in-cluster extension server may run in plaintext.
- The Temporal Cloud Web UI calls a codec server from the
  browser over HTTPS, and the response needs
  `Access-Control-Allow-Origin: https://cloud.temporal.io`,
  `Access-Control-Allow-Methods: POST, GET, OPTIONS` and
  `Access-Control-Allow-Headers: X-Namespace, Content-Type`.

**Why:** these constraints decide the shape of the
`encryption` scenario before a line of it is built — one
shared service rather than two, a plaintext extension
server, and an HTTPS-only codec server with a fixed CORS
policy. Deriving them from the Helm chart or from memory
risks a design that cannot start, or a Web UI that cannot
call it.

**How to access:** at temporal-proxy's pinned release tag,
read `pkg/crypto/keys.go` and its test for
`DefaultSchemes`, `pkg/ext/kms.go` for the `ext.KMS`
interface, `pkg/crypto` for `crypto.KEK` and
`crypto.KEKRegistry`, and `internal/config/extensions.go`
for the TLS rule. See
[[reference-temporal-proxy-upstream]] and
[[project-demo-scope]].
