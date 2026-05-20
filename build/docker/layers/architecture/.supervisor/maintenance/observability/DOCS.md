# Observability

## TODO

- [ ] Document how to enable the observability stack via `ENABLE_OBSERVABILITY=true`
- [ ] Add Grafana dashboard JSON for core NetLocal services (DNS query rates, CA cert issuance)
- [ ] Configure Loki log retention and Tempo trace sampling rates
- [ ] Document Promtail scrape config for each Docker service

## Outline

The observability subsystem provides metrics, logs, and traces for all NetLocal services using the Prometheus/Grafana/Loki/Tempo stack.

- Enabled by setting `ENABLE_OBSERVABILITY=true` in `.env`; adds Prometheus, Grafana, Loki, Promtail, and Tempo containers
- Prometheus scrapes metrics from all services with a `netlocal.component` label via Docker service discovery
- Grafana provides dashboards and alert rules; provisioning configs live in `config/grafana/provisioning/`
- Loki aggregates container logs via Promtail, which reads Docker socket log streams
- Tempo collects distributed traces from services instrumented with OpenTelemetry
- Grafana is accessible at `grafana.<ROOT_DOMAIN>` through the gateway with TLS from Step-CA
