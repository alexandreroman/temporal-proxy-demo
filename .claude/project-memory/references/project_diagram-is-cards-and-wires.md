---
name: "The diagram is cards joined by static SVG wires"
description: "Fixed-size component cards, hard-coded wire geometry, and the sizing rule that the dev-server loop cannot show"
type: project
---

# The diagram is cards joined by static SVG wires

The page's diagram draws the real topology: the API and
the Worker are both clients of temporal-proxy, which
alone reaches Temporal. Each component is a fixed-size
card with a hairline border, and the connections are
SVG wires — two disjoint diagonals converging on the
proxy, and one horizontal hop upstream that carries the
"the application's knowledge ends here" annotation.

The wire geometry is hard-coded, not measured: a
`viewBox` and literal path coordinates describe each
connector, surviving scrolling, font loading and
reduced motion without a single
`getBoundingClientRect`.

The horizontal hop flexes between a floor and whatever
the band leaves, so the diagram fills the content width
where there is room and its edges sit flush with the
result panel's; below that the hop reaches its floor
and the band scrolls. The diagonals do **not** flex,
and the reason is worth keeping: stretching a
`viewBox` on one axis either thickens their stroke, or,
with `vector-effect: non-scaling-stroke` to prevent
that, breaks the dash — a device-space dash stops
honouring `pathLength`, so the pulse never completes
its wire. A horizontal wire has neither problem,
because an x-only stretch cannot touch a stroke width
measured in y.

A connector's SVG must be taken out of flow. In flow, a
`viewBox` carries its own aspect ratio, so a flexing
column makes the SVG demand a matching height and the
diagram's rows size to that instead of to the cards.

**A caption item is truncated, never wrapped.** Each
one holds a single line and ends in an ellipsis when it
does not fit, because the cards share a fixed height
that a second line box would break. The full text stays
in the DOM, so nothing is lost to assistive technology
— but a projector cannot hover a truncated value, so an
item worth reading has to fit.

The card's width therefore comes from the longest item
that must stay whole, which is a prose caption rather
than the endpoint address. Watch the interaction with
the lockup card: its wider mark column makes the same
string need more room there than on an icon card, so
the binding measurement may not be on the card you
expect. Include the borders in that arithmetic.

The endpoint captions render `TEMPORAL_ADDRESS`, short
against a dev server and a long cluster DNS name in
Kubernetes — the only place the page is projected. So
judge truncation against the cluster value, never the
one on screen during development. A three-item caption
sets the height.

One card carries a different indent, derived from its
own artwork: where a name row is a logo lockup rather
than an icon beside text, the caption aligns to where
the lockup's lettering starts, not to the shared
column, because the mark that precedes the lettering
sets the artwork's edge.

One constraint is not obvious from the code: the
scroll band's `overflow-y` cannot stay `visible` beside
`overflow-x: auto`, so the band needs padding of its
own or it clips the cards' halos.

**Why:** the diagram is the demo's argument, so it has
to be true before it is attractive; and it is watched on
a projector while it animates, which is the worst
possible place for geometry that depends on measuring a
live layout.

**How to apply:** change a card's size and re-derive the
connector viewBoxes and the column sum together. Test a
caption change against the cluster address, not the
dev-server one. See
[The demo page is read from the back of a
room](feedback_page-projection-legibility.md).
