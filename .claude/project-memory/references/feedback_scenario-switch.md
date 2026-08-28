---
name: "Switching upstreams is a proxy-config change"
description: "A scenario is a Kustomize overlay plus one temporal-proxy Helm values file, selected by SCENARIO"
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

A scenario is a directory under `k8s/scenarios/`: a
Kustomize overlay and one temporal-proxy Helm values file,
`proxy-values.yaml`. `make deploy SCENARIO=<name>` selects
it, defaulting to `credentials`. Reading two values files
side by side, or diffing them, is the teaching material:
what differs between scenarios is how Vault backs
temporal-proxy, and nothing else does.

A scenario whose credentials are absent is refused before
`make deploy` touches the cluster, because temporal-proxy
crash-loops on a configuration it cannot parse, with the
reason buried in its pod's log.

**Why:** the demo's whole claim is that upstream choice
and Vault's role are deployment configuration rather than
application code. A Helm values file is deployment; a
switch that touched a Go file or rebuilt the Worker or the
API would disprove the claim on stage.

**How to apply:** add a scenario as a new directory under
`k8s/scenarios/<name>/`, with a `kustomization.yaml` and a
`proxy-values.yaml` decalqued from `credentials`, keeping
everything outside the Vault-specific blocks unchanged
where the scenario allows it. Anything a scenario needs
beyond temporal-proxy — a credential, an account id —
reaches it as an environment variable or a mounted Secret
and never reaches the application. See
[[project-demo-scope]].
