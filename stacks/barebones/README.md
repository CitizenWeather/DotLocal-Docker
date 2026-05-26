# stacks/barebones — Legacy Reference (Not Used)

⚠️ **This directory is NOT included in the active Makefile.** It is kept for reference only.

## Status

The swappable implementations under `stacks/barebones/` have been refactored into `slots/` directory, which is the canonical location for all swappable implementations.

The Makefile now includes compose files from:
- `slots/<slot>/<impl>/docker-compose.yml` — current active implementations
- `stacks/net_providers/` — fixed services (mail, cache, database tiers)
- `stacks/net_web/` — web tier services

The old `stacks/barebones/` directory structure is preserved for reference but is **not compiled into docker compose commands**.

## Why it's here

This structure was used in early versions of the project. It provides a historical record of how the system was originally organised before the refactor to `slots/`.

## If you see duplicate implementations

If you notice that both `slots/gateway/caddy/docker-compose.yml` and `stacks/barebones/net_root/.../gateway/caddy/docker-compose.yml` exist, the **`slots/` version is the one in use**. The `stacks/barebones/` version is dead code.

### To cleanup

You can safely delete this entire directory without affecting the running stack:

```bash
rm -rf stacks/barebones/
```

However, it's kept for now in case someone needs historical reference.

## See also

- `slots/` — Active swappable slot implementations
- `Makefile` — The definitive source of truth for what gets compiled
