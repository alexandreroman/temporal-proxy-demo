---
name: "A rollout overlaps only where traffic arrives"
description: "The API Deployment holds its outgoing pod until the replacement serves; the Worker needs no such guarantee"
type: feedback
---

# A rollout overlaps only where traffic arrives

`k8s/app/deployment-app.yaml` carries
`strategy.rollingUpdate.maxUnavailable: 0` and a `preStop`
sleep on the `app` container. Together they make a restart
overlap: the replacement is Ready, and in the EndpointSlice,
before the outgoing pod is touched, and the outgoing pod
keeps answering while Traefik still holds its address.
`strategy.type` and `maxSurge` stay absent — both are API
defaults, and the default surge is the one extra pod a
single replica needs.

`k8s/app/deployment-worker.yaml` carries neither. The Worker
takes no inbound traffic, and a gap in its availability only
delays a Workflow Task, which the demo waits for anyway.

**Why:** `make app-up` ends by restarting `deploy/app` and
`make demo` curls it straight after. With one replica behind
the cluster's only route, a pod that stops before Traefik's
view of it catches up blackholes the request, so Traefik
times out with a 504 rather than failing fast.

A cluster created from nothing keeps one window the overlap
cannot close: Traefik loads a route only after its
`providersThrottleDuration`, two seconds by default, so the
first `make demo` after a cold `make app-up` can answer 503.
`app-up` does not poll the published route to hide it — the
README tells the reader to run the command again, which keeps
the recipe on a slide.

**How to apply:** give a workload an overlapping rollout when
it serves inbound traffic through the Gateway, and leave it
out otherwise. A readiness probe is not enough on its own —
it proves the pod can serve, not that the ingress has caught
up. See
[Manifests omit defaults](feedback_manifests-omit-defaults.md).
