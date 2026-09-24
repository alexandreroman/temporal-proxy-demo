---
name: "Shape of the hello-workflow demo app"
description: "Why the demo is triggered over HTTP, split across two application binaries, and why its Activity sleeps"
type: project
---

# Shape of the hello-workflow demo app

The demo application is called **hello-workflow**:
one Workflow, one Activity returning a greeting
message, and an HTTP endpoint that triggers an
Execution. `make demo` is a `curl` on that
endpoint.

Three choices shape it:

- **HTTP trigger rather than a CLI starter.** The
  entry point is a running service, so the demo
  looks like an application rather than a script.
- **Two application binaries, `cmd/worker` and
  `cmd/app`.** A Worker and a Client are separate
  roles in Temporal, so each runs as its own process,
  deployed and scaled on its own, as a real
  application would. Both ask for the same Namespace,
  so they always reach the same upstream.
- **The Activity sleeps two seconds.** Long enough
  to watch the Execution move through the Temporal
  Web UI while the HTTP call is still in flight.

**Why:** the demo has to be legible while it runs,
not only after it finishes, and it has to look like
an application a team would deploy rather than a
single process doing both jobs.

**How to apply:** keep the Activity's duration
perceptible, keep the endpoint the only trigger,
and change what the demo shows by changing
temporal-proxy's configuration rather than the Go
code.
