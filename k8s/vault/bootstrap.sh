#!/usr/bin/env sh
# Configure this Vault so the Vault Secrets Operator can read the
# Temporal Cloud client certificate.
#
# Run by the chart's postStart hook, inside the Vault container, on
# every start. That repetition is the point: this Vault is in dev mode
# and keeps nothing across a restart, so a configuration that reapplies
# itself is the difference between a pod restart being invisible and
# leaving the demo silently broken.
#
# A failing postStart hook kills the container, so every step here has
# to tolerate having already been done.
set -eu

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root

# postStart fires as soon as the container starts, which is before the
# listener accepts connections. Without this wait the first command
# fails and takes the container down with it.
i=0
until vault status >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -lt 60 ] || { echo "vault did not become reachable"; exit 1; }
    sleep 1
done

vault policy write temporal-proxy - <<'POLICY'
path "secret/data/temporal-cloud" {
  capabilities = ["read"]
}
POLICY

# Enabling an already-enabled method is an error rather than a no-op,
# and this script reruns on every restart. That one case is swallowed;
# nothing else is.
vault auth enable kubernetes 2>/dev/null || true

# Vault's own ServiceAccount is bound to system:auth-delegator by the
# chart, so the token mounted in this container is allowed to call the
# TokenReview API. That is what lets the configuration live inside the
# Vault pod instead of needing a ServiceAccount and a
# ClusterRoleBinding of its own.
vault write auth/kubernetes/config \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token \
    kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

vault write auth/kubernetes/role/temporal-proxy \
    bound_service_account_names=temporal-proxy-vault \
    bound_service_account_namespaces=temporal-proxy \
    policies=temporal-proxy \
    ttl=1h
