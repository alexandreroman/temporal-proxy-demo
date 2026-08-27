---
name: "temporal-proxy upstream resources"
description: "Where the temporal-proxy source, docs, examples, images and Helm chart live"
type: reference
---

# temporal-proxy upstream resources

temporal-proxy is a gRPC proxy that sits between
SDK Clients, Workers and the Web UI on one side
and one or more upstream Temporal Services on the
other. It is **pre-release** and evolving quickly.

- Source: <https://github.com/temporalio/temporal-proxy>
- Docs: <https://docs.temporal.io/production-deployment/temporal-proxy/>
- Go package: `github.com/temporalio/temporal-proxy/cmd/proxy`
- Container image: `temporalio/temporal-proxy` on Docker Hub
- Helm chart: `temporal-proxy` in <https://go.temporal.io/helm-charts>
- Worked examples in the upstream repo, under
  `examples/`: `cloud`, `kms`, `authz`

**Why:** the proxy's configuration schema is not
stable, so the upstream repository — not memory
and not older blog posts — is the authority on
what a valid config looks like.

**How to access:** read the upstream `README.md`
and the relevant `examples/<name>/` directory
before writing or changing proxy configuration,
and pin an explicit release rather than tracking
`latest`.
