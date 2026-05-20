# Domain Name Authority

## TODO

- [ ] Document the PowerDNS REST API endpoints used by `register-service.sh`
- [ ] Add zone import/export tooling for backup and migration of DNS records
- [ ] Document DNSSEC key management for the authoritative PowerDNS zone
- [ ] Create a guide for adding secondary/slave DNS for redundancy

## Outline

The domain name authority manages the authoritative DNS zone for the NetLocal root domain, storing and serving all internal DNS records.

- PowerDNS (at `169.254.0.3`) is the authoritative DNS server, backed by PostgreSQL for record storage
- CoreDNS (at `169.254.0.2`) handles recursion for the `.local` zone and forwards all other queries to public resolvers
- New service DNS records are created via `scripts/lib/register-service.sh`, which PATCHes the PowerDNS REST API
- `POWERDNS_API_KEY` in `.env` authenticates management requests to the PowerDNS HTTP API
- The `NETLOCAL_ROOT_DOMAIN` variable determines the zone name (default: `net.local`)
- Both CoreDNS and PowerDNS attach to `localnet_backbone` with static IPs to ensure they are always reachable
