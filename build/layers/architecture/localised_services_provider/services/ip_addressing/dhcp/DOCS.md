# DHCP Server

## TODO

- [ ] Deploy a DHCP server container (Kea or dnsmasq DHCP) and document pool configuration
- [ ] Configure DHCP to set the local CoreDNS IP (`169.254.0.2`) as the DNS server for LAN clients
- [ ] Implement DHCP reservation records linked to IPAM for static-by-MAC assignments
- [ ] Forward DHCP lease events to the event bus for automatic DNS registration

## Outline

The DHCP server automatically assigns IP addresses, gateway, and DNS settings to devices joining the local network.

- Preferred implementation is Kea DHCP for its REST API, allowing dynamic lease management and IPAM integration
- DHCP pools are defined per VLAN/subnet and align with the `NETLOCAL_SUBNET_DEFAULT` range
- DNS server option (`option 6`) is set to the CoreDNS backbone IP so clients resolve `.local` names automatically
- Static reservations tie MAC addresses to fixed IPs and are synchronized with IPAM records
- Lease events are published to the event bus to trigger automatic DNS `A` record creation in PowerDNS
- Status: optional service — Docker containers use Docker DNS by default; DHCP is needed for physical LAN devices
