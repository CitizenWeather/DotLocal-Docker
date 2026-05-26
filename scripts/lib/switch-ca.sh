#!/bin/bash
# Convenience wrapper to switch the certificate authority implementation.
#
# Purpose: Shorthand for `make switch SLOT=ca IMPL=<impl>`. Delegates to
#          the generic switch.sh script which handles zero-downtime apply.
#
# Usage: ./scripts/lib/switch-ca.sh <implementation>
#   or:  make switch-ca <implementation>
#
# Arguments:
#   $1  CA implementation (smallstep, openxpki, vault-pki)
#
# Examples:
#   ./scripts/lib/switch-ca.sh smallstep
#   ./scripts/lib/switch-ca.sh openxpki
#
# Environment:
#   SWITCH_LEGACY=1  Use legacy down/up instead of zero-downtime apply
#
# Exit codes:
#   0  Successfully switched CA and applied
#   1  Unknown implementation or apply failed

set -e

NEW_CA=$1
if [ -z "$NEW_CA" ]; then
    echo "Usage: ./scripts/lib/switch-ca.sh <implementation>" >&2
    echo "Examples: smallstep, openxpki, vault-pki" >&2
    exit 1
fi

# Delegate to generic switcher
exec ./scripts/lib/switch.sh ca "$NEW_CA"