# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- `.env.example` fully populated with all variables, defaults, and inline documentation
- `README.md` with architecture overview, quick start, component table, and directory layout
- `CONTRIBUTING.md` with step-by-step guides for adding implementations, extensions, and fixed services
- `SECURITY.md` with security model, trust boundaries, and vulnerability reporting process
- `CHANGELOG.md` (this file)
- `docs/architecture.md` — network topology, Makefile composition, DNS/TLS flow
- `docs/troubleshooting.md` — common issues and diagnostics
- `scripts/validate-env.sh` — pre-flight `.env` validation with allowlist checking
- `scripts/backup.sh` — timestamped backup of `volumes/` and `.env`
- `scripts/restore.sh` — restore from a backup tarball
- `config/prometheus/alerts/core.yml` — Prometheus alert rules for core services
- `.editorconfig` — consistent editor settings across the project
- `.yamllint` — YAML linting configuration
- `.pre-commit-config.yaml` — pre-commit hooks (shellcheck, yamllint, trailing whitespace)
- `.github/workflows/ci.yml` — CI pipeline: compose validation, shellcheck, yamllint
- `.github/workflows/security.yml` — Trivy filesystem scan and secret scanning
- Makefile: `validate-env`, `validate-compose`, `lint`, `backup`, `restore`, `help` targets
- Makefile: `switch-dns`, `switch-ca`, `switch-cache` now accept `APP=<name>` argument
- Docker `healthcheck`, `restart: unless-stopped`, `logging`, and `security_opt` added to core services

### Fixed
- Makefile paths updated to match actual directory structure (`apps/localnet/barebones/…`)
- `gateway/traefik/docker-compose.yml` — was incorrectly containing PowerDNS content; replaced with proper Traefik config
- `enhancements/observability/docker-compose.yml` — was incorrectly containing PowerDNS content; replaced with Grafana + Loki + Promtail + Tempo
- `enhancements/dot_dashboard/docker-compose.yml` — was incorrectly containing PowerDNS content; replaced with placeholder
- `cache/redis/docker-compose.yml` — was empty; replaced with proper Redis config (with memory limits and healthcheck)
- Makefile `MESSAGING_APP` now correctly maps to `messages/` directory (was `messaging/`)
- Makefile `-include .env` (with leading dash) silently skips missing `.env` instead of failing
- Extensions path corrected to `apps/extensions/<tag>/` (was `extensions/<tag>/`)

---

## [0.1.0-alpha] — Initial implementation

### Added
- Dual Docker network topology: `localnet_backbone` (infrastructure) + `localnet_default` (applications)
- Swappable DNS implementations: CoreDNS, BIND9, Knot
- Swappable CA implementations: Smallstep, OpenXPKI, Vault PKI
- Swappable registry implementations: PowerDNS, Knot-DNS
- Swappable gateway implementations: Traefik, Caddy
- Swappable database implementations: PostgreSQL, MySQL
- Swappable cache implementations: Redis, Redis Stack
- Swappable storage implementations: MinIO, SeaweedFS
- Swappable message broker implementations: NATS, NATS JetStream, Kafka
- Tiered email: Mailpit (tier 1), Stalwart (tier 2), Dovecot (tier 3), Postfix relay (tier 4)
- Optional observability stack: Prometheus, Grafana, Loki, Promtail, Tempo
- Extension packs: IoT (MQTT/ChirpStack), chaos, labs, legacy
- Cloud service emulators: LocalStack, Azurite, GCP emulators
- `scripts/bootstrap.sh` — network and directory setup
- `scripts/healthcheck.py` — TCP/UDP reachability checks for core services
- `scripts/lib/switch-{ca,cache,dns}.sh` — live component switching
- `scripts/lib/register-service.sh` — PowerDNS REST API service registration
- `scripts/lib/issue-cert.sh` — TLS certificate issuance via step-cli
- Makefile-driven orchestration with compose file assembly
- ContainerLab network simulation topology
