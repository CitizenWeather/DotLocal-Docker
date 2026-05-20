# Build System & Makefile Composition

## TODO

- [ ] Document all Makefile targets with descriptions and usage examples
- [ ] Add validation logic to check required `.env` variables before `make up`
- [ ] Create a `make lint` target that validates compose file syntax
- [ ] Document the multi-`-f` compose assembly pattern and ordering rules

## Outline

The build system is the top-level orchestration layer that assembles Docker Compose invocations from environment-selected component slots.

- The Makefile reads `.env` automatically via `include .env` and composes a single multi-`-f` `docker compose` command
- Swappable slots (DNS, CA, gateway, database, cache, etc.) are resolved from `*_APP` variables in `.env` to compose file paths under `apps/localnet/barebones/`
- Fixed services (dnsmasq, Heimdall, health endpoint, Squid, Chrony, Uptime Kuma) are always appended regardless of slot choices
- Extension packs in `apps/extensions/` are activated via `EXTENSION_TAGS` and injected as `--profile tag-<name>` flags
- Bootstrap (`make bootstrap`) creates Docker networks, required directories, and copies config templates before first run
- Health verification is handled by `scripts/healthcheck.py` via `make health`
