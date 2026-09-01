---
name: "Lifecycle targets come in up/down pairs"
description: "One name per job, platform and workload as symmetric pairs, and a teardown that never fails because something is already gone"
type: feedback
---

# Lifecycle targets come in up/down pairs

The Makefile exposes each lifecycle layer as a
symmetric pair: `cluster-up` and `cluster-down` for
the platform, `app-up` and `app-down` for the
workload. A reader who knows one half can guess the
other, and the help listing reads as pairs rather
than as a list of verbs.

Each job carries exactly one name. Where a single
command already brings something up, it is that
pair's `-up` half rather than a second name beside
it.

A teardown target succeeds when its subject is
already absent. Removing workloads passes
`--ignore-not-found` so missing resources are not an
error, and guards on the cluster existing at all
before addressing a kubeconfig context, because
`kubectl --context` fails on a context that is not
there. Teardown also carries no setup guard: it
needs no Cloud Namespace, no account id, no master
secret and no certificate, and demanding them would
fail in exactly the situation where someone wants to
tear down.

The asymmetry between the pairs is deliberate:
`app-down` stops short of the platform layer so that
`app-up` returns quickly, which leaves `cluster-down`
as the only way to remove everything.

**Why:** the commands are the demo's interface, and
a reader typing them under time pressure should not
have to remember which of two similar names is
authoritative, nor discover that tearing down errors
because a previous teardown worked. Symmetry makes
the surface guessable; tolerant teardown makes it
safe to repeat.

**How to apply:** add a lifecycle target as a pair,
give both halves a `##` description, and make the
`-down` half exit zero whatever state it finds. Use
the guard idiom already in the file — `kind get
clusters | grep -qx` — rather than a new one. See
[The Makefile's help listing is its public
surface](feedback_help-is-the-public-surface.md).
