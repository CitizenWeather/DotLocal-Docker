# VPN Client

## TODO

- [ ] Deploy a WireGuard or OpenVPN client container and document `.env` configuration variables
- [ ] Document how to import VPN provider credentials (Mullvad, ProtonVPN, custom)
- [ ] Configure split tunneling rules so `.local` traffic bypasses the VPN tunnel
- [ ] Add VPN connection health check (check external IP) to `scripts/healthcheck.py`

## Outline

The VPN client addon routes outbound internet traffic from the NetLocal stack through an external VPN provider for privacy or geolocation purposes.

- Supports WireGuard and OpenVPN client modes; WireGuard is preferred for performance
- VPN credentials and server configs are stored as Docker secrets or in `config/vpn/client/`
- Split tunneling ensures that `.local` domain traffic and backbone communications bypass the VPN interface
- Containers can opt in to VPN routing by attaching to the VPN client network namespace
- Kill switch rules drop internet traffic if the VPN tunnel goes down, preventing IP leaks
- Status: optional addon — not included in the default stack; must be explicitly enabled
