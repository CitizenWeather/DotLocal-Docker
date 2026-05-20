# Supervisor API

## TODO

- [ ] Define REST API endpoints for stack management operations (start, stop, status)
- [ ] Document authentication mechanism for API access (token, mTLS)
- [ ] Implement health and readiness endpoints consumed by Uptime Kuma
- [ ] Add OpenAPI/Swagger spec generation to the build process

## Outline

The Supervisor API provides a management plane HTTP interface for controlling and querying the NetLocal stack programmatically.

- Exposes REST endpoints for service lifecycle management, status queries, and configuration updates
- Secured by the supervisor identity subsystem; API tokens or mutual TLS are the intended auth mechanisms
- Consumed by the dashboard, CLI tooling, and automated health checks
- Integrates with the observability stack to surface metrics and log queries via API
- Planned feature — currently a placeholder for future management automation
