#!/bin/bash
# Wait for OpenBao
until curl -s http://secrets.net.local:8200/v1/sys/health | grep -q '"initialized":true'; do
    sleep 2
done

# Store PowerDNS API key
curl -X POST http://secrets.net.local:8200/v1/secret/data/powerdns \
  -H "X-Vault-Token: ${OPENBAO_ROOT_TOKEN:-root}" \
  -d '{"data": {"api_key": "'"${POWERDNS_API_KEY}"'"}}'

# Store PostgreSQL password
curl -X POST http://secrets.net.local:8200/v1/secret/data/postgres \
  -H "X-Vault-Token: ${OPENBAO_ROOT_TOKEN:-root}" \
  -d '{"data": {"password": "'"${POSTGRES_PASSWORD}"'"}}'

# Store MinIO credentials
curl -X POST http://secrets.net.local:8200/v1/secret/data/minio \
  -H "X-Vault-Token: ${OPENBAO_ROOT_TOKEN:-root}" \
  -d '{"data": {"root_user": "'"${MINIO_ROOT_USER}"'", "root_password": "'"${MINIO_ROOT_PASSWORD}"'"}}'