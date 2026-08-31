---
name: "The page's error hints name no command"
description: "The same binary serves the page in the cluster and in a local loop, so its recovery hints stay context-neutral"
type: project
---

# The page's error hints name no command

The error hints on the page `cmd/app` serves say what
went wrong and what to do about it in the abstract:
restart the demo, read the app log, check that a Worker
is polling. They name no command, no `make` target, and
no tool.

The same binary serves this page in two places. In the
Kind cluster `make app-up` brings it back; on a
developer's machine it runs against a plain `temporal
server start-dev` alongside `go run ./cmd/worker` and
`go run ./cmd/app` — see
[Local development needs no cluster](project_local-development.md).
The running page cannot tell which of the two it is in,
and it has no variable that would tell it.

Each hint is one or two short sentences at the page's
body size, read from the back of a room — see
[The demo page is read from the back of a room](feedback_page-projection-legibility.md).

**Why:** a hint that names one of the two ways to start
the demo is wrong half the time it is read, and a wrong
instruction on a projected screen costs more than a
vague one. Naming a command also puts a second copy of
the demo's entry points inside a template, where nothing
checks them against the Makefile.

**How to apply:** describe the recovery, not the
keystroke. If a hint seems to need a command to be
useful, the missing information belongs in the README or
in the log the hint points at, not in the page.
