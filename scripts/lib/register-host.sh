#!/bin/bash
# Register a remote host in PowerDNS (NOT YET IMPLEMENTED).
#
# Purpose: [Planned] Adds DNS records for a remote or bridged host so it can
#          communicate with local services using the .local domain.
#
# Usage: ./scripts/lib/register-host.sh <hostname> <ip-address>
#
# Arguments:
#   $1  Hostname (e.g., developer-laptop, ci-runner)
#   $2  IPv4 address of the remote host
#
# Examples:
#   ./scripts/lib/register-host.sh developer-laptop 192.168.1.50
#   ./scripts/lib/register-host.sh ci-runner 10.0.0.100
#
# Environment:
#   NETLOCAL_ROOT_DOMAIN  Local TLD (default: net.local)
#   POWERDNS_API_KEY      PowerDNS HTTP API key
#
# Exit codes:
#   0  Host registered successfully
#   1  Registration failed
#
# Status: TODO (see ROADMAP.md §11 for details)

echo "Error: register-host.sh is not yet implemented." >&2
echo "See ROADMAP.md §11 (Developer Experience) for planned functionality." >&2
exit 1
