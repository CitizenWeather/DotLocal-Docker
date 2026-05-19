#!/bin/bash
# Register a service with PowerDNS and Traefik
SERVICE_NAME=$1
SERVICE_IP=$2
DOMAIN="${SERVICE_NAME}.${NETLOCAL_ROOT_DOMAIN:-net.local}"

curl -X PATCH "http://registrar:8081/api/v1/servers/localhost/zones/${NETLOCAL_ROOT_DOMAIN:-net.local}" \
  -H "X-API-Key: ${POWERDNS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"rrsets\": [{\"name\": \"$DOMAIN.\", \"type\": \"A\", \"ttl\": 3600, \"records\": [{\"content\": \"$SERVICE_IP\", \"disabled\": false}]}]}"