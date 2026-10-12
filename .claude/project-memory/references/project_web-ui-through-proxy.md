---
name: "A standalone Web UI reads through temporal-proxy"
description: "k8s/ui runs temporalio/ui against temporal-proxy, so it follows routing.default and shows cleartext; Cloud requires the API key"
type: project
---

# A standalone Web UI reads through temporal-proxy

`k8s/ui` runs the open-source Web UI server, `temporalio/ui`,
with temporal-proxy as its only Temporal frontend. It reads
from whichever upstream `routing.default` selects, and it
shows payloads in cleartext, because temporal-proxy opens
them on every response. It is a third UI beside the Temporal
Cloud UI and the self-hosted Service's embedded one, and
both of those show ciphertext.

On a Cloud upstream, temporal-proxy answers the calls the
Cloud frontend refuses on its own. It translates
`ListNamespaces`, `ListSearchAttributes` and the Nexus
endpoint reads onto the Cloud Ops API, and it replies to
`GetClusterInfo` itself. The Cloud Ops API accepts an API key
only, never mTLS. The Cloud upstream's own API key covers it,
inherited with no `apiTranslations` block, and that is why
Temporal Cloud is reached with an API key.

**Why:** with mTLS and no key, both translated calls fail
with gRPC `Unauthenticated`, which the UI server turns into
HTTP 401. The UI reads a 401 on search attributes as an
expired session and redirects to `/login`, which is a 404
when auth is off. The Workflow list and history still load
through the API, but the page is unusable. Routing
Namespace-less calls to another upstream does not help,
because `ListSearchAttributes` carries the Namespace.

**How to apply:** treat the UI as a decryption viewer. It
shows what temporal-proxy decrypts, so it stays on the
machine running the cluster. Verify a change to it in a
browser on a Workflow page, including a Query sent from the
page: curl on `/api/v1` passes where the page redirects, and
curl carries no CSRF cookie to lose. The source is temporal-proxy's
`internal/cloud/translation/doc.go` and
`internal/config/cloudapi.go` at the pinned tag. See [A codec
server serves both Web UIs from
loopback](project_codec-server-design.md) and [Demo
scope](project_demo-scope.md).
