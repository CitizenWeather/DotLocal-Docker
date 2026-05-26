# File Storage Service

## TODO

- [ ] Deploy a file storage service (Nextcloud, Seafile, or Samba) and document slot configuration
- [ ] Configure TLS via Step-CA and register `files.<ROOT_DOMAIN>` in PowerDNS
- [ ] Document user provisioning and quota management for file storage
- [ ] Add file storage capacity metrics to the Grafana observability dashboard

## Outline

The file storage service provides a self-hosted file sharing and sync platform accessible to users on the local network.

- Nextcloud or Seafile are the candidate implementations, offering web UI, desktop sync, and mobile app access
- Files are stored on Docker volumes under `volumes/storage/file/` with configurable capacity limits
- User accounts are federated with the IAM subsystem via LDAP for single sign-on
- Accessible at `files.<ROOT_DOMAIN>` through the gateway with TLS from Step-CA
- WebDAV interface enables mounting the file storage as a network drive on client devices
- Status: optional service — must be enabled via compose file inclusion; not part of the default stack
