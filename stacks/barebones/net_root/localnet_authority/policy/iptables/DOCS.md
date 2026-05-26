# iptables / nftables firewall slot

Slot path: `slots/policy/iptables/`

Set `POLICY_APP=iptables` in `.env` to activate.

## What it does

Applies a **default-deny ingress** host firewall at stack startup using nftables (preferred) or iptables (fallback). Rules are applied once by a privileged one-shot container that runs with `NET_ADMIN` + `NET_RAW` capabilities in host networking mode.

### Default allow-list

| Protocol | Ports | Purpose |
|----------|-------|---------|
| TCP | 22, 53, 80, 443 | SSH, DNS, HTTP, HTTPS |
| UDP | 53, 67, 68, 123 | DNS, DHCP, NTP |

Inbound traffic from Docker bridge networks (backbone, default, NAT) is always allowed. ICMP is always allowed. All other inbound traffic is dropped.

FORWARD is default-deny; intra-stack and cross-network gateway traffic is explicitly allowed.

## Customising the allow-list

Override `FIREWALL_ALLOW_TCP` and `FIREWALL_ALLOW_UDP` in `.env`:

```env
FIREWALL_ALLOW_TCP=22 53 80 443 8080
FIREWALL_ALLOW_UDP=53 123
```

## Requirements

The host kernel must have nftables (`nft`) or iptables available. The container installs both from Alpine apk at startup.
