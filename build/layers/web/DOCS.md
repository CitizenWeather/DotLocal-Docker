# Web Layer

## TODO

- [ ] Document TLS termination configuration for Caddy and Traefik gateway slots
- [ ] Add examples of virtual host routing rules for `.local` domain services
- [ ] Document automatic ACME certificate issuance flow from Step-CA
- [ ] List all HTTP services exposed through the web layer and their default ports

## Outline

The web layer handles HTTP/HTTPS routing, TLS termination, and reverse proxying for all services accessible via the `localnet_default` network.

- Gateway slot is swappable: `GATEWAY_APP=caddy` or `GATEWAY_APP=traefik` controls which reverse proxy handles HTTP traffic
- TLS certificates are automatically obtained from the local Step-CA ACME endpoint at `https://ca.<ROOT_DOMAIN>/acme/acme/directory`
- Services on `localnet_default` (`172.20.0.0/16`) are exposed through the gateway via virtual host routing on `<service>.<ROOT_DOMAIN>`
- Caddy uses a `Caddyfile` config; Traefik uses dynamic provider configs — both live in `config/` subdirectories
- The Heimdall dashboard and Uptime Kuma health monitor are fixed services always included in the web layer
- Web layer integrates with the DNS registry (PowerDNS) to resolve internal `.local` names
