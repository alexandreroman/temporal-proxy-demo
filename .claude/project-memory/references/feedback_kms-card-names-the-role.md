---
name: "The kms card names the role, not the transport"
description: "What the diagram's key-service station says, why its transport stays off it, and why two caption items are a legitimate shape"
type: feedback
---

# The kms card names the role, not the transport

The diagram's `kms` station carries two caption items:
`temporal-proxy extension`, then `derives one key per
namespace`. The card says what the service *is* — the
key service temporal-proxy plugs into, rather than a
Temporal component — and what it produces: one wrapping
key per Namespace, which is the tenancy boundary,
because learning one Namespace's key hands over none of
the others.

How temporal-proxy reaches it stays off the card. TLS,
the bearer token and the controllers that issue them
describe the connection rather than the role, and a
caption line spent on them is a line the room reads
instead of the one fact the station exists to carry.
The wrapping contract needs no line either: the wire
says the endpoint calls there, and the endpoint's own
`payloads are sealed here` says why.

Two items is a shape the cards allow. A three-item
caption sets their fixed height, so a station with
fewer leaves that room unused — which the upstream's
lockup card already does.

**Why:** the diagram is watched from the back of a
room, not read, and each station gets two or three
lines that have to land in one glance. A line about
plumbing displaces the fact that justifies drawing the
component at all.

**How to apply:** before adding a caption item, ask
whether it names what the component is or what it
produces. If it describes how something connects to it,
it belongs in the README. See
[The diagram is cards joined by static SVG
wires](project_diagram-is-cards-and-wires.md) for the
caption's geometry and
[The page names no upstream](project_page-names-no-upstream.md)
for the neighbouring station's rule.
