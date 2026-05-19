#!/bin/bash
# Usage: ./scripts/register-consul.sh <service-name> <port> [health-check-url]
SERVICE=$1
PORT=$2
HEALTH=$3

curl -X PUT "http://consul.net.local:8500/v1/agent/service/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"Name\": \"$SERVICE\",
    \"Port\": $PORT,
    \"Check\": {
      \"HTTP\": \"$HEALTH\",
      \"Interval\": \"10s\"
    }
  }"