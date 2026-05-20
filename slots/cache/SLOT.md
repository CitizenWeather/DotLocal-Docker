# Slot: cache

**Variable:** `CACHE_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=cache`

## Contract

An implementation must:
- Expose the Redis wire protocol on port 6379
- Be reachable from services on `localnet_default` as `cache` or by container name

## Required environment variables

None required. Optional: `REDIS_PASSWORD` if auth is enabled.

## Available implementations

| Name | Image | Notes |
|---|---|---|
| `redis-stack` *(recommended)* | `redis/redis-stack:latest` | Adds RedisJSON, RediSearch, RedisTimeSeries modules |
| `redis` | `redis:7-alpine` | Minimal footprint, standard Redis only |

Both expose identical Redis wire protocol on port 6379 — applications need not change when switching.

## Adding a new implementation

1. Create `slots/cache/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Expose port 6379
4. Add label `netlocal.component=cache`
5. Set `CACHE_APP=<impl-name>` in `.env`
