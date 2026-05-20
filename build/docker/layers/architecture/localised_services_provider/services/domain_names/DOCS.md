# Local Domain Name Services

## TODO

- [ ] Document the `.local` zone file format and how to add static DNS records manually
- [ ] Add automated DNS registration to the service bootstrap process
- [ ] Document PTR (reverse DNS) record management for backbone IP addresses
- [ ] Test mDNS/Bonjour coexistence with CoreDNS `.local` zone on the same host

## Outline

Local domain name services manage DNS resolution for `.local` and custom TLD names within the NetLocal LAN environment.

- CoreDNS (at `169.254.0.2`) serves the authoritative `.local` zone from a static zone file in `apps/localnet/barebones/dns/coredns/`
- Dynamic DNS records are stored in PowerDNS (at `169.254.0.3`) backed by PostgreSQL, and managed via the REST API
- New services are registered using `scripts/lib/register-service.sh`, which PATCHes the PowerDNS API
- The `NETLOCAL_ROOT_DOMAIN` variable (default `net.local`) sets the TLD for all internal service names
- dnsmasq on the host forwards `.local` queries to CoreDNS so the host machine can resolve internal names
- Wildcard DNS (`*.<ROOT_DOMAIN>` → gateway IP) enables automatic routing for new services added to the gateway
