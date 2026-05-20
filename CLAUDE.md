# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

DotLocal-Docker (internally called **NetLocal**) is a self-hosted local network infrastructure stack driven entirely by Docker Compose. It provisions a complete `.local` (or custom TLD) intranet including DNS, a certificate authority, a service registry, an API gateway, databases, cache, object storage, messaging, email, and observability — all running locally via Docker.

The core principle is **swappable implementations**: each functional role (DNS, CA, gateway, database, etc.) is a named slot that can be filled by any of several concrete implementations. Slots are selected via environment variables in `.env`, and the Makefile assembles the final `docker compose` invocation from those choices.

---

## Commands

All top-level operations go through `make` from the repo root. The Makefile reads `.env` automatically (via `include .env`).

```bash
make bootstrap   # First-time setup: create Docker networks, directories, copy config templates
make up          # Start the full stack (uses docker compose with all selected app files)
make down        # Stop the stack
make restart     # down + up
make status      # docker compose ps
make logs        # Follow logs for all services
make clean       # Stop, remove volumes, wipe volumes/ directory
make health      # Run scripts/healthcheck.py — checks TCP/UDP reachability of all core services
make network-lab # Deploy the containerlab network topology (containerlab must be installed)
make switch-ca   # Wrapper for scripts/lib/switch-ca.sh — changes CA provider
make switch-cache # Wrapper for scripts/lib/switch-cache — changes cache provider
```

To switch a swappable component:
```bash
# Edit .env to change the slot variable, then restart
./scripts/lib/switch-ca.sh smallstep      # or openxpki, vault-pki
./scripts/lib/switch-cache redis-stack    # or redis
```

To register a new service in DNS:
```bash
./scripts/lib/register-service.sh <service-name> <ip-address>
```

To issue a TLS certificate:
```bash
./scripts/lib/issue-cert.sh
```

There are no test suites. The health check in `scripts/healthcheck.py` is the operational verification tool.

---

## Architecture

### Dual Docker networks

Two Docker bridge networks are created by `make bootstrap` and declared as `external` in `core/networks.yml`:

- **`localnet_backbone`** (`169.254.0.0/16`, internal) — infrastructure-only traffic: DNS resolver → registry, CA, backbone services. Services here get static IPs in the `169.254.x.x` range.
- **`localnet_default`** (`172.20.0.0/16`, internet-facing) — application traffic routed through the gateway.

Core infrastructure services (DNS, CA, registry) are attached to `localnet_backbone` with fixed IPs. Application services join `localnet_default` and are exposed through the gateway.

### Makefile composition pattern

The Makefile builds a single multi-`-f` `docker compose` command. It always includes `core/networks.yml`, then conditionally adds app compose files based on `.env` variables:

```
DNS_APP=coredns         → apps/localnet/barebones/dns/coredns/docker-compose.yml
CA_APP=smallstep        → apps/localnet/barebones/ca/smallstep/docker-compose.yml
REGISTRY_APP=powerdns   → apps/localnet/barebones/registry/powerdns/docker-compose.yml
GATEWAY_APP=caddy       → apps/localnet/barebones/gateway/caddy/docker-compose.yml
DB_APP=postgres         → apps/localnet/barebones/database/postgres/docker-compose.yml
CACHE_APP=redis         → apps/localnet/barebones/cache/redis/docker-compose.yml
...
```

Fixed (non-swappable) apps are always appended regardless of `.env`: dnsmasq forwarder, Heimdall dashboard, health endpoint, fabric router, Squid proxy, Chrony NTP, whoisd, Uptime Kuma.

### Email tiers

`EMAIL_TIER` in `.env` selects a tiered email setup:
- `1` — Mailpit only (dev trap, no real delivery)
- `2` — Stalwart full mail server + SnappyMail webmail
- `3` — adds Dovecot IMAP
- `4` — adds Postfix relay for external delivery

### Observability stack

When `ENABLE_OBSERVABILITY=true`, four services are added: Prometheus, Grafana, Loki, Promtail, Tempo. Configuration lives in `config/grafana/provisioning/` and `config/prometheus/`.

### Extensions

Optional extension packs live in `apps/extensions/`. They use Docker Compose `profiles` keyed by tags: `--profile tag-<name>`. Active extensions are listed in `EXTENSION_TAGS` in `.env`.

