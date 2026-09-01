---
name: "A typographic accent on the page is presentational"
description: "Weight, colour and gradient accents inside a heading or a sentence use a <span>; <strong> is reserved for text that carries more meaning"
type: feedback
---

# A typographic accent on the page is presentational

On the page `cmd/app` serves, a word set apart by
weight, colour or a gradient — the bold `Demo` in
the headline, for instance — is wrapped in a
`<span>` carrying the utility that styles it.
`<strong>` and `<b>` are reserved for text that
genuinely carries more meaning than its
neighbours, such as the component name in the
intro paragraph.

An inline child inside a `.title-sweep` heading
inherits `color: transparent` and declares no
background of its own, so the heading's
`background-clip: text` gradient keeps painting
through the child's glyphs. A child that sets its
own colour or background is what breaks the sweep.

**Why:** a screen reader announces `<strong>` as
emphasis. A word that is only heavier for the eye
must not be louder for the ear, and the page's
headline styles two halves of one title rather
than ranking them.

**How to apply:** ask what the markup claims
before choosing the element. Styling only — a
`<span>`. A real difference in importance —
`<strong>`. Inside a gradient-clipped heading,
give the child a weight or a size, never a colour
or a background.
