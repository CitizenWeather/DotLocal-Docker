# Billing & Usage Tracking

## TODO

- [ ] Define metrics to track for usage accounting (bandwidth, storage, compute-hours)
- [ ] Design a usage data schema compatible with the observability Prometheus metrics
- [ ] Implement a usage reporting endpoint in the Supervisor API
- [ ] Document how billing data integrates with the tenancy subsystem per-tenant

## Outline

The billing subsystem tracks resource consumption across tenants and services for internal usage accounting within the NetLocal stack.

- Collects usage metrics from Prometheus (network bytes, storage written, request counts) and aggregates them per tenant
- Designed for multi-tenant deployments where resource allocation and showback/chargeback are needed
- Integrates with the quotas subsystem to enforce limits and generate alerts when thresholds are approached
- Usage records are stored in the primary database (PostgreSQL via `DB_APP` slot)
- Status: planned — no billing service is deployed by default; this is a future management plane feature
- **Cloud provider pricing integration** (optional, default-disabled): an extension module can pull public pricing APIs from AWS, GCP, Azure, and others to provide cost comparison or showback against equivalent cloud resources; activated via `EXTENSION_TAGS` and never enabled in the base stack
