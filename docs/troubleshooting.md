# Troubleshooting

## Quick Diagnostics

```bash
make status          # see which containers are running and their health
make health          # check TCP/UDP reachability of all core services
make logs            # follow all logs (Ctrl-C to stop)
docker compose logs <service-name>   # logs for one service
docker inspect netlocal_<service>    # full container metadata
```

---

## Common Issues

### "make up" fails immediately

**Check 1 — `.env` is missing:**
```bash
ls -la .env          # should exist
cp .env.example .env # if missing
make validate-env    # check for invalid values
```

**Check 2 — Docker networks don't exist:**
```bash
docker network ls | grep localnet
# if missing:
make bootstrap
```

**Check 3 — Compose config is invalid:**
```bash
make validate-compose   # will show the first YAML error
```

---

### Container exits immediately / restarts in a loop

```bash
docker compose logs <service-name>   # look at the last few lines before exit
docker inspect --format='{{.State.ExitCode}}' netlocal_<service>
```

Common causes:
- Missing config file that's bind-mounted as `:ro` — run `make bootstrap` to generate templates
- Incorrect credentials in `.env` — check the service's required env vars
- Port already in use — check `sudo ss -tlnp | grep :<port>`

---

### DNS not resolving `*.net.local`

```bash
# Check that the DNS container is running and healthy
docker ps | grep netlocal_dns

# Test resolution from inside the default network
docker run --rm --network localnet_default alpine nslookup ca.net.local 169.254.0.2

# Test from host (requires DNS_APP container to publish port 53, or use a resolver trick)
dig @169.254.0.2 ca.net.local
```

Point your system DNS resolver or `/etc/hosts` at the DNS container's backbone IP (`169.254.0.2` by default).

---

### TLS certificate not trusted / browser warning

```bash
# Get the root CA cert
docker exec netlocal_ca step ca root > /tmp/netlocal-root-ca.crt

# Trust it on Linux (Debian/Ubuntu):
sudo cp /tmp/netlocal-root-ca.crt /usr/local/share/ca-certificates/netlocal-root-ca.crt
sudo update-ca-certificates

# Trust it on macOS:
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/netlocal-root-ca.crt

# Trust it in Chrome/Firefox: Settings → Certificates → Import
```

---

### Traefik not routing to a service

```bash
# Check the Traefik dashboard
open http://traefik.net.local   # or http://localhost:8080 if dashboard is port-published

# Verify the service container is running
docker ps | grep <service-name>

# Check labels on the container
docker inspect netlocal_<service> | grep -A20 Labels
```

A service must have these labels for Traefik to pick it up:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<name>.rule=Host(`<name>.net.local`)"
```

---

### Health check fails for a specific service

```bash
# Run make health to see which services are failing
make health

# Manually test TCP connectivity
docker run --rm --network localnet_default alpine nc -zv <container-name> <port>

# Check Docker healthcheck status
docker inspect --format='{{json .State.Health}}' netlocal_<service> | jq .
```

---

### Volumes ran out of space

```bash
# Check volume usage
docker system df -v

# Remove unused volumes (be careful — this deletes data!)
docker volume prune

# Full cleanup (removes all NetLocal data):
make clean
```

---

### Backup and Restore

```bash
# Create a backup (stops the stack, tarballs volumes/ + .env)
make backup
# Output: backups/YYYY-MM-DD_HHMMSS.tar.gz

# Restore (stops the stack, extracts the tarball)
make restore BACKUP=backups/2025-01-01_120000.tar.gz
make up
```

---

## Network Debugging

```bash
# Inspect backbone network
docker network inspect localnet_backbone

# Inspect default network
docker network inspect localnet_default

# List all containers and their networks
docker ps --format '{{.Names}}: {{.Networks}}'

# Ping between containers on the same network
docker exec netlocal_<svc1> ping -c 3 netlocal_<svc2>

# Check iptables rules (if fabric/iptables extension is active)
docker exec netlocal_router iptables -t nat -L -n
```

---

## Useful Log Patterns

```bash
# Errors only across all services
make logs 2>&1 | grep -i error

# CoreDNS query log
docker logs netlocal_dns 2>&1 | grep -v "^$"

# Traefik access log
docker logs netlocal_traefik 2>&1 | grep '"GET\|POST'

# PostgreSQL slow queries
docker logs netlocal_postgres 2>&1 | grep "duration:"
```
