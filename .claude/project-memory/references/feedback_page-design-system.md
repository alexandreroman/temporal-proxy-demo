---
name: "The demo page borrows temporal.io's own design system"
description: "Where the page's palette, typefaces, logo assets and background vocabulary come from, and which colour is barred from text"
type: feedback
---

# The demo page borrows temporal.io's own design system

The page `cmd/app` serves takes its visual
language from temporal.io rather than inventing
one. The colours in its `@theme` block are read
off temporal.io's live stylesheet, so they are
findable again: fetch the site, extract the hex
values, and rank them by frequency. `#141414` is
the background and `#B664FF` the dominant accent;
`#444CE7`, `#1FF1A5` and `#FF6BFF` follow.

Typography splits by availability. temporal.io
sets its text in **Aeonik**, which is licensed and
cannot be served from a public CDN, so the page
uses **General Sans** in its place — a geometric
grotesque of the same temperature, whose display
weight sits closest to Aeonik's width and colour,
served from Fontshare. Its mono is **Noto Sans
Mono**, which is not a substitute for anything:
temporal.io ships that exact face, and the page
uses it for everything machine-shaped — station
names, endpoints, Workflow IDs, timings. The two
faces come from two origins, Fontshare and Google
Fonts, and the page preconnects to both.

Every icon is an inline `<symbol>` filled or
stroked with `currentColor`, declared once and
reused, so each one inherits the brightness of the
text beside it. The Temporal lockup is the official
white asset from
`https://temporal.io/images/logos/logo-temporal-with-copy-white-text.svg`
with its `fill="white"` swapped for `currentColor`;
the interface symbols are Lucide, ISC-licensed. The
page carries them in the binary rather than
fetching them, so no runtime dependency on anyone's
CDN is added for artwork.

The backdrop is three fixed layers over the flat
`#141414` field, all reproduced in CSS so the binary
ships no image: two diffuse blooms on `body`, a
sparse starfield of 1px dots, and a flat grid masked
to fade out before it reaches the diagram. Its
ceiling is an attention limit rather than a contrast
one — a grid bright enough to cross the diagram's
band makes the cards read as holes punched in a lit
field, while still measuring safely inside contrast
limits.

`#444CE7` is barred from anything text-sized. It
measures 3.01:1 against `#141414` — exactly the
floor for large text, with nothing left once a
projector washes it out — so gradients that paint
letters use violet, pink and mint. Indigo's home is
the backdrop bloom, where a diffuse wash carries no
meaning that contrast has to protect.

Tailwind and Alpine arrive from a CDN at pinned
versions. Tailwind 4 is configured in CSS through
`@theme`, and has no JavaScript config object. It
also drops `@theme` tokens that nothing consumes,
so a `var(--color-…)` naming an otherwise-unused
token resolves to nothing at all rather than to its
declared value — a token and its first consumer
have to arrive together.

**Why:** a demo of a Temporal component that looks
like Temporal is read as part of that world before
a word of it is read. Recording where the values
came from is what stops the next session from
substituting a palette that merely looks similar,
and what explains why exactly one of the two
typefaces is a stand-in.

**How to apply:** take a new colour from
temporal.io or do not add one, and check it against
`#141414` before putting it under text. Keep the
CDN versions pinned and bump them deliberately.
Record the source URL beside any asset copied in.
Should Aeonik ever become servable, it replaces
General Sans and nothing else changes.
