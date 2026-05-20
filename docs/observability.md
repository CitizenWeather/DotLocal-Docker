# Observability Stack

NetLocal includes an optional observability stack that adds metrics, logs, traces, and dashboards. Enable it by setting `ENABLE_OBSERVABILITY=true` in `.env` and restarting.

---

## Services

| Service | Image | Role | URL |
|---|---|---|---|
| Prometheus | `prom/prometheus` | Metrics scraping and storage | `http://prometheus.localnet:9090` |
| Grafana | `grafana/grafana` | Dashboards and alerting | `http://grafana.localnet:3000` |
| Loki | `grafana/loki` | Log aggregation | Internal; queried via Grafana |
| Promtail | `grafana/promtail` | Log shipper (Docker logs → Loki) | Internal only |
| Tempo | `grafana/tempo` | Distributed tracing | Internal; queried via Grafana |

---

## Enabling

```bash
# In .env:
ENABLE_OBSERVABILITY=true

# Then restart:
make restart
```

All five services start together. There is no way to enable a subset through `.env` — if you need that, edit the Makefile directly.

---

## Grafana

Grafana starts pre-provisioned with datasources for Prometheus, Loki, and Tempo. No manual datasource setup is required.

Default login: `admin` / `admin` (change on first login).

Pre-configured datasources (from `config/grafana/provisioning/datasources/`):
- **Prometheus** — `http://prometheus:9090`
- **Loki** — `http://loki:3100`
- **Tempo** — `http://tempo:3200`

---

## Prometheus

Prometheus scrapes metrics from services that expose a `/metrics` endpoint. Scrape targets are configured in `config/prometheus/prometheus.yml`.

To add a new scrape target, edit that file and reload Prometheus:

```bash
curl -X POST http://prometheus.localnet:9090/-/reload
```

---

## Loki and Promtail

Promtail runs as a sidecar that reads Docker container logs (via the Docker socket and `/var/log` mounts) and ships them to Loki. All container logs are available in Grafana's Explore view using the Loki datasource.

---

## Tempo

Tempo receives OpenTelemetry traces. To send traces from your own services, configure the OTLP exporter endpoint:

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo.localnet:4317
```

Traces are visible in Grafana's Explore view using the Tempo datasource.
