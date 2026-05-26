#!/bin/bash
# Issue a TLS certificate from the local CA for a given domain.
#
# Purpose: Generates a certificate signed by the NetLocal CA (step-ca) for use
#          in testing and local development. Certificates are valid for 24 hours.
#
# Usage: ./scripts/lib/issue-cert.sh <domain>
#
# Arguments:
#   $1  Domain name to issue a certificate for (e.g., myservice.net.local)
#
# Examples:
#   ./scripts/lib/issue-cert.sh api.net.local
#   ./scripts/lib/issue-cert.sh myapp.net.local
#
# Environment:
#   NETLOCAL_ROOT_DOMAIN  Local TLD (default: net.local)
#
# Output files:
#   <domain>.crt  Certificate file
#   <domain>.key  Private key file
#   ca.crt        Local CA root certificate (downloaded if needed)
#
# Requirements:
#   - Step CA must be running at https://ca.<NETLOCAL_ROOT_DOMAIN>
#   - step-cli binary must be in PATH or mounted in container
#   - Local CA root certificate must be trusted by clients
#
# Exit codes:
#   0  Certificate issued successfully
#   1  CA unreachable or certificate generation failed

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain>" >&2
  echo "Example: $0 myservice.net.local" >&2
  exit 1
fi

step-cli ca certificate $DOMAIN $DOMAIN.crt $DOMAIN.key --ca-url https://ca.${NETLOCAL_ROOT_DOMAIN:-net.local} --root ./ca.crt