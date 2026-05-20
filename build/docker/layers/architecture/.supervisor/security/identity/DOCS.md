# Supervisor Identity & Authentication

## TODO

- [ ] Integrate an OIDC provider (Keycloak or Authentik) for Supervisor API authentication
- [ ] Document role definitions: admin, operator, tenant-user, read-only
- [ ] Configure service account tokens for automated scripts and CI/CD pipelines
- [ ] Add identity provider registration to `scripts/lib/register-service.sh`
- [ ] Evaluate additional provider support: LDAP/Active Directory, SAML 2.0, and local user database fallback

## Outline

The supervisor identity subsystem manages authentication and authorization for the NetLocal management plane, securing access to the Supervisor API and admin interfaces.

- Supports OIDC/OAuth2 for human operator login (primary); service accounts use short-lived tokens issued by Step-CA
- Additional identity provider options under consideration:
  - **LDAP / Active Directory** — for organisations with existing directory infrastructure
  - **SAML 2.0** — for enterprise SSO integrations
  - **Local user database** — lightweight fallback for isolated or air-gapped deployments with no external IdP
- Role-based access control (RBAC) defines permissions at three levels: global admin, tenant operator, and read-only viewer
- Integrates with the broader IAM subsystem in `dotlocal_authority/iam/` for consistent identity across the stack
- API tokens are rotated automatically; long-lived credentials are stored in Vault via the secrets subsystem
- All login events and permission checks are emitted as audit log entries, forwarded to Loki
- Status: in design — currently the stack uses no authentication on management interfaces
