"""Zero-downtime apply pipeline: drain → recreate → health-gate, tier by tier."""
from __future__ import annotations

import fcntl
import os
import subprocess
import time
from pathlib import Path

from . import audit, engine, health, plan as planmod, snapshot, tiers

LOCK_FILE = "volumes/_apply/.lock"
DRAIN_HOOK_TIMEOUT = float(os.environ.get("DOTLOCAL_DRAIN_TIMEOUT", "30"))


def _acquire_lock(root: Path):
    lock_path = root / LOCK_FILE
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    fh = lock_path.open("w")
    try:
        fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        fh.close()
        raise engine.ApplyError(
            f"another `dotlocal apply` is already running (lock: {lock_path})"
        )
    return fh


def _confirm(plan: planmod.Plan) -> bool:
    engine.log(planmod.render_text(plan), stream=__import__("sys").stdout)
    try:
        ans = input("Proceed with apply? [y/N] ").strip().lower()
    except EOFError:
        return False
    return ans in {"y", "yes"}


def _run_drain_hook(ctx: engine.Context, service: str, container: str | None) -> None:
    hook = ctx.root / "scripts" / "lib" / "drain" / f"{service}.sh"
    if not hook.is_file() or not os.access(hook, os.X_OK):
        return
    engine.log(f"  drain: running {hook.name} for {service}")
    env = os.environ.copy()
    env["NETLOCAL_PROJECT"] = ctx.project
    env["SERVICE"] = service
    env["CONTAINER"] = container or ""
    env["PHASE"] = "pre-recreate"
    try:
        proc = subprocess.run(
            [str(hook)],
            cwd=ctx.root,
            env=env,
            timeout=DRAIN_HOOK_TIMEOUT,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except subprocess.TimeoutExpired:
        raise engine.ApplyError(
            f"drain hook for {service} exceeded {DRAIN_HOOK_TIMEOUT:.0f}s"
        )
    if proc.returncode != 0:
        engine.log(proc.stdout or "")
        if not ctx.force:
            raise engine.ApplyError(
                f"drain hook for {service} failed (exit {proc.returncode}); "
                f"rerun with --force to ignore"
            )
        engine.log(f"  drain: hook failed (exit {proc.returncode}); --force set, continuing")


def _check_major_bumps(p: planmod.Plan, allow_major: bool) -> list[str]:
    blocked: list[str] = []
    for c in p.actionable():
        if not c.stateful or c.kind != planmod.ChangeKind.RECREATE:
            continue
        if planmod._is_major_bump(c.running_image, c.desired_image) and not allow_major:
            blocked.append(
                f"{c.service}: {c.running_image} → {c.desired_image} "
                f"(major version bump on stateful service)"
            )
    return blocked


def run_apply(ctx: engine.Context, p: planmod.Plan, *, source: str = "apply") -> Path:
    """Drive the apply pipeline. Returns snapshot path."""
    if p.empty and not ctx.force:
        engine.log("Nothing to do. Stack matches desired configuration.")
        return Path()

    if not ctx.auto_approve and not _confirm(p):
        raise engine.ApplyError("aborted by user")

    blocked = _check_major_bumps(p, ctx.allow_major)
    if blocked:
        raise engine.ApplyError(
            "refusing to recreate stateful services across major versions "
            "without --allow-major:\n  - " + "\n  - ".join(blocked)
        )

    lock = _acquire_lock(ctx.root)
    try:
        return _run_apply_locked(ctx, p, source=source)
    finally:
        lock.close()


def _run_apply_locked(ctx: engine.Context, p: planmod.Plan, *, source: str) -> Path:
    entry = audit.Entry(cmd=source)
    started = time.monotonic()

    snap = snapshot.take(ctx)
    entry.snapshot = str(snap.path.relative_to(ctx.root))
    engine.log(f"snapshot: {entry.snapshot}")

    # 1. Pre-pull images (after snapshot — a failed pull leaves nothing changed)
    if not ctx.skip_pull:
        engine.log("pulling images (parallel)…")
        proc = engine.run(ctx, "pull", "--parallel", "--quiet", capture=True, check=False)
        if proc.returncode != 0:
            entry.result = "failed"
            entry.error = f"image pull failed: {proc.stderr.strip()}"
            entry.duration_s = time.monotonic() - started
            audit.append(ctx.root, entry)
            raise engine.ApplyError(entry.error)

    # 2. Tier-by-tier recreate + health gate
    summary = {"create": 0, "recreate": 0, "remove": 0, "tiers": []}
    for tier, changes in p.by_tier():
        tier_name = tiers.TIER_NAMES.get(tier, f"tier-{tier}")
        recreate_or_create = [
            c for c in changes if c.kind in (planmod.ChangeKind.CREATE, planmod.ChangeKind.RECREATE)
        ]
        removes = [c for c in changes if c.kind == planmod.ChangeKind.REMOVE]

        engine.log(f"\n=== T{tier} {tier_name}: "
                   f"{len(recreate_or_create)} up, {len(removes)} remove ===")

        # Drain stateful services about to be recreated
        for c in recreate_or_create:
            if c.kind == planmod.ChangeKind.RECREATE:
                _run_drain_hook(ctx, c.service, None)
            summary[c.kind.value] += 1

        # Recreate / create — --no-deps prevents cascading into other tiers
        if recreate_or_create:
            svcs = [c.service for c in recreate_or_create]
            engine.run(ctx, "up", "-d", "--no-deps", *svcs)

            results = health.wait_tier(ctx, svcs)
            unhealthy = [s for s, (ok, _) in results.items() if not ok]
            if unhealthy:
                for svc, (ok, msg) in results.items():
                    engine.log(f"  {svc}: {'ok' if ok else 'FAIL'} ({msg})")
                entry.result = "failed"
                entry.error = (
                    f"tier {tier_name} health check failed for: "
                    + ", ".join(unhealthy)
                )
                entry.summary = summary
                entry.duration_s = time.monotonic() - started
                audit.append(ctx.root, entry)
                raise engine.ApplyError(entry.error + f" (snapshot: {entry.snapshot})")

        # Removes happen after the up-and-healthy verification
        for c in removes:
            engine.run(ctx, "rm", "-sf", c.service, check=False)
            summary["remove"] = summary.get("remove", 0) + 1

        summary["tiers"].append({"tier": tier, "name": tier_name,
                                 "services": [c.service for c in changes]})

    # 3. Smoke check (existing healthcheck.py)
    ok, msg = health.smoke_check(ctx)
    summary["smoke"] = {"ok": ok, "msg": msg.splitlines()[-1][:200] if msg else ""}
    if not ok and not ctx.force:
        entry.result = "failed"
        entry.error = f"post-apply smoke check failed: {msg.splitlines()[-1] if msg else ''}"
        entry.summary = summary
        entry.duration_s = time.monotonic() - started
        audit.append(ctx.root, entry)
        raise engine.ApplyError(entry.error + f" (snapshot: {entry.snapshot})")

    entry.result = "success"
    entry.summary = summary
    entry.duration_s = time.monotonic() - started
    audit.append(ctx.root, entry)

    # 4. Prune old snapshots
    pruned = snapshot.prune(ctx.root)
    if pruned:
        engine.log(f"pruned {len(pruned)} old snapshot(s)")

    engine.log(
        f"\napply complete: +{summary['create']} ~{summary['recreate']} "
        f"-{summary['remove']} ({entry.duration_s:.1f}s)"
    )
    return snap.path


def run_rollback(ctx: engine.Context, snap: snapshot.Snapshot) -> Path:
    """Apply a previous snapshot as the new desired state."""
    if not snap.compose_dir.is_dir():
        raise engine.ApplyError(f"snapshot has no compose tree: {snap.path}")

    # Build a context that points at the snapshotted compose files.
    rel = snap.compose_dir.relative_to(ctx.root)
    compose_files: list[str] = []
    for path in sorted(snap.compose_dir.rglob("*.yml")):
        rel_path = path.relative_to(ctx.root)
        compose_files.extend(["-f", str(rel_path)])

    # Pin images by digest so rollback is exact
    override = snapshot.write_image_pinning_override(snap)
    if override:
        compose_files.extend(["-f", str(override.relative_to(ctx.root))])

    if not compose_files:
        raise engine.ApplyError(f"no compose files in snapshot {snap.path}")

    engine.log(f"rolling back to snapshot {snap.timestamp} ({rel})")

    rollback_ctx = engine.Context(
        root=ctx.root,
        project=ctx.project,
        compose_files=tuple(compose_files),
        auto_approve=ctx.auto_approve,
        skip_pull=ctx.skip_pull,
        force=True,            # rollbacks always proceed past drain failures
        allow_major=True,      # the previous state already ran successfully
    )
    p = planmod.compute_plan(rollback_ctx)
    return run_apply(rollback_ctx, p, source=f"rollback:{snap.timestamp}")
