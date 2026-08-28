# Temporal Proxy Demo

Runs Temporal Workers that know nothing about the Temporal Service they
talk to. [temporal-proxy][proxy] sits in front of them and owns the
upstream address, TLS, the client certificate and the Namespace names,
so the Worker and the API carry no upstream connection, TLS, credential
or Namespace configuration of their own.

The whole demo runs on a local Kubernetes cluster: Traefik publishes the
API, Vault holds the Temporal Cloud client certificate, and
temporal-proxy is the only workload that knows where Temporal is.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Prerequisites

- Docker — builds the image, and runs the cluster's nodes. Podman also
  works: export `KIND_EXPERIMENTAL_PROVIDER=podman` so `kind` uses it,
  and either put a `docker` shim on `PATH` or run `make` with
  `CONTAINER_TOOL=podman`
- [kind][kind] — the local Kubernetes cluster
- `kubectl` and [Helm][helm] 3.13 or later — `helm uninstall
  --ignore-not-found` needs it
- Go 1.27 or later — for `make worktree-init` and `make check`
- A Temporal Cloud Namespace whose accepted client CA signed the
  certificate in `proxy/certs/`

The image is built locally and loaded straight into the cluster's nodes,
so there is no registry and nothing to push.

### Generating the client certificate

Temporal Cloud authenticates temporal-proxy with mTLS, so it needs a
client certificate signed by a CA the Namespace accepts.
[`tcld`][tcld] generates both halves. Keep the CA outside this
repository — only the client pair belongs in `proxy/certs/`:

```bash
tcld generate-certificates certificate-authority-certificate \
  --organization "my-org" \
  --validity-period 365d \
  --ca-certificate-file ca.pem \
  --ca-key-file ca.key

tcld generate-certificates end-entity-certificate \
  --organization "my-org" \
  --ca-certificate-file ca.pem \
  --ca-key-file ca.key \
  --certificate-file proxy/certs/client.pem \
  --key-file proxy/certs/client.key
```

Then register the CA on the Namespace, so Cloud accepts certificates it
signed. `--namespace` takes the fully-qualified name, and the command
talks to Cloud, so authenticate first:

```bash
tcld login
tcld namespace accepted-client-ca add \
  --namespace "quickstart.a1b2c" \
  --ca-certificate-file ca.pem
```

`proxy/certs/` is git-ignored apart from its `.gitkeep`, so the client
pair stays out of version control. See
[Authenticate with mTLS certificates][mtls] for the Cloud side.

## Quick start

Copy the environment template and fill in the two Temporal Cloud
values — the short Namespace name and the account id, the two halves of
a fully-qualified Cloud Namespace (`quickstart.a1b2c` is `quickstart`
plus `a1b2c`):

```bash
cp .env.example .env
```

Put the client certificate in `proxy/certs/` as `client.pem` and
`client.key`, then bring the demo up and trigger a Workflow:

```bash
make worktree-init
make deploy
make demo
```

```json
{"greeting":"Hello, Temporal!"}
```

`make worktree-init` writes `k8s/kind-config.yaml`, which pins the one
host port this cluster publishes; `make deploy` creates the cluster,
installs everything in it and waits for the rollout. The answer takes
about two seconds — the Activity sleeps, so there is time to watch the
Execution in the Cloud Web UI. `make endpoints` prints the addresses,
and `make demo NAME=Alex` greets someone else.

Run `make` to list every target, and `make cluster-down` to delete the
cluster.

## What runs where

| Namespace                | What it holds                                    |
| ------------------------ | ------------------------------------------------ |
| `traefik`                | Traefik and its Gateway, the cluster's only port |
| `vault`                  | Vault, custodian of the client certificate       |
| `vault-secrets-operator` | The Vault Secrets Operator                       |
| `temporal-proxy`         | temporal-proxy and the Secret it mounts          |
| `hello`                  | The Worker and the API, with Service and route   |

Traefik's web entrypoint is the single published port, and the API is
the only route behind it. Everything else is reachable only from inside
the cluster, temporal-proxy included.

## How the certificate travels

The certificate never appears in a manifest. It travels from the working
directory to temporal-proxy's mount, one hop at a time:

```text
proxy/certs/client.pem + client.key
  → make vault-cert
  → Vault KV: secret/temporal-cloud (keys tls.crt and tls.key)
  → VaultStaticSecret (temporal-cloud-client)
  → Secret temporal-cloud-client, type kubernetes.io/tls
  → temporal-proxy's TLS mount
```

`make vault-cert` streams both files into the Vault pod and writes them
to the KV path. From there the Vault Secrets Operator does the rest: the
`VaultStaticSecret` under `k8s/base/vault-secrets/` reads that path and
creates the Secret, and temporal-proxy's values name that Secret. The KV
keys are already `tls.crt` and `tls.key`, which is exactly what a
`kubernetes.io/tls` Secret requires, so nothing has to be transformed on
the way.

temporal-proxy reads its certificate once, at startup. A rotation in
Vault therefore only takes effect when the pod restarts, which is what
`rolloutRestartTargets` on the `VaultStaticSecret` is for: the operator
restarts the Deployment itself when the Secret's content changes.

## What the application does not carry

The Worker and the API get two environment variables, and neither
describes an upstream:

| Variable             | Value                                |
| -------------------- | ------------------------------------ |
| `TEMPORAL_ADDRESS`   | `temporal-proxy.temporal-proxy:7233` |
| `TEMPORAL_NAMESPACE` | `default`                            |

That is a cluster-local address, dialled in plaintext, and a short
Namespace name. Nothing else is needed because everything else lives in
temporal-proxy's configuration: the Cloud host name, the TLS material,
and the rewrite from `default` to the fully-qualified Cloud Namespace.
`TEMPORAL_NAMESPACE` says which Namespace the application asks for, not
which upstream serves it — picking an upstream is not something the
application can do.

The same two variables also have defaults in the code
(`localhost:7233` and `default`), so the binaries run unchanged outside
the cluster against anything that speaks the Temporal gRPC API on a
local port.

## Scenarios

A scenario is one directory under `k8s/scenarios/`: a Kustomize overlay
and one temporal-proxy values file.

```text
k8s/scenarios/<name>/kustomization.yaml   # the workloads
k8s/scenarios/<name>/proxy-values.yaml    # temporal-proxy's Helm values
```

Deploy one by name:

```bash
make deploy SCENARIO=<name>
```

`credentials` is the default and the only scenario shipped today: one
upstream, Temporal Cloud, reached with a client certificate that came
from Vault. Everything a scenario changes is in those two files — no Go
code and no image rebuild.

## Limits of this demo

- **Vault is the custodian of the certificate, not its origin.**
  `make vault-cert` pushes this repository's own certificate into
  Vault. A real deployment would have Vault issue the material, or
  receive it from whatever does; here the push is what makes the demo
  self-contained.
- **Vault runs in dev mode: in-memory, unsealed, one known root
  token.** Restarting it loses the certificate. The configuration
  returns on its own through the chart's postStart hook, and
  `make vault-cert` reloads the certificate.

## License

This project is licensed under the Apache-2.0 License — see
[LICENSE](LICENSE) for details.

temporal-proxy itself is a separate project, licensed under MIT.

[proxy]: https://github.com/temporalio/temporal-proxy
[kind]: https://kind.sigs.k8s.io
[helm]: https://helm.sh
[mtls]: https://docs.temporal.io/cloud/certificates
[tcld]: https://docs.temporal.io/cloud/tcld
