"""Tier resolution: groups services into apply waves to minimise blast radius."""
from __future__ import annotations

from dataclasses import dataclass

TIER_NAMES = {
    0: "backbone",
    1: "data",
    2: "identity",
    3: "gateway",
    4: "apps",
    5: "observability",
}

# Maps `netlocal.component=<slot>` (already present on most services today)
# to the apply tier. Add new slots here when they're introduced.
_COMPONENT_TIER = {
    "dns": 0, "ca": 0, "registry": 0, "policy": 0, "ntp": 0,
    "db": 1, "cache": 1, "storage": 1, "messaging": 1, "secrets": 1,
    "identity": 2,
    "gateway": 3,
    "dashboard": 4, "uptime": 4, "email": 4, "whois": 4, "health": 4,
    "extensions": 4, "mail": 4,
    "log": 5, "trace": 5, "metrics": 5, "observability": 5,
}

DEFAULT_TIER = 4


@dataclass(frozen=True)
class TierAssignment:
    service: str
    tier: int

    @property
    def tier_name(self) -> str:
        return TIER_NAMES.get(self.tier, f"tier-{self.tier}")


def resolve_tier(service_name: str, labels: dict[str, str]) -> int:
    """Resolve a service's tier from its labels.

    Order: explicit `netlocal.tier` > `netlocal.component` mapping > default.
    """
    raw_tier = labels.get("netlocal.tier")
    if raw_tier is not None:
        try:
            return int(raw_tier)
        except ValueError:
            pass
    component = labels.get("netlocal.component")
    if component and component in _COMPONENT_TIER:
        return _COMPONENT_TIER[component]
    # Some heuristics from the service name itself.
    low = service_name.lower()
    for key, tier in _COMPONENT_TIER.items():
        if key in low:
            return tier
    return DEFAULT_TIER


def group_by_tier(assignments: list[TierAssignment]) -> list[tuple[int, list[str]]]:
    """Return [(tier, [service, ...]), ...] sorted ascending."""
    buckets: dict[int, list[str]] = {}
    for a in assignments:
        buckets.setdefault(a.tier, []).append(a.service)
    return sorted((t, sorted(svcs)) for t, svcs in buckets.items())


def labels_from_compose_service(svc_cfg: dict) -> dict[str, str]:
    """Compose `labels` can be either a list of `K=V` strings or a dict."""
    raw = svc_cfg.get("labels", {}) or {}
    if isinstance(raw, list):
        out: dict[str, str] = {}
        for entry in raw:
            if isinstance(entry, str) and "=" in entry:
                k, v = entry.split("=", 1)
                out[k.strip()] = v.strip()
        return out
    if isinstance(raw, dict):
        return {str(k): str(v) for k, v in raw.items()}
    return {}
