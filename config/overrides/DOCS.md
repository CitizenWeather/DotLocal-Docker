# Config Overrides

## TODO

- [ ] Document the override merge order and precedence rules (base config vs override)
- [ ] Add validation to `make bootstrap` that checks override files for syntax errors
- [ ] Create example override files for common customizations (custom DNS records, Caddy rules)
- [ ] Document which config files are safe to override without requiring a service restart

## Outline

The config overrides directory holds service-specific configuration customizations that supplement or replace default configs generated at bootstrap time.

- Override files in `config/overrides/` are merged with or replace defaults in `config/<service>/` during bootstrap or at runtime
- Allows per-environment customization without modifying the base compose files or config templates
- Generated configs (in `**/config/generated/`, git-ignored) are produced from templates plus overrides
- Common use cases: custom Caddyfile snippets, additional PowerDNS zones, Prometheus scrape job additions
- Override files are tracked in git (unlike `volumes/` and `config/generated/`), enabling config-as-code workflows
- Changes to overrides generally require a `make restart` to take effect for the affected service
