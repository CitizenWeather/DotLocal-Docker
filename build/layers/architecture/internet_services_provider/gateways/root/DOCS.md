# Root Gateway

## TODO

- [ ] Document root gateway configuration for internet ingress (inbound port mappings)
- [ ] Add TLS offloading rules for externally-reachable services with public certificates
- [ ] Document integration with DDNS providers for dynamic public IP updates
- [ ] Define the boundary between root gateway (internet-facing) and the internal gateway slot

## Outline

The root gateway is the outermost ingress/egress point for internet traffic entering and leaving the NetLocal environment.

- Handles inbound internet connections destined for services exposed on the LAN (port forwarding, reverse proxy)
- Terminates TLS for publicly-reachable services using certificates from Let's Encrypt or the local CA
- Distinct from the internal gateway slot (`GATEWAY_APP`): the root gateway faces the WAN while the slot faces the LAN
- Integrates with DDNS (Dynamic DNS) to keep public DNS records updated when the WAN IP changes
- Acts as the policy enforcement point for inbound ACLs and rate limiting
- Status: basic Docker port mapping handles current ingress; a dedicated root gateway container is planned
