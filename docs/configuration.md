# Configuration Reference

All configuration is done via `.env` in the repository root. Copy `.env.example` to `.env` before running `make bootstrap`.

The Makefile reads `.env` automatically via `include .env; export`, so all variables are available to Make targets and to any subprocess they invoke.

---

## Network

| Variable | Default | Description |
|---|---|---|
| `NETLOCAL_ROOT_DOMAIN` | `net.local` | Local TLD. All services are reachable at `<name>.<NETLOCAL_ROOT_DOMAIN>`. Change this if you want a different TLD (e.g. `home.arpa`). |
| `NETLOCAL_SUBNET_BACKBONE` | `169.254.0.0/16` | CIDR for the internal backbone Docker network. Core infrastructure services get static IPs within this range. |
| `NETLOCAL_SUBNET_DEFAULT` | `172.20.0.0/16` | CIDR for the application Docker network. App services get dynamic IPs within this range and are exposed through the gateway. |

---

## Swappable slots

| Variable | Default | Options | Description |
|---|---|---|---|
| `DNS_APP` | `coredns` | `coredns`, `bind9`, `knot` | DNS resolver for the `.local` zone. |
| `CA_APP` | `smallstep` | `smallstep`, `openxpki`, `vault-pki` | Certificate authority for ACME TLS. |
| `REGISTRY_APP` | `powerdns` | `powerdns` | Authoritative nameserver for dynamic DNS records. |
| `GATEWAY_APP` | `caddy` | `caddy`, `traefik` | Reverse proxy / TLS terminator. |
| `DB_APP` | `postgres` | `postgres`, `mysql` | Relational database. |
| `CACHE_APP` | `redis-stack` | `redis`, `redis-stack` | Cache layer. |
| `STORAGE_APP` | `minio` | `minio`, `seaweedfs` | S3-compatible object storage. |
| `MESSAGING_APP` | `nats-jetstream` | `nats`, `nats-jetstream`, `kafka` | Message broker. |
| `POLICY_APP` | `opa` | `opa`, `iptables` | Network/request policy enforcement. |

See [Swappable Slots](slots.md) for details on each option.

---

## Email

| Variable | Default | Description |
|---|---|---|
| `EMAIL_TIER` | `1` | Email stack depth. `1` = Mailpit dev trap only. `2` = Stalwart + SnappyMail webmail. `3` = adds Dovecot IMAP. `4` = adds Postfix relay for real outbound delivery. See [Email Tiers](email.md). |

---

## Observability

| Variable | Default | Description |
|---|---|---|
| `ENABLE_OBSERVABILITY` | `false` | Set to `true` to start Prometheus, Grafana, Loki, Promtail, and Tempo. See [Observability](observability.md). |

---

## Extensions

| Variable | Default | Description |
|---|---|---|
| `EXTENSION_TAGS` | *(empty)* | Space-separated list of extension pack tags to activate. Each tag enables the corresponding `apps/extensions/<tag>/docker-compose.yml`. Example: `EXTENSION_TAGS=iot chaos`. See [Extensions](extensions.md). |

---

## Secrets

These must be changed from their defaults in any environment reachable by others.

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_PASSWORD` | `changeme` | Password for the `netlocal` PostgreSQL user. Used by PostgreSQL, PowerDNS, and ChirpStack. |
| `POWERDNS_API_KEY` | `changeme` | API key for the PowerDNS HTTP API. Used by `register-service.sh` to add DNS records. |
| `MINIO_ROOT_USER` | `admin` | MinIO root user (S3 access key). |
| `MINIO_ROOT_PASSWORD` | `changeme` | MinIO root password (S3 secret key). |
| `CHIRPSTACK_DB_PASSWORD` | `changeme` | Database password for ChirpStack (only needed when `iot` extension is active). |

---

## Git-ignored files

These are never committed:

| Path | Contents |
|---|---|
| `.env` | Live configuration (contains secrets) |
| `volumes/` | All runtime data (databases, CA state, object storage) |
| `**/config/generated/` | Rendered configs produced at startup |
| `acme.json` | Traefik ACME certificate store |
| `deployed/` | Rendered compose output |
