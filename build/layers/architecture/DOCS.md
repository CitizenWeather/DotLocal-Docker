# Architecture Layer Overview

## TODO

- [ ] Create an architecture decision record (ADR) process and index
- [ ] Document the layered model (authority, barebones, architecture, providers)
- [ ] Map each service to its network attachment and IP range
- [ ] Produce a dependency graph showing inter-layer relationships

## Outline

The architecture layer describes the high-level logical structure of the NetLocal stack, organizing services into functional planes: authority, infrastructure, ISP-facing, and LAN-facing.

- The stack is divided into `dotlocal_authority` (core control plane), `internet_services_provider` (WAN-facing), and `localised_services_provider` (LAN-facing) subsystems
- A `.supervisor` management plane provides cross-cutting concerns: API, observability, secrets, identity, quotas, tenancy, and maintenance
- Each subsystem maps to directories under `build/layers/architecture/` and corresponds to concrete compose service definitions
- The authority layer (`build/layers/authority/`) houses the CA, domain name, and identity authorities that underpin the entire stack
- Barebones infrastructure (`build/layers/barebones/`) provides swappable implementations for databases, caches, and message brokers
- The providers layer (`build/layers/providers/`) covers optional higher-level service offerings built atop the infrastructure
