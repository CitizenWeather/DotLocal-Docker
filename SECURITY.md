# Security Policy

## Scope

DotLocal-Docker is designed for **local and LAN use only**. It is not intended to be exposed to the public internet. Services running in this stack bind to link-local (`169.254.x.x`) or private (`172.20.x.x`) addresses by default.

Do not expose the PowerDNS API, Step-CA ACME endpoint, Vault, or any management interface to an untrusted network without additional hardening.

## Supported versions

Security fixes are applied to the `main` branch. There are no stable release branches at this time.

| Branch | Supported |
|--------|-----------|
| `main` | Yes |
| Others | No |

## Reporting a vulnerability

If you discover a security vulnerability, please **do not open a public GitHub issue**.

Instead, report it privately via GitHub's built-in security advisory feature:

1. Go to the [Security tab](https://github.com/CitizenWeather/DotLocal-Docker/security) of the repository.
2. Click **"Report a vulnerability"**.
3. Describe the issue, steps to reproduce, and potential impact.

You will receive an acknowledgement within 5 business days. We aim to triage and patch confirmed vulnerabilities within 30 days of disclosure.

## Security considerations for operators

- Change all default credentials (API keys, passwords) in `.env` before first use.
- The `POWERDNS_API_KEY` in `.env` grants full DNS write access — treat it as a secret.
- Step-CA's root certificate is generated locally; distribute it only to trusted clients.
- The `localnet_backbone` network is marked `internal: true` — do not attach internet-facing containers to it.
- Vault (if enabled) should be initialised and unsealed by a human operator; do not automate unseal in production.
- Review extension packs before enabling them; they may open additional ports or introduce third-party images.
