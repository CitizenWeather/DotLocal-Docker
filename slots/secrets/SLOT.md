# Slot: secrets

**Variable:** `SECRETS_APP`
**Network:** `localnet_backbone` (static IP `169.254.0.6`) + `localnet_default`
**Label:** `netlocal.component=secrets`

> **Status:** No implementations exist yet. Set `SECRETS_APP=` (blank) to skip this slot.

## Contract

An implementation must:
- Expose a KV secrets API at `https://vault.${NETLOCAL_ROOT_DOMAIN}`
- Support dynamic secret generation (database credentials, TLS certs, etc.)
- Provide an audit log of all secret access
- Support token/AppRole/OIDC authentication methods

### Minimum API surface (Vault HTTP API compatible)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/v1/secret/data/<path>` | Read a secret |
| `POST` | `/v1/secret/data/<path>` | Write a secret |
| `DELETE` | `/v1/secret/data/<path>` | Delete a secret |
| `POST` | `/v1/auth/token/lookup-self` | Validate a token |

## Required environment variables

| Variable | Purpose |
|---|---|
| `VAULT_ROOT_TOKEN` | Bootstrap root token (rotate immediately after init) |

## Planned implementations

| Name | Image | Notes |
|---|---|---|
| `vault` | `hashicorp/vault:latest` | De facto standard; requires unseal on restart |
| `infisical` | `infisical/infisical:latest` | Developer-friendly UI; auto-unseal |

## Dependencies

- Requires the **ca** slot (TLS for secrets endpoints)
- Can integrate with the **identity** slot for OIDC auth method

## Adding an implementation

1. Create `slots/secrets/<impl-name>/docker-compose.yml`
2. Attach to `localnet_backbone` (static IP `169.254.0.6`) and `localnet_default`
3. Add label `netlocal.component=secrets`
4. Set `SECRETS_APP=<impl-name>` in `.env`
