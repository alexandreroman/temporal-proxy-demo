---
name: "Kustomize rewrites generated names within a namespace"
description: "A generator entry needs an explicit namespace, or references keep the un-hashed name and nothing says so"
type: reference
---

# Kustomize rewrites generated names within a namespace

`secretGenerator` and `configMapGenerator` append a hash of the
content to the object's name, and Kustomize rewrites the
references that point at it. It performs that rewrite only when
the referring object and the generated object are in the same
namespace, and a generated object carries no namespace unless one
is set on its generator entry:

```yaml
configMapGenerator:
  - name: temporal-proxy
    namespace: temporal-proxy
    files:
      - config.yaml
```

Without that line, a Deployment declaring
`namespace: temporal-proxy` keeps referring to the un-hashed name.
`kustomize build` succeeds, `kubectl apply` succeeds, and the pods
wait in `ContainerCreating` for objects that do not exist.

A blanket `namespace:` on the kustomization achieves the same
rewrite, but it stamps every resource in the build, which an
overlay spanning more than one namespace cannot accept.

**Why:** the failure is silent at every stage that could report
it, and the symptom appears on the cluster, far from the two lines
of YAML that cause it.

**How to apply:** set `namespace` on every generator entry, and
check a render for the hashed name in the *referring* object —
not only in the generated one — before applying it. See
[[feedback-scenario-switch]].
