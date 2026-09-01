---
name: "The Makefile's help listing is its public surface"
description: "A target carries a ## description when a reader should type it, and quality has one entry point"
type: feedback
---

# The Makefile's help listing is its public surface

`make help` lists a target when that target carries
a `##` description, and the listing is the contract
with a reader: everything in it is a command someone
would type. Internal guards, `require-setup` among
them, carry no description and stay out of it, with
their rationale in the comment block above the
`define` they run.

Quality has one entry point, `check`, which runs the
test suite and the static checks together.

**Why:** a listing that mixes commands with plumbing
makes a reader work out which is which, and two
entry points for one kind of check invite the
question of which one is authoritative.

**How to apply:** give a `##` description to a
target a reader should type, and leave it off a
target that exists only as a prerequisite. See
[One environment file](feedback_single-env-file.md).
