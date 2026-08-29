---
name: "Switching upstreams is a proxy-config change"
description: "A scenario is a Kustomize overlay plus one temporal-proxy configuration file, selected by SCENARIO"
type: feedback
---

# Switching upstreams is a proxy-config change

Moving the whole demo from one upstream to another is a
change to temporal-proxy's configuration and nothing else.
The application keeps dialling the same local endpoint in
plaintext with the same short Namespace name, `default`,
in every scenario; the upstream's own name for that
Namespace is a translation rule temporal-proxy owns. No Go
file and no rebuild.

A scenario is a directory under `k8s/scenarios/`, holding a
`kustomization.yaml` and a `config.yaml`, temporal-proxy's
own configuration file verbatim. `make deploy
SCENARIO=<name>` selects it, defaulting to `credentials`.
Diffing two `config.yaml` files is the teaching material:
what differs between scenarios is how temporal-proxy is
configured, and nothing else does.

Deploying a scenario restarts every component: the
ConfigMap's name carries a hash of `config.yaml`, so a
scenario switch changes temporal-proxy's pod template and
Kubernetes rolls it; `kubectl rollout restart` recreates
the Worker and the API, whose image tag is fixed. Nothing
keeps polling an upstream a scenario switch leaves behind.

A scenario whose credentials are absent is refused before
temporal-proxy is applied, because temporal-proxy
crash-loops on a configuration it cannot parse, with the
reason buried in its pod's log.

**Why:** a configuration file is deployment; a switch that
touched a Go file would disprove the claim on stage.

**How to apply:** add a scenario as a new directory with a
`kustomization.yaml` and a `config.yaml` copied from
`credentials`. Anything a scenario needs beyond
temporal-proxy — a credential, an account id — reaches it
as an environment variable or a mounted Secret and never
reaches the application. See [[project-demo-scope]].
