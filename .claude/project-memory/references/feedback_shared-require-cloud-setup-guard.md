---
name: "The require-cloud-setup guard is one Make variable, reused by name"
description: "Two call sites share a define block; the later definition in the file wins for both"
type: feedback
---

# The require-cloud-setup guard is one Make variable, reused by name

The Makefile carries two `define require-cloud-setup ... endef` blocks:
one under `##@ Scenarios` (used by `use-cloud`) and one under `##@
Kubernetes` (used by `vault-cert`). Both run the identical four checks
for `TEMPORAL_CLOUD_NAMESPACE`, `TEMPORAL_ACCOUNT`,
`proxy/certs/client.pem`, and `proxy/certs/client.key`, but their
`echo` wording differs slightly (one talks about "switching to the
cloud scenario", the other about "deploying").

`define NAME ... endef` in GNU Make is a plain variable assignment,
and the whole file is parsed before any recipe runs. This means the
**later** definition in the file — the Kubernetes one — is what every
caller gets, including `use-cloud`, regardless of which definition sits
textually closer to it. The pass/fail behavior of both targets is
identical either way (same checks, same exit code), but only one
message wording is ever printed.

Anyone editing either block should either keep the two `echo` bodies
in sync on purpose, or give the Kubernetes one a distinct name (e.g.
`require-cloud-setup-k8s`) to stop the implicit override. As of Task 3
of the Kubernetes migration this was left as a same-name override,
deliberately, per that task's brief.
