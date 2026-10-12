---
name: "A rollout overlaps only where traffic arrives"
description: "The API Deployment holds its outgoing pod until the replacement serves; the Worker needs no such guarantee"
type: feedback
---

# A rollout overlaps only where traffic arrives

A restart of the API overlaps its outgoing and incoming
pods, and `k8s/app/deployment-app.yaml` carries no
`strategy` block to get there. For a single replica the
RollingUpdate defaults already give the overlap:
`maxUnavailable` of 25% rounds down to 0 and `maxSurge` of
25% rounds up to 1, so the replacement is Ready, and in the
EndpointSlice, before the outgoing pod is touched. The one
thing the manifest adds is a `preStop` sleep on the `app`
container, so the outgoing pod keeps answering while
Traefik still holds its address.

`k8s/app/deployment-worker.yaml` carries no `preStop`. The Worker
takes no inbound traffic, and a gap in its availability only
delays a Workflow Task, which the demo waits for anyway.

**Why:** `make app-up` ends by restarting `deploy/app` and
`make demo` curls it straight after. With one replica behind
the cluster's only route, a pod that stops before Traefik's
view of it catches up blackholes the request, so Traefik
times out with a 504 rather than failing fast.

On a freshly created cluster one window stays open that the
overlap cannot close: Traefik applies provider changes at
most once per `providersThrottleDuration`, two seconds by
default, so it can take that long to pick up the new pod.
`app-up` does not poll the published route to hide it — the
README tells the reader to retry instead, which keeps the
recipe on a slide.

**How to apply:** give a workload an overlapping rollout when
it serves inbound traffic through the Gateway, and leave it
out otherwise. A readiness probe is not enough on its own —
it proves the pod can serve, not that the ingress has caught
up. See
[Manifests state only what differs from the
default](feedback_manifests-omit-defaults.md).
