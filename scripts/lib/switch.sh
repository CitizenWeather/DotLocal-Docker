#!/bin/bash
# Generic slot switcher.
# Usage: make switch SLOT=<slot> IMPL=<impl>
#   or:  ./scripts/lib/switch.sh <slot> <impl>

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
make down
make up
