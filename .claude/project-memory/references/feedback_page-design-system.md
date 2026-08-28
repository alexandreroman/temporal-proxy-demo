---
name: "The demo page borrows temporal.io's own design system"
description: "Where the page's palette and typefaces come from, and why Aeonik is not among them"
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
uses **Schibsted Grotesk** in its place — a
geometric grotesque of the same temperature,
available on Google Fonts. Its mono is **Noto Sans
Mono**, which is not a substitute for anything:
temporal.io ships that exact face, and the page
uses it for everything machine-shaped — station
names, endpoints, Workflow and Run IDs, timings.

Tailwind and Alpine arrive from a CDN at pinned
versions. Tailwind 4 is configured in CSS through
`@theme`, and has no JavaScript config object.

**Why:** a demo of a Temporal component that looks
like Temporal is read as part of that world before
a word of it is read. Recording where the values
came from is what stops the next session from
substituting a palette that merely looks similar,
and what explains why exactly one of the two
typefaces is a stand-in.

**How to apply:** take a new colour from
temporal.io or do not add one. Keep the CDN
versions pinned and bump them deliberately. Should
Aeonik ever become servable, it replaces Schibsted
Grotesk and nothing else changes.
