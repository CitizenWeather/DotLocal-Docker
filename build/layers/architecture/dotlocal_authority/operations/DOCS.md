# Operations Plane

## TODO

- [ ] Define runbooks for common operational tasks (cert renewal, DNS record cleanup, service restart)
- [ ] Automate routine operations (log rotation, volume pruning) as scheduled jobs
- [ ] Integrate operational alerts from Prometheus into a notification channel (email, webhook)
- [ ] Document the on-call playbook for common failure scenarios

## Outline

The operations plane covers the day-to-day management and automation of the NetLocal authority, including scheduled tasks, runbooks, and operational tooling.

- Operational tasks are implemented as scripts in `scripts/lib/` and invoked via Makefile targets
- Scheduled jobs (backup, health checks, certificate renewal reminders) are managed via cron containers or the Supervisor API
- Runbooks document manual procedures for certificate rotation, DNS zone reloads, and CA key ceremony steps
- Alert routing from Prometheus/Alertmanager sends notifications when services become unhealthy or certificates near expiry
- Operational logs are forwarded to Loki and visible in the Grafana `Operations` dashboard
- Status: scripts exist for cert issuance and service registration; full automation is in progress
