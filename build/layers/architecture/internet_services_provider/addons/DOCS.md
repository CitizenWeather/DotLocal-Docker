# ISP Addons

## TODO

- [ ] Enumerate available ISP-layer addons and document each with a one-line description
- [ ] Document how to enable/disable individual addons via `.env` or extension tags
- [ ] Test addon compatibility with both Caddy and Traefik gateway implementations
- [ ] Add addon health checks to `scripts/healthcheck.py`

## Outline

ISP addons provide optional supplementary services layered on top of the internet-facing infrastructure of the NetLocal stack.

- Addons extend the ISP layer with capabilities such as ad-blocking (Pi-hole), traffic shaping, DPI inspection, or captive portal support
- Each addon is deployed as a separate compose file and activated via `EXTENSION_TAGS` or explicit compose file inclusion
- Addons sit between the root gateway and the internal network, intercepting or enriching traffic flows
- Configuration is service-specific and lives in `config/` subdirectories adjacent to each addon compose file
- Addons must not conflict with core ISP services (DNS, firewall, NAT egress) and should be documented with dependency notes
- Status: placeholder — specific addon implementations are defined in the extensions layer
