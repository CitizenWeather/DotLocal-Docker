# Secrets Management

## TODO

- [ ] Document Vault initialization and unsealing procedure for the NetLocal environment
- [ ] Define which secrets are stored in Vault vs `.env` vs Docker secrets
- [ ] Add a `scripts/lib/rotate-secrets.sh` helper for automated secret rotation
- [ ] Configure Vault agent sidecar injection for services that need dynamic secrets

## Outline

The secrets management subsystem handles secure storage, rotation, and distribution of sensitive credentials across all NetLocal services.

- HashiCorp Vault is the primary secrets backend when enabled; it stores CA private keys, API tokens, DB passwords, and TLS certificates
- For simpler deployments, Docker secrets and `.env` variables serve as the fallback secrets mechanism
- Generated configs land in `**/config/generated/` (git-ignored) and are populated at bootstrap time by `scripts/bootstrap.sh`
- Step-CA private key material is the most critical secret and must be backed up separately from other volumes
- Vault PKI secrets engine can replace Step-CA as the `CA_APP` slot via `./scripts/lib/switch-ca.sh vault-pki`
- The `POWERDNS_API_KEY` and other service credentials in `.env` should be migrated to Vault for production deployments
