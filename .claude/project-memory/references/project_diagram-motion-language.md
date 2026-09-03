---
name: "What the diagram's motion means"
description: "The wires carry no arrowheads and direction is the travelling pulse's job, violet is the request going out, mint is the result coming home"
type: project
---

# What the diagram's motion means

A run plays five phases: the Execution starts
(application to proxy to Temporal), the Workflow Task
reaches the Worker's long poll (Temporal to proxy to
worker), the Activity dwells, the result is reported
(worker to proxy to Temporal), and the caller's long
poll returns (Temporal to proxy to application). Each
of the four movements detours through the key service
on its way: every payload is sealed on its way out and
unsealed on its way in, so the proxy calls there and
comes back before the movement goes on. Every wire
therefore carries traffic in both directions over one
run.

**The wires carry no arrowheads.** Direction is the
travelling pulse's job alone, so the diagram never
draws a claim about which way a wire flows. A static
head would be a false claim on a wire that carries
both directions, and a head shown only during travel
would duplicate what the pulse already says.

**The pulse is a step of lightness above the accent,
never the accent itself.** A wire lights in the accent
as soon as it has been crossed, so a pulse painted in
the accent is invisible on every crossing after the
first — which is every return leg. Mixing the page's
foreground into the accent puts the pulse above both
the lit and the finished wire, in either phase colour,
and keeps the documented levels below it untouched.
Dimming the wire instead would close the gap between
travelling and finished, which the legibility budget
does not allow.

Two consecutive movements on one wire always run in
opposite directions, because every hop touches the
endpoint. So the two travel directions are separate
named animations rather than one played in reverse: a
change of `animation-name` is what restarts an
animation, and a shared name silently inherits the
previous hop's finished clock.

**Violet is the request going out; mint is the result
coming home.** Mint begins the moment the Activity
finishes and covers every movement until the greeting
reaches the caller. The delivery of a Workflow Task to
the Worker is not mint: it carries work, not an answer,
and mint is the colour the greeting itself arrives in
in the result panel.

The rule reaches the component cards as well as the
wires, from one token override rather than two
mechanisms, so the two can never disagree. Because the
answer passes over everything, a successful run settles
the whole diagram to a single mint record. Mint is
damped into the ink until it matches violet's own OKLab
lightness — raw mint is more than twice violet's
contrast against the background, and at equal weight it
reads as an alarm rather than as an answer.

The dwell on the Worker carries a floor of its own, in
the script rather than the stylesheet. Four hops a walk
means the outbound animation can outrun a short round
trip, and a phase that ends before anyone sees it
teaches nothing, so the rail dwells for as long as the
Workflow takes or for that floor, whichever is longer.
What the page reports stays measured around the fetch:
the floor delays when a result is shown, never what the
result claims.

Reduced motion plays the same sequence at the same
pace; only the stylesheet stops things moving. What
that mode conveys is narrower, and the limit is known.
The *order* is inferable and the *active leg* is
identifiable, because the still pulse sits a step above
the wire it covers. **Direction is not**, on either
hop leaving the endpoint: each carries both phase
colours in both directions, so its violet steps and its
mint steps are pairwise indistinguishable, and only a
card happening to flip colour separates them. The client
wires do imply direction: each is crossed once in each
direction, in a different phase colour each way.

**Why:** an audience reads this from the back of a room
and infers the protocol from what moves. A colour or an
arrow that means two things, or that promises an answer
before there is one, teaches the wrong model of how the
system works.

**How to apply:** add a movement by naming its phase
and deciding whether it carries a request or a result;
the colour follows from that. Leave direction to the
pulse rather than drawing it. See
[What the diagram's construction
is](project_diagram-is-cards-and-wires.md).
