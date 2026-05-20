# Changelog

All notable changes to DotLocal-Docker (NetLocal) will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Swappable slot architecture for DNS, CA, gateway, database, cache, storage, messaging, and email
- Dual Docker network topology: `localnet_backbone` (169.254.0.0/16) and `localnet_default` (172.20.0.0/16)
- CoreDNS + PowerDNS registry combo for `.local` zone resolution
- Step-CA (smallstep) as default ACME certificate authority
- Caddy and Traefik as swappable gateway implementations
- MinIO object storage slot
- NATS and Kafka as swappable messaging implementations
- Tiered email stack: Mailpit (tier 1) → Stalwart + SnappyMail (tier 2) → Dovecot (tier 3) → Postfix relay (tier 4)
- Observability stack: Prometheus, Grafana, Loki, Promtail, Tempo
- Heimdall dashboard and Uptime Kuma status page (always-on)
- Chrony NTP and whoisd as fixed services
- `make bootstrap` / `make up` / `make health` operational workflow
- `scripts/lib/register-service.sh` for dynamic DNS registration via PowerDNS API
- `scripts/lib/issue-cert.sh` for ACME certificate issuance
- `scripts/lib/switch-ca.sh` and `scripts/lib/switch-cache` for live slot switching
- `scripts/healthcheck.py` for TCP/UDP reachability verification
- Extension tag system: IoT (LoRaWAN, mesh), chaos engineering, legacy protocol packs
- Containerlab network topology support (`make network-lab`)
- OPA policy engine slot
- OpenVault (Vault) secrets management integration
- Full documentation suite under `docs/`

---

## [0.1.0] — Initial private release

- Repository scaffolding and Makefile composition pattern
- Core network and slot definitions

---

[Unreleased]: https://github.com/CitizenWeather/DotLocal-Docker/compare/HEAD
