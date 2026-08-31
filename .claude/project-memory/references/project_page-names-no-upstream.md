---
name: "The page names no upstream"
description: "The destination station reads Temporal, and the page shows only the endpoint and Namespace the application dials"
type: project
---

# The page names no upstream

The page `cmd/app` serves names no upstream. Its
destination station reads `Temporal` and nothing
more: no vendor, no host, no environment. The two
endpoint stations show the address and the short
Namespace name the application dials, resolved
through the same code path the Temporal client
dials with, so the page reports the pair that was
actually used and cannot drift from the deployment
it runs in.

The three stations that run in the cluster carry a
Kubernetes mark. The destination station does not:
it is the upstream, outside the cluster, and the
mark is what draws that line.

**Why:** the application has no way to observe
which upstream serves its endpoint — that is the
demo's whole claim. A page that named the
destination would be asserting knowledge the code
does not have, and the rail already says where that
knowledge stops. Showing the dialled endpoint
instead proves the claim rather than describing it:
what is on screen is everything the application
knows.

**How to apply:** keep the destination generic in
the template, and derive anything the page says
about where it connects from the client's own
resolved endpoint rather than from a second source.
A deep link into a specific upstream's web UI would
require the application to carry that upstream's
fully-qualified Namespace, which is a change to the
demo's central claim and not a page detail — see
[[feedback-agnostic-app-code]].
