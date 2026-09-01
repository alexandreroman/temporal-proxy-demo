---
name: "Verifying a page change means rendering the template"
description: "The page is embedded in the binary, so a temp render rather than the deployment is the fast loop, and which measurements are trustworthy at which viewport"
type: feedback
---

# Verifying a page change means rendering the template

`cmd/app/templates/index.html` is a Go template
embedded in the `app` binary, so the deployed page
answers with whatever the running image was built
from. Editing the file changes what a browser sees
only once the image is rebuilt and the Deployment
restarted.

The fast loop skips the cluster entirely:
substitute the template's actions — `.Address` and
`.Namespace` — into a copy outside the repository,
serve that copy over HTTP, and screenshot it. HTTP
rather than the file itself, because the browser
panel opens `http` and `https` and nothing else.

Judge the result against the cluster address,
`temporal-proxy.temporal-proxy:7233`, which is the
long value the captions have to survive. A short
dev-server address hides every truncation the
projected page would show.

Two measurement traps are worth knowing before
trusting a number:

- `casper browser screenshot --width --height`
  renders off-screen at exactly that viewport, so
  breakpoints are faithful. `casper browser eval`
  runs in the workspace panel instead, whose
  `innerWidth` reads `0` with `lg` inactive, so a
  measurement taken there is not the projection
  viewport unless it is taken inside a fixed-size
  iframe.
- `scrollHeight === clientHeight` does not mean a
  card's caption fits. With `overflow: visible`
  the value clamps, so content that spills reports
  nothing. Compare the caption's bottom rectangle
  against the card's instead.

**Why:** a page verified against the deployment is
verified against the previous build, and a page
verified in the panel is verified at a viewport
nobody presents at — both answer confidently and
wrongly. The projection budget is the only viewport
that settles a layout question, and reaching it
takes a deliberate render.

**How to apply:** render the template to a
throwaway copy and screenshot it at 1440x950 for
any change to the page's geometry, type or
spacing, and read the image back rather than
trusting the arithmetic. Rebuild the image only to
confirm the finished change end to end. See
[The demo page is read from the back of a
room](feedback_page-projection-legibility.md) for
the states to check, and
[The diagram is cards joined by static SVG
wires](project_diagram-is-cards-and-wires.md) for
the geometry that has to be re-derived together.
