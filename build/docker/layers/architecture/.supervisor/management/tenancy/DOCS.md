# Multi-Tenancy

## TODO

- [ ] Design tenant isolation model (network namespaces, separate compose stacks, or labels)
- [ ] Document tenant onboarding workflow via the Supervisor API
- [ ] Define tenant-scoped DNS namespace conventions (e.g., `<tenant>.<ROOT_DOMAIN>`)
- [ ] Implement tenant data in PostgreSQL with row-level security

## Outline

The tenancy subsystem provides multi-tenant isolation and management for the NetLocal stack, enabling multiple users or teams to share the infrastructure with logical separation.

- Each tenant gets a scoped namespace under the root domain, isolated DNS records, and separate TLS certificates from Step-CA
- Tenant metadata (name, quotas, billing, users) is stored in PostgreSQL via the `DB_APP` slot
- Network isolation between tenants is achieved via Docker network labels and gateway routing rules
- The Supervisor API enforces tenant boundaries — all management operations are scoped to a tenant context
- Integrates with the identity subsystem for tenant user authentication and role-based access control
- Status: planned — single-tenant operation is the current default
