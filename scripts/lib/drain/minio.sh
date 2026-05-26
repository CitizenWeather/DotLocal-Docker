#!/usr/bin/env bash
# Drain hook: minio. Best-effort graceful flush via `mc admin service stop`.
# If `mc` is not configured inside the container, falls back to a no-op.
set -euo pipefail

CONTAINER="${CONTAINER:-}"
SERVICE="${SERVICE:-minio}"
PROJECT="${NETLOCAL_PROJECT:-netlocal}"

if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker compose --project-name "$PROJECT" ps -q "$SERVICE" 2>/dev/null | head -n1 || true)
fi
if [ -z "$CONTAINER" ]; then
    echo "drain/minio: no running container for service '$SERVICE'" >&2
    exit 0
fi

# `mc admin service stop local` is the cleanest shutdown path. If the alias
# is not configured we silently skip — recreate will issue a SIGTERM anyway
# and minio handles that gracefully.
if docker exec "$CONTAINER" mc alias list local >/dev/null 2>&1; then
    docker exec "$CONTAINER" mc admin service stop local >/dev/null 2>&1 || true
fi

exit 0
