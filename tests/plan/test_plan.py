"""Unit tests for the plan diff engine.

These tests don't require a Docker daemon. We monkey-patch the three
compose-CLI functions that plan.py calls, then exercise scenarios that mirror
real apply situations.
"""
from __future__ import annotations

from pathlib import Path

import pytest

from scripts.dotlocal_lib import engine, plan


def _ctx() -> engine.Context:
    return engine.Context(
        root=Path("/tmp"),
        project="test",
        compose_files=("-f", "fake.yml"),
    )


def _patch(monkeypatch, *, desired: dict, running: list[dict], hashes: dict[str, str | None]):
    monkeypatch.setattr(engine, "compose_config_json", lambda ctx: {"services": desired})
    monkeypatch.setattr(engine, "docker_ps_json", lambda ctx: running)
    monkeypatch.setattr(engine, "compose_service_hash", lambda ctx, svc: hashes.get(svc))


def _running_row(service: str, image: str, config_hash: str | None) -> dict:
    labels = f"com.docker.compose.service={service},com.docker.compose.project=test"
    if config_hash:
        labels += f",com.docker.compose.config-hash={config_hash}"
    return {"Service": service, "Image": image, "Labels": labels, "ID": f"id-{service}"}


def test_noop_when_hashes_match(monkeypatch):
    _patch(
        monkeypatch,
        desired={"app": {"image": "app:1", "labels": ["netlocal.component=gateway"]}},
        running=[_running_row("app", "app:1", "h1")],
        hashes={"app": "h1"},
    )
    p = plan.compute_plan(_ctx())
    assert p.empty
    assert p.changes[0].kind == plan.ChangeKind.NOOP


def test_create_when_service_missing(monkeypatch):
    _patch(
        monkeypatch,
        desired={"new": {"image": "new:1", "labels": ["netlocal.component=db"]}},
        running=[],
        hashes={"new": "h1"},
    )
    p = plan.compute_plan(_ctx())
    assert not p.empty
    assert p.changes[0].kind == plan.ChangeKind.CREATE
    assert p.changes[0].tier == 1  # db


def test_recreate_on_image_bump(monkeypatch):
    _patch(
        monkeypatch,
        desired={"app": {"image": "app:2", "labels": ["netlocal.component=cache"]}},
        running=[_running_row("app", "app:1", "h1")],
        hashes={"app": "h2"},  # new hash because image changed
    )
    p = plan.compute_plan(_ctx())
    assert any(c.kind == plan.ChangeKind.RECREATE for c in p.changes)
    c = next(c for c in p.changes if c.service == "app")
    assert c.desired_image == "app:2"
    assert c.running_image == "app:1"
    assert c.tier == 1


def test_remove_when_service_dropped(monkeypatch):
    _patch(
        monkeypatch,
        desired={},
        running=[_running_row("legacy", "old:1", "h1")],
        hashes={},
    )
    p = plan.compute_plan(_ctx())
    assert p.changes[0].kind == plan.ChangeKind.REMOVE
    assert p.changes[0].service == "legacy"


def test_slot_swap_replaces_one_service(monkeypatch):
    """Swap CACHE_APP=redis → redis-stack — old service removed, new created."""
    _patch(
        monkeypatch,
        desired={"redis-stack": {"image": "redis/redis-stack-server:latest",
                                 "labels": ["netlocal.component=cache"]}},
        running=[_running_row("redis", "redis:7", "h1")],
        hashes={"redis-stack": "h2"},
    )
    p = plan.compute_plan(_ctx())
    kinds = {c.service: c.kind for c in p.changes}
    assert kinds["redis"] == plan.ChangeKind.REMOVE
    assert kinds["redis-stack"] == plan.ChangeKind.CREATE


def test_major_version_bump_detection():
    assert plan._is_major_bump("postgres:16-alpine", "postgres:17-alpine") is True
    assert plan._is_major_bump("postgres:16-alpine", "postgres:16.2-alpine") is False
    assert plan._is_major_bump("redis:7.0", "redis:7.2") is False
    assert plan._is_major_bump(None, "x:1") is False


def test_by_tier_groups_changes(monkeypatch):
    _patch(
        monkeypatch,
        desired={
            "postgres": {"image": "postgres:16", "labels": ["netlocal.component=db"]},
            "caddy": {"image": "caddy:2", "labels": ["netlocal.component=gateway"]},
            "coredns": {"image": "coredns/coredns:1", "labels": ["netlocal.component=dns"]},
        },
        running=[],
        hashes={"postgres": "h", "caddy": "h", "coredns": "h"},
    )
    p = plan.compute_plan(_ctx())
    by_tier = dict(p.by_tier())
    # DNS is T0, DB is T1, gateway is T3.
    assert sorted(by_tier.keys()) == [0, 1, 3]
    assert {c.service for c in by_tier[0]} == {"coredns"}
    assert {c.service for c in by_tier[1]} == {"postgres"}
    assert {c.service for c in by_tier[3]} == {"caddy"}


def test_render_text_handles_empty_plan(monkeypatch):
    _patch(monkeypatch, desired={}, running=[], hashes={})
    p = plan.compute_plan(_ctx())
    text = plan.render_text(p)
    assert "Nothing to do" in text


def test_render_text_includes_image_transition(monkeypatch):
    _patch(
        monkeypatch,
        desired={"app": {"image": "app:2", "labels": ["netlocal.component=gateway"]}},
        running=[_running_row("app", "app:1", "old")],
        hashes={"app": "new"},
    )
    p = plan.compute_plan(_ctx())
    text = plan.render_text(p)
    assert "app:1" in text and "app:2" in text and "RECREATE" in text


def test_json_output_is_parseable(monkeypatch):
    import json
    _patch(
        monkeypatch,
        desired={"x": {"image": "x:1", "labels": ["netlocal.component=cache"]}},
        running=[],
        hashes={"x": "h"},
    )
    p = plan.compute_plan(_ctx())
    parsed = json.loads(p.to_json())
    assert parsed["changes"][0]["service"] == "x"
    assert parsed["changes"][0]["kind"] == "create"
