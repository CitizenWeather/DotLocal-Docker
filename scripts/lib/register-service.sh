#!/bin/bash
# Register a service in PowerDNS and expose it via the gateway.
#
# Purpose: Adds an A record to the local DNS registry (PowerDNS) so the service
#          becomes accessible via the gateway at <SERVICE_NAME>.<NETLOCAL_ROOT_DOMAIN>.
#
# Usage: ./scripts/lib/register-service.sh <service-name> <ip-address>
#
# Arguments:
#   $1  Service name (e.g., myapp, backend, api)
#   $2  IPv4 address where the service is running
#
# Examples:
#   ./scripts/lib/register-service.sh myapp 192.168.1.100
#   ./scripts/lib/register-service.sh backend 172.20.0.10
#
# Environment:
#   NETLOCAL_ROOT_DOMAIN  Local TLD (default: net.local)
#   POWERDNS_API_KEY      PowerDNS HTTP API key (must be set)
#
# Requirements:
#   - PowerDNS must be running at http://registrar:8081
#   - POWERDNS_API_KEY must match the API key configured in PowerDNS
#
# Exit codes:
#   0  Record added/updated successfully
#   1  DNS update failed (check POWERDNS_API_KEY and PowerDNS connectivity)

SERVICE_NAME=$1
SERVICE_IP=$2
DOMAIN="${SERVICE_NAME}.${NETLOCAL_ROOT_DOMAIN:-net.local}"

curl -X PATCH "http://registrar:8081/api/v1/servers/localhost/zones/${NETLOCAL_ROOT_DOMAIN:-net.local}" \
  -H "X-API-Key: ${POWERDNS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"rrsets\": [{\"name\": \"$DOMAIN.\", \"type\": \"A\", \"ttl\": 3600, \"records\": [{\"content\": \"$SERVICE_IP\", \"disabled\": false}]}]}"