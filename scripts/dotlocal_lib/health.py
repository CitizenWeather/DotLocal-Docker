"""Wait-for-healthy logic for newly recreated tiers."""
from __future__ import annotations

import json
import os
import time

from . import engine

DEFAULT_TIMEOUT = float(os.environ.get("DOTLOCAL_HEALTH_TIMEOUT", "90"))
SETTLE_SECONDS = float(os.environ.get("DOTLOCAL_HEALTH_SETTLE", "3"))


def _container_id_for(ctx: engine.Context, service: str) -> str | None:
    proc = engine.run(ctx, "ps", "--all", "--format", "json", capture=True, check=False)
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue
        rows = data if isinstance(data, list) else [data]
        for row in rows:
            svc = row.get("Service") or row.get("Labels", {}).get("com.docker.compose.service")
            if svc == service:
                return row.get("ID") or row.get("ContainerID")
    return None


def wait_service(ctx: engine.Context, service: str, *, timeout: float = DEFAULT_TIMEOUT) -> tuple[bool, str]:
    """Poll docker inspect for health/running. Returns (ok, status_msg)."""
    deadline = time.monotonic() + timeout
    last_state = "unknown"
    declared_health: bool | None = None

    while time.monotonic() < deadline:
        cid = _container_id_for(ctx, service)
        if not cid:
            time.sleep(1.0)
            continue
        try:
            info = engine.docker_inspect(cid)
        except engine.ApplyError as exc:
            last_state = f"inspect failed: {exc}"
            time.sleep(1.0)
            continue
        state = info.get("State", {}) or {}
        running = state.get("Running", False)
        health = (state.get("Health") or {}).get("Status")
        if declared_health is None:
            declared_health = health is not None

        if declared_health:
            if health == "healthy":
                return True, "healthy"
            if health == "unhealthy":
                return False, "unhealthy"
            last_state = f"health={health or 'starting'}"
        else:
            if running:
                # Settle period: brief pause before declaring victory for
                # services without a real healthcheck.
                time.sleep(SETTLE_SECONDS)
                return True, "running"
            last_state = "not running"
        time.sleep(2.0)

    return False, f"timeout after {timeout:.0f}s ({last_state})"


def wait_tier(ctx: engine.Context, services: list[str], *, timeout: float = DEFAULT_TIMEOUT) -> dict[str, tuple[bool, str]]:
    results: dict[str, tuple[bool, str]] = {}
    for svc in services:
        results[svc] = wait_service(ctx, svc, timeout=timeout)
    return results


def smoke_check(ctx: engine.Context) -> tuple[bool, str]:
    """Run scripts/healthcheck.py as a final cross-stack check."""
    script = ctx.root / "scripts" / "healthcheck.py"
    if not script.is_file():
        return True, "healthcheck.py absent — skipped"
    proc = engine.run_raw(["python3", str(script)], cwd=ctx.root, check=False, capture=True)
    return proc.returncode == 0, proc.stdout.strip() or proc.stderr.strip()
