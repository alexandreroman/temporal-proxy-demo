---
name: "Naming the proxy outside the Go code"
description: "Docs, Makefile and Compose call the component temporal-proxy, and PORT is unqualified"
type: feedback
---

# Naming the proxy outside the Go code

Everywhere the demo is free to name the component
— README, Makefile, Compose files, the scenario
configs under `proxy/`, `.env.example` — it is
called `temporal-proxy`, its own name. A generic
word for a network intermediary is vaguer than the
name and describes any proxy equally well, so it
earns no place in prose or in identifiers. The Go
code is the one place that names nothing at all:
see [[feedback-agnostic-app-code]].

`temporal-proxy` is a proper name and takes no
article: "temporal-proxy validates its config on
startup", never "the temporal-proxy validates".
Where repeating the name weighs a sentence down,
recast the sentence.

Make variables holding a host port are qualified
by what they publish: `TEMPORAL_PROXY_PORT`,
`TEMPORAL_WEB_UI_PORT`. `PORT` is the deliberate
exception, because it is the variable the API
itself reads from its environment — `cmd/app`
calls `os.Getenv("PORT")` — so the Make variable
and the application's environment contract carry
one name.

**Why:** the component's own name is precise and
searchable, and a demo built to show temporal-proxy
should say what it is showing. Qualifying the port
variables makes them readable side by side, while
qualifying `PORT` would break its correspondence
with the application silently: nothing fails, the
API simply binds its own 8080 default.

**How to apply:** name the component in
documentation, in Makefile and Compose comments,
and in target descriptions. Where a variable
mirrors an environment variable an application
reads, keep both names identical. See
[[feedback-casper-workspace-integration]] for the
port variables `.casper.json` passes in.
