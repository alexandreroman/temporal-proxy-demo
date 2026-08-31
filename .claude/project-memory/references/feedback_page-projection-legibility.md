---
name: "The demo page is read from the back of a room"
description: "The 1440x950 projection budget, the type scale's floor, and the three brightness levels the rail carries"
type: feedback
---

# The demo page is read from the back of a room

The page `cmd/app` serves is presented on a
projector at roughly 1440×950. At that viewport the
rail and the top of the result panel are visible
together, without scrolling, in every state
including a finished run — the audience watches the
rail exactly when it moves. The result panel holds
one fixed height from `lg` up, sized to its tallest
state, so the page's total height does not depend
on which state is showing.

Vertical room comes from spacing and from the
horizontal room the layout leaves unused: the
headline spans the full content width on its own
line, and from `lg` the intro and the control row
sit side by side beneath it. The panel keeps a
minimum height below `lg` rather than a fixed one,
so text that wraps further has somewhere to go.

The diagram always flows left to right and never
stacks into a reading-order list. Narrower than its
content, it scrolls horizontally from the left, by
hand — a run does not move it. Below the width where
all the components fit, the parts that leave the
viewport first are the upstream hop and the component
beyond it, which is where the return journey happens.

The type scale is compressed at the top and floored
at the bottom. Display sizes carry legibility
headroom a projector never needs, so the top of the
scale is where it gives. The floor holds: the
station captions at `text-xs` and the caliper label
at `0.7rem` are the smallest text on the page and
the first thing to fail from the back row. Every
size relationship remains an ordering at both
breakpoints.

The diagram carries three brightness levels on its
component cards — a card border is a far larger
target than a dot, which is what makes them readable
at a distance. Component names stay white throughout:
colour says what a thing is, geometry says what is
happening.

The wires carry those same three levels plus a fourth
above them, for the pulse travelling along one.

The levels are:

- **idle** — hairline grey, nothing has travelled.
- **travelling** — the accent at full strength,
  with the halo and the pulse, following the request.
- **finished** — the same accents mixed down, a
  quiet record of the path the request took.

A failed request leaves the diagram unlit — every
border and stroke back to the idle hairline. Those
three lit levels plus the unlit failure are four states
to check, not three: a half-done round trip must not
read like a success.

**Why:** every accessory on the page competes with
the one thing the audience is meant to watch. A
marker, a caption or a gap that costs vertical room
or clutters the rail costs more than it earns, and
the annotations on the rail are out of flow so that
they can never displace its geometry. Legibility
from the back row outranks any layout convenience,
which is why the scale gives at the display end and
never at the floor.

**How to apply:** measure a change at 1440×950
before calling it done, in the idle, running,
finished and failed states. When something has to
fit, take the room from the large end of the scale,
from spacing, or from width — never from the floor.
Keep the three brightness levels distinguishable,
and keep `prefers-reduced-motion` free of travel
and glow while every state change still lands.
