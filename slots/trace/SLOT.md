# Slot: trace

**Variable:** `TRACE_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=trace`
**Active when:** `ENABLE_OBSERVABILITY=true`

## Contract

An implementation must:
- Accept distributed traces via Jaeger Thrift HTTP on port 3200 (or compatible)
- Be queryable by Grafana via the Tempo data source protocol
- Store trace data in a named volume

## Available implementations

| Name | Image | Notes |
|---|---|---|
| `tempo` *(recommended)* | `grafana/tempo:latest` | Native Grafana integration; low resource use |
| `jaeger` | `jaegertracing/all-in-one:latest` | Battle-tested; UI on port 16686 |

## Adding a new implementation

1. Create `slots/trace/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`, expose port 3200 (or adjust Grafana data source)
3. Add label `netlocal.component=trace`
4. Set `TRACE_APP=<impl-name>` in `.env`
