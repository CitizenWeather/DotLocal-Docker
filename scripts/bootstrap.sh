#!/bin/bash
# First-time setup: create Docker networks, required directories, and config templates.
set -euo pipefail

# Load .env if present
if [ -f .env ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

BACKBONE_SUBNET="${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16}"
DEFAULT_SUBNET="${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16}"

echo "==> Creating required directories..."
mkdir -p volumes
mkdir -p core/containerlab/nodes
mkdir -p backups
mkdir -p config/grafana/provisioning/datasources
mkdir -p config/prometheus/alerts

echo "==> Creating Docker networks..."
if ! docker network inspect localnet_backbone >/dev/null 2>&1; then
    docker network create \
        --driver bridge \
        --subnet "$BACKBONE_SUBNET" \
        --internal \
        localnet_backbone
    echo "    Created localnet_backbone ($BACKBONE_SUBNET)"
else
    echo "    localnet_backbone already exists"
fi

if ! docker network inspect localnet_default >/dev/null 2>&1; then
    docker network create \
        --driver bridge \
        --subnet "$DEFAULT_SUBNET" \
        localnet_default
    echo "    Created localnet_default ($DEFAULT_SUBNET)"
else
    echo "    localnet_default already exists"
fi

echo "==> Copying config templates..."

# Caddy
CADDY_CFG="apps/localnet/barebones/gateway/caddy/config/Caddyfile"
if [ ! -f "$CADDY_CFG" ]; then
    mkdir -p "$(dirname "$CADDY_CFG")"
    cat > "$CADDY_CFG" <<'EOF'
# NetLocal Caddyfile — edit to add routes
{
    admin off
}

:80 {
    respond "NetLocal gateway running" 200
}
EOF
    echo "    Created $CADDY_CFG"
fi

# IoT extension: mosquitto config
MOSQ_CFG="apps/extensions/iot/config/mosquitto.conf"
if [ ! -f "$MOSQ_CFG" ]; then
    mkdir -p "$(dirname "$MOSQ_CFG")"
    cat > "$MOSQ_CFG" <<'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest stdout
EOF
    echo "    Created $MOSQ_CFG"
fi

echo ""
echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Review .env (defaults are in .env.example)"
echo "  2. make validate-env"
echo "  3. make up"
echo "  4. make health"
