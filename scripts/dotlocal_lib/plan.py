"""Diff engine: compute the per-service action plan."""
from __future__ import annotations

import enum
import hashlib
import json
from dataclasses import dataclass, field
from typing import Iterable

from . import engine, tiers


class ChangeKind(enum.Enum):
    NOOP = "noop"
    CREATE = "create"
    RECREATE = "recreate"
    REMOVE = "remove"


@dataclass(frozen=True)
class Change:
    service: str
    kind: ChangeKind
    tier: int
    reason: str = ""
    desired_image: str | None = None
    running_image: str | None = None
    stateful: bool = False

    @property
    def tier_name(self) -> str:
        return tiers.TIER_NAMES.get(self.tier, f"tier-{self.tier}")


@dataclass
class Plan:
    changes: list[Change] = field(default_factory=list)

    @property
    def empty(self) -> bool:
        return not any(c.kind != ChangeKind.NOOP for c in self.changes)

    def actionable(self) -> list[Change]:
        return [c for c in self.changes if c.kind != ChangeKind.NOOP]

    def by_tier(self) -> list[tuple[int, list[Change]]]:
        buckets: dict[int, list[Change]] = {}
        for c in self.actionable():
            buckets.setdefault(c.tier, []).append(c)
        return sorted(buckets.items())

    def to_json(self) -> str:
        return json.dumps({
            "changes": [
                {
                    "service": c.service,
                    "kind": c.kind.value,
                    "tier": c.tier,
                    "tier_name": c.tier_name,
                    "reason": c.reason,
                    "desired_image": c.desired_image,
                    "running_image": c.running_image,
                    "stateful": c.stateful,
                }
                for c in self.changes
            ],
            "empty": self.empty,
        }, indent=2)


# Services for which we refuse to RECREATE across a major-version bump
# without an explicit `--allow-major` opt-in. Schema migration is out of
# scope for §1.1 — silent recreates of a postgres major would risk
# permanent data loss.
_STATEFUL_SERVICES = {
    "postgres", "mysql", "powerdns",
    "redis", "redis-stack",
    "minio", "seaweedfs",
    "rabbitmq", "kafka", "redpanda", "nats",
    "step-ca", "smallstep",
    "loki", "tempo", "graylog", "jaeger",
}


def _fallback_hash(svc_cfg: dict) -> str:
    """Used when `docker compose config --hash` is unavailable."""
    canonical = json.dumps(svc_cfg, sort_keys=True, default=str)
    return hashlib.sha256(canonical.encode()).hexdigest()


def _running_index(items: Iterable[dict]) -> dict[str, dict]:
    """Map compose Service name → running container summary."""
    out: dict[str, dict] = {}
    for item in items:
        svc = item.get("Service") or item.get("Labels", {}).get("com.docker.compose.service")
        if svc:
            out[svc] = item
    return out


def _running_config_hash(container: dict) -> str | None:
    """Pull the compose config-hash from a `docker compose ps` row."""
    # `docker compose ps --format json` includes Labels as a comma-joined string
    raw = container.get("Labels") or ""
    if isinstance(raw, dict):
        return raw.get("com.docker.compose.config-hash")
    for chunk in raw.split(","):
        chunk = chunk.strip()
        if chunk.startswith("com.docker.compose.config-hash="):
            return chunk.split("=", 1)[1]
    return None


def _image_of(container: dict) -> str | None:
    return container.get("Image")


def _is_major_bump(running: str | None, desired: str | None) -> bool:
    """Best-effort detection of a major-version image bump.

    Compares the tag portion only — `repo/img:16-alpine` vs `repo/img:17-alpine`
    counts as a major bump. Conservative: returns False on any ambiguity.
    """
    if not running or not desired:
        return False
    rt = running.rsplit(":", 1)[-1] if ":" in running else ""
    dt = desired.rsplit(":", 1)[-1] if ":" in desired else ""

    def major(tag: str) -> int | None:
        # Strip leading 'v', take first dot/dash component
        cleaned = tag.lstrip("v").split("-")[0].split(".")[0]
        return int(cleaned) if cleaned.isdigit() else None

    rm, dm = major(rt), major(dt)
    if rm is None or dm is None:
        return False
    return rm != dm


def compute_plan(ctx: engine.Context) -> Plan:
    desired_cfg = engine.compose_config_json(ctx)
    services_cfg: dict = desired_cfg.get("services", {}) or {}

    running = _running_index(engine.docker_ps_json(ctx))

    plan = Plan()
    desired_names = set(services_cfg.keys())
    running_names = set(running.keys())

    for name in sorted(desired_names | running_names):
        svc_cfg = services_cfg.get(name, {})
        container = running.get(name, {})
        labels = tiers.labels_from_compose_service(svc_cfg) if svc_cfg else {}
        tier = tiers.resolve_tier(name, labels)
        stateful = name in _STATEFUL_SERVICES

        if name in desired_names and name not in running_names:
            plan.changes.append(Change(
                service=name, kind=ChangeKind.CREATE, tier=tier,
                reason="not running",
                desired_image=svc_cfg.get("image"),
                stateful=stateful,
            ))
            continue

        if name in running_names and name not in desired_names:
            plan.changes.append(Change(
                service=name, kind=ChangeKind.REMOVE, tier=tier,
                reason="no longer in desired config",
                running_image=_image_of(container),
                stateful=stateful,
            ))
            continue

        # In both sets — compare config hashes.
        desired_hash = engine.compose_service_hash(ctx, name) or _fallback_hash(svc_cfg)
        running_hash = _running_config_hash(container)
        if running_hash and running_hash == desired_hash:
            plan.changes.append(Change(
                service=name, kind=ChangeKind.NOOP, tier=tier,
                desired_image=svc_cfg.get("image"),
                running_image=_image_of(container),
                stateful=stateful,
            ))
        else:
            reason = "config hash changed" if running_hash else "no running hash label"
            plan.changes.append(Change(
                service=name, kind=ChangeKind.RECREATE, tier=tier,
                reason=reason,
                desired_image=svc_cfg.get("image"),
                running_image=_image_of(container),
                stateful=stateful,
            ))

    return plan


def render_text(plan: Plan) -> str:
    """Terraform-style rendering."""
    if plan.empty:
        return "Nothing to do. Stack matches desired configuration.\n"
    lines: list[str] = []
    summary = {ChangeKind.CREATE: 0, ChangeKind.RECREATE: 0, ChangeKind.REMOVE: 0}
    for tier, changes in plan.by_tier():
        tier_name = tiers.TIER_NAMES.get(tier, f"tier-{tier}")
        lines.append(f"\nT{tier} {tier_name}:")
        for c in changes:
            summary[c.kind] = summary.get(c.kind, 0) + 1
            sigil = {"create": "+", "recreate": "~", "remove": "-"}.get(c.kind.value, " ")
            img = ""
            if c.kind == ChangeKind.RECREATE and c.running_image and c.desired_image and c.running_image != c.desired_image:
                img = f"  image: {c.running_image} → {c.desired_image}"
            elif c.desired_image:
                img = f"  image: {c.desired_image}"
            tag = c.kind.value.upper()
            warn = " [stateful]" if c.stateful else ""
            lines.append(f"  {sigil} {c.service:<28} {tag}{warn}{img}   ({c.reason})")
    lines.append("")
    lines.append(
        f"Summary: +{summary[ChangeKind.CREATE]} create  "
        f"~{summary[ChangeKind.RECREATE]} recreate  "
        f"-{summary[ChangeKind.REMOVE]} remove"
    )
    return "\n".join(lines) + "\n"
