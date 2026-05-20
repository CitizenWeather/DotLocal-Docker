# Local Proxy Addons

## TODO

- [ ] Document available local proxy addons (SOCKS5, HTTP CONNECT, transparent proxy)
- [ ] Add per-service proxy bypass rules for traffic that should not be proxied
- [ ] Configure automatic proxy discovery via WPAD for LAN clients
- [ ] Document how local proxies interact with the VPN client and site-to-site addons

## Outline

Local proxy addons provide LAN-internal proxy services for clients on the `localnet_default` network, complementing the internet-facing Squid proxy.

- SOCKS5 proxy support enables clients to tunnel arbitrary TCP connections through the local network
- Transparent proxy mode intercepts HTTP traffic without requiring client-side proxy configuration
- Proxy bypass rules ensure internal `.local` traffic is never inadvertently routed through the proxy
- Integrates with the VPN addons to allow proxied traffic to traverse VPN tunnels
- Config files for local proxy addons live in `config/` alongside the corresponding compose file
- Status: Squid covers the primary proxy use case; local-only proxy addons are optional extensions
