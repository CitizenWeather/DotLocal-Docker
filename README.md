# DotLocal-Docker · NetLocal

A self-hosted, Docker Compose-driven local network stack — DNS, PKI, gateway, databases, storage, messaging, email, and observability — all running on a single machine with swappable implementations for each role.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  localnet_backbone  (169.254.0.0/16, internal)           │
│  ├─ DNS          (CoreDNS / BIND9 / Knot)                │
│  ├─ CA           (Smallstep / OpenXPKI / Vault)          │
│  └─ Registry     (PowerDNS / Knot-DNS)                   │
├──────────────────────────────────────────────────────────┤
│  localnet_default  (172.20.0.0/16, application-facing)   │
│  ├─ Gateway      (Traefik / Caddy)                       │
│  ├─ Database     (PostgreSQL / MySQL)                     │
│  ├─ Cache        (Redis / Redis Stack)                    │
│  ├─ Storage      (MinIO / SeaweedFS)                      │
│  ├─ Messages     (NATS / Kafka)                           │
│  └─ Optional: Email, Observability, Extensions            │
└──────────────────────────────────────────────────────────┘
```

Each component role is **swappable** — select the implementation via a single env var in `.env` and restart.

---

## Prerequisites

- Docker 24+ with Docker Compose v2 plugin
- 4 GB RAM minimum (8 GB recommended with observability enabled)
- Ports 80 and 443 free on the host
- Python 3.8+ for the health check script

---

## Quick Start

```bash
# 1. Clone and enter the repo
git clone https://github.com/citizenweather/dotlocal-docker.git
cd dotlocal-docker

# 2. Configure
cp .env.example .env
$EDITOR .env   # review defaults, change passwords

# 3. Bootstrap (create Docker networks, directories, config templates)
make bootstrap

# 4. Start the stack
make up

# 5. Verify
make health
```

Services are exposed at `<name>.net.local` (e.g. `traefik.net.local`, `grafana.net.local`). Point your system DNS or browser proxy at the running DNS container to resolve these names.

---

## Component Selection

Edit `.env` to choose implementations. All options ship in the repo.

| Variable | Default | Options |
|---|---|---|
| `DNS_APP` | `coredns` | `coredns`, `bind9`, `knot` |
| `CA_APP` | `smallstep` | `smallstep`, `openxpki`, `vault-pki` |
| `REGISTRY_APP` | `powerdns` | `powerdns`, `knot-dns` |
| `GATEWAY_APP` | `traefik` | `traefik`, `caddy` |
| `DB_APP` | `postgres` | `postgres`, `mysql` |
| `CACHE_APP` | `redis` | `redis`, `redis-stack` |
| `STORAGE_APP` | `minio` | `minio`, `seaweedfs` |
| `MESSAGING_APP` | `nats` | `nats`, `nats-jetstream`, `kafka` |
| `EMAIL_TIER` | `1` | `1` (Mailpit), `2` (+Stalwart), `3` (+Dovecot), `4` (+Postfix) |
| `ENABLE_OBSERVABILITY` | `false` | `true`, `false` |
| `EXTENSION_TAGS` | _(none)_ | `iot`, `chaos`, `labs`, `legacy` (space-separated) |

To switch an implementation live:

```bash
make switch-dns APP=bind9
make switch-ca APP=vault-pki
make switch-cache APP=redis-stack
```

---

## Make Targets

```
make up               Start all services
make down             Stop all services
make restart          Stop then start
make status           Show running containers
make logs             Follow all logs
make clean            Stop, remove volumes, wipe data
make bootstrap        First-time setup
make health           Check service reachability
make validate-env     Validate .env before starting
make validate-compose Validate assembled compose config
make lint             Run shellcheck + yamllint
make backup           Backup volumes to backups/
make restore          Restore: make restore BACKUP=backups/...tar.gz
make network-lab      Deploy ContainerLab network topology
make help             Show all targets with descriptions
```

---

## Directory Layout

```
apps/
  localnet/
    barebones/       Mandatory infrastructure services
      dns/           DNS implementations
      ca/            Certificate authority implementations
      registry/      DNS/DHCP registry implementations
      gateway/       Reverse proxy / API gateway
      database/      Relational database
      cache/         In-memory cache
      storage/       Object storage
      messages/      Message broker
      mail/          Email services (tiers 1-4)
      fabric/        Routing and proxy fabric
      health/        Health endpoint
      ntp/           NTP server
      status/        Uptime monitoring
    enhancements/    Optional always-on services
      dot_dashboard/ Application dashboard (Heimdall)
      observability/ Prometheus, Grafana, Loki, Tempo
      whois/         WHOIS daemon
  extensions/        Optional tagged extension packs
    iot/             MQTT + ChirpStack
    chaos/           Chaos engineering tools
    labs/            Development and security labs
    legacy/          Legacy protocol services
  faux_provider/     Cloud service emulators (LocalStack, Azurite, GCP)
config/              Shared configuration files
core/                Network definitions and ContainerLab topology
scripts/             Management scripts
```

---

## Adding a New Service Implementation

1. Create `apps/localnet/barebones/<role>/<name>/docker-compose.yml`
2. Connect the service to `localnet_backbone` (if infrastructure) or `localnet_default` (if application)
3. Add `netlocal.component=<role>` label
4. Add `restart: unless-stopped`, `healthcheck`, and `logging` blocks
5. Set the env var in `.env` and run `make restart`

See [CONTRIBUTING.md](CONTRIBUTING.md) for full details.

---

## Documentation

- [Architecture](docs/architecture.md) — network topology, Makefile composition, DNS/TLS flow
- [Troubleshooting](docs/troubleshooting.md) — common issues and how to diagnose them
- [Contributing](CONTRIBUTING.md) — how to add services, implementations, and extensions
- [Security](SECURITY.md) — security model and vulnerability reporting
- [Changelog](CHANGELOG.md) — version history

A minimal Traefik reverse proxy that routes `*.localhost` domains to Docker services — no DNS configuration required.

## How it works

`*.localhost` is natively resolved to `127.0.0.1` by modern browsers and most operating systems. Traefik watches the Docker socket and routes incoming requests based on container labels, so each service is reachable at `<name>.localhost` as soon as it starts.

## Quick start

```bash
make up
```

- Traefik dashboard: http://traefik.localhost
- Example whoami service: http://whoami.localhost

## Adding your own services

Attach your service to the `dotlocal` network and add two labels:

```yaml
services:
  myapp:
    image: myapp:latest
    networks:
      - dotlocal
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"

networks:
  dotlocal:
    external: true
```

If the service exposes multiple ports, specify which one Traefik should use:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"
  - "traefik.http.services.myapp.loadbalancer.server.port=3000"
```

## Commands

| Command        | Description                  |
|----------------|------------------------------|
| `make up`      | Start Traefik in the background |
| `make down`    | Stop all services            |
| `make restart` | Restart all services         |
| `make ps`      | Show running containers      |
| `make logs`    | Tail logs                    |

## Requirements

- Docker with Compose plugin (v2)
