# ISP-Level Domain Name Services

## TODO

- [ ] Document integration with public DNS resolvers (1.1.1.1, 8.8.8.8) as upstream forwarders
- [ ] Configure DNSSEC validation for external domain queries
- [ ] Add split-horizon DNS so internal names resolve locally and external names resolve publicly
- [ ] Document how to override external DNS records for development/testing purposes

## Outline

ISP-level domain name services handle resolution of public internet domain names for clients on the local network, forwarding queries to upstream public resolvers.

- CoreDNS forwards non-`.local` queries to public resolvers (Cloudflare `1.1.1.1`, Google `8.8.8.8`) configured in `Corefile`
- Split-horizon DNS ensures `.local` (and `NETLOCAL_ROOT_DOMAIN`) names resolve to internal IPs, never leaking to public DNS
- DNSSEC validation on upstream responses protects against DNS poisoning attacks
- The dnsmasq forwarder on the host bridges host-level name resolution to the CoreDNS container
- DNS query logs for external lookups are forwarded to Loki for traffic analysis and ad-block list evaluation
- Configuration lives in `apps/localnet/barebones/dns/coredns/` Corefile and zone files
