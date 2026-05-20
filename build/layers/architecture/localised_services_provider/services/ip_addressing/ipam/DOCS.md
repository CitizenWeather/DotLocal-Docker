# IP Address Management (IPAM)

## TODO

- [ ] Deploy NetBox or phpIPAM as the IPAM implementation and document initial subnet configuration
- [ ] Import the backbone (`169.254.0.0/16`) and default (`172.20.0.0/16`) subnets into IPAM
- [ ] Automate IP allocation requests from `scripts/lib/register-service.sh`
- [ ] Export IPAM data to Prometheus for IP utilization dashboards in Grafana

## Outline

IPAM provides a centralized inventory of IP address allocations across all subnets in the NetLocal environment, preventing conflicts and documenting ownership.

- Tracks allocations across `localnet_backbone` (`169.254.0.0/16`) and `localnet_default` (`172.20.0.0/16`) subnets
- NetBox or phpIPAM are candidate implementations, accessible via a web UI at `ipam.<ROOT_DOMAIN>`
- Integrates with the DHCP server to record dynamic leases and with `register-service.sh` for static allocations
- Each allocation record includes the service name, `netlocal.component` label, owner, and backbone IP
- IPAM data is backed by PostgreSQL via the `DB_APP` slot
- Status: optional service — manual IP management via `.env` static IPs is the current approach
