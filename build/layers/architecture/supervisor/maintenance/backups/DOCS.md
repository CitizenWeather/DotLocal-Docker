# Backups & Restore

## TODO

- [ ] Implement scheduled backup scripts for PostgreSQL, MinIO, and Vault data
- [ ] Document restore procedures for each service with step-by-step instructions
- [ ] Add backup verification (restore-and-verify) to the health check pipeline
- [ ] Define backup retention policy and storage location configuration

## Outline

Covers scheduled backup automation and restore procedures for all stateful services in the NetLocal stack.

- Targets stateful services: PostgreSQL (PowerDNS registry, application data), MinIO object storage, Step-CA root CA data, and Vault secrets
- Backup jobs run as Docker containers with access to the `volumes/` directory where persistent data is stored
- Backup storage destinations can be local filesystem, MinIO (S3-compatible), or remote via rclone
- Restore procedures must account for service dependency ordering (CA before gateway, DNS before applications)
- Integration with the GitOps slot (Gitea) allows config-as-code backups of compose files and `.env` templates
- Status: planned — no automated backup service is currently deployed by default
