# Resource Quotas

## TODO

- [ ] Define quota dimensions: CPU, memory, storage, network egress, DNS records
- [ ] Implement quota enforcement hooks in the Supervisor API
- [ ] Document how to configure per-tenant quotas in the tenancy subsystem
- [ ] Add quota utilization panels to the Grafana observability dashboards

## Outline

The quotas subsystem manages resource limits and usage caps for services and tenants within the NetLocal stack.

- Quotas are defined per tenant and per service, covering dimensions like storage capacity, DNS record count, and certificate issuance rate
- Enforced at the Supervisor API layer — requests that would exceed quota are rejected with an informative error
- Quota state is persisted in PostgreSQL alongside billing and tenancy data
- Integrates with the observability stack to emit quota utilization metrics scraped by Prometheus
- Quota breaches can trigger alerts via Grafana and optionally throttle or suspend affected services
- Status: planned — quota enforcement requires the Supervisor API to be implemented first
