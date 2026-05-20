# Internet Proxies

## TODO

- [ ] Document Squid proxy configuration options (ACLs, SSL bumping, cache settings)
- [ ] Add WPAD/PAC file auto-configuration so LAN clients discover the proxy automatically
- [ ] Document transparent vs explicit proxy modes and how to switch between them
- [ ] Export Squid access logs to Loki for traffic analysis

## Outline

The internet proxies layer provides forward proxy services for outbound HTTP/HTTPS traffic from the local network to the internet.

- Squid is the primary fixed-service forward proxy, always included in the stack regardless of slot choices
- Squid config lives in `config/squid/` and supports both explicit (HTTP CONNECT) and transparent interception modes
- SSL bumping (TLS inspection) is optional and requires distributing the local CA certificate to clients
- The proxy enforces outbound URL filtering rules aligned with the internet filtering layer
- Clients on `localnet_default` can use `proxy.<ROOT_DOMAIN>:3128` as their HTTP proxy address
- Proxy cache reduces repeated bandwidth usage for common HTTP assets and package downloads
