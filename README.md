# Temporal Proxy Demo

Runs Temporal Workers that know nothing about the Temporal Service they
talk to. [temporal-proxy][proxy] sits in front of them and owns the
upstream address, TLS, the client certificate and the Namespace names,
so the Worker and the API carry no upstream connection, TLS, credential
or Namespace configuration of their own.

The whole demo runs on a local Kubernetes cluster: Traefik publishes the
API, and temporal-proxy is the only workload that knows where Temporal
is.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Prerequisites

- Docker — builds the image, and runs the cluster's nodes. Podman also
  works: export `KIND_EXPERIMENTAL_PROVIDER=podman` so `kind` uses it,
  and either put a `docker` shim on `PATH` or run `make` with
  `CONTAINER_TOOL=podman`
- [kind][kind] — the local Kubernetes cluster
- `kubectl` and [Helm][helm] 3.16+ — Traefik, cert-manager and
  temporal-proxy all come from their upstream charts, each pinned to an
  explicit version
- Go 1.27 or later — for `make worktree-init` and `make check`
- A Temporal Cloud Namespace whose accepted client CA signed the
  certificate in `k8s/certs/`

The image is built locally and loaded straight into the cluster's nodes,
so there is no registry and nothing to push.

### Generating the client certificate

Temporal Cloud authenticates temporal-proxy with mTLS, so it needs a
client certificate signed by a CA the Namespace accepts.
[`tcld`][tcld] generates both halves. Keep the CA outside this
repository — only the client pair belongs in `k8s/certs/`:

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
  --certificate-file k8s/certs/client.pem \
  --key-file k8s/certs/client.key
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

`k8s/certs/` is git-ignored apart from its `.gitkeep`, so the client
pair stays out of version control. `make` reads the two files from there
to build the Secret temporal-proxy mounts. See [Authenticate with mTLS
certificates][mtls] for the Cloud side.

## Quick start

Copy the environment template and fill in the two Temporal Cloud
values — the short Namespace name and the account id, the two halves of
a fully-qualified Cloud Namespace (`quickstart.a1b2c` is `quickstart`
plus `a1b2c`) — then generate the payload key's master secret:

```bash
cp .env.example .env
echo "KMS_MASTER_SECRET=$(openssl rand -base64 32)" >> .env
```

Put the client certificate in `k8s/certs/` as `client.pem` and
`client.key`, then bring the demo up and trigger a Workflow:

```bash
make worktree-init
make app-up
make demo
```

```json
{"greeting":"Hello, John Doe!","workflowId":"hello-x4t7…","runId":"01a0…"}
```

`make worktree-init` writes `k8s/kind-config.yaml`, which pins the one
host port this cluster publishes; `make app-up` creates the cluster,
installs everything in it and waits for the rollout. The answer takes
about two seconds — the Activity sleeps, so there is time to watch the
Execution in the Cloud Web UI. `make endpoints` prints the addresses,
and `make demo NAME=Alex` greets someone else.

The API also serves a page at the published address, which
`make endpoints` prints: one button starts an Execution, and the request
is drawn travelling through the stack. The page and `make demo` are two
ways into the same endpoint.

On a cluster that has just been created, Traefik loads a new route a
moment after the rollout finishes, so the very first `make demo` can
answer `503`. Run it again.

Run `make` to list every target. `make app-down` removes the Worker and
the API and leaves the cluster, Traefik, temporal-proxy and the KMS
server standing, so `make app-up` puts the demo back without rebuilding
any of that; `make cluster-down` deletes everything.

## What runs where

| Namespace        | What it holds                                          |
| ---------------- | ------------------------------------------------------ |
| `traefik`        | Traefik and its Gateway, the cluster's only port       |
| `temporal-proxy` | temporal-proxy and the KMS server, plus what they read |
| `hello`          | The Worker and the API, with Service and route         |

`make cluster-up` also creates a `cert-manager` and a
`secretgen-controller` namespace, for the two controllers that issue the
KMS server's certificate and generate its bearer token.

Traefik's web entrypoint is the single published port, and the API is
the only route behind it. Everything else is reachable only from inside
the cluster, temporal-proxy included.

