---
name: "A readiness probe for a Temporal Service names the WorkflowService"
description: "Why a bare gRPC health probe reports Ready from process start on a Temporal frontend, and which service name to ask for instead"
type: reference
---

# A readiness probe for a Temporal Service names the WorkflowService

A bare `grpc` probe asks the health service for the empty
service name. grpc-go's health server initialises that name
to `SERVING` when it is constructed, and Temporal server
sets a status only for the services it registers by name.
On a Temporal frontend a bare probe therefore answers
`SERVING` from process start, before the frontend's own
health interceptor stops rejecting WorkflowService calls —
it proves the process is listening, not that it can serve.

`k8s/temporal/deployment.yaml` names the service the cluster
actually dials:

```yaml
readinessProbe:
  grpc:
    port: 7233
    service: temporal.api.workflowservice.v1.WorkflowService
```

That name is registered and answers `SERVING` once the
frontend can serve. An unregistered name answers
`NOT_FOUND`, which Kubernetes counts as a probe failure, so
a typo fails closed.

The bare probe in `k8s/charts/temporal-proxy.yaml` is right
for the opposite reason: temporal-proxy has no warm-up
behind its listener, so a bound socket and a servable
gateway are the same moment. The two probes differ because
the workloads differ, not by oversight.

**Why:** a probe that passes early makes
`kubectl rollout status` return before the Service can
answer, and the failure lands on whatever runs next rather
than on the probe. Nothing about a bare `grpc:` block hints
that the empty name is pre-set.

**How to access:** confirm a name is registered by asking
the running image directly —
`grpcurl -plaintext -d '{"service":"<name>"}' <host>:7233
grpc.health.v1.Health/Check`. The initialisation is in
grpc-go's `health/server.go` (`NewServer`), and the
interceptor is Temporal server's
`common/rpc/interceptor/health.go`. See
[Two upstreams, and the one word that selects between
them](project_two-upstreams-one-word.md) and
[temporal-proxy's Helm chart](reference_proxy-helm-chart.md).
