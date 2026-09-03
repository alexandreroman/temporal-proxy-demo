---
name: "The rail is grouped by persona"
description: "Three groups naming the role that answers for each component, the upstream that belongs to none, the unlabelled boundaries, the lengths sized for the groups' overhang, and what the pointer reveals"
type: project
---

# The rail is grouped by persona

The diagram groups its components by the person who
answers for them. Three dashed boxes, each carrying a
chip on its top-left border with a Lucide icon and the
role's name:

- **developer** — the application and the Worker.
- **platform operator** — temporal-proxy.
- **security operator** — the key service.

**The upstream card belongs to no group.** No role in
the org owns it, and that absence is what draws the
line the diagram exists to draw: everything inside a
dashed box is somebody's to run, and the thing beyond
them is not.

Two identical dashed boundaries cut the rail into
three bands, one before the endpoint and one before
the upstream. **Neither carries a label.** The chips
already say who owns what, and a legend under the rail
costs vertical room in the one budget that has none to
spare.

## A group contains its cards

A group is the cards' parent, not a layer over them,
and the reason is the pointer. A layer that takes
pointer events swallows whatever is under it; a layer
that does not cannot answer to `:hover` at all.
Containment settles both: the highlight is a plain CSS
rule, and nothing sits over a card.

Because a `<li>` cannot hold a `<li>`, each group
holds its chip, its note, then a `<ul>` of its
stations. The group whose two cards straddle both rows
lays them out with `space-between` over the full
height, so the grid's own row gap is what separates
them and no gutter length is written twice.

**A group costs the grid nothing.** It is stretched
into its cells and pulled back out by a negative
margin that cancels its padding *and its border* —
`calc(-1rem - 1px)`, not `-1rem`, or two pixels of
border stay in the count and the cards no longer land
on the rows. Its content box then equals the cell
exactly.

## What the overhang costs

A group overhangs its cards by 17px: 1rem of padding
and the 1px of its own stroke. Four lengths answer to
that number and move together — change it and
re-derive them all:

- the scroll band's inline padding, which is the same
  17px, because `overflow-x: auto` makes only
  *trailing* overflow scrollable: a leading pixel is
  clipped, and the leading pixel here is the border
  itself;
- the column the client wires cross, 72px, which
  carries an overhang on each side of its boundary and
  leaves 19px of air either way;
- the upstream column, 62px, with an overhang on one
  side only — the upstream card is bare — so its
  boundary sits 14px from the group and 31px from the
  card;
- the row gap, 48px, which two groups overhang from
  opposite sides, leaving 14px between their borders.

**The row gap is a floor, not comfort**, and the link
to the key service crosses both borders in it.

The card width is declared once, as a custom property
on the rail, and read by both the column that holds a
card and the card itself — so the width that bounds
caption truncation cannot drift from the column it
sets.

## What the pointer reveals

Hovering a group brightens its border and its chip,
and raises a bubble that follows the cursor, carrying
the role's name with its icon and a sentence on what
that role holds and what it never sees.

**The hover answers on a neutral axis** — the ink,
never an accent. A run paints the cards violet or
mint, and a highlight reaching for either would read
as traffic.

**The border closes to a solid stroke**, which is what
carries from the back of a room. A dash is the
vocabulary every annotation on the rail is drawn in,
the two boundaries included, so a brighter dash is
still one of the family; a hovered group is the band's
only unbroken stroke apart from the cards themselves.
Only the colour transitions — `border-style` does not
interpolate, so listing it beside the colour would
suggest a smoothness that cannot exist.

**It is a pointer affordance only.** No group is
focusable and none is in the tab order: this is a tool
for whoever drives the demo. The prose is still
reachable to a screen reader, because it lives once in
the group as visually-hidden text and the bubble reads
it off the element — the same move that keeps a second
copy of any string out of the markup. The name and the
icon reference are read off the group's own chip for
the same reason.

**No connector takes the pointer either.** An `<svg>`
box swallows events across the whole of its column,
including the strip a neighbouring group overhangs
into it, which would leave that strip the one part of
a group deaf to its own hover. Nothing in a connector
is clickable — its wires are hidden from assistive
technology and the boundary it hosts is an annotation
— so one rule covers all three.

The bubble is `position: fixed`, outside the scroll
band so its overflow cannot clip it, and it never
takes the pointer, or it would settle under the cursor
and flicker. Its box is declared rather than measured:
the stylesheet sets the width, the script reads the
same number back, and both axes flip against the
viewport with no call into layout.

**The caption items carry no `title`.** A native
tooltip and this one fire on the same pointer over the
same place and cover each other, and the room a
projector shows cannot hover anything anyway — which
is already why an item worth reading has to fit rather
than lean on a fallback.

**Why:** the demo's claim is that no one person needs
to hold all of this. Naming the three roles makes that
claim visible before a word of the page is read;
leaving the upstream outside every box stops the claim
from becoming a diagram of the deployment; and the
bubble is where the argument gets said out loud
without costing the rail a line of vertical room.

**How to apply:** add a component to the group of
whoever answers for it, or to none if nobody in the
org does. Keep the boundaries unlabelled. Before
changing the overhang, re-derive the four lengths
above together, and check the result at 1440×950 — see
[Verifying a page change means rendering the
template](feedback_verifying-a-page-change.md) and
[The diagram is cards joined by static SVG
wires](project_diagram-is-cards-and-wires.md).
