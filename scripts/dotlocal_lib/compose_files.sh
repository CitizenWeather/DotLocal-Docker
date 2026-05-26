#!/usr/bin/env bash
# Single source of truth for the compose-file list.
# Sourced by `scripts/dotlocal` and (indirectly via `make compose-files`) by
# the Makefile. Mirrors the Makefile's include_if / EMAIL_TIER /
# ENABLE_OBSERVABILITY / EXTENSION_TAGS logic so the two never drift.
#
# After sourcing this file, $COMPOSE_FILES contains a space-separated list
# of `-f path/to/compose.yml` flags suitable for `docker compose`.

if [ -z "${DOTLOCAL_ROOT:-}" ]; then
    echo "compose_files.sh: DOTLOCAL_ROOT must be set before sourcing" >&2
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

# Load .env if present (mirrors the Makefile's `include .env`).
if [ -f "$DOTLOCAL_ROOT/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$DOTLOCAL_ROOT/.env"
    set +a
fi

NETLOCAL_PROJECT="${NETLOCAL_PROJECT:-netlocal}"

_add_if_exists() {
    local rel="$1"
    if [ -f "$DOTLOCAL_ROOT/$rel" ]; then
        COMPOSE_FILES="$COMPOSE_FILES -f $rel"
    fi
}

COMPOSE_FILES="-f stacks/core/networks.yml"

# Role slots
_add_if_exists "slots/dns/${DNS_APP}/docker-compose.yml"
_add_if_exists "slots/ca/${CA_APP}/docker-compose.yml"
_add_if_exists "slots/registry/${REGISTRY_APP}/docker-compose.yml"
_add_if_exists "slots/gateway/${GATEWAY_APP}/docker-compose.yml"
_add_if_exists "slots/db/${DB_APP}/docker-compose.yml"
_add_if_exists "slots/cache/${CACHE_APP}/docker-compose.yml"
_add_if_exists "slots/storage/${STORAGE_APP}/docker-compose.yml"
_add_if_exists "slots/messaging/${MESSAGING_APP}/docker-compose.yml"
_add_if_exists "slots/policy/${POLICY_APP}/docker-compose.yml"
_add_if_exists "slots/ntp/${NTP_APP}/docker-compose.yml"
_add_if_exists "slots/dashboard/${DASHBOARD_APP}/docker-compose.yml"
_add_if_exists "slots/uptime/${UPTIME_APP}/docker-compose.yml"

# Optional slots (blank-by-default)
if [ -n "${IDENTITY_APP:-}" ]; then
    _add_if_exists "slots/identity/${IDENTITY_APP}/docker-compose.yml"
fi
if [ -n "${SECRETS_APP:-}" ]; then
    _add_if_exists "slots/secrets/${SECRETS_APP}/docker-compose.yml"
fi

# Fixed services
_add_if_exists "stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core/dnsmasq/docker-compose.yml"
_add_if_exists "stacks/barebones/net_root/localnet_authority/dashboards/heimdall/docker-compose.yml"
_add_if_exists "stacks/barebones/net_root/intranet_service_provider/base/health/endpoint/docker-compose.yml"
_add_if_exists "build/layers/authority/net_time/slots/chrony/docker-compose.yml"
_add_if_exists "stacks/net_web/whois/whoisd/docker-compose.yml"
_add_if_exists "stacks/barebones/net_root/localnet_authority/dashboards/dotlocal/status/uptime-kuma/docker-compose.yml"
_add_if_exists "build/layers/architecture/internet_services_provider/gateways/nat_egress/docker-compose.yml"

# Email tiers (additive)
case "${EMAIL_TIER:-1}" in
    1)
        _add_if_exists "stacks/net_providers/mail_provider/mailpit/docker-compose.yml"
        ;;
    2|3|4)
        _add_if_exists "stacks/net_providers/mail_provider/stalwart/docker-compose.yml"
        if [ "${EMAIL_TIER}" = "3" ] || [ "${EMAIL_TIER}" = "4" ]; then
            _add_if_exists "stacks/net_providers/mail_provider/dovecot/docker-compose.yml"
        fi
        if [ "${EMAIL_TIER}" = "4" ]; then
            _add_if_exists "stacks/net_providers/mail_provider/postfix/relay/docker-compose.yml"
        fi
        ;;
esac

# Observability
if [ "${ENABLE_OBSERVABILITY:-false}" = "true" ]; then
    _add_if_exists "build/layers/architecture/supervisor/observability/docker-compose.yml"
    _add_if_exists "build/layers/architecture/supervisor/observability/slots/prometheus/docker-compose.yml"
    _add_if_exists "slots/log/${LOG_APP}/docker-compose.yml"
    _add_if_exists "slots/trace/${TRACE_APP}/docker-compose.yml"
fi

# Extension tags
if [ -n "${EXTENSION_TAGS:-}" ]; then
    for tag in $EXTENSION_TAGS; do
        _add_if_exists "extensions/${tag}/docker-compose.yml"
    done
fi

export COMPOSE_FILES NETLOCAL_PROJECT
