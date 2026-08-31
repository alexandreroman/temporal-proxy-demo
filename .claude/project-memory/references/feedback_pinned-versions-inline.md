---
name: "Pinned versions are literals in the recipe"
description: "Every version the Makefile pins is written inline, with its rationale in the target's comment"
type: feedback
---

# Pinned versions are literals in the recipe

Every version the `Makefile` pins is written as a literal
in the recipe line that uses it, never lifted into a `make`
variable, and its rationale lives in the block comment
above its target.

**Why:** these pins are deliberate, not knobs a caller is
meant to turn, so a `?=` variable advertises an override
that should not happen. One convention for all of them also
keeps a reader from hunting for the value in a second place.

**How to apply:** when a version needs to change, edit the
literal in the recipe, and explain a new pin in the
target's existing comment block rather than in a
mid-recipe comment.
