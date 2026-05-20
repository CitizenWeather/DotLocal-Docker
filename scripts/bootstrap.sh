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

# In multi-instance mode set NETLOCAL_NETWORK_PREFIX=<instance>_ so parallel
# stacks on the same host do not share networks.  Default is empty (single instance).
PREFIX="${NETLOCAL_NETWORK_PREFIX:-}"

# Create Docker networks if they don't exist
docker network inspect "${PREFIX}localnet_backbone" >/dev/null 2>&1 || \
    docker network create \
        --driver bridge \
        --subnet "${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16}" \
        --internal \
        "${PREFIX}localnet_backbone"

docker network inspect "${PREFIX}localnet_default" >/dev/null 2>&1 || \
    docker network create \
        --driver bridge \
        --subnet "${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16}" \
        "${PREFIX}localnet_default"

# localnet_nat: internet-capable bridge (no --internal).
# Docker's built-in MASQUERADE rule provides NAT egress automatically.
# Use for containers that need outbound internet access outside the service mesh.
docker network inspect "${PREFIX}localnet_nat" >/dev/null 2>&1 || \
    docker network create \
        --driver bridge \
        --subnet "${NETLOCAL_SUBNET_NAT:-10.20.0.0/16}" \
        "${PREFIX}localnet_nat"

echo "Bootstrap complete. Run 'make up' to start NetLocal."
