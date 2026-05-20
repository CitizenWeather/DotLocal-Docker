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

Two Docker bridge networks are created by `make bootstrap` and declared as `external` in `stacks/core/networks.yml`:

- **`localnet_backbone`** (`169.254.0.0/16`, internal) — infrastructure-only traffic: DNS resolver → registry, CA, backbone services. Services here get static IPs in the `169.254.x.x` range.
- **`localnet_default`** (`172.20.0.0/16`, internet-facing) — application traffic routed through the gateway.

Core infrastructure services (DNS, CA, registry) are attached to `localnet_backbone` with fixed IPs. Application services join `localnet_default` and are exposed through the gateway.

### Makefile composition pattern

The Makefile builds a single multi-`-f` `docker compose` command. It always includes `stacks/core/networks.yml`, then conditionally adds compose files based on `.env` variables. Each swappable slot has a base directory defined in the Makefile; the selected implementation is appended as a subdirectory:

```
GATEWAY_APP=caddy     → stacks/barebones/net_root/intranet_service_provider/base/gateway/caddy/docker-compose.yml
REGISTRY_APP=powerdns → stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core/powerdns/docker-compose.yml
POLICY_APP=opa        → stacks/barebones/net_root/localnet_authority/policy/opa/docker-compose.yml
CACHE_APP=redis       → stacks/net_providers/cache_provider/redis/docker-compose.yml
MESSAGING_APP=nats    → build/layers/barebones/infrastructure/messages/nats/docker-compose.yml
...
```

Files are included via `include_if` which silently skips missing implementations. Fixed (non-swappable) services are always appended: dnsmasq forwarder, Heimdall dashboard, health endpoint, Chrony NTP, whoisd, Uptime Kuma.

### Email tiers

`EMAIL_TIER` in `.env` selects a tiered email setup:
- `1` — Mailpit only (dev trap, no real delivery)
- `2` — Stalwart full mail server + SnappyMail webmail
- `3` — adds Dovecot IMAP
- `4` — adds Postfix relay for external delivery

### Observability stack

When `ENABLE_OBSERVABILITY=true`, services are added from `build/layers/architecture/.supervisor/maintenance/observability/`. Configuration for Loki, Promtail, and Tempo lives alongside their compose files in `slots/<service>/config/`.

### Extensions

Optional extension packs live in the top-level `extensions/` directory. The Makefile expects `extensions/<tag>/docker-compose.yml` for each active tag in `EXTENSION_TAGS`. Standalone extension stacks (labs, technologies, native modules) live in `stacks/extensions/`.

Cloud/service emulators (LocalStack, Supabase, etc.) are in `extensions/as-a-service/` and are not auto-included — use them as standalone compose stacks.

### DNS flow

CoreDNS (on `169.254.0.2`) handles the `.local` zone from a static zone file. All other queries forward to the PowerDNS registry (on `169.254.0.3`), which stores dynamic DNS records in PostgreSQL and exposes an HTTP API. The dnsmasq forwarder (always enabled) handles host-level DNS forwarding so the host machine can resolve `.local` names.

New services are registered via `scripts/lib/register-service.sh`, which PATCHes the PowerDNS REST API.

### TLS flow

Step-CA (smallstep, on `169.254.0.4`) acts as the local root CA using ACME protocol. The gateway (Caddy or Traefik) obtains certificates automatically. The CA's ACME endpoint is `https://ca.<ROOT_DOMAIN>/acme/acme/directory`.

### Service labelling convention

Every compose service carries a `netlocal.component=<role>` Docker label (e.g. `netlocal.component=dns`, `netlocal.component=gateway`). This is used for filtering and identification but is not enforced by tooling.

### Directory layout summary

```
stacks/
  core/             External networks declaration, containerlab topology
  barebones/        Core infrastructure compose files (gateway, registry, policy, health, dashboards)
  net_providers/    Provider-role services (mail, cache, DNS registrar, hosting)
  net_web/          Web-tier services (whois, full/light web profiles)
  extensions/       Standalone extension stacks (labs, technologies, native modules, hardware)
build/
  layers/           Architectural layer compose files and configs
    authority/      CA, NTP, identity services
    barebones/      Infrastructure primitives (messaging: NATS, Kafka, etc.)
    architecture/   Supervisor plane (observability, tenancy, secrets, backups)
  profiles/         Build profiles (out-of-the-box configurations)
extensions/         Tag-activated extension packs (referenced by EXTENSION_TAGS in .env)
  as-a-service/     Cloud/service emulators (Supabase, LocalStack, etc.) — standalone stacks
  labs/             Lab environments (developer, data, security)
  technologies/     Specialist technology stacks (LoRaWAN, mesh, cellular, etc.)
config/             Runtime configuration overrides and generated output
  generated/        Git-ignored; written at runtime by services
scripts/
  bootstrap.sh      First-time setup (creates Docker networks, runtime dirs)
  healthcheck.py    Operational health check
  lib/              Operational helpers (switch-ca.sh, switch-cache, switch-dns.sh, register-service.sh, issue-cert.sh)
  utils/            Utility scripts (backup, restore, device provisioning)
docs/               User-facing documentation
```

### Adding a new swappable implementation

1. Identify the slot's `*_DIR` variable in the Makefile (e.g. `GATEWAY_DIR`)
2. Create `<SLOT_DIR>/<impl-name>/docker-compose.yml`
3. Attach the service to the appropriate network(s) with a static backbone IP if needed
4. Add a `netlocal.component=<slot>` label
5. Set `<SLOT>_APP=<impl-name>` in `.env` — the Makefile picks it up automatically

If the slot has no `*_DIR` entry yet, add one in the Makefile's "Swappable slot base paths" section.

### Adding a new extension (tag-activated)

1. Create `extensions/<tag>/docker-compose.yml`
2. Add the tag to `EXTENSION_TAGS` in `.env`
3. The Makefile automatically includes `-f extensions/<tag>/docker-compose.yml` for each active tag

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
