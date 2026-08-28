---
name: "The demo page is read from the back of a room"
description: "The 1440x950 projection budget, and the three brightness levels the rail carries"
type: feedback
---

# The demo page is read from the back of a room

The page `cmd/app` serves is presented on a
projector at roughly 1440×950. At that viewport the
rail and the top of the result panel are visible
together, without scrolling, in every state
including a finished run — the audience watches the
rail exactly when it moves.

Vertical room comes from spacing and from the
horizontal room the header leaves unused: from `lg`
the control row sits beside the header rather than
under it, and below `lg` the blocks stay stacked in
reading order. Display type is never shrunk to make
something fit; legibility from the back row outranks
any layout convenience.

The rail carries three brightness levels, and the
distance between them is what makes it readable at
a distance:

- **idle** — hairline grey, nothing has travelled.
- **travelling** — the accent at full strength,
  with the halo and the pulse, following the request.
- **finished** — the same accents mixed down, a
  quiet record of the path the request took.

A failed request leaves the rail unlit: a half-done
round trip must not read like a success.

**Why:** every accessory on the page competes with
the one thing the audience is meant to watch. A
marker, a caption or a gap that costs vertical room
or clutters the rail costs more than it earns, and
the annotations on the rail are out of flow so that
they can never displace its geometry.

**How to apply:** measure a change at 1440×950
before calling it done, in the idle, running,
finished and failed states. Keep the three
brightness levels distinguishable, and keep
`prefers-reduced-motion` free of travel and glow
while every state change still lands.
