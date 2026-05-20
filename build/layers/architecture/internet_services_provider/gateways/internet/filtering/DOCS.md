# Internet Traffic Filtering

## TODO

- [ ] Implement DNS-based ad/malware blocking (Pi-hole or similar) as a filtering slot
- [ ] Document URL filtering rules and how to manage blocklists
- [ ] Add content filtering bypass rules for trusted internal services
- [ ] Integrate filtering logs with Loki for query analysis in Grafana

## Outline

The internet filtering layer inspects and controls outbound internet traffic, providing DNS-based and proxy-based content filtering for the local network.

- DNS-based filtering intercepts queries from the dnsmasq forwarder and blocks known malware, ad, and phishing domains
- Proxy-based filtering (via Squid) can enforce URL blocklists and content categories on HTTP/HTTPS traffic
- Allowlist and blocklist rules are managed via config files in `config/` and hot-reloaded without container restart
- Filtering statistics are exported as Prometheus metrics for visualization in Grafana
- Integrates with the firewall service to drop connections to blocked IPs at the network layer
- Status: Squid proxy is a fixed service; DNS-level filtering (Pi-hole) is an optional addon
