# Local Identity Services

## TODO

- [ ] Deploy an LDAP directory (OpenLDAP or Lldap) for LAN device and user authentication
- [ ] Integrate local identity with the dot local authority IAM for unified user management
- [ ] Configure RADIUS authentication for Wi-Fi and wired 802.1X network access
- [ ] Document how to provision local user accounts and assign them to service-level groups

## Outline

Local identity services provide authentication and directory services for devices and users accessing the LAN, separate from the broader IAM subsystem.

- LDAP directory stores LAN user accounts, device credentials, and group memberships
- RADIUS server (FreeRADIUS) enables 802.1X authentication for Wi-Fi access points and managed switches
- Integrates with the dotlocal authority IAM via LDAP federation for single-user-store management
- Local identity data is backed by PostgreSQL via the `DB_APP` slot for persistence and replication
- Used by the IRL access control service for physical access management
- Status: optional service — not enabled by default; required for enterprise-style network access control
