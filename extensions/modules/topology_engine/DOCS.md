# Topology Engine

## TODO

- [ ] Design the topology API for declaring virtual network nodes, links, and routing policies
- [ ] Integrate with containerlab to apply declared topologies to running containers
- [ ] Implement topology state persistence in PostgreSQL so changes survive restarts
- [ ] Add topology visualization UI accessible at `topology.<ROOT_DOMAIN>`

## Outline

The topology engine provides dynamic network topology management for the NetLocal environment, enabling programmatic control over virtual network configurations.

- Declarative API allows operators to define network nodes, links, bandwidth constraints, and routing policies as code
- Translates topology declarations into containerlab configurations and FRR routing table updates
- Supports topology versioning — roll forward or back to a named topology snapshot
- Useful for testing network failure scenarios (link down, route withdrawal) in conjunction with the chaos module
- Topology state is persisted in PostgreSQL and reflected in the observability stack
- Status: planned — currently topology changes require manual editing of containerlab YAML and FRR config files
