# Git Server Slot

## TODO

- [ ] Write compose files for Gitea and Forgejo as slot implementations
- [ ] Document initial admin setup and organization/team structure
- [ ] Configure SSH access at `git.<ROOT_DOMAIN>:22` and HTTPS at `https://git.<ROOT_DOMAIN>`
- [ ] Set up mirroring from external GitHub repositories for offline development

## Outline

The git server slot provides a self-hosted Git repository hosting service for the local developer environment.

- Swappable slot: Gitea and Forgejo are the supported implementations (Forgejo is the community fork of Gitea)
- Accessible via HTTPS at `git.<ROOT_DOMAIN>` and SSH at port 22 through the gateway
- PostgreSQL (via `DB_APP` slot) stores repository metadata, users, and issues
- Repository data is persisted in `volumes/git/repositories/`
- Integrates with the CI/CD slot via webhook registration on repository push and PR events
- User authentication federated with the IAM subsystem via OIDC; LDAP group sync for org/team membership
