#!/bin/bash
# Convenience wrapper to switch the DNS resolver implementation.
#
# Purpose: Shorthand for `make switch SLOT=dns IMPL=<impl>`. Delegates to
#          the generic switch.sh script which handles zero-downtime apply.
#
# Usage: ./scripts/lib/switch-dns.sh <implementation>
#   or:  make switch-dns <implementation>
#
# Arguments:
#   $1  DNS implementation (coredns, bind9, knot)
#
# Examples:
#   ./scripts/lib/switch-dns.sh coredns
#   ./scripts/lib/switch-dns.sh bind9
#   ./scripts/lib/switch-dns.sh knot
#
# Environment:
#   SWITCH_LEGACY=1  Use legacy down/up instead of zero-downtime apply
#
# Exit codes:
#   0  Successfully switched DNS and applied
#   1  Unknown implementation or apply failed

set -e

NEW_DNS=$1
if [ -z "$NEW_DNS" ]; then
    echo "Usage: ./scripts/lib/switch-dns.sh <implementation>" >&2
    echo "Examples: coredns, bind9, knot" >&2
    exit 1
fi

# Delegate to generic switcher
exec ./scripts/lib/switch.sh dns "$NEW_DNS"