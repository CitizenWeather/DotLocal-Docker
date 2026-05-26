# Architecture

## Overview

NetLocal uses two isolated Docker bridge networks and a Makefile that assembles a multi-file `docker compose` command from environment variables. Every infrastructure role is a named slot filled by a concrete implementation chosen at startup.

---

## Dual-network design

```
┌─────────────────────────────────────────────────────────────────┐
│  localnet_backbone  169.254.0.0/16  (--internal, no internet)   │
│                                                                  │
│   169.254.0.2   CoreDNS          (DNS_APP)                      │
│   169.254.0.3   PowerDNS         (REGISTRY_APP)                 │
│   169.254.0.4   Step-CA          (CA_APP)                       │
└──────────────────────────────┬──────────────────────────────────┘
                               │ services that need both networks
                               │ join both (e.g. PowerDNS needs DB)
┌──────────────────────────────┴──────────────────────────────────┐
│  localnet_default   172.20.0.0/16  (internet-facing)            │
│                                                                  │
│   Gateway (Caddy/Traefik)    — terminates TLS, routes requests  │
│   PostgreSQL / MySQL         — relational database              │
│   Redis / Redis Stack        — cache                            │
│   MinIO / SeaweedFS          — object storage                   │
│   NATS / Kafka               — messaging                        │
│   Heimdall, Uptime Kuma      — dashboard and status             │
│   Email, Webmail             — mail stack (by tier)             │
│   Observability stack        — when ENABLE_OBSERVABILITY=true   │
└─────────────────────────────────────────────────────────────────┘
```

**localnet_backbone** is created with `--internal` so containers on it have no direct internet access. It carries only infrastructure traffic between DNS, CA, registry, and the fabric router.

**localnet_default** is the application network. The gateway is the single entry point from the outside world; all services are reached through it.

---

## DNS resolution flow

```
Host machine resolver
  └─ dnsmasq forwarder (always on, port 53 on Docker host)
       ├─ *.<NETLOCAL_ROOT_DOMAIN>  →  CoreDNS (169.254.0.2)
       │     ├─ Static zone records  (ca, registrar, ns1)
       │     └─ All other .local queries  →  PowerDNS (169.254.0.3)
       │              └─ Dynamic records stored in PostgreSQL
       └─ Everything else  →  upstream public resolver (e.g. 1.1.1.1)
```

New services are added to the DNS registry via the PowerDNS HTTP API. The helper script `scripts/lib/register-service.sh` does this automatically using a `PATCH` call to the PowerDNS zones endpoint.

---

## TLS flow

```
Gateway (Caddy or Traefik)
  └─ Requests certificate for *.localnet via ACME
       └─ Step-CA ACME endpoint: https://ca.localnet/acme/acme/directory
              └─ Issues cert signed by the NetLocal Root CA
                     └─ Root CA cert must be trusted on client machines
```

Caddy and Traefik both support automatic ACME certificate issuance. Caddy's `Caddyfile` sets `local_ca` to the Step-CA ACME URL; Traefik uses a `certificatesResolvers` block in its static config. After first boot, all `*.localnet` subdomains served through the gateway get valid TLS automatically.

---

## Makefile composition pattern

The Makefile reads `.env` on startup (via `include .env; export`) and builds a single `docker compose` command by conditionally appending `-f <path>` flags:

```makefile
COMPOSE_BASE = -f stacks/core/networks.yml

define include_if
$(if $(wildcard $(1)),-f $(1))
endef

DNS_DIR     = slots/dns
GATEWAY_DIR = slots/gateway

COMPOSE_FILES  = $(COMPOSE_BASE)
COMPOSE_FILES += $(call include_if,$(DNS_DIR)/$(DNS_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(GATEWAY_DIR)/$(GATEWAY_APP)/docker-compose.yml)
# ... and so on for each swappable slot
```

Fixed services (dnsmasq, Heimdall, Uptime Kuma, Squid, Chrony, whoisd, health endpoint) are always appended regardless of `.env`.

Email tiers and the observability stack are added conditionally on `EMAIL_TIER` and `ENABLE_OBSERVABILITY`.

Extensions are added by iterating `EXTENSION_TAGS`: each tag adds `--profile tag-<tag> -f extensions/<tag>/docker-compose.yml`.

---

## Service labelling convention

Every compose service carries a Docker label `netlocal.component=<role>`:

```yaml
labels:
  - netlocal.component=dns       # or: ca, gateway, database, cache, etc.
```

This label is used for filtering with `docker ps --filter label=netlocal.component=dns` and for identification in monitoring. It is not enforced by tooling.

Gateway routing labels follow Traefik's convention (used even with Caddy for consistency):

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.minio.rule=Host(`minio.localnet`)
  - traefik.http.services.minio.loadbalancer.server.port=9000
```

---

## Directory layout

```
stacks/
  core/                   External Docker network declarations, containerlab topology
  barebones/              Fixed always-on services (dnsmasq, Heimdall, health endpoint)
  net_providers/          Email stack by tier (Mailpit, Stalwart, Dovecot, Postfix)
  net_web/                Web services (whoisd)
slots/                    Swappable implementations — one directory per role
  dns/                    coredns/ | bind9/ | knot/
  ca/                     smallstep/
  registry/               powerdns/
  gateway/                caddy/ | traefik/
  db/                     postgres/ | mysql/
  cache/                  redis/ | redis-stack/
  storage/                minio/ | seaweedfs/
  messaging/              nats/ | kafka/ | rabbitmq/ | redpanda/
  policy/                 opa/ | iptables/
  ntp/                    chrony/
  dashboard/              heimdall/ | homer/ | dashy/
  uptime/                 uptime-kuma/ | gatus/ | statping/
  identity/               (empty — Keycloak/Authentik planned)
  secrets/                (empty — Vault/Infisical planned)
  log/                    loki/
  trace/                  tempo/
build/
  layers/                 Architectural layer compose files (observability, authority, etc.)
extensions/
  tags/                   Tag-activated optional packs (chaos, iot, labs, legacy)
  as-a-service/           Standalone cloud emulator stacks (Supabase, LocalStack)
  labs/                   Lab environments (developer, data, security)
config/                   Runtime config overrides; config/generated/ is git-ignored
scripts/                  bootstrap.sh, healthcheck.py, lib/ helpers, dotlocal_lib/ Python core
```
