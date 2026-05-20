#!/usr/bin/env bash
# Drain hook: redis / redis-stack. Trigger BGSAVE and wait for LASTSAVE to
# advance so the AOF/RDB snapshot is on disk before recreation.
set -euo pipefail

CONTAINER="${CONTAINER:-}"
SERVICE="${SERVICE:-redis}"
PROJECT="${NETLOCAL_PROJECT:-netlocal}"

if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker compose --project-name "$PROJECT" ps -q "$SERVICE" 2>/dev/null | head -n1 || true)
fi
if [ -z "$CONTAINER" ]; then
    echo "drain/redis: no running container for service '$SERVICE'" >&2
    exit 0
fi

before=$(docker exec "$CONTAINER" redis-cli LASTSAVE 2>/dev/null || echo "0")
docker exec "$CONTAINER" redis-cli BGSAVE >/dev/null 2>&1 || true

# Poll for LASTSAVE to advance (BGSAVE done) — up to 20s.
for _ in $(seq 1 20); do
    sleep 1
    after=$(docker exec "$CONTAINER" redis-cli LASTSAVE 2>/dev/null || echo "0")
    if [ "$after" != "$before" ]; then
        exit 0
    fi
done

echo "drain/redis: BGSAVE did not complete within 20s — proceeding anyway" >&2
exit 0
