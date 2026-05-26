# Slot: db

**Variable:** `DB_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=db`

## Contract

An implementation must:

- Expose a SQL-compatible port reachable from other services on `localnet_default`
- Accept credentials from environment variables
- Be accessible to the **registry** slot (PowerDNS uses PostgreSQL)

## Required environment variables

| Variable            | Purpose                                       |
|---------------------|-----------------------------------------------|
| `POSTGRES_PASSWORD` | Database password (shared with registry slot) |

## Port conventions

| Implementation | Port |
|----------------|------|
| `postgres`     | 5432 |
| `mysql`        | 3306 |

## Available implementations

| Name                       | Image                |
|----------------------------|----------------------|
| `postgres` *(recommended)* | `postgres:16-alpine` |
| `mysql`                    | `mysql:8.0`          |

## Dependencies

- Required by the **registry** slot (PowerDNS)

## Adding a new implementation

1. Create `slots/db/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Add label `netlocal.component=db`
4. Set `DB_APP=<impl-name>` in `.env`
