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
- **Build profiles** (e.g. `.yellow`, `.green`, `.red`) are named configuration presets that pre-select slot implementations and `.env` values for a specific deployment shape (e.g. minimal, standard, full); they live in `build/profiles/` and are applied by copying the profile file over `.env`
- Other config artefacts generated at build time (rendered compose fragments, resolved variable files) are written to `config/generated/` which is git-ignored

## Further / Future

Ideas and roadmap items for the build system:

- **Complete as-code config** — move all environment state into declarative config files with schema validation, eliminating manual `.env` editing
- **Cross-platform build scripts** — provide both `.sh` (Linux/macOS) and `.py` wrappers for all `make` targets to support environments without GNU Make
- **Installer** — a single bootstrap script or package that clones the repo, detects the host environment, and selects the appropriate build profile automatically
- **OS / Host adapter** — an abstraction layer that queries host capabilities (systemd, brew, apt, etc.) and adjusts DNS forwarding, certificate trust, and network configuration per platform
- **Virtualisation engine adapter** — a plugin interface supporting Docker Engine, Docker Desktop, Docker Swarm, and future container runtimes; the adapter normalises network and volume semantics across engines
