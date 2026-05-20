#!/bin/bash
set -e

# Load .env if present
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Runtime data directory
mkdir -p volumes

# Generated config output (git-ignored; services write here at runtime)
mkdir -p config/generated

# Create Docker networks if they don't exist
docker network inspect localnet_backbone >/dev/null 2>&1 || \
    docker network create \
        --driver bridge \
        --subnet "${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16}" \
        --internal \
        localnet_backbone

docker network inspect localnet_default >/dev/null 2>&1 || \
    docker network create \
        --driver bridge \
        --subnet "${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16}" \
        localnet_default

echo "Bootstrap complete. Run 'make up' to start NetLocal."