Traefik, cert-manager and temporal-proxy come from their upstream Helm
charts, each pinned to an explicit version, with the values this demo
needs in `k8s/charts/`. The Worker and the API come from the manifests
under `k8s/app`, applied with Kustomize.

## How the certificate travels

The certificate never appears in a manifest. `make apply` reads it from
the working directory and builds the Secret the chart mounts:

```text
k8s/certs/client.pem + client.key
  → Secret temporal-cloud-client (keys tls.crt and tls.key)
  → the upstream's tls.secretName in k8s/charts/temporal-proxy.yaml
  → mounted by the chart at /etc/temporal-proxy/certs/upstream-cloud
  → the cert and key paths in the rendered configuration
```

Rotation is two steps: replace the two files and run `make apply`, the
narrower target that deploys temporal-proxy and the application without
rebuilding the image. It ends by restarting temporal-proxy, which reads
its certificate only at startup.

## How the payload key travels

Nothing seals a payload with a key from a file. temporal-proxy generates
a data encryption key, seals payloads with it, and asks the KMS server
to wrap that key:

```text
KMS_MASTER_SECRET in .env
  → Secret kms-master-secret
  → the KMS server, which derives one AES-256-GCM key per Namespace
  → wraps each data encryption key temporal-proxy sends it
  → the wrapped key travels inside the sealed payload
```

The KMS server derives its key from the short Namespace name the
application asked for — `demo` — never the fully-qualified Cloud name.
Its certificate comes from cert-manager, and the token temporal-proxy
presents to it comes from secretgen-controller — both generated inside
the cluster, so neither one appears in any file.

Turning encryption off is one flag, `encryption.enabled`, plus
`make apply`. Payloads sealed earlier stay readable, which is why the
flag rather than the whole block is what turns encryption off.

## What the application does not carry

The Worker and the API each get the same two environment variables, and
neither describes an upstream:

| Variable             | Value                                |
| -------------------- | ------------------------------------ |
| `TEMPORAL_ADDRESS`   | `temporal-proxy.temporal-proxy:7233` |
| `TEMPORAL_NAMESPACE` | `demo`                               |

Those two are a cluster-local address, dialled in plaintext, and a short
Namespace name. Nothing else is needed because everything else lives in
temporal-proxy's configuration: the Cloud host name, the TLS material,
and the rewrite from `demo` to the fully-qualified Cloud Namespace.
`TEMPORAL_NAMESPACE` says which Namespace the application asks for, not
which upstream serves it — picking an upstream is not something the
application can do.

The page renders those same two values and names no upstream at all —
naming one is precisely what the application cannot do.

The short name is `demo` rather than `default` because one
temporal-proxy fronts several applications, so the name each one asks
for has to identify it. Both variables also have fallbacks in the code —
`localhost:7233` and `default`, what a `temporal server start-dev`
serves — so the binaries run unchanged outside the cluster.

## Limit of this demo

Both secrets come from the working directory rather than from a secret
manager — the client certificate from `k8s/certs/`, the master secret
from `.env` — and nothing rotates either one. Losing the master secret
loses every payload ever sealed under it. `make` filling those Secrets
is what makes the demo self-contained; a real deployment would have a
secret manager fill them. The KMS server derives its keys rather than
fronting an HSM or a key service: it shows the shape of the contract,
not a key manager.

Payloads reach Temporal Cloud sealed, so the Cloud Web UI shows workflow
inputs and results as `binary/encrypted`. Making them readable there
needs a codec server, which temporal-proxy does not provide and which
would have to be reachable from the browser over HTTPS — out of reach of
a local cluster without a tunnel.

## License

This project is licensed under the Apache-2.0 License — see
[LICENSE](LICENSE) for details.

temporal-proxy itself is a separate project, licensed under MIT.

[proxy]: https://github.com/temporalio/temporal-proxy
[kind]: https://kind.sigs.k8s.io
[helm]: https://helm.sh
[mtls]: https://docs.temporal.io/cloud/certificates
[tcld]: https://docs.temporal.io/cloud/tcld
