---
name: "The deployment names the target, the application displays it"
description: "TEMPORAL_TARGET is an opaque display label the Go code renders and never interprets"
type: feedback
---

# The deployment names the target, the application displays it

The page the API serves shows where Workflow
Executions land, and it learns that from
`TEMPORAL_TARGET` in its environment. The Go code
treats the value as an opaque string: it reads it,
renders it, and compares it to nothing. An unset
variable stays empty and the template renders a
neutral fallback, because "the deployment said
nothing" is a different fact from any particular
scenario.

This is the single word the application carries
about where it connects, and it holds to the
endpoint-agnostic rule because it is a label
rather than knowledge: the value arrives from
outside and nothing branches on it. See
[[feedback-agnostic-app-code]].

The label is deployment configuration: the API's
Deployment manifest sets it in the container's
environment, and a binary run outside the cluster
has it unset, which the page renders as an unnamed
destination. It reaches the API alone, the one
workload that serves the page.

**Why:** the application has no way to observe
which upstream serves its endpoint — that is the
demo's whole claim. A page that names the target
while the code stays ignorant of it shows the
separation rather than describing it.

**How to apply:** pass the label in from the
deployment, keep the Go side to reading and
rendering it, and put the fallback in the template
rather than a default in Go. The page is free to
recognise the value and draw the matching branch —
that is presentation. The Go code is not: nothing
there compares the label to anything.
