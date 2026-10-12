---
name: "Application code stays endpoint-agnostic"
description: "The Go code never names a proxy — it only knows a local Temporal endpoint"
type: feedback
---

# Application code stays endpoint-agnostic

CLAUDE.md states the rule: the Go code dials a local
endpoint in plaintext with a short Namespace name, and
never names what backs it. The rule covers vocabulary
as well as configuration — "proxy", "upstream",
"gateway" and "the proxy handles X" all presuppose
the thing the code is meant to be ignorant of. This
note spells those words out so the check below has
something to match.

Stating what is deliberately **absent** from the
client options is welcome — no TLS material, no
credentials, no fully-qualified Namespace — as long
as it does not name who supplies it. The
`internal/temporalclient` package doc says it once
for both binaries.

The prohibition binds the Go source, not the
deployment configuration or the process's own
output. `internal/temporalclient` logs the address
it dials, read from the `TEMPORAL_ADDRESS`
environment variable, and in the cluster that value
is `temporal-proxy.temporal-proxy:7233` — so the
string `temporal-proxy` appears in the Worker's and
the API's own log line. That is not a violation: the
log statement names an environment variable and
echoes whatever value it holds, carrying no proxy
vocabulary of its own. Deployment manifests are free
to name the component; the Go source is the one
place that stays silent about it.

**Why:** the same binaries must run unchanged
whatever temporal-proxy is configured to do. A
comment naming a proxy is
a claim about the deployment, and it is exactly the
claim the demo exists to disprove.

**How to apply:** review new Go code in the packages
this rule covers:

```sh
grep -rniE "proxy|gateway|upstream" --include='*.go' \
  cmd/worker cmd/app internal/hello \
  internal/temporalclient internal/kms
```

Checked by hand — `make check` runs `go test` and
`go vet`, not this grep. Only an import path carrying
the repository name is expected to match: the module
path is `github.com/alexandreroman/temporal-proxy-demo`,
so any file importing one of its own packages carries
the substring "proxy", and nothing else should.
`cmd/kms` sits outside that scope: it implements
`api.kms.v1.EncryptionService`, an interface
temporal-proxy defines, so the name there names the
interface it implements, not the endpoint it serves.
`internal/kms` stays inside the rule despite sharing
a name with that neighbour — it is pure cryptography
and names nothing about its caller. See
[Demo scope](project_demo-scope.md).
