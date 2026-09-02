---
name: "CI runs the quality gate only"
description: "The GitHub Actions workflow runs make check, and neither the container image nor the cluster belongs in it"
type: feedback
---

# CI runs the quality gate only

The GitHub Actions workflow runs `make check` and nothing
else: no container image build, no Kind cluster, and no
linter that target does not already run.

**Why:** the image is built to be loaded into a local Kind
cluster, and standing that cluster up needs Temporal Cloud
credentials and a client certificate CI does not have.
Calling `make check` rather than spelling out its commands
keeps the local gate and CI from drifting apart.

**How to apply:** add a new check to the `check` target
first, and the workflow picks it up for free. Keep
`go test` and `go vet` out of the workflow file itself.
