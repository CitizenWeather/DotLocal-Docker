#!/usr/bin/env bash
# Drain hook: postgres. Forces a CHECKPOINT and waits for pg_isready before
# allowing the container to be recreated, so on-disk state is consistent.
#
# Env (set by dotlocal): SERVICE, CONTAINER, PHASE, NETLOCAL_PROJECT.
set -euo pipefail

CONTAINER="${CONTAINER:-}"
SERVICE="${SERVICE:-postgres}"
PROJECT="${NETLOCAL_PROJECT:-netlocal}"

# Resolve a container ID by service name if not provided
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker compose --project-name "$PROJECT" ps -q "$SERVICE" 2>/dev/null | head -n1 || true)
fi
if [ -z "$CONTAINER" ]; then
    echo "drain/postgres: no running container for service '$SERVICE' — nothing to drain" >&2
    exit 0
fi

# Use POSTGRES_USER from env or fall back to the conventional default.
PG_USER="${POSTGRES_USER:-postgres}"

# CHECKPOINT flushes dirty buffers to disk so a clean recreate is safe.
if ! docker exec "$CONTAINER" psql -U "$PG_USER" -c "CHECKPOINT;" >/dev/null 2>&1; then
    echo "drain/postgres: CHECKPOINT failed (continuing — postgres may still be starting)" >&2
fi

# Wait briefly for pg_isready so we don't shoot it mid-write.
for _ in 1 2 3 4 5; do
    if docker exec "$CONTAINER" pg_isready -U "$PG_USER" >/dev/null 2>&1; then
        exit 0
    fi
    sleep 1
done

echo "drain/postgres: pg_isready never returned — proceeding anyway" >&2
exit 0
