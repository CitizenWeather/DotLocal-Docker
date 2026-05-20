# Architecture

## Network Topology

NetLocal uses two isolated Docker bridge networks:

```
Host machine
│
├── localnet_backbone  (169.254.0.0/16)
│   ├── internal: true  ← no internet access from this network
│   ├── Fixed IPs via ipv4_address
│   │   ├── 169.254.0.2  DNS server
│   │   ├── 169.254.0.3  Registry (PowerDNS)
│   │   └── 169.254.0.4  CA (Smallstep)
│   └── Services: DNS, CA, Registry (infrastructure)
│
└── localnet_default  (172.20.0.0/16)
    ├── Exposed to host via gateway on ports 80 and 443
    ├── Services: Gateway, DB, Cache, Storage, Messages, Email, Dashboard, etc.
    └── Dual-homed services (e.g. PowerDNS): connected to BOTH networks
```

The backbone network is for infrastructure services that must be reachable at stable, well-known IPs but must not themselves be able to initiate connections to the internet.

---

## Makefile Composition

The `Makefile` dynamically assembles a `docker compose` command from multiple individual compose files using `$(wildcard …)` guards. No file is included unless it exists on disk.

```
make up
  → docker compose
      -f core/networks.yml          ← always included (declares external networks)
      -f apps/localnet/barebones/dns/coredns/docker-compose.yml
      -f apps/localnet/barebones/ca/smallstep/docker-compose.yml
      -f apps/localnet/barebones/registry/powerdns/docker-compose.yml
      -f apps/localnet/barebones/gateway/traefik/docker-compose.yml
      -f apps/localnet/barebones/database/postgres/docker-compose.yml
      -f apps/localnet/barebones/cache/redis/docker-compose.yml
      -f apps/localnet/barebones/storage/minio/docker-compose.yml
      -f apps/localnet/barebones/messages/nats/docker-compose.yml
      -f apps/localnet/barebones/health/endpoint/docker-compose.yml
      -f apps/localnet/barebones/fabric/default-router/docker-compose.yml
      -f apps/localnet/barebones/fabric/squid/docker-compose.yml
      -f apps/localnet/barebones/ntp/chrony/docker-compose.yml
      -f apps/localnet/barebones/status/uptime-kuma/docker-compose.yml
      -f apps/localnet/enhancements/dot_dashboard/heimdall/docker-compose.yml
      -f apps/localnet/enhancements/whois/whoisd/docker-compose.yml
      [+ email tier, observability, extensions if configured]
      up -d
```

The key Makefile helper functions:

| Helper | Pattern | Used for |
|---|---|---|
| `barebones_app` | `apps/localnet/barebones/$(role)/$(impl)/docker-compose.yml` | Swappable components |
| `barebones_svc` | `apps/localnet/barebones/$(path)/docker-compose.yml` | Fixed barebones services |
| `enhancement_svc` | `apps/localnet/enhancements/$(path)/docker-compose.yml` | Fixed enhancement services |

---

## DNS Bootstrap Flow

```
1. make bootstrap
   └── Creates Docker networks (localnet_backbone, localnet_default)

2. make up
   └── Starts DNS container (e.g. CoreDNS at 169.254.0.2)
   └── CoreDNS serves zone files for *.net.local
   └── Starts CA (Smallstep at 169.254.0.4)
   └── Starts Registry (PowerDNS at 169.254.0.3)
   └── Starts Gateway (Traefik on :80/:443)
   └── Traefik reads Docker labels and auto-configures routing

3. Service resolves via DNS:
   Host → DNS (169.254.0.2) → returns IP of Docker container
   Container → Traefik → routes to target service by hostname
```

---

## TLS Flow

```
1. CA (Smallstep) auto-initializes with a self-signed root CA
2. scripts/lib/issue-cert.sh <hostname> uses step-cli to issue a cert
3. Gateway (Traefik/Caddy) uses the issued cert for HTTPS termination
4. Services behind the gateway communicate over internal Docker networking
5. Trust the root CA cert on your machine to avoid browser warnings:
   step certificate install $(docker exec netlocal_ca step path)/certs/root_ca.crt
```

---

## Component Dependency Graph

```
localnet_backbone
    ├─ DNS (no dependencies)
    ├─ CA (no dependencies)
    └─ Registry → depends on: Database (postgres)

localnet_default
    ├─ Gateway (depends on: Registry for DNS; CA for TLS)
    ├─ Database (no dependencies)
    ├─ Cache (no dependencies)
    ├─ Storage (no dependencies)
    ├─ Messages (no dependencies)
    ├─ Mail tier 1: Mailpit (no dependencies)
    ├─ Mail tier 2+: Stalwart (no dependencies)
    ├─ Observability: Prometheus → scrapes all services
    │                 Grafana   → reads Prometheus, Loki, Tempo
    │                 Loki      ← Promtail ships logs from Docker
    └─ Dashboard: Heimdall (no dependencies)
```

---

## Extension System

Extensions are enabled via `EXTENSION_TAGS` in `.env` (space-separated list):

```
EXTENSION_TAGS=iot chaos
```

The Makefile adds `--profile tag-<tag> -f apps/extensions/<tag>/docker-compose.yml` for each tag. Extensions use Docker Compose profiles so their services only start when explicitly activated.

Available extension packs:

| Tag | Contents |
|---|---|
| `iot` | Mosquitto (MQTT broker), ChirpStack (LoRaWAN) |
| `chaos` | Chaos engineering tools for resilience testing |
| `labs` | AI lab, dev tools (n8n, MkDocs, PlantUML), security lab |
| `legacy` | Legacy protocol servers (Gopher, Gemini) |

---

## Faux Cloud Providers

`apps/faux_provider/` contains local emulators for cloud services:

| Provider | Service | Emulates |
|---|---|---|
| `cloud_local/localstack` | LocalStack | AWS (S3, SQS, Lambda, DynamoDB, etc.) |
| `cloud_local/azurite` | Azurite | Azure Blob, Queue, Table Storage |
| `cloud_local/gcp-emulators` | GCP emulators | Pub/Sub, Spanner, Firestore |
| `mail_local/webmail/snappymail` | SnappyMail | Webmail UI |
| `registry_local` | Docker Registry | Private container registry |
| `search_local` | Search | Local search engine |

These are not part of the default stack — include them by adding the relevant compose file to the Makefile or via a local override.
