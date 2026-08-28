---
name: "The API tolerates unknown request fields"
description: "Extra JSON fields in a request body are ignored so the contract can grow without breaking clients"
type: project
---

# The API tolerates unknown request fields

The HTTP API decodes request bodies with the
`encoding/json` defaults. A field the request type does
not declare is ignored and the request succeeds. An
absent or empty body is equally valid and falls back to
the default name. A `400` is reserved for a body that is
not valid JSON and for a declared field carrying the
wrong type.

**Why:** what matters is finding the expected fields.
Rejecting the rest freezes the contract — every client
sending a field the server does not declare fails, so
the payload cannot gain a field without a coordinated
client rollout.

**How to apply:** decode without any strict mode. Cover
an extra field as an accepted case in the tests, and
keep malformed JSON and wrong field types at `400`.
