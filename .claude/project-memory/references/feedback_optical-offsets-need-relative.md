---
name: "Optical offsets on the rail's wordmark"
description: "vertical-align cannot move the lockup's wordmark: the box sets the line box, so use position: relative and top"
type: feedback
---

# Optical offsets on the rail's wordmark

`.rail-logo` carries two offsets and each does one job.
`vertical-align` is the honest baseline derivation, the wordmark's
own descent of 12.67/44 x its height, and it seats the lettering on
the text baseline. Any further optical correction goes on
`position: relative` with `top`.

**Why:** the logo box is taller than the row's strut, so the box
itself sets the line box. In the card's flex column the row's top
edge is pinned, so a line box that grows upward pushes the baseline
down by the same amount: whatever `vertical-align` lifts, the
baseline gives straight back, and the wordmark does not move
relative to the neighbouring card. A relative offset paints the box
away from its position without entering the line-box calculation,
so it moves the wordmark and nothing else.

**How to apply:** when the wordmark reads wrong against a
neighbouring card's mono name, verify in a browser which of the two
offsets is at fault. Baseline error belongs to `vertical-align`.
Cap-band error — the wordmark's caps are shorter than the mono's, so
baseline-aligned lettering reads low — belongs to `top`. Measure the
cap tops, not the baselines, before and after, and confirm the row
height is unchanged.
