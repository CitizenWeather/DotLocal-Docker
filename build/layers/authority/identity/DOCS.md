# Identity Authority

## TODO

- [ ] Select and deploy an identity authority (Keycloak, Authentik, or Dex) as the root IdP
- [ ] Document federation between the identity authority and downstream IAM/LDAP services
- [ ] Configure the gateway to delegate authentication to the identity authority via OIDC
- [ ] Add the identity authority to the backbone network with a static IP

## Outline

The identity authority is the root identity provider for the entire NetLocal stack, issuing tokens and delegating to downstream identity services.

- Acts as the OIDC/OAuth2 authorization server for all human and service authentication in the stack
- Federates with the localised services provider LDAP directory for LAN user authentication
- Issues ID tokens and access tokens consumed by the gateway (forward auth), Supervisor API, and application services
- Root CA integration enables certificate-based authentication as an alternative to password login
- All token issuance and revocation events are audit-logged and forwarded to Loki
- Status: planned — identity authority selection and deployment is pending the IAM subsystem design
