#!/bin/bash
# Validates .env configuration before starting the stack.
set -euo pipefail

ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found. Run: cp .env.example .env" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

errors=0

fail() {
    echo "ERROR: $*" >&2
    errors=$((errors + 1))
}

warn() {
    echo "WARN:  $*"
}

check_one_of() {
    local var="$1"
    local value="${!var:-}"
    shift
    local options=("$@")
    if [ -z "$value" ]; then
        return 0  # empty is allowed (disables the component)
    fi
    for opt in "${options[@]}"; do
        [ "$value" = "$opt" ] && return 0
    done
    fail "$var='$value' is not valid. Options: ${options[*]}"
}

check_non_empty() {
    local var="$1"
    local value="${!var:-}"
    if [ -z "$value" ]; then
        fail "$var must not be empty"
    fi
}

check_not_default() {
    local var="$1"
    local default="$2"
    local value="${!var:-}"
    if [ "$value" = "$default" ]; then
        warn "$var is still set to the default '$default' — change before use in shared environments"
    fi
}

# ── Required variables ────────────────────────────────────────────────────────
check_non_empty NETLOCAL_ROOT_DOMAIN
check_non_empty NETLOCAL_SUBNET_BACKBONE
check_non_empty NETLOCAL_SUBNET_DEFAULT

# ── Swappable components ──────────────────────────────────────────────────────
check_one_of DNS_APP        coredns bind9 knot
check_one_of CA_APP         smallstep openxpki vault-pki
check_one_of REGISTRY_APP   powerdns knot-dns
check_one_of POLICY_APP     opa iptables ""
check_one_of GATEWAY_APP    traefik caddy
check_one_of DB_APP         postgres mysql
check_one_of CACHE_APP      redis redis-stack
check_one_of STORAGE_APP    minio seaweedfs
check_one_of MESSAGING_APP  nats nats-jetstream kafka

# ── Email tier ────────────────────────────────────────────────────────────────
EMAIL_TIER="${EMAIL_TIER:-}"
if [ -n "$EMAIL_TIER" ]; then
    case "$EMAIL_TIER" in
        1|2|3|4) ;;
        *) fail "EMAIL_TIER='$EMAIL_TIER' is not valid. Options: 1 2 3 4 (or leave blank to disable)" ;;
    esac
fi

# ── Observability ─────────────────────────────────────────────────────────────
check_one_of ENABLE_OBSERVABILITY true false ""

# ── Subnet overlap check ──────────────────────────────────────────────────────
BACKBONE="${NETLOCAL_SUBNET_BACKBONE:-}"
DEFAULT="${NETLOCAL_SUBNET_DEFAULT:-}"
if [ "$BACKBONE" = "$DEFAULT" ]; then
    fail "NETLOCAL_SUBNET_BACKBONE and NETLOCAL_SUBNET_DEFAULT must not be the same subnet"
fi

# ── Credential warnings ───────────────────────────────────────────────────────
check_not_default POSTGRES_PASSWORD      changeme
check_not_default POWERDNS_API_KEY       changeme
check_not_default MINIO_ROOT_PASSWORD    changeme
check_not_default GRAFANA_ADMIN_PASSWORD changeme

# ── Result ────────────────────────────────────────────────────────────────────
if [ "$errors" -gt 0 ]; then
    echo ""
    echo "Found $errors error(s) in $ENV_FILE — fix them before running 'make up'" >&2
    exit 1
fi

echo "✓ $ENV_FILE is valid"
