# Slot: registry

**Variable:** `REGISTRY_APP`
**Network:** `localnet_backbone` (static IP `169.254.0.3`)
**Label:** `netlocal.component=registry`

> **Note:** Only one implementation (`powerdns`) exists today. This slot is a fixed service in practice until a second implementation is added.

## Contract

An implementation must:
- Serve as an authoritative nameserver for dynamic DNS records
- Accept queries from the DNS resolver at `169.254.0.2`
- Store records in the PostgreSQL instance (DB slot)
- Expose a REST API on port 8081 authenticated via `X-API-Key: ${POWERDNS_API_KEY}`

### REST API surface used by `register-service.sh`

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/servers/localhost/zones` | List zones |
| `POST` | `/api/v1/servers/localhost/zones` | Create a zone |
| `PATCH` | `/api/v1/servers/localhost/zones/{zone}` | Add/update records |
| `DELETE` | `/api/v1/servers/localhost/zones/{zone}/records/{name}/{type}` | Remove a record |

All requests must include `X-API-Key: ${POWERDNS_API_KEY}` and `Content-Type: application/json`.

## Required environment variables

| Variable | Purpose |
|---|---|
| `POWERDNS_API_KEY` | REST API authentication key |
| `POSTGRES_PASSWORD` | Database credentials |

## Available implementations

| Name | Image |
|---|---|
| `powerdns` *(only option)* | `powerdns/pdns-auth:latest` |

## Dependencies

- Requires the **db** slot to be running (PostgreSQL backend)

## Adding a new implementation

1. Create `slots/registry/<impl-name>/docker-compose.yml`
2. Attach to `localnet_backbone` with static IP `169.254.0.3`
3. Add label `netlocal.component=registry`
4. Expose REST API compatible with `scripts/lib/register-service.sh`
5. Set `REGISTRY_APP=<impl-name>` in `.env`
