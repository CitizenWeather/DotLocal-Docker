# VPN Site-to-Site Tunnels

## TODO

- [ ] Document WireGuard site-to-site tunnel setup between two NetLocal instances
- [ ] Define IP addressing scheme for cross-site backbone connectivity
- [ ] Configure cross-site DNS resolution so `<host>.<site>.local` resolves between sites
- [ ] Add site-to-site tunnel health checks with latency and packet loss metrics

## Outline

The site-to-site VPN addon creates persistent encrypted tunnels between two or more NetLocal deployments, extending the local network across physical locations.

- Uses WireGuard for high-performance, low-overhead encrypted tunnels between sites
- Each site allocates a unique subnet within the `169.254.0.0/16` backbone range to avoid IP conflicts
- Cross-site DNS resolution is achieved by adding forwarding rules in CoreDNS for each remote site's zone
- FRR routing (via the containerlab topology) can advertise cross-site routes dynamically using BGP
- TLS certificates issued by the local Step-CA are trusted across sites when the root CA cert is distributed
- Status: optional addon — requires WireGuard kernel module on all hosts
