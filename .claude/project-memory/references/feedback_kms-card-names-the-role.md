---
name: "The key service card names the role, not the transport"
description: "What the diagram's key-service station and the intro prose say about it, why its transport stays off the card, and why the prose lists the places keys live without ranking them"
type: feedback
---

# The key service card names the role, not the transport

**The station is called `key service`**, not by the
name of the component that implements it. The room
reads a role there; `kms` is what the deployment, the
extension and the code are called, and those keep the
name. The card then says what that service is —
reached as an extension rather than as a Temporal
component — and what it produces: one wrapping key per
Namespace, which is the tenancy boundary, because
learning one Namespace's key hands over none of the
others.

Naming the role on the card matters because the
diagram groups each component with the person who
answers for it, and this one sits with the security
operator — see [The rail is grouped by
persona](project_rail-grouped-by-persona.md).

How temporal-proxy reaches it stays off the card. TLS,
the bearer token and the controllers that issue them
describe the connection rather than the role, and a
caption line spent on them is a line the room reads
instead of the one fact the station exists to carry.
The wrapping contract needs no line either: the wire
says the endpoint calls there, and the endpoint's own
`payloads are sealed here` says why.

The page's prose frames it the same way, and states
what the extension buys rather than what it does. The
intro says the operator's keys stay where they already
are — a cloud KMS, an on-prem HSM — and that they can
bring their own key service through temporal-proxy's
own `kms` extension, which is where the demo's own key
service sits.

The places stand side by side, unranked: a built-in
cloud backend is as legitimate a place to keep keys as
any other, and prose setting the extension against one
of them argues with a choice much of the room has
already made. What keeps the list true is that it puts
no named backend behind the extension: the extension
covers the backends temporal-proxy carries no built-in
scheme for, so prose placing a cloud KMS behind it
reads as false to anyone who knows the scheme list —
see [temporal-proxy encryption
constraints](reference_proxy-encryption-constraints.md)
for the list that decides which side a backend falls
on. An invitation to bring a key service of one's own
names no backend at all, so it stays true whatever the
scheme list holds. The sealing and the key a payload is sealed
with stay temporal-proxy's, in the prose as on the
card.

Wording about what temporal-proxy or one of its
extensions is *for* comes from the upstream project's
own README. Paraphrasing the mechanism out of this
repository's code instead yields prose that is
accurate and sells nothing: a sentence saying the
extension wraps keys names an operation the audience
has no reason to care about.

Three items is what every card carries, and the shape
that sets their shared height. The cards allow fewer,
which simply leaves that room unused; a card with
three has none to give.

**The three items line up across the cards on a
request's path**, so the same slot answers the same
question at each station. The second one carries the
state of a payload there — plaintext at the clients,
sealed at the endpoint, sealed on arrival upstream —
and that is the encryption story read straight across
the diagram, without a line of prose.

**Why:** the diagram is watched from the back of a
room, not read, and each station gets three lines that
have to land in one glance. A line about
plumbing displaces the fact that justifies drawing the
component at all.

**How to apply:** before adding a caption item, ask
whether it names what the component is or what it
produces. If it describes how something connects to it,
it belongs in the README. Where the prose lists the
options an operator has, list them and stop — a
comparison that rules one out reads as an argument
against part of the audience. A sentence naming what
the extension reaches is checked against the built-in
scheme list before it ships: the non-ranking rule
governs the tone of that list, never its accuracy. See
[The diagram is cards joined by static SVG
wires](project_diagram-is-cards-and-wires.md) for the
caption's geometry and
[The page names no upstream](project_page-names-no-upstream.md)
for the neighbouring station's rule.
