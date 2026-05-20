# Slot: identity

**Variable:** `IDENTITY_APP`
**Network:** `localnet_backbone` (static IP `169.254.0.5`) + `localnet_default`
**Label:** `netlocal.component=identity`

> **Status:** No implementations exist yet. Set `IDENTITY_APP=` (blank) to skip this slot.

## Contract

An implementation must:
- Expose an OIDC discovery document at `https://id.${NETLOCAL_ROOT_DOMAIN}/.well-known/openid-configuration`
- Issue JWT tokens for services and users within the local stack
- Support OAuth2 authorization code flow for browser-based service auth
- Be reachable from the gateway for auth delegation (forward auth / JWT verification)
- Expose an admin UI for user and client management

## Required environment variables

| Variable | Purpose |
|---|---|
| `IDENTITY_ADMIN_PASSWORD` | Initial admin credentials |
| `NETLOCAL_ROOT_DOMAIN` | Used to construct redirect URIs and issuer URL |

## Planned implementations

| Name | Image | Notes |
|---|---|---|
| `keycloak` | `quay.io/keycloak/keycloak:latest` | Full-featured; Realm-based multi-tenancy |
| `authentik` | `ghcr.io/goauthentik/server:latest` | Modern UI; LDAP/SAML/OIDC; flow-based |
| `dex` | `dexidp/dex:latest` | Lightweight OIDC connector; delegates to upstream IdPs |

## Dependencies

- Requires the **db** slot (user/client storage)
- Requires the **ca** slot (TLS for OIDC endpoints)
- Gateway should be configured to delegate auth via forward-auth to this service

## Adding an implementation

1. Create `slots/identity/<impl-name>/docker-compose.yml`
2. Attach to `localnet_backbone` (static IP `169.254.0.5`) and `localnet_default`
3. Add label `netlocal.component=identity`
4. Set `IDENTITY_APP=<impl-name>` in `.env`
