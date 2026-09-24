---
name: "An end-to-end test drives the page in a browser"
description: "E2E means running a Workflow from the demo page in a browser on a live cluster; curl and make demo are not enough"
type: feedback
---

# An end-to-end test drives the page in a browser

An end-to-end test of this demo is a Workflow started from the
demo page in a real browser, against a cluster brought up with
`make app-up`. It loads the page, submits the form, waits for
the greeting to render, and reads the console for errors.
`make demo`, a `curl` of the API or a `curl` of the page are
supporting checks, not the end-to-end test.

**Why:** the page is what the audience sees, and the page loads
Tailwind and Alpine.js from a CDN at pinned versions. A broken
page with a healthy API passes every command-line check.

**How to apply:** after `make app-up`, open
`http://hello.127-0-0-1.nip.io:<port>/` in the browser panel
(the port is the `hostPort:` in `k8s/kind-config.yaml`). Run a
Workflow from the form and confirm the greeting, the Workflow
ID and the duration render with an empty console. Then take an
off-screen screenshot at 1440x950, the page's projection
budget: the panel's own viewport is narrower and clips the
diagram's right-hand card. See
[The demo page is read from the back of a
room](feedback_page-projection-legibility.md).
