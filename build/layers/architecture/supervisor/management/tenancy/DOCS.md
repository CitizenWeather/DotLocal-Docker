# Multi-Tenancy

## TODO

- [ ] Design tenant isolation model (network namespaces, separate compose stacks, or labels)
- [ ] Document tenant onboarding workflow via the Supervisor API
- [ ] Define tenant-scoped DNS namespace conventions (e.g., `<tenant>.<ROOT_DOMAIN>`)
- [ ] Implement tenant data in PostgreSQL with row-level security
- [ ] Design sub-tenancy model: parent/child tenant relationships, quota inheritance, and delegated administration

## Outline

The tenancy subsystem provides multi-tenant isolation and management for the NetLocal stack, enabling multiple users or teams to share the infrastructure with logical separation.

- Each tenant gets a scoped namespace under the root domain, isolated DNS records, and separate TLS certificates from Step-CA
- Tenant metadata (name, quotas, billing, users) is stored in PostgreSQL via the `DB_APP` slot
- Network isolation between tenants is achieved via Docker network labels and gateway routing rules
- The Supervisor API enforces tenant boundaries — all management operations are scoped to a tenant context
- Integrates with the identity subsystem for tenant user authentication and role-based access control
- **Sub-tenancy / relations**: tenants can have parent/child relationships enabling delegated quota management, inherited policies, and scoped admin roles without flattening the hierarchy
- Status: planned — single-tenant operation is the current default
- **localTLD management**: for deep or sensitive isolation, the stack can reserve dedicated safe TLDs per deployment tier rather than using sub-domains of the root domain — candidate TLDs include `.localhost`, `.localnode`, `.localadmin`, `.dotlocal`, `.localweb`, `.localnet`, `.localnetwork`; TLD assignment is governed by build profile and can be managed via the Supervisor API
- **HyperNet extension**: an optional extension module (`extensions/hypernet/`) that enables controlled inter-tenant connectivity and interoperability — tenants remain isolated by default but can opt in to shared service discovery, cross-tenant API calls, and data exchange channels without collapsing their isolated environments
