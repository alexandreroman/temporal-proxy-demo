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
- `kubectl` and [Helm][helm] 3 — Traefik and temporal-proxy both come
  from their upstream charts, each pinned to an explicit version
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
plus `a1b2c`):

```bash
cp .env.example .env
```

Put the client certificate in `k8s/certs/` as `client.pem` and
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

| Namespace        | What it holds                                         |
| ---------------- | ----------------------------------------------------- |
| `traefik`        | Traefik and its Gateway, the cluster's only port      |
| `temporal-proxy` | temporal-proxy and the ConfigMap and Secrets it reads |
| `hello`          | The Worker and the API, with Service and route        |

Traefik's web entrypoint is the single published port, and the API is
the only route behind it. Everything else is reachable only from inside
the cluster, temporal-proxy included.

Traefik and temporal-proxy come from their upstream Helm charts, each
pinned to an explicit version, with the values this demo needs in
`k8s/charts/`. The Worker and the API come from the manifests under
`k8s/app`, applied with Kustomize.

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
rebuilding the image. The Secret keeps its name, so nothing in the pod
template changes and Kubernetes has no reason to roll the Deployment on
its own — which is why `apply` ends with a `kubectl rollout restart`.
That restart matters because temporal-proxy reads its certificate once,
at startup.

## What the application does not carry

The Worker and the API get two environment variables, and neither
describes an upstream:

| Variable             | Value                                |
| -------------------- | ------------------------------------ |
| `TEMPORAL_ADDRESS`   | `temporal-proxy.temporal-proxy:7233` |
| `TEMPORAL_NAMESPACE` | `demo`                               |

That is a cluster-local address, dialled in plaintext, and a short
Namespace name. Nothing else is needed because everything else lives in
temporal-proxy's configuration: the Cloud host name, the TLS material,
and the rewrite from `demo` to the fully-qualified Cloud Namespace.
`TEMPORAL_NAMESPACE` says which Namespace the application asks for, not
which upstream serves it — picking an upstream is not something the
application can do.

The short name is this application's own, which is why it is not
`default`: one temporal-proxy sits in front of several applications, so
the name each one asks for has to identify it. temporal-proxy owns the
mapping from that name to whatever the upstream calls the Namespace.

The same two variables also have fallbacks in the code
(`localhost:7233` and `default`) — the address and Namespace a
`temporal server start-dev` serves — so the binaries run unchanged
outside the cluster with nothing set. Those are local-development
values; in the cluster the Deployments supply the real ones, and `demo`
is the name that reaches temporal-proxy.

## Limits of this demo

- **The certificate comes from the working directory, not from a secret
  manager.** temporal-proxy mounts a Kubernetes Secret and reads two
  files from it; nothing in temporal-proxy can observe how that Secret
  was filled. A real deployment would have a secret manager fill it.
  Here `make` does, which is what makes the demo self-contained.
- **Nothing on the cluster reacts to a content change.** The ConfigMap
  and the Secrets keep fixed names, so a new configuration, a new
  certificate or a new account id leaves every pod template untouched.
  `make apply` therefore restarts temporal-proxy every time, rather
  than working out whether it has to.

## License

This project is licensed under the Apache-2.0 License — see
[LICENSE](LICENSE) for details.

temporal-proxy itself is a separate project, licensed under MIT.

[proxy]: https://github.com/temporalio/temporal-proxy
[kind]: https://kind.sigs.k8s.io
[helm]: https://helm.sh
[mtls]: https://docs.temporal.io/cloud/certificates
[tcld]: https://docs.temporal.io/cloud/tcld
