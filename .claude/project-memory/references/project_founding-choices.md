---
name: "Founding technical choices"
description: "Why Go, Kubernetes on Kind and Apache-2.0 were chosen for Temporal Proxy Demo"
type: project
---

# Founding technical choices

- **Go SDK** for the Worker and starter, matching the
  language temporal-proxy itself is written in, so readers
  can follow both sides of the wire without a language
  switch.
- **Kubernetes on Kind** as the only runtime for the demo:
  a local cluster brings up Traefik, Vault, the Vault
  Secrets Operator and temporal-proxy through Helm, and the
  application's own manifests through Kustomize, all with
  one command, `make deploy`.
- **Apache-2.0** as the repository license, even though
  temporal-proxy upstream is MIT.

**Why:** the demo must be runnable end to end in minutes on
any machine with a container runtime and `kind`, and its
code must read as ordinary Temporal Go SDK code.

**How to apply:** keep the entry point a single `Makefile`
with `make deploy` as the one command that brings up the
whole demo. Propose a second runtime or a second SDK
language as an addition to discuss, never as a silent
replacement.
