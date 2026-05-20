# Central Certificate Authority

## TODO

- [ ] Document the CA initialization ceremony and root key backup procedure
- [ ] Add certificate expiry alerting via Prometheus and Grafana
- [ ] Document how to switch CA implementations using `scripts/lib/switch-ca.sh`
- [ ] Create a client onboarding guide for trusting the local root CA on common OS/browser combinations

## Outline

The central certificate authority issues TLS certificates for all services within the NetLocal environment, enabling trusted HTTPS on `.local` domains.

- Swappable via `CA_APP` in `.env`; supported implementations: `smallstep` (Step-CA), `openxpki`, `vault-pki`
- Step-CA (default) runs on backbone IP `169.254.0.4` and serves an ACME endpoint at `https://ca.<ROOT_DOMAIN>/acme/acme/directory`
- The gateway (Caddy/Traefik) automatically requests certificates via ACME; no manual cert management required
- Root CA certificate must be distributed to all client devices and browsers to avoid TLS warnings
- `scripts/lib/switch-ca.sh` handles CA provider switching with service restart and config regeneration
- CA private key material is stored in `volumes/ca/` and must be backed up separately from other data
