# iptables policy slot

Slot path: `stacks/barebones/net_root/localnet_authority/policy/iptables/`

To activate: set `POLICY_APP=iptables` in `.env`.

Enforces network policy via iptables rules applied to the Docker bridge networks.
Requires `NET_ADMIN` and `NET_RAW` capabilities.
