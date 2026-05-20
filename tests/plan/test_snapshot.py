"""File-management tests for snapshot.py — no Docker required."""
from __future__ import annotations

import json
from pathlib import Path

from scripts.dotlocal_lib import snapshot


def test_list_snapshots_orders_chronologically(tmp_path: Path):
    base = tmp_path / snapshot.SNAPSHOT_ROOT
    base.mkdir(parents=True)
    for name in ["20260101T000000Z", "20260102T000000Z", "20260103T000000Z"]:
        (base / name).mkdir()
    snaps = snapshot.list_snapshots(tmp_path)
    assert [s.timestamp for s in snaps] == [
        "20260101T000000Z", "20260102T000000Z", "20260103T000000Z",
    ]


def test_latest_returns_most_recent(tmp_path: Path):
    base = tmp_path / snapshot.SNAPSHOT_ROOT
    base.mkdir(parents=True)
    (base / "20260101T000000Z").mkdir()
    (base / "20260102T000000Z").mkdir()
    latest = snapshot.latest(tmp_path)
    assert latest is not None
    assert latest.timestamp == "20260102T000000Z"


def test_prune_keeps_retention_window(tmp_path: Path):
    base = tmp_path / snapshot.SNAPSHOT_ROOT
    base.mkdir(parents=True)
    timestamps = [f"2026010{i}T000000Z" for i in range(1, 6)]
    for ts in timestamps:
        (base / ts).mkdir()
    pruned = snapshot.prune(tmp_path, keep=2)
    assert len(pruned) == 3
    remaining = [s.timestamp for s in snapshot.list_snapshots(tmp_path)]
    assert remaining == ["20260104T000000Z", "20260105T000000Z"]


def test_write_image_pinning_override_uses_digest(tmp_path: Path):
    snap_dir = tmp_path / snapshot.SNAPSHOT_ROOT / "20260101T000000Z"
    snap_dir.mkdir(parents=True)
    (snap_dir / "images.json").write_text(json.dumps({
        "postgres": {"image": "postgres:16",
                     "digest": "sha256:abc123",
                     "config_hash": "h1"},
        "no-digest": {"image": "x:1", "digest": None, "config_hash": "h2"},
    }))
    snap = snapshot.Snapshot(path=snap_dir, timestamp="20260101T000000Z")
    override = snapshot.write_image_pinning_override(snap)
    assert override is not None
    text = override.read_text()
    assert "postgres@sha256:abc123" in text
    assert "x:1" in text  # falls back to tag when no digest


def test_write_image_pinning_override_returns_none_when_empty(tmp_path: Path):
    snap_dir = tmp_path / snapshot.SNAPSHOT_ROOT / "20260101T000000Z"
    snap_dir.mkdir(parents=True)
    (snap_dir / "images.json").write_text("{}")
    snap = snapshot.Snapshot(path=snap_dir, timestamp="20260101T000000Z")
    assert snapshot.write_image_pinning_override(snap) is None
