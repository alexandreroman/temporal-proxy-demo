---
name: "Pinned versions are literals in the recipe"
description: "Every version the Makefile pins is written inline, with its rationale in the target's comment"
type: feedback
---

# Pinned versions are literals in the recipe

Every version the `Makefile` pins — the Gateway API
release, the Traefik chart, the temporal-proxy chart — is
written as a literal in the recipe line that uses it, never
lifted into a `make` variable. The rationale for a pin lives
in the block comment above its target, not next to a
variable.

**Why:** these pins are deliberate, not knobs a caller is
meant to turn, so a `?=` variable advertises an override
that should not happen. One convention for all of them also
keeps a reader from hunting for the value in a second place.

**How to apply:** when a version needs to change, edit the
literal in the recipe. Explain a new pin in the target's
existing comment block rather than adding a mid-recipe
comment — `apply` already carries the file's only one, and
that pattern stays a single case.
