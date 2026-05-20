# Slot: uptime

**Variable:** `UPTIME_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=uptime`

## Contract

An implementation must:
- Serve a status/uptime dashboard on port 3001 (HTTP)
- Be routable by the gateway at `status.${NETLOCAL_ROOT_DOMAIN}`
- Monitor services reachable on `localnet_default` and `localnet_backbone`

## Available implementations

| Name | Image | Notes |
|---|---|---|
| `uptime-kuma` *(recommended)* | `louislam/uptime-kuma:latest` | Rich UI, multi-protocol monitoring |
| `gatus` | `twinproduction/gatus:latest` | YAML-configured, Prometheus metrics |
| `statping` | `statping/statping:latest` | Status page with historical data |

## Adding a new implementation

1. Create `slots/uptime/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`, expose port 3001
3. Add label `netlocal.component=uptime`
4. Set `UPTIME_APP=<impl-name>` in `.env`
