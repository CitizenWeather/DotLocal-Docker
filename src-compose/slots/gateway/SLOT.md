# Slot: gateway

**Variable:** `GATEWAY_APP`
**Networks:** `localnet_backbone` + `localnet_default` (bridges both)
**Label:** `netlocal.component=gateway`

## Contract

An implementation must:

- Listen on port 80 (HTTP) and port 443 (HTTPS)
- Terminate TLS using certificates obtained from the CA slot (ACME)
- Route `*.<NETLOCAL_ROOT_DOMAIN>` requests to upstream services on `localnet_default`
- Obtain certificates from `https://ca.${NETLOCAL_ROOT_DOMAIN}/acme/acme/directory`

## Required environment variables

| Variable               | Purpose                  |
|------------------------|--------------------------|
| `NETLOCAL_ROOT_DOMAIN` | Wildcard domain to route |

## Available implementations

| Name                    | Image          | Extra ports      |
|-------------------------|----------------|------------------|
| `caddy` *(recommended)* | `caddy:latest` | —                |
| `traefik`               | `traefik:v3.0` | 8080 (dashboard) |

## Adding a new implementation

1. Create `slots/gateway/<impl-name>/docker-compose.yml`
2. Attach to both `localnet_backbone` and `localnet_default`
3. Add label `netlocal.component=gateway`
4. Configure ACME to use `https://ca.${NETLOCAL_ROOT_DOMAIN}/acme/acme/directory`
5. Set `GATEWAY_APP=<impl-name>` in `.env`
