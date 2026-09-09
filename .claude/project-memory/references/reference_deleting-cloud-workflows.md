---
name: "Deleting every Workflow in the Cloud Namespace"
description: "The batch-delete recipe the Temporal CLI accepts non-interactively, and the flag constraint that forces it"
type: reference
---

# Deleting every Workflow in the Cloud Namespace

Clearing the demo's Temporal Cloud Namespace is one
batch operation, driven by a query rather than by a
list of Workflow Ids:

```bash
temporal workflow delete \
  --address "$TEMPORAL_CLOUD_NAMESPACE.$TEMPORAL_ACCOUNT.tmprl.cloud:7233" \
  --namespace "$TEMPORAL_CLOUD_NAMESPACE.$TEMPORAL_ACCOUNT" \
  --tls-cert-path k8s/certs/client.pem \
  --tls-key-path k8s/certs/client.key \
  --query 'WorkflowId != ""' --reason 'demo cleanup' -y
```

Four things make that shape the only one that works
unattended:

- `-y` is accepted **only** alongside `--query`.
  The per-execution form, `--workflow-id`, always
  prompts and has no way to skip the prompt, so
  deleting a namespace one Id at a time stalls.
- `WorkflowId != ""` matches every execution
  whatever its status, which a filter on
  `WorkflowType` or `ExecutionStatus` does not.
- The removal is asynchronous. The command returns
  a job id; `temporal batch describe --job-id` then
  reports `CompletedCount` and `FailureCount`, and
  `temporal workflow count` confirms the Namespace
  is empty.
- Deletion takes the Event History with it, and
  terminates a Running execution before removing
  it. Nothing is recoverable afterwards.

**Why:** the connection carries no defaults of its
own — the Namespace is fully qualified here, unlike
the short name the application dials — so every
invocation needs the address, the qualified
Namespace and the client certificate spelled out.

**How to access:** `TEMPORAL_CLOUD_NAMESPACE` and
`TEMPORAL_ACCOUNT` come from `.env`; the client
certificate pair lives in `k8s/certs/`. See
[One environment file](feedback_single-env-file.md) and
[naming the tenant](feedback_namespace-identifies-the-tenant.md).
