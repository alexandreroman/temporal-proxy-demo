---
name: "The pulse durations are declared once, in the parse-time stylesheet"
description: "Where the diagram's two pulse durations live, and why they sit outside the Tailwind-compiled stylesheet"
type: project
---

# The pulse durations are declared once, in the parse-time stylesheet

The diagram's two pulse durations are declared once, as
`--rail-out-ms` (200ms) and `--rail-back-ms` (170ms) on
`.rail` in `cmd/app/templates/index.html`. The CSS
animations consume them through `var()`, and the script
that paces a walk with `sleep()` reads them back off the
`.rail` element. One declaration answers to both, so the
pulse crossing a wire and the pause timing it cannot
drift apart.

They are declared in the page's plain `<style>` block in
`<head>`, which the browser applies as it parses, rather
than beside the animations in the
`<style type="text/tailwindcss">` block. The trailing
script reads them with `getComputedStyle`, and only the
parse-time stylesheet is guaranteed to be applied by
then: a read that reached the element before Tailwind's
asynchronously compiled stylesheet did would yield `NaN`
and collapse every pulse to zero, with the walk still
stepping through its stations in silence.

**Why:** the two numbers govern one behaviour in two
languages, and prose asking a maintainer to keep them
in step is what a single declaration makes unnecessary.
Placing that declaration where the animations are would
read as tidier and would put the read-back in a race it
loses silently — the diagram degrades rather than
breaking, so nothing reports it.

**How to apply:** change a duration in the `.rail` rule
in the parse-time stylesheet, and leave the `var()`
consumers and the script alone. Keep custom properties
the script reads out of the Tailwind-compiled block. See
[What the diagram's motion means](project_diagram-motion-language.md)
and
[The diagram is cards joined by static SVG
wires](project_diagram-is-cards-and-wires.md).
