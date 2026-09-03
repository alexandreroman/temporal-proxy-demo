---
name: "The diagram is cards joined by static SVG wires"
description: "The five component cards, hard-coded wire geometry, the two landing points on the endpoint, the one column that flexes, and the sizing rules the dev-server loop cannot show"
type: project
---

# The diagram is cards joined by static SVG wires

The page's diagram draws the real topology: the API
and the Worker are both clients of temporal-proxy,
which alone reaches anything past itself — Temporal
upstream, and the key service holding the key its
payloads are sealed with. Each component is a card
with a hairline border, and the connections are SVG
wires.

The grid is two rows and five columns: the two
clients stacked on the left, temporal-proxy and the
key service stacked in the middle, the upstream alone
on the top right. The cell below the upstream card is
empty.

The wire geometry is hard-coded, not measured: a
`viewBox` and literal path coordinates describe each
connector, surviving scrolling, font loading and
reduced motion without a single
`getBoundingClientRect`.

**Only the upstream hop flexes.** Its column stretches
between a floor and whatever the band leaves, so the
diagram fills the content width where there is room
and its edges sit flush with the result panel's; below
that the column reaches its floor and the band
scrolls. That hop survives the stretch because it is
horizontal: an x-only stretch cannot touch a stroke
width measured in y. Why no other wire flexes is worth
keeping: stretching a `viewBox` on one axis either
thickens a slanted stroke, or, with
`vector-effect: non-scaling-stroke` to prevent that,
breaks the dash — a device-space dash stops honouring
`pathLength`, so the pulse never completes its wire.

**The two client wires land at two distinct points on
the endpoint's left edge.** Both finish horizontal, so
a shared landing point puts them on top of each other
over their last stretch, and a lit wire has to say
whose traffic is on it. The application's wire meets
the row centre; the Worker's arrives well below it,
still inside the card.

**The Worker's wire is a cubic Bézier, horizontal at
both ends.** Its card sits a row below the endpoint's,
and a straight line across that rise reads as a corner
between two cards rather than as a run — the same
threshold that keeps a slant below 45°. Horizontal
tangents make it read as a run at any rise, and
`pathLength` normalises a curve exactly as it does a
line, so the pulse needs nothing from it.

**The link to the key service is a short vertical
segment in the row gutter.** Its connector spans both
rows of the endpoint's column and carries nothing but
that segment. Like every other connector it is out of
flow, so it costs the grid no size and the two cards
it passes between are what set the rows.

That segment is pushed as far right as the two edges
it meets allow, and what stops it is the cards' corner
radius rather than their width: a card's edge stops
being straight where the arc begins, so the wire's
outer edge has to land inside that. Its position is
derived from the right edge inwards — the corner
radius, the same again as margin, and the wire's own
half-stroke. Clearing the persona chip, which starts
at the group's left border, follows from that rather
than deciding it; a wire on the column's axis would
land exactly where the chip's text ends and read as a
wire leaving the label.

A connector's SVG must be taken out of flow. In flow,
a `viewBox` carries its own aspect ratio, so a flexing
column makes the SVG demand a matching height and the
diagram's rows size to that instead of to the cards.

**Every card shares one fixed size**, 19.5rem by 8rem.
The width is declared once, as a custom property on
the rail, and read by both the column that holds a
card and the card itself, so the two cannot disagree.
It is derived rather than chosen: the
34-character cluster address sets 244.8px at
`text-xs` in Noto Sans Mono, and the card's 1rem of
padding either side plus its 1.6rem mark column leave
254.4px — 9.6px of slack. The ellipsis guards an
address longer than that one; it is not part of what a
deployment shows. A prose caption can bind before the
address does, so measure the longest item that must
stay whole against the width, and watch the
interaction with the lockup card: its wider mark
column makes the same string need more room there than
on an icon card, so the binding measurement may not be
on the card you expect. Include the borders in that
arithmetic, and re-derive it together with the
connector columns, which answer to the persona boxes'
overhang — see [The rail is grouped by
persona](project_rail-grouped-by-persona.md).

The client cards render `TEMPORAL_ADDRESS`, short
against a dev server and a long cluster DNS name in
Kubernetes — the only place the page is projected. So
judge truncation against the cluster value, never the
one on screen during development.

**A caption item is truncated, never wrapped.** Each
one holds a single line and ends in an ellipsis when
it does not fit, because the cards share a fixed
height that a second line box would break. The full
text stays in the DOM, so nothing is lost to assistive
technology — but a projector cannot hover a truncated
value, so an item worth reading has to fit. A
three-item caption sets the shared height; a station
with fewer leaves that room unused.

One card carries a different indent, derived from its
own artwork: where a name row is a logo lockup rather
than an icon beside text, the caption aligns to where
the lockup's lettering starts, not to the shared
column, because the mark that precedes the lettering
sets the artwork's edge.

One constraint is not obvious from the code: the
scroll band's `overflow-y` cannot stay `visible`
beside `overflow-x: auto`, so the band needs padding
of its own on both axes or it clips what hangs outside
the rows — the cards' halos, the persona boxes' own
borders, and above the rail the chip that carries a
persona's name.

**Why:** the diagram is the demo's argument, so it has
to be true before it is attractive; and it is watched
on a projector while it animates, which is the worst
possible place for geometry that depends on measuring
a live layout.

**How to apply:** change a card's size and re-derive
the connector viewBoxes and the column sum together.
Test a caption change against the cluster address, not
the dev-server one. See [The demo page is read from
the back of a
room](feedback_page-projection-legibility.md).
