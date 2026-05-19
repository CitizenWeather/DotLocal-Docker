#!/bin/bash
# Usage: ./scripts/switch-ca.sh <smallstep|openxpki|vault-pki>

set -e

NEW_CA=$1
if [ -z "$NEW_CA" ]; then
    echo "Usage: switch-ca.sh <smallstep|openxpki|vault-pki>"
    exit 1
fi

# Update .env
sed -i.bak "s/^CA_APP=.*/CA_APP=$NEW_CA/" .env

# Stop and restart CA service
make down
make up

echo "Switched CA to $NEW_CA. Verify at https://ca.${NETLOCAL_ROOT_DOMAIN:-net.local}/health"