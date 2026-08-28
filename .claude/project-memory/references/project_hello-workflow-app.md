---
name: "Shape of the hello-workflow demo app"
description: "Why the demo is triggered over HTTP, split across two binaries, and why its Activity sleeps"
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
- **Two binaries, `cmd/worker` and `cmd/app`.**
  Worker-side and Client-side traffic reach the
  proxy separately and can be pointed at different
  upstreams independently.
- **The Activity sleeps two seconds.** Long enough
  to watch the Execution move through the Temporal
  Web UI while the HTTP call is still in flight.

**Why:** the demo has to be legible while it runs,
not only after it finishes, and the split makes the
proxy's per-Namespace routing visible on both sides
of the wire.

**How to apply:** keep the Activity's duration
perceptible, keep the endpoint the only trigger,
and add new scenarios by changing proxy
configuration rather than the Go code.
