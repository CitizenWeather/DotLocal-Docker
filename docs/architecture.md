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
       ├─ *.net.local  →  CoreDNS (169.254.0.2)
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
  └─ Requests certificate for *.net.local via ACME
       └─ Step-CA ACME endpoint: https://ca.net.local/acme/acme/directory
              └─ Issues cert signed by the NetLocal Root CA
                     └─ Root CA cert must be trusted on client machines
```

Caddy and Traefik both support automatic ACME certificate issuance. Caddy's `Caddyfile` sets `local_ca` to the Step-CA ACME URL; Traefik uses a `certificatesResolvers` block in its static config. After first boot, all `*.net.local` subdomains served through the gateway get valid TLS automatically.

---

## Makefile composition pattern

The Makefile reads `.env` on startup (via `include .env; export`) and builds a single `docker compose` command by conditionally appending `-f <path>` flags:

```makefile
COMPOSE_BASE = -f core/networks.yml

define include_app
$(if $(wildcard apps/$(1)/$(2)/docker-compose.yml),\
  -f apps/$(1)/$(2)/docker-compose.yml)
endef

COMPOSE_FILES  = $(COMPOSE_BASE)
COMPOSE_FILES += $(call include_app,dns,$(DNS_APP))
COMPOSE_FILES += $(call include_app,ca,$(CA_APP))
COMPOSE_FILES += $(call include_app,gateway,$(GATEWAY_APP))
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
  - traefik.http.routers.minio.rule=Host(`minio.net.local`)
  - traefik.http.services.minio.loadbalancer.server.port=9000
```

---

## Directory layout

```
core/                     Network definitions, containerlab topology, FRR config
apps/
  localnet/
    barebones/            Swappable implementations for each infrastructure role
      dns/                coredns/ | bind9/ | knot/
      ca/                 smallstep/ | openxpki/ | vault-pki/
      registry/           powerdns/
      gateway/            caddy/ | traefik/
      database/           postgres/ | mysql/
      cache/              redis/ | redis-stack/
      storage/            minio/ | seaweedfs/
      messages/           nats/ | nats-jetstream/ | kafka/
      policy/             opa/ | iptables/
      fabric/             default-router/ | squid/
      health/             endpoint/
      ntp/                chrony/
  extensions/             Tag-activated optional packs
    chaos/                ToxiProxy + Pumba
    iot/                  Mosquitto + ChirpStack
    legacy/               Gemini, Gopher
config/                   Static service configs (Grafana, Prometheus, Squid)
scripts/                  bootstrap.sh, healthcheck.py, lib/ helpers
deployed/                 Rendered compose output (reference only)
```
