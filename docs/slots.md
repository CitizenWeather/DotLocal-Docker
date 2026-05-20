# Swappable Slots

Each infrastructure role in NetLocal is a **slot** — a named position in the stack that can be filled by any of its listed implementations. You select an implementation by setting the corresponding variable in `.env`.

The Makefile includes `apps/localnet/barebones/<slot>/<impl>/docker-compose.yml` for each slot, using the `include_app` helper that silently skips the file if it does not exist.

---

## DNS resolver

**Variable:** `DNS_APP`  
**Backbone IP:** `169.254.0.2`  
**Role:** Resolves the `.local` zone from a static zone file; forwards all other queries to the DNS registry.

| Implementation | Image | Notes |
|---|---|---|
| `coredns` *(recommended)* | `coredns/coredns:1.11.1` | Zone file at `apps/localnet/barebones/dns/coredns/config/zones/`; Corefile configures forwarding to PowerDNS |
| `bind9` | `ubuntu/bind9:latest` | Named zones; heavier but battle-tested |
| `knot` | `cznic/knot:latest` | High-performance authoritative DNS |

Switch with: `./scripts/lib/switch-dns.sh <impl>`

---

## Certificate authority

**Variable:** `CA_APP`  
**Backbone IP:** `169.254.0.4`  
**Role:** Issues TLS certificates via ACME. The gateway obtains wildcard certs automatically.

| Implementation | Image | Notes |
|---|---|---|
| `smallstep` *(recommended)* | `smallstep/step-ca:0.27.0` | ACME support, fast startup, zero config; ACME endpoint: `https://ca.localnet/acme/acme/directory` |
| `openxpki` | `openxpki/openxpki:latest` | Enterprise CA with web UI and workflows |
| `vault-pki` | `hashicorp/vault:latest` | HashiCorp Vault PKI secrets engine; requires Vault initialisation |

Switch with: `./scripts/lib/switch-ca.sh <impl>`

---

## DNS registry

**Variable:** `REGISTRY_APP`  
**Backbone IP:** `169.254.0.3`  
**Role:** Authoritative nameserver for dynamic records. Stores records in PostgreSQL and exposes a REST API for programmatic registration.

| Implementation | Image | Notes |
|---|---|---|
| `powerdns` *(only option)* | `powerdns/pdns-auth:latest` | PostgreSQL backend; HTTP API at port 8081 for `register-service.sh` |

---

## Gateway

**Variable:** `GATEWAY_APP`  
**Network:** `localnet_default`  
**Role:** Reverse proxy that terminates TLS and routes `*.<NETLOCAL_ROOT_DOMAIN>` requests to upstream services.

| Implementation | Image | Ports | Notes |
|---|---|---|---|
| `caddy` *(recommended)* | `caddy:latest` | 80, 443 | Automatic HTTPS via `local_ca` directive; reads `config/Caddyfile` |
| `traefik` | `traefik:v3.0` | 80, 443, 8080 | Docker-label-based routing; ACME via `certificatesResolvers` |

---

## Database

**Variable:** `DB_APP`  
**Network:** `localnet_default`  
**Role:** Relational database for PowerDNS registry records and any services that need SQL storage.

| Implementation | Image | Port | Notes |
|---|---|---|---|
| `postgres` *(recommended)* | `postgres:16-alpine` | 5432 | Used by PowerDNS and ChirpStack; credentials from `POSTGRES_PASSWORD` |
| `mysql` | `mysql:8.0` | 3306 | Alternative for MySQL-only applications |

---

## Cache

**Variable:** `CACHE_APP`  
**Network:** `localnet_default`  
**Role:** In-memory key-value store. Both implementations expose the same Redis wire protocol on port 6379.

| Implementation | Image | Notes |
|---|---|---|
| `redis-stack` *(recommended)* | `redis/redis-stack:latest` | Adds RedisJSON, RediSearch, RedisTimeSeries, and RedisGraph modules |
| `redis` | `redis:7-alpine` | Minimal footprint; standard Redis only |

Switch with: `./scripts/lib/switch-cache.sh <impl>`

---

## Object storage

**Variable:** `STORAGE_APP`  
**Network:** `localnet_default`  
**Role:** S3-compatible blob storage.

| Implementation | Image | Ports | Notes |
|---|---|---|---|
| `minio` *(recommended)* | `minio/minio:latest` | 9000 (API), 9001 (console) | Full S3 API; web console at `minio.localnet:9001`; credentials from `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` |
| `seaweedfs` | `chrislusf/seaweedfs:latest` | 9000 | Distributed; lighter weight; S3-compatible mode with `-s3` flag |

---

## Messaging

**Variable:** `MESSAGING_APP`  
**Network:** `localnet_default`  
**Role:** Message broker for async communication between services.

| Implementation | Image | Port | Notes |
|---|---|---|---|
| `nats-jetstream` *(recommended)* | `nats:2.10-alpine` | 4222 | JetStream enabled (`-js`); persistent streams stored in `messaging_data` volume |
| `nats` | `nats:2.10-alpine` | 4222 | Core NATS only; no persistence |
| `kafka` | `confluentinc/cp-kafka:latest` | 9092 | Includes Zookeeper; high-throughput event streaming |

---

## Policy

**Variable:** `POLICY_APP`  
**Network:** `localnet_default`  
**Role:** Network or request policy enforcement.

| Implementation | Image | Port | Notes |
|---|---|---|---|
| `opa` *(recommended)* | `openpolicyagent/opa:latest` | 8181 | Open Policy Agent; REST API for Rego policy evaluation |
| `iptables` | `alpine:latest` | — | Host-level iptables rules applied via NET_ADMIN container |

---

## Fixed (non-swappable) services

These are always included regardless of `.env`:

| Service | Image | Role |
|---|---|---|
| dnsmasq forwarder | `andyshinn/dnsmasq` | Host-level DNS forwarding |
| Heimdall | `linuxserver/heimdall` | Service portal / dashboard |
| Health endpoint | `alpine` | Simple HTTP health probe |
| Default router | `alpine` | IP forwarding between networks |
| Squid | `sameersbn/squid` | HTTP proxy cache |
| Chrony | `cturra/ntp` | NTP time server |
| whoisd | `local/whoisd` | Whois lookup service |
| Uptime Kuma | `louislam/uptime-kuma` | Service status monitor |
