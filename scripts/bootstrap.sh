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
