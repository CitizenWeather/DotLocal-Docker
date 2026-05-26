# Slot: dns

**Variable:** `DNS_APP`
**Network:** `localnet_backbone` (static IP `169.254.0.2`)
**Label:** `netlocal.component=dns`

## Contract

An implementation must:

- Listen on UDP/TCP port 53
- Resolve the `${NETLOCAL_ROOT_DOMAIN}` zone from a local zone file
- Forward all other queries to the DNS registry at `169.254.0.3`
- Mount zone config from `./config/` (read-only)

## Required environment variables

| Variable               | Purpose                |
|------------------------|------------------------|
| `NETLOCAL_ROOT_DOMAIN` | The local TLD to serve |

## Available implementations

| Name                      | Image                    |
|---------------------------|--------------------------|
| `coredns` *(recommended)* | `coredns/coredns:1.11.1` |
| `bind9`                   | `ubuntu/bind9:latest`    |
| `knot`                    | `cznic/knot:latest`      |

## Adding a new implementation

1. Create `slots/dns/<impl-name>/docker-compose.yml`
2. Attach to `localnet_backbone` with static IP `169.254.0.2`
3. Add label `netlocal.component=dns`
4. Set `DNS_APP=<impl-name>` in `.env`
