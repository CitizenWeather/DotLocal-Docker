# GitHub Copilot Instructions — DotLocal-Docker (NetLocal)

## What this project is

DotLocal-Docker (internally **NetLocal**) is a Docker Compose–driven local network infrastructure stack. It provisions a complete `.local` intranet: DNS, certificate authority, service registry, API gateway, database, cache, object storage, messaging, email, and observability — all running on a single machine or LAN.

The core pattern is **swappable slots**: every infrastructure role is a named slot filled by one concrete implementation selected via an environment variable in `.env`. The Makefile assembles the final `docker compose -f … -f …` invocation automatically.

## Key rules for code generation

- **Never hardcode IPs** outside the `169.254.x.x` backbone range. Use environment variables for anything configurable.
- **Every compose service** must carry a `netlocal.component=<role>` Docker label (e.g. `netlocal.component=dns`).
- **Network placement**: infrastructure services go on `localnet_backbone` with a static IP; application services go on `localnet_default` and are accessed through the gateway.
- **Slot compose files** live at `<SLOT_DIR>/<impl-name>/docker-compose.yml`. The Makefile's `include_if` macro picks them up — do not edit the Makefile's core loop.
- **Extension packs** live at `extensions/<tag>/docker-compose.yml`. Activated by adding the tag to `EXTENSION_TAGS` in `.env`.
- **No secrets in compose files** — all credentials come from `.env` (git-ignored).
- **No bind-mounts for generated state** — use named Docker volumes. Config files that need templating may use bind-mounts to `config/` subdirectories.
- **Do not commit** `.env`, `volumes/`, or anything under `**/config/generated/`.

## Repository layout (summary)

```
stacks/         Core infrastructure compose files (gateway, registry, policy, dashboards)
build/          Architectural layer compose files (CA, NTP, observability, messaging)
extensions/     Optional extension packs
scripts/        Operational helpers (bootstrap, healthcheck, switch-*, register-service, issue-cert)
config/         Runtime config overrides; config/generated/ is git-ignored
docs/           User documentation
```

## Adding a swappable implementation (step-by-step)

1. Find the slot's `*_DIR` variable in the Makefile.
2. Create `<SLOT_DIR>/<impl-name>/docker-compose.yml`.
3. Attach to the correct network(s); assign a static backbone IP if needed.
4. Add `netlocal.component=<slot>` label to every service.
5. Set `<SLOT>_APP=<impl-name>` in `.env`.
6. Update `docs/slots.md`.

## Verification

There is no test suite. To verify correctness, run:

```bash
make bootstrap && make up && make health
```

`make health` runs `scripts/healthcheck.py`, which checks TCP/UDP reachability of all core services.