Current extensions:
- `iot` — Eclipse Mosquitto (MQTT) + ChirpStack LoRa server
- `chaos` — chaos engineering tools
- `labs` — experimental services
- `legacy` — older/deprecated services

### Faux providers

`apps/faux_provider/` contains local emulators of cloud or external services:
- `cloud_local` — LocalStack (AWS), Azurite (Azure), GCP emulators
- `mail_local` — local mail testing
- `registry_local` — local container registry
- `search_local` — local search engine

These are not included by default and must be manually added to `COMPOSE_FILES` or treated as standalone compose stacks.

### DNS flow

CoreDNS (on `169.254.0.2`) handles the `.local` zone from a static zone file. All other queries forward to the PowerDNS registry (on `169.254.0.3`), which stores dynamic DNS records in PostgreSQL and exposes an HTTP API. The dnsmasq forwarder (always enabled) handles host-level DNS forwarding so the host machine can resolve `.local` names.

New services are registered via `scripts/lib/register-service.sh`, which PATCHes the PowerDNS REST API.

### TLS flow

Step-CA (smallstep, on `169.254.0.4`) acts as the local root CA using ACME protocol. The gateway (Caddy or Traefik) obtains certificates automatically. The CA's ACME endpoint is `https://ca.<ROOT_DOMAIN>/acme/acme/directory`.

### Service labelling convention

Every compose service carries a `netlocal.component=<role>` Docker label (e.g. `netlocal.component=dns`, `netlocal.component=gateway`). This is used for filtering and identification but is not enforced by tooling.

### Directory layout summary

```
core/               Network definitions, containerlab topology, FRR config
apps/
  localnet/
    barebones/      Swappable implementations for each infrastructure role
    enhancements/   Optional add-ons: dashboard, observability, whois
  extensions/       Tag-activated extension packs (iot, chaos, labs, legacy)
  faux_provider/    Local emulators for cloud/external services
config/             Static service configs (Grafana, Prometheus, Keepalived, Squid)
scripts/            bootstrap.sh, healthcheck.py, and lib/ helpers
deployed/           Rendered/merged compose output (for reference or deployment)
examples/           Example deployed configurations
```

### Adding a new swappable implementation

1. Create `apps/localnet/barebones/<slot>/<impl-name>/docker-compose.yml`
2. Attach the service to the appropriate network(s) with a static backbone IP if needed
3. Add a `netlocal.component=<slot>` label
4. Add a line in the Makefile's `include_app` block for the new slot variable
5. Document the new `<SLOT>_APP` variable in `.env.example`

### Adding a new extension

1. Create `apps/extensions/<tag>/docker-compose.yml` with `profiles: ["tag-<tag>"]` on every service
2. Add `EXTENSION_TAGS` entry in `.env` to activate it
3. The Makefile automatically includes `--profile tag-<tag> -f extensions/<tag>/docker-compose.yml` for each tag in `EXTENSION_TAGS`

---

## Environment configuration

Copy `.env.example` to `.env` before running. Key variables:

| Variable | Purpose |
|---|---|
| `NETLOCAL_ROOT_DOMAIN` | The local TLD (default `net.local`) |
| `NETLOCAL_SUBNET_BACKBONE` | Backbone network CIDR (default `169.254.0.0/16`) |
| `NETLOCAL_SUBNET_DEFAULT` | Default network CIDR (default `172.20.0.0/16`) |
| `DNS_APP` | DNS resolver implementation |
| `CA_APP` | Certificate authority implementation |
| `REGISTRY_APP` | DNS registry/authoritative server |
| `GATEWAY_APP` | Reverse proxy / API gateway |
| `DB_APP` | Database |
| `CACHE_APP` | Cache |
| `STORAGE_APP` | Object storage |
| `MESSAGING_APP` | Message broker |
| `EMAIL_TIER` | Email stack tier (1–4) |
| `ENABLE_OBSERVABILITY` | `true` to enable Prometheus/Grafana/Loki stack |
| `EXTENSION_TAGS` | Space-separated list of active extension tags |
| `POWERDNS_API_KEY` | PowerDNS API key (used by register-service.sh) |

`.env` is git-ignored. Generated configs go to `**/config/generated/` (also git-ignored). Runtime data goes to `volumes/` (also git-ignored).
