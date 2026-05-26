#!/bin/bash
# Switch a slot implementation and reconcile the running stack.
#
# Purpose: Changes a swappable slot implementation (DNS, gateway, database, etc.)
#          and applies the change via zero-downtime apply (preserves volumes).
#
# Usage: ./scripts/lib/switch.sh <slot> <impl>
#   or:  make switch SLOT=<slot> IMPL=<impl>
#
# Arguments:
#   $1  Slot name (dns, ca, gateway, db, cache, storage, messaging, policy, etc.)
#   $2  New implementation name (e.g., coredns, caddy, postgres)
#
# Examples:
#   ./scripts/lib/switch.sh dns bind9
#   ./scripts/lib/switch.sh gateway traefik
#   ./scripts/lib/switch.sh db mysql
#
# Environment:
#   SWITCH_LEGACY=1  Use legacy `make down && make up` instead of zero-downtime apply
#   NETLOCAL_ROOT_DOMAIN  Local TLD (default: net.local)
#
# Exit codes:
#   0  Successfully switched and applied
#   1  Invalid slot, missing compose file, or apply failed

set -e

SLOT=$1
IMPL=$2

SLOTS="dns ca registry gateway db cache storage messaging policy ntp dashboard uptime identity secrets log trace"

if [ -z "$SLOT" ] || [ -z "$IMPL" ]; then
    echo "Usage: make switch SLOT=<slot> IMPL=<impl>"
    echo ""
    echo "Available slots: $SLOTS"
    exit 1
fi

# Validate slot name
valid=0
for s in $SLOTS; do
    [ "$s" = "$SLOT" ] && valid=1
done
if [ "$valid" -eq 0 ]; then
    echo "Error: unknown slot '$SLOT'. Available: $SLOTS" >&2
    exit 1
fi

# Check implementation compose file exists
COMPOSE_FILE="slots/$SLOT/$IMPL/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: no compose file at $COMPOSE_FILE" >&2
    echo "  Available implementations for slot '$SLOT':" >&2
    ls "slots/$SLOT/" 2>/dev/null | grep -v SLOT.md | sed 's/^/    /' >&2 || true
    exit 1
fi

# Update .env
ENV_VAR=$(echo "$SLOT" | tr '[:lower:]' '[:upper:]')_APP
if [ ! -f .env ]; then
    echo "Error: .env not found. Run 'make bootstrap' first." >&2
    exit 1
fi

sed -i.bak "s/^${ENV_VAR}=.*/${ENV_VAR}=${IMPL}/" .env

echo "Switched $ENV_VAR → $IMPL"

# Reconcile via zero-downtime apply (preserves named volumes, drains stateful
# services, gates each tier on healthchecks). Set SWITCH_LEGACY=1 to fall
# back to the old `make down && make up` behaviour.
if [ "${SWITCH_LEGACY:-0}" = "1" ]; then
    make down
    make up
else
    exec ./scripts/dotlocal apply --auto-approve
fi
