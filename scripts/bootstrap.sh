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

# Create networks
docker network inspect localnet_backbone >/dev/null 2>&1 || \
    docker network create --driver bridge --subnet ${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16} --internal localnet_backbone
docker network inspect localnet_default >/dev/null 2>&1 || \
    docker network create --driver bridge --subnet ${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16} localnet_default

# Generate Caddyfile template if not present
if [ ! -f apps/gateway/caddy/config/Caddyfile ]; then
    cp apps/gateway/caddy/config/Caddyfile.template apps/gateway/caddy/config/Caddyfile
fi

# Similarly for mosquitto.conf, frr/daemons, and Grafana datasource YAMLs

echo "Bootstrap complete. Run 'make up' to start NetLocal."

