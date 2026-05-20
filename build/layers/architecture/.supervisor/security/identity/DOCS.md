# Supervisor Identity & Authentication

## TODO

- [ ] Integrate an OIDC provider (Keycloak or Authentik) for Supervisor API authentication
- [ ] Document role definitions: admin, operator, tenant-user, read-only
- [ ] Configure service account tokens for automated scripts and CI/CD pipelines
- [ ] Add identity provider registration to `scripts/lib/register-service.sh`

## Outline

The supervisor identity subsystem manages authentication and authorization for the NetLocal management plane, securing access to the Supervisor API and admin interfaces.

- Supports OIDC/OAuth2 for human operator login; service accounts use short-lived tokens issued by Step-CA
- Role-based access control (RBAC) defines permissions at three levels: global admin, tenant operator, and read-only viewer
- Integrates with the broader IAM subsystem in `dotlocal_authority/iam/` for consistent identity across the stack
- API tokens are rotated automatically; long-lived credentials are stored in Vault via the secrets subsystem
- All login events and permission checks are emitted as audit log entries, forwarded to Loki
- Status: in design — currently the stack uses no authentication on management interfaces
