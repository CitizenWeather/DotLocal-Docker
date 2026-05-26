# NetLocal Setup Guide

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Docker Engine | 24+ | With Compose v2 plugin (`docker compose`) |
| GNU Make | any | Pre-installed on most Linux systems |
| Python 3 | 3.8+ | Required only for `make health` |
| containerlab | any | Optional; required only for `make network-lab` |

### Checking prerequisites

```bash
docker compose version   # must show v2.x
make --version
python3 --version
```

### Installing Docker Compose v2

If `docker compose` (with a space) is not available, install the plugin:

```bash
# Debian / Ubuntu
sudo apt-get install docker-compose-plugin

# Fedora / RHEL
sudo dnf install docker-compose-plugin
```

---

## First boot

### 1. Clone the repository

```bash
git clone <repo-url> DotLocal-Docker
cd DotLocal-Docker
```

### 2. Configure your environment

```bash
cp .env.example .env
```

Open `.env` and review the defaults. At minimum, change all `changeme` secrets before running the stack in any environment that could be reached by others. See [Configuration Reference](docs/configuration.md) for every variable.

### 3. Bootstrap the infrastructure

```bash
make bootstrap
```

This creates:
- Two Docker bridge networks (`localnet_backbone` and `localnet_default`)
- Required volume directories under `volumes/`
- Config file directories for gateway and extensions
- A `Caddyfile` template if the gateway config directory is empty

### 4. Start the stack

```bash
make up
```

The Makefile reads your `.env`, assembles a `docker compose` command with the correct set of `-f` files for your chosen implementations, and starts everything in detached mode.

### 5. Verify health

```bash
make health
```

The health check script tests TCP/UDP reachability for every core service. All items should show a checkmark. If any fail, run `make logs` to investigate.

---

## Host DNS configuration

For your host machine to resolve `*.<NETLOCAL_ROOT_DOMAIN>` names (default `.localnet`), point your system resolver at the dnsmasq forwarder container (which listens on the Docker host at port 53).

### Linux (systemd-resolved)

```bash
# Create a drop-in for the localnet domain
sudo mkdir -p /etc/systemd/resolved.conf.d
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/netlocal.conf
[Resolve]
DNS=127.0.0.1
Domains=~.localnet
EOF
sudo systemctl restart systemd-resolved
```

### Linux (plain /etc/resolv.conf)

Add to the top of `/etc/resolv.conf`:
```
nameserver 127.0.0.1
search .localnet
```

### macOS

```bash
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/.localnet
```

> Note: Link-local address ranges (169.254.x.x) may require additional routing on macOS and Windows. Prefer running NetLocal on a native Linux host.

---

## Trusting the root CA certificate

After first boot, Step-CA generates a self-signed root certificate. Browsers and tools need to trust this root to avoid TLS warnings.

### Export the root certificate

```bash
# From inside the CA container
docker exec netlocal_ca step certificate inspect /home/step/certs/root_ca.crt --format pem > root_ca.crt
```

### Install on Linux

```bash
sudo cp root_ca.crt /usr/local/share/ca-certificates/netlocal-root.crt
sudo update-ca-certificates
```

### Install on macOS

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root_ca.crt
```

### Install in Firefox

Firefox uses its own certificate store. Go to **Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import** and import `root_ca.crt`.

---

## Switching implementations

Change the relevant `*_APP` variable in `.env`, then restart:

```bash
# Example: switch from CoreDNS to BIND9
# Edit .env: DNS_APP=bind9
make restart
```

Convenience wrappers are available for the most common swaps:

```bash
./scripts/lib/switch-ca.sh smallstep      # or openxpki, vault-pki
./scripts/lib/switch-cache.sh redis-stack # or redis
./scripts/lib/switch-dns.sh coredns       # or bind9
```

See [Swappable Slots](docs/slots.md) for all available implementations.

---

## Stopping and cleaning up

```bash
make down      # stop all containers (preserves volumes)
make clean     # stop containers and delete all volume data
```

> `make clean` is destructive. All database data, CA state, and object storage will be lost.
