# Slot: log

**Variable:** `LOG_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=log`
**Active when:** `ENABLE_OBSERVABILITY=true`

## Contract

An implementation must:

- Ingest log streams via HTTP on port 3100 (Loki push API or compatible)
- Accept log entries from Promtail (the always-on log collector in the observability stack)
- Be queryable by Grafana via the Loki data source protocol

### Ingest endpoint

```
POST http://netlocal_loki:3100/loki/api/v1/push
Content-Type: application/json
```

## Available implementations

| Name                   | Image                                 | Notes                             |
|------------------------|---------------------------------------|-----------------------------------|
| `loki` *(recommended)* | `grafana/loki:latest`                 | Native Grafana integration        |
| `opensearch`           | `opensearchproject/opensearch:latest` | Elasticsearch-compatible; heavier |
| `graylog`              | `graylog/graylog:latest`              | Full-featured log management UI   |

## Adding a new implementation

1. Create `slots/log/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`, expose port 3100
3. Add label `netlocal.component=log`
4. Set `LOG_APP=<impl-name>` in `.env`
