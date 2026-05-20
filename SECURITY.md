# Security Policy

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Report vulnerabilities privately via GitHub's [security advisory feature](https://github.com/citizenweather/dotlocal-docker/security/advisories/new) or by emailing the maintainers directly. Include a description of the issue, steps to reproduce, and potential impact. You'll receive a response within 5 business days.

---

## Security Model

NetLocal is designed for **local development and lab environments**, not production internet-facing deployments. The security model reflects this:

### Trust Boundaries

```
[Host machine]
   │
   ├── localnet_backbone (169.254.0.0/16)
   │     internal: true — no external routing
   │     Contains: DNS, CA, Registry
   │     Static IPs assigned to each service
   │
   └── localnet_default (172.20.0.0/16)
         application-facing
         Exposed via gateway on ports 80/443
         Contains: all application services
```

- The backbone network has `internal: true` in Docker — containers on it cannot reach the internet.
- The default network connects to the host and (by default) allows external traffic through the gateway.
- Services on the backbone that also need to serve application traffic are dual-homed (e.g., PowerDNS).

### TLS

- The local CA (Smallstep / OpenXPKI / Vault) issues certificates for `*.net.local` services.
- Trust the root CA certificate on your local machine to avoid browser warnings.
- Certificates are stored in the `ca_data` volume and are **not** committed to git.

### Secrets

- **Never** commit `.env` to git (it's gitignored).
- All credentials are environment-variable-driven — change defaults before use.
- For team use, consider a secrets manager (Vault, 1Password Secrets Automation, etc.) instead of a shared `.env` file.
- The `volumes/` directory contains persistent data — protect it with appropriate filesystem permissions.

### Container Hardening

Services are configured with:
- `security_opt: no-new-privileges:true` — prevents privilege escalation
- Minimal capabilities (`cap_drop: ALL` where feasible)
- Read-only root filesystems where the service supports it
- Non-root users where images provide them

### Image Provenance

- All images are pulled from official Docker Hub repositories or trusted vendors.
- Versions are pinned to specific tags in the compose files.
- Run `docker scout cves` or Trivy locally to scan for known CVEs before deploying.

---

## Known Limitations

- This stack is **not hardened for internet exposure** — do not publish the gateway ports publicly without additional security review.
- The `localnet_default` network is accessible from the host by default — restrict with host firewall rules if needed.
- Admin UIs (Grafana, Traefik dashboard, MinIO console) have default or `.env`-configured credentials — change them before use.
