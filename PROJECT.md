# NetLocal — Project Overview

NetLocal (DotLocal-Docker) is a self-hosted local network infrastructure stack driven entirely by Docker Compose. It turns a single machine or LAN into a complete `.local` intranet with DNS, a certificate authority, a service registry, an API gateway, databases, cache, object storage, messaging, email, and observability — all running locally, all swappable.

## Goal

Make it trivially easy to spin up production-grade local infrastructure for development, home labs, and air-gapped environments, with no cloud dependency.

## Repositories

| Repo | Purpose |
|------|---------|
| [citizenweather/dotlocal-docker](https://github.com/CitizenWeather/DotLocal-Docker) | Main stack (this repo) |

## Project status

Early alpha. Core infrastructure slots (DNS, CA, gateway, registry) are functional. Advanced slots (messaging, storage, policy) are partially implemented. See [ROADMAP.md](ROADMAP.md) for the full capability map and [TODO.md](TODO.md) for the prioritised work list.

## Design principles

- **Swappable implementations** — every infrastructure role is a named slot filled by whichever implementation you choose in `.env`.
- **No magic** — the Makefile assembles a plain `docker compose` command from your choices; nothing runs that you did not configure.
- **Local-first** — all services bind to RFC 1918 or link-local addresses; nothing reaches the public internet by default.
- **Operational parity** — `plan`/`apply`/`rollback` give the stack the same lifecycle semantics as production infrastructure tools.

## Maintainers

- **Aidan Khogg** ([@aidankhogg](https://github.com/aidankhogg)) — creator and maintainer

## Licence

MIT — see [LICENSE](LICENSE).
