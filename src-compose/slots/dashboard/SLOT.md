# Slot: dashboard

**Variable:** `DASHBOARD_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=dashboard`

## Contract

An implementation must:

- Serve a web UI on port 80 (HTTP)
- Be routable by the gateway at `dashboard.${NETLOCAL_ROOT_DOMAIN}`
- Provide a landing page / service link directory for the local stack

## Available implementations

| Name                       | Image                         | Notes                                   |
|----------------------------|-------------------------------|-----------------------------------------|
| `heimdall` *(recommended)* | `linuxserver/heimdall:latest` | Application dashboard with custom links |
| `homer`                    | `b4bz/homer:latest`           | Static YAML-configured dashboard        |
| `dashy`                    | `lissy93/dashy:latest`        | Feature-rich; config via YAML           |

## Adding a new implementation

1. Create `slots/dashboard/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`, expose port 80
3. Add label `netlocal.component=dashboard`
4. Set `DASHBOARD_APP=<impl-name>` in `.env`
