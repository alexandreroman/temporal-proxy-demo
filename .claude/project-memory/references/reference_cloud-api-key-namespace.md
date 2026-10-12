---
name: "The Cloud Namespace accepts API keys only"
description: "The demo's Cloud Namespace uses auth method ApiKey with a Namespace-scoped service account key; a both-methods Namespace and the regional endpoint each fail the Web UI"
type: reference
---

# The Cloud Namespace accepts API keys only

The demo's Temporal Cloud Namespace is dedicated to it and
uses API key authentication only (auth method `ApiKey`; its
short name is `TEMPORAL_CLOUD_NAMESPACE`). temporal-proxy dials its
Namespace endpoint, `<ns>.<account>.tmprl.cloud:7233`, with
the key. That endpoint identifies the Namespace by host name,
and temporal-proxy recognizes it as Cloud from the
`.tmprl.cloud` suffix alone.

Two other setups look valid and fail:

- **A Namespace that allows both API keys and mTLS**
  (`ApiKeyOrMtls`). Its Namespace endpoint refuses the TLS
  handshake without a client certificate, and Temporal's
  Namespaces page states that API keys cannot authenticate
  through it.
- **The regional endpoint** (`regionalGrpc`, such as
  `ca-central-1.aws.api.temporal.io:7233`). It accepts the
  key but routes by the `temporal-namespace` gRPC header.
  The SDK sets that header, but the Web UI server never
  does. temporal-proxy rewrites the header only when it is
  present, so every namespaced call from the UI gets
  `PermissionDenied`, "Request unauthorized".

The key belongs to a Namespace-scoped Service Account with
`Write` on that Namespace; README.md gives the `tcld` recipe.
`CloudService.GetNamespaces` answers such a key with its one
Namespace, so the Web UI's Namespaces page lists only `demo`.
A user's key lists every Namespace the user can see, because
neither temporal-proxy nor the Web UI filters that list.

A Temporal Cloud API key is a long token that starts with
`eyJ`. A 32-character value is the key's identifier, not its
secret, and Cloud answers it with `unauthenticated`.

**Why:** both failures name something other than the cause:
an mTLS handshake error when the auth method is already set,
and an authorization error when the key is valid. The Worker
and the CLI pass on the regional endpoint, so only the
Web UI shows the problem.

**How to access:** test a key from the host with
`temporal workflow count --address <ns>.<account>.tmprl.cloud:7233
--namespace <ns>.<account> --api-key "$TEMPORAL_CLOUD_API_KEY"`,
and read the auth method with `tcld namespace get`. The
header rewrite is `rewriteNamespaceHeader` in temporal-proxy's
`internal/proxy/translation.go`. See
<https://docs.temporal.io/cloud/namespaces> and [A standalone
Web UI reads through
temporal-proxy](project_web-ui-through-proxy.md).
