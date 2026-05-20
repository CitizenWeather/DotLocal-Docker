# DotDash - DotLocal WebUI

## TODO

- [ ] Document how to add new services to the Heimdall dashboard via the compose label convention
- [ ] Configure Uptime Kuma monitors for all core services and set alert thresholds
- [ ] Add a custom DotDash landing page that links to all active service dashboards
- [ ] Document the `netlocal.component` label values that trigger automatic dashboard registration

## Outline

DotDash is the web UI layer for the NetLocal authority, providing a unified dashboard and uptime monitoring interface for all services in the stack.

- Heimdall Application Dashboard provides a visual home page with links to all running NetLocal services, accessible at `dashboard.<ROOT_DOMAIN>`
- Uptime Kuma monitors TCP and HTTP health of all core services and provides a public status page at `status.<ROOT_DOMAIN>`
- Both services are fixed (always-included) in the compose build, regardless of slot selections
- Services self-register in the dashboard via Docker labels; `netlocal.component` and `netlocal.url` labels are read by the dashboard
- TLS for dashboard and status page is automatically provisioned by the gateway via Step-CA ACME
- Heimdall stores its config in `volumes/heimdall/` and Uptime Kuma state in `volumes/uptime-kuma/`
