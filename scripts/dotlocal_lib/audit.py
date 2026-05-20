"""Append-only JSONL audit log for every apply/rollback."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

HISTORY_FILE = "volumes/_apply/history.jsonl"


@dataclass
class Entry:
    cmd: str
    user: str = field(default_factory=lambda: os.environ.get("USER", "unknown"))
    started_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    snapshot: str | None = None
    summary: dict[str, Any] = field(default_factory=dict)
    result: str = "started"
    duration_s: float = 0.0
    error: str | None = None

    def as_dict(self) -> dict[str, Any]:
        return {
            "ts": self.started_at,
            "user": self.user,
            "cmd": self.cmd,
            "snapshot": self.snapshot,
            "summary": self.summary,
            "result": self.result,
            "duration_s": round(self.duration_s, 3),
            "error": self.error,
        }


def append(root: Path, entry: Entry) -> None:
    path = root / HISTORY_FILE
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry.as_dict()) + "\n")


def read_all(root: Path) -> list[dict]:
    path = root / HISTORY_FILE
    if not path.exists():
        return []
    out: list[dict] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return out


def latest(root: Path) -> dict | None:
    entries = read_all(root)
    return entries[-1] if entries else None
