# Gitea GitOps Slot

## TODO

- [ ] Write compose file for Gitea under the `gitops` slot path
- [ ] Configure Gitea to use the local PostgreSQL instance for persistence
- [ ] Document webhook integration with CI/CD pipeline (Drone, Woodpecker)
- [ ] Add DNS registration for `git.<ROOT_DOMAIN>` via register-service.sh

## Outline

The Gitea slot provides a self-hosted Git service for GitOps workflows within the NetLocal environment.

- Gitea runs as the `gitops` slot implementation, accessible at `git.<ROOT_DOMAIN>` through the gateway
- Uses PostgreSQL (the `DB_APP` slot) for metadata storage and local filesystem for repository data
- Integrates with the CI/CD slot (Drone or Woodpecker) via webhook triggers on push events
- TLS certificate issued automatically by Step-CA via the gateway's ACME integration
- Acts as the source-of-truth for NetLocal stack configuration when GitOps mode is enabled
- Forgejo is an alternative drop-in implementation for this slot
