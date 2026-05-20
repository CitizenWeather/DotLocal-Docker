# Web Hosting Provider Layer

## TODO

- [ ] Define the web hosting slot schema (static site hosting, PHP apps, Node.js apps)
- [ ] Document how to add a new hosted site via gateway virtual host configuration
- [ ] Integrate automatic TLS provisioning for hosted sites via Step-CA ACME
- [ ] Create an example hosted site compose template for quick deployment

## Outline

The web hosting provider layer enables self-hosted websites and web applications to be served through the NetLocal gateway with automatic TLS and DNS registration.

- Hosted services are registered in PowerDNS and exposed through the gateway (Caddy/Traefik) as virtual hosts
- Supports static sites (Nginx/Apache containers), dynamic apps (Node.js, PHP-FPM), and proxied upstream services
- Each hosted site gets a subdomain under `<site>.<ROOT_DOMAIN>` with TLS from Step-CA
- Volume mounts provide persistent web root storage under `volumes/webhosting/<site-name>/`
- Integrates with the object storage slot (MinIO) for media and asset hosting via S3-compatible APIs
- Status: functional via manual gateway config; automated site provisioning tooling is planned
