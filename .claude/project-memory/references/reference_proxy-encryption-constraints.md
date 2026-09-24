---
name: "temporal-proxy encryption constraints"
description: "What governs payload encryption through temporal-proxy, verified against the temporal-proxy source"
type: reference
---

# temporal-proxy encryption constraints

Ten facts govern payload encryption whose keys come
from a KMS temporal-proxy does not implement natively,
none of them visible from a configuration file alone:

- `crypto.DefaultSchemes()` returns `awskms`,
  `azurekeyvault`, `gcpkms` and `testing`. A KMS outside
  that list — Vault Transit, for instance — reaches
  temporal-proxy only through an extension server
  implementing `api.kms.v1.EncryptionService`.
- `ext.KMS.Wrap` receives the Namespace, but `Unwrap`
  receives only the ciphertext, with no Namespace and no
  context. Whatever identifies the key has to travel
  inside what `Wrap` returns, which makes that output a
  durable format.
- `pkg/ext` supplies that format, `api.ext.v1.KeyMaterial`,
  so an extension server writes no framing of its own.
  `ext.NewKeyWrapper` serves a server that holds key
  bytes: it takes a `KeyLookup`, seals with AES-256-GCM by
  default, and authenticates the Namespace, the key
  version and the cipher as AEAD additional data, so
  relabelled material fails to open. The lookup reports
  the version rather than being told it, so a store that
  rotates keeps old material readable, and an unversioned
  store ignores the field.
- `ext.NewSealWrapper` serves a key service that never
  hands over key bytes — an HSM, a cloud KMS. Its
  `KeySealer` calls out to that service, and the wrapper
  frames the result and seals nothing itself, so binding
  the clear fields is the implementation's job, through
  `ext.BindingContext` passed as an encryption context.
- `internal/config/extensions.go` rejects credentials sent
  over an insecure connection, so an extension server that
  authenticates the proxy is dialled over TLS. A plaintext
  in-cluster extension server is the one that carries no
  credentials, and it declares `insecure: true` to get
  there.
- `internal/dataplane/dataplane.go` reads
  `cfg.Encryption.Enabled` as one top-level boolean, and
  `KeyPolicy` carries no `enabled` field of its own —
  `encryption.overrides` selects which key seals a
  Namespace's payloads, never whether they are sealed, so
  per-request selectivity is not expressible.
- The same file gates only sealing on `Enabled`; a vault is
  built whenever `encryption.default` names a key. A proxy
  configured with a key but `enabled: false` stops sealing
  new payloads while everything sealed under that key stays
  readable.
- `Encryption.CacheSize` is a `*int`, so the config
  distinguishes an operator who wrote nothing from one who
  wrote zero. `Encryption.DEKCacheSize()` answers an absent
  field with `crypto.DefaultCacheSize` (100) and a written
  `0` with no cache at all, which is what makes disabling
  the DEK cache something spelled out rather than inherited.
- The temporal-proxy Helm chart's `_helpers.tpl` wires TLS
  Secrets and rewrites `secretKeyRef` credentials for the
  gateway, the upstreams, and `auth.staticToken` — never for
  an extension server. Its CA and API key reach the
  container through the chart's own top-level `volumes`,
  `volumeMounts` and `env` values instead.
- `pkg/crypto/dek.go` fixes the payload cipher: a 256-bit
  key, `cipher.NewGCM`, and a random nonce prefixed to the
  ciphertext. An extension server's `Wrap`/`Unwrap` pair
  carries opaque bytes, never inspected by temporal-proxy,
  so it chooses only how the DEK is wrapped — never the
  cipher that seals the payload itself.

**Why:** these constraints decide the shape of an
encryption setup before a line of it is built: whether a
KMS needs an extension server at all, how much
cryptography that server writes itself, whether an
in-cluster extension server can skip TLS, and what
turning sealing off leaves readable. Deriving them from
the Helm chart or from memory risks a design that cannot
start.

**How to access:** at temporal-proxy's pinned release tag,
read `pkg/crypto/keys.go` and its test for
`DefaultSchemes`, `pkg/ext/kms.go` for the `ext.KMS`
interface, `pkg/ext/doc.go`, `pkg/ext/keywrap.go` and
`pkg/ext/sealwrap.go` for the two wrappers and the
`KeyMaterial` framing, `internal/config/extensions.go` for
the credentials rule, `internal/dataplane/dataplane.go` for
the `Enabled` gate and the always-on vault,
`internal/config/encryption.go` for `DEKCacheSize`,
`pkg/crypto/dek.go` for the fixed cipher, and the
temporal-proxy chart's `_helpers.tpl`
(`go.temporal.io/helm-charts`) for what it wires and what
it leaves to `env`/`volumes`/`volumeMounts`. See
[temporal-proxy upstream resources](reference_temporal-proxy-upstream.md),
[Transport security is stated, not
inferred](reference_proxy-transport-security.md)
and [Demo scope](project_demo-scope.md).
