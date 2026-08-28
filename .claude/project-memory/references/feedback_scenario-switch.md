---
name: "Switching upstreams is a proxy-config change"
description: "One proxy config file per scenario, and where the active choice is recorded"
type: feedback
---

# Switching upstreams is a proxy-config change

Moving the whole demo from one upstream to
another is a change to the proxy configuration
and nothing else. The application keeps dialling
the same local endpoint in plaintext with the
same short Namespace name, `default`, in every
scenario; the upstream's own name for that
Namespace is a translation rule the proxy owns.
No Go file and no rebuild.

Applying a scenario recreates temporal-proxy and
restarts the Worker and the API, so nothing keeps
polling the upstream left behind. It takes about
six seconds, and triggering a Workflow answers
right after. The switch checks nothing: `docker
compose up -d --force-recreate` starts
temporal-proxy when it is down, and `restart` is a
silent no-op on a container that does not exist.

Each scenario is a whole config file under
`proxy/`, named after the scenario and committed.
Reading two of them side by side, or diffing
them, is the teaching material: what differs is
the `upstreams` block, and nothing else does.

The active choice lives in `.env`, as the path of
the file Compose mounts. That is the one file
`docker compose` reads unprompted, so a bare
`docker compose up` in a worktree runs the same
scenario as any `make` target — the same reason
worktree ports live in a generated Compose
override rather than in the environment. See
[[feedback-worktree-config-on-disk]].

A scenario whose credentials are absent is
refused before the switch happens, because
temporal-proxy crash-loops on a configuration it
cannot parse, with the reason buried in its log.

**Why:** the demo's whole claim is that upstream
choice is deployment configuration rather than
application code. Restarting a container is
deployment; a switch that touched a Go file or
rebuilt an image would disprove the claim on
stage.

**How to apply:** add a scenario as
`proxy/<name>.yaml` decalqued from an existing
one, keeping everything outside `upstreams`
byte-identical where the scenario allows it, and
give it a Make target that records the choice.
Anything a scenario needs beyond the proxy —
a credential, an account id — reaches
temporal-proxy as an environment variable and
never reaches the application. See
[[project-demo-scope]].
