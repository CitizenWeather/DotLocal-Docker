# DotLocal _(Docker)_

A self-hosted local network infrastructure stack driven entirely by Docker Compose. NetLocal provisions a complete `.local` intranet — DNS, certificate authority, service registry, API gateway, database, cache, object storage, messaging, email, and observability — running entirely on your machine or LAN.

The core design is **swappable implementations**: every infrastructure role is a named slot that can be filled by any of several concrete implementations. You choose implementations in `.env`; the Makefile assembles the right `docker compose` invocation automatically.

## Quick start

```bash
cp .env.example .env        # configure your stack
make bootstrap              # create Docker networks and directories
make up                     # start the full stack
make health                 # verify all services are reachable
```

## Default service endpoints

Once running, services are available at `<name>.<NETLOCAL_ROOT_DOMAIN>` (default `.localnet`):

| Service | URL | Notes |
|---|---|---|
| Dashboard | `http://dashboard.localnet` | Heimdall service portal |
| Gateway | `https://*.localnet` | Caddy / Traefik reverse proxy |
| CA | `https://ca.localnet` | Step-CA ACME endpoint |
| Registry | `http://registrar.localnet:8081` | PowerDNS API |
| Object storage | `http://minio.localnet:9000` | MinIO S3 API |
| Storage console | `http://minio.localnet:9001` | MinIO web UI |
| Status page | `http://status.localnet` | Uptime Kuma |
| Mail (tier 1) | `http://mail.localnet` | Mailpit dev trap |
| Grafana | `http://grafana.localnet` | When observability enabled |

## Commands

| Command | Description |
|---|---|
| `make bootstrap` | First-time setup: Docker networks, directories, config templates |
| `make up` | Start the full stack |
| `make down` | Stop the stack |
| `make restart` | Stop and restart |
| `make status` | Show running containers |
| `make logs` | Follow logs for all services |
| `make health` | Check TCP/UDP reachability of all core services |
| `make clean` | Stop, remove containers and volumes |
| `make network-lab` | Deploy containerlab network topology |
| `make switch-ca` | Switch certificate authority implementation |
| `make switch-cache` | Switch cache implementation |
| `make plan` | Show what `apply` would do (zero-downtime diff vs running stack) |
| `make apply` | Reconcile running stack to desired state — tier-by-tier, drain + health-gated, with snapshot + rollback |
| `make rollback` | Roll back to the previous snapshot (or `make rollback SNAPSHOT=<timestamp>`) |
| `make apply-status` | Show the most recent apply result |
| `make apply-history` | List past applies |

## Zero-downtime upgrades

When you change `.env`, bump an image tag, or swap a slot, run `make plan` to see
the diff (Terraform-style), then `make apply` to roll it out. The apply pipeline
reconciles the stack tier-by-tier (backbone → data → identity → gateway → apps →
observability), invokes per-service drain hooks for stateful services (postgres,
redis, rabbitmq, minio), gates each tier on container health, and snapshots the
prior state under `volumes/_apply/<timestamp>/` so `make rollback` can restore it.

Slot switches (`./scripts/lib/switch.sh`, `make switch-cache`, etc.) automatically
route through `dotlocal apply`, so you no longer lose every TCP connection on a
slot swap. Set `SWITCH_LEGACY=1` to fall back to the old `make down && make up`
behaviour.

## Documentation

- [Architecture](docs/architecture.md) — dual-network design, DNS and TLS flows, Makefile composition
- [Swappable Slots](docs/slots.md) — all implementations available for each role
- [Configuration Reference](docs/configuration.md) — every `.env` variable explained
- [Email Tiers](docs/email.md) — selecting your email stack (dev trap → full delivery)
- [Observability](docs/observability.md) — Prometheus, Grafana, Loki, Tempo
- [Extensions](docs/extensions.md) — IoT, chaos engineering, legacy protocol packs
- [Operations](docs/operations.md) — health checks, DNS registration, cert issuance, switching
- [Extending the Stack](docs/extending.md) — adding new implementations and extensions
- [Setup Guide](SETUP.md) — prerequisites and first-boot walkthrough

## Requirements

- Docker Engine 24+ with Compose v2 plugin
- GNU Make
- Linux host (or WSL2 / Docker Desktop on macOS/Windows with caveats for link-local networking)
