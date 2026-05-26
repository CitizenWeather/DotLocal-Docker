# Slot: ca

| **Variable:** | **Network:**                                  | **Label:**              |
|---------------|-----------------------------------------------|-------------------------|
| `CA_APP`      | `localnet_backbone` (static IP `169.254.0.4`) | `netlocal.component=ca` |

## Contract

An implementation must:

- Expose an ACME directory endpoint (used by the gateway for automatic TLS)
- Accept ACME challenges on HTTPS (port 443) or HTTP (port 80)
- Default ACME URL: `https://ca.${NETLOCAL_ROOT_DOMAIN}/acme/acme/directory`
- Expose a health endpoint reachable from the backbone network

## Required environment variables

| Variable               | Purpose                               |
|------------------------|---------------------------------------|
| `NETLOCAL_ROOT_DOMAIN` | Domain for the CA's ACME endpoint URL |

## Available implementations

| Name                        | Image                      |
|-----------------------------|----------------------------|
| `smallstep` *(recommended)* | `smallstep/step-ca:0.27.0` |
| `openxpki`                  | `openxpki/openxpki:latest` |
| `vault-pki`                 | `hashicorp/vault:latest`   |

## Adding a new implementation

1. Create `slots/ca/<impl-name>/docker-compose.yml`
2. Attach to `localnet_backbone` with static IP `169.254.0.4`
3. Add label `netlocal.component=ca`
4. Set `CA_APP=<impl-name>` in `.env`
