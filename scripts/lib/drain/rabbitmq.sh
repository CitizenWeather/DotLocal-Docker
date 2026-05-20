#!/usr/bin/env bash
# Drain hook: rabbitmq. Calls `rabbitmqctl stop_app` so durable queues are
# checkpointed before the container is replaced. Idempotent.
set -euo pipefail

CONTAINER="${CONTAINER:-}"
SERVICE="${SERVICE:-rabbitmq}"
PROJECT="${NETLOCAL_PROJECT:-netlocal}"

if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker compose --project-name "$PROJECT" ps -q "$SERVICE" 2>/dev/null | head -n1 || true)
fi
if [ -z "$CONTAINER" ]; then
    echo "drain/rabbitmq: no running container for service '$SERVICE'" >&2
    exit 0
fi

docker exec "$CONTAINER" rabbitmqctl stop_app >/dev/null 2>&1 || \
    echo "drain/rabbitmq: stop_app returned non-zero (container may already be down)" >&2

exit 0
