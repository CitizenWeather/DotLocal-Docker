# Contributing to DotLocal-Docker

Thank you for your interest in contributing to NetLocal. All kinds of contributions are welcome: bug reports, documentation improvements, new slot implementations, and extension packs.

## Before you start

- Read [README.md](README.md) and [docs/architecture.md](docs/architecture.md) to understand the slot/composition model.
- Check [ROADMAP.md](ROADMAP.md) and open issues for planned work before starting something large.
- For significant changes, open an issue first to discuss the approach.

## Development setup

```bash
cp .env.example .env    # configure your local stack
make bootstrap          # create Docker networks and runtime directories
make up                 # start the stack
make health             # verify all services are reachable
```

There is no test suite. Use `make health` (`scripts/healthcheck.py`) to verify that your changes do not break service reachability.

## Contribution guidelines

### Adding a new slot implementation

1. Identify the slot's `*_DIR` in the Makefile.
2. Create `<SLOT_DIR>/<impl-name>/docker-compose.yml`.
3. Attach the service to the correct network(s) with a static backbone IP if the service belongs on `localnet_backbone`.
4. Add a `netlocal.component=<slot>` Docker label.
5. Set `<SLOT>_APP=<impl-name>` in `.env` to activate it.
6. Update `docs/slots.md` to document the new implementation.

### Adding an extension pack

1. Create `extensions/<tag>/docker-compose.yml`.
2. Add the tag to `EXTENSION_TAGS` in `.env`.
3. Document the extension in `docs/extensions.md`.

### General rules

- Keep compose files self-contained: do not depend on state from another slot's compose file.
- Never hardcode IPs outside the `169.254.x.x` backbone range; use environment variables for anything that needs to be configurable.
- Every new service must carry a `netlocal.component=<role>` Docker label.
- Prefer named volumes over bind-mounts except for config files that need to be templated.
- Do not commit `.env`, `volumes/`, or anything under `**/config/generated/`.

## Pull request checklist

- [ ] `make bootstrap && make up && make health` passes against the changed compose files
- [ ] New or changed `.env` variables are added to `.env.example` with explanatory comments
- [ ] Documentation updated (`docs/`, `README.md`, or `CHANGELOG.md`) where applicable
- [ ] Compose services carry the `netlocal.component` label

## Code of conduct

Be respectful and constructive. Harassment or bad-faith contributions will not be tolerated.

## Licence

By contributing you agree that your contributions will be licensed under the [MIT License](LICENSE).
