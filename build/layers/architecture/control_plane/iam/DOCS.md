# Identity & Access Management (IAM)

## TODO

- [ ] Deploy an OIDC provider (Keycloak or Authentik) as the IAM implementation
- [ ] Document user provisioning and group management workflows
- [ ] Integrate IAM with the gateway for automatic SSO on all `.local` services
- [ ] Configure Step-CA to issue user certificates backed by the IAM identity store

## Outline

The IAM subsystem provides centralized identity, authentication, and authorization services for all users and services within the NetLocal authority.

- Supports OIDC/OAuth2 and LDAP protocols; Keycloak and Authentik are the primary candidate implementations
- Single Sign-On (SSO) integration with the gateway (Caddy/Traefik) enables transparent auth for all `.local` web services
- Service-to-service authentication uses short-lived mTLS certificates issued by Step-CA, bound to IAM-defined service accounts
- User directory and group memberships are stored in the IAM provider's own database, backed by PostgreSQL
- IAM events (login, token issuance, permission change) are published to the event bus for audit logging
- Integrates with the localised services provider identity slot for LAN device and user authentication
