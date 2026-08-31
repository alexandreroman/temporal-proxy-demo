---
name: "The Workflow's contract and the API's response are two different types"
description: "Why execution identifiers live in a cmd/app envelope and never in hello.Response"
type: feedback
---

# The Workflow's contract and the API's response are two different types

`hello.Response` is what the Workflow returns. It
carries the greeting and nothing else, and it is
shared between the HTTP layer and Temporal
payloads.

What `POST /hello` answers is a wider shape: the
greeting plus the identifiers of the Execution
that produced it, `workflowId` and `runId`. That
envelope lives in `cmd/app` and embeds
`hello.Response`, so a field added to the
Workflow's contract reaches the wire on its own
rather than being copied by hand.

The identifiers stay out of `hello.Response`
because a Workflow does not return its own Run ID
— they belong to the Execution, not to its
result. `internal/hello` describes what the
Workflow computes; `cmd/app` describes what the
API answers.

How long a request took is not on the wire. The
caller brackets its own call and has as good a
claim to that number as the server, so the page
times its own round trip.

**Why:** the two shapes drift apart as soon as the
API grows anything the Workflow has no notion of.
Merging them puts Execution metadata inside a
Temporal payload, where it is both wrong and
invisible until someone reads a history.

**How to apply:** add anything the API reports
about an Execution to the envelope in `cmd/app`.
Add to `hello.Response` only what the Workflow
itself computes.
