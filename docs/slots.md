# Swappable Slots

Each infrastructure role in NetLocal is a **slot** — a named position in the stack that can be filled by any of its listed implementations. You select an implementation by setting the corresponding variable in `.env`.

The Makefile includes `slots/<slot>/<impl>/docker-compose.yml` for each slot, using the `include_if` helper that silently skips the file if it does not exist.

---

## DNS resolver

**Variable:** `DNS_APP`  
**Backbone IP:** `169.254.0.2`  
**Role:** Resolves the `.local` zone from a static zone file; forwards all other queries to the DNS registry.

| Implementation | Image | Notes |
|---|---|---|
| `coredns` *(recommended)* | `coredns/coredns:1.11.1` | Zone file at `slots/dns/coredns/config/zones/`; Corefile configures forwarding to PowerDNS |
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

> **Note:** Only one implementation exists today. `REGISTRY_APP` is effectively a fixed service until a second alternative is added.

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

---

## Email tiers

Email is configured differently from slots. Rather than selecting one of several mutually-exclusive implementations, `EMAIL_TIER` stacks services progressively:

| Tier | Services started |
|---|---|
| `1` | Mailpit (dev trap only, no real delivery) |
| `2` | Stalwart mail server + SnappyMail webmail |
| `3` | tier 2 + Dovecot IMAP |
| `4` | tier 3 + Postfix relay (enables real outbound delivery) |

This is intentionally different from the slot model — each tier is a superset of the one below it.

---

## Slot dependencies

Some slots depend on others being present and healthy. The gateway and DNS resolver cannot function until their dependencies are running.

```
db  ──────────────► registry ──► dns
                                  │
ca ────────────────────────────► gateway
```

| Slot | Depends on |
|---|---|
| `registry` | `db` (stores DNS records in PostgreSQL) |
| `dns` | `registry` (forwards non-local queries to it) |
| `gateway` | `ca` (obtains TLS certificates via ACME) |
| `ca` | `dns` (CA hostname must resolve) |

Docker's `depends_on` does not span multi-file compose assemblies. Start order matters: `db` and `ca` should be healthy before `registry`, `dns`, and `gateway` are started. `make up` brings everything up together; use `make health` to verify after startup.

---

## Switching slots

To switch any slot:

```bash
make switch SLOT=<slot> IMPL=<impl>
# e.g.:
make switch SLOT=gateway IMPL=traefik
make switch SLOT=messaging IMPL=kafka
```

Or edit `.env` directly and run `make restart`.

The `make switch` command validates that the target compose file exists before making any changes.

---

## Adding a new slot implementation

See `slots/<role>/SLOT.md` for the interface contract each implementation must satisfy (required ports, labels, environment variables, network attachment).

1. Create `slots/<role>/<impl-name>/docker-compose.yml`
2. Attach to the correct network(s) — see `SLOT.md` for the role
3. Add `netlocal.component=<role>` label
4. Set `<ROLE>_APP=<impl-name>` in `.env`
5. Run `make validate-slots` to confirm the path resolves before `make up`

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
