#!/bin/bash
set -e

# Load .env if present
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Create required directories
mkdir -p volumes
mkdir -p core/containerlab/nodes
mkdir -p apps/gateway/caddy/config
mkdir -p extensions/iot/config
mkdir -p core/containerlab/config/frr
mkdir -p apps/observability/grafana/provisioning/datasources
mkdir -p core/containerlab/config/{chirpstack,5g/open5gs,ics/{plc,modbus,hmi}}

# Copy default configs if not present (placeholders)
if [ ! -f core/containerlab/config/chirpstack/chirpstack.toml ]; then
    cp -r ./examples/config/chirpstack/* core/containerlab/config/chirpstack/
fi
if [ ! -f core/containerlab/config/5g/gnb1.conf ]; then
    cp -r ./examples/config/5g/* core/containerlab/config/5g/
fi
if [ ! -f core/containerlab/config/ics/plc/staircase.st ]; then
    cp -r ./examples/config/ics/* core/containerlab/config/ics/
fi

# Create networks
docker network inspect localnet_backbone >/dev/null 2>&1 || \
    docker network create --driver bridge --subnet ${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16} --internal localnet_backbone
docker network inspect localnet_default >/dev/null 2>&1 || \
    docker network create --driver bridge --subnet ${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16} localnet_default

# Generate Caddyfile template if not present
if [ ! -f apps/gateway/caddy/config/Caddyfile ]; then
    cp apps/gateway/caddy/config/Caddyfile.template apps/gateway/caddy/config/Caddyfile
fi


# Wait for OpenBao
until curl -s http://secrets.net.local:8200/v1/sys/health; do sleep 2; done

# Store PowerDNS API key
curl -X POST http://secrets.net.local:8200/v1/secret/data/powerdns \
  -H "X-Vault-Token: root" \
  -d '{"data": {"api_key": "'"${POWERDNS_API_KEY}"'"}}'

# Store database password
curl -X POST http://secrets.net.local:8200/v1/secret/data/postgres \
  -H "X-Vault-Token: root" \
  -d '{"data": {"password": "'"${POSTGRES_PASSWORD}"'"}}'


# Seed secrets if OpenBao is enabled
if [ -f apps/localnet/barebones/secrets/openbao/docker-compose.yml ]; then
    ./scripts/bootstrap-secrets.sh
fi

# Similarly for mosquitto.conf, frr/daemons, and Grafana datasource YAMLs

echo "Bootstrap complete. Run 'make up' to start NetLocal."

