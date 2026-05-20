# Operations

Day-to-day operational tasks for a running NetLocal stack.

---

## Stack management

```bash
make up          # start all services (detached)
make down        # stop all services
make restart     # stop then start
make status      # list running containers with health and ports
make logs        # follow logs for all services (Ctrl-C to exit)
make clean       # stop containers and delete all volume data (destructive)
```

`make status` and `make logs` include the full set of composed files, so they show services from whichever slot implementations and extensions are active.

---

## Health check

```bash
make health
```

Runs `scripts/healthcheck.py`, which tests TCP or UDP reachability for every core service:

| Service | Host | Port | Protocol |
|---|---|---|---|
| DNS | `ca.localnet` | 53 | UDP |
| CA | `ca.localnet` | 443 | TCP |
| Registry | `registrar.localnet` | 8081 | TCP |
| Gateway | `traefik.localnet` | 443 | TCP |
| PostgreSQL | `postgres` | 5432 | TCP |
| Redis | `redis` | 6379 | TCP |
| MinIO | `minio` | 9000 | TCP |
| NATS | `nats` | 4222 | TCP |
| DNS Forwarder | `dnsmasq` | 53 | UDP |
| Dashboard | `dashboard.localnet` | 80 | TCP |
| Health endpoint | `health.localnet` | 80 | TCP |

Exits with code `0` if all checks pass, `1` if any fail. Each line shows `✅` or `❌`.

---

## Switching implementations

Any swappable slot can be changed by editing `.env` and restarting. Convenience wrappers exist for common swaps:

```bash
# Switch certificate authority
./scripts/lib/switch-ca.sh smallstep     # or: openxpki, vault-pki

# Switch cache
./scripts/lib/switch-cache.sh redis-stack  # or: redis

# Switch DNS resolver
./scripts/lib/switch-dns.sh coredns      # or: bind9
```

Each wrapper updates the relevant `*_APP` variable in `.env` using `sed`, then runs `make down && make up`.

To switch any other slot manually:

```bash
# Edit .env, e.g.: GATEWAY_APP=traefik
make restart
```

> Switching a stateful service (database, CA) without migrating its data volume will result in an empty store on the new implementation. Plan migrations accordingly.

---

## Registering a service in DNS

To make a new service reachable by name on the local network, register it with PowerDNS:

```bash
./scripts/lib/register-service.sh <service-name> <ip-address>
```

Example:

```bash
./scripts/lib/register-service.sh myapp 172.20.0.10
# Creates an A record: myapp.localnet → 172.20.0.10
```

The script sends a `PATCH` request to the PowerDNS HTTP API using `POWERDNS_API_KEY` from `.env`. The record is available immediately — no restart needed.

---

## Issuing a TLS certificate

To issue a certificate for a service using the local CA:

```bash
./scripts/lib/issue-cert.sh <domain>
```

Example:

```bash
./scripts/lib/issue-cert.sh myapp.localnet
# Produces: myapp.localnet.crt and myapp.localnet.key
```

This uses `step-cli` to request a certificate from Step-CA via ACME. The gateway issues its own certificates automatically — this is only needed for services that manage their own TLS.

**Prerequisite:** `step-cli` must be installed on the host. Install it from [smallstep.com/docs/step-cli](https://smallstep.com/docs/step-cli/).

---

## Viewing logs for a specific service

```bash
# All services
make logs

# A specific service
docker compose logs -f netlocal_caddy
docker compose logs -f netlocal_postgres

# Last 100 lines from the DNS service
docker logs --tail=100 netlocal_dns
```

---

## Inspecting running containers

```bash
# All NetLocal containers
docker ps --filter name=netlocal

# Filter by role label
docker ps --filter label=netlocal.component=gateway
docker ps --filter label=netlocal.component=dns
```

---

## Backup and restore

Data volumes live under `volumes/` in the repository root. Back them up with standard tools:

```bash
# Stop the stack before backing up to ensure consistency
make down

# Archive the volumes directory
tar -czf netlocal-backup-$(date +%Y%m%d).tar.gz volumes/

# Restart
make up
```

To restore, stop the stack, replace the `volumes/` directory with the backup, and restart.

> The CA state (including the root key) is stored in the `ca_data` named volume. Back this up separately and keep it secure — anyone with the root key can issue trusted certificates for your domain.
