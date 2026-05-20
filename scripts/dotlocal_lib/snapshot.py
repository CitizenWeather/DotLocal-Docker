"""Snapshot the resolved compose state so an apply can be rolled back."""
from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from . import engine

SNAPSHOT_ROOT = "volumes/_apply"
RETENTION = 20


@dataclass(frozen=True)
class Snapshot:
    path: Path
    timestamp: str

    @property
    def env_file(self) -> Path:
        return self.path / "env"

    @property
    def compose_dir(self) -> Path:
        return self.path / "compose"

    @property
    def resolved_yaml(self) -> Path:
        return self.path / "resolved.yml"

    @property
    def images_json(self) -> Path:
        return self.path / "images.json"


def _compose_file_paths(ctx: engine.Context) -> list[str]:
    """Extract the `-f path` arguments from ctx.compose_files."""
    paths: list[str] = []
    args = list(ctx.compose_files)
    i = 0
    while i < len(args):
        if args[i] == "-f" and i + 1 < len(args):
            paths.append(args[i + 1])
            i += 2
        else:
            i += 1
    return paths


def take(ctx: engine.Context) -> Snapshot:
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    root = ctx.root / SNAPSHOT_ROOT / ts
    root.mkdir(parents=True, exist_ok=True)

    # .env
    env_path = ctx.root / ".env"
    if env_path.exists():
        shutil.copy2(env_path, root / "env")

    # Compose files — preserve their tree under compose/
    for rel in _compose_file_paths(ctx):
        src = ctx.root / rel
        if not src.exists():
            continue
        dst = root / "compose" / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)

    # Resolved compose config (single file)
    resolved = engine.run(ctx, "config", capture=True)
    (root / "resolved.yml").write_text(resolved.stdout)

    # Per-service image digests + config hashes
    images: dict[str, dict[str, str | None]] = {}
    for container in engine.docker_ps_json(ctx):
        svc = container.get("Service")
        if not svc:
            continue
        image = container.get("Image")
        config_hash = None
        labels = container.get("Labels")
        if isinstance(labels, str):
            for chunk in labels.split(","):
                chunk = chunk.strip()
                if chunk.startswith("com.docker.compose.config-hash="):
                    config_hash = chunk.split("=", 1)[1]
        elif isinstance(labels, dict):
            config_hash = labels.get("com.docker.compose.config-hash")
        # Resolve digest where possible
        digest = None
        if image and container.get("ID"):
            try:
                inspected = engine.docker_inspect(container["ID"])
                digest = inspected.get("Image")  # sha256:...
            except Exception:
                pass
        images[svc] = {"image": image, "digest": digest, "config_hash": config_hash}
    (root / "images.json").write_text(json.dumps(images, indent=2))

    # Hashes only (separate file for diff convenience)
    hashes = {svc: meta.get("config_hash") for svc, meta in images.items()}
    (root / "hashes.json").write_text(json.dumps(hashes, indent=2))

    return Snapshot(path=root, timestamp=ts)


def list_snapshots(root: Path) -> list[Snapshot]:
    base = root / SNAPSHOT_ROOT
    if not base.is_dir():
        return []
    out: list[Snapshot] = []
    for entry in sorted(base.iterdir()):
        if entry.is_dir() and entry.name and entry.name[0].isdigit():
            out.append(Snapshot(path=entry, timestamp=entry.name))
    return out


def latest(root: Path) -> Snapshot | None:
    snaps = list_snapshots(root)
    return snaps[-1] if snaps else None


def prune(root: Path, keep: int = RETENTION) -> list[Snapshot]:
    """Delete oldest snapshots beyond the retention window. Returns deleted."""
    snaps = list_snapshots(root)
    if len(snaps) <= keep:
        return []
    to_delete = snaps[:-keep]
    for s in to_delete:
        shutil.rmtree(s.path, ignore_errors=True)
    return to_delete


def write_image_pinning_override(snap: Snapshot) -> Path | None:
    """Generate a compose override that pins each service to its snapshotted digest.

    Returns the override path, or None if no usable digests are recorded.
    """
    if not snap.images_json.exists():
        return None
    data = json.loads(snap.images_json.read_text())
    services: dict[str, dict] = {}
    for svc, meta in data.items():
        digest = meta.get("digest")
        image = meta.get("image")
        if digest and image and "@" not in image:
            # `image@sha256:...` form pins by content digest, image-tag independent.
            base = image.split("@")[0].rsplit(":", 1)[0]
            services[svc] = {"image": f"{base}@{digest}"}
        elif image:
            services[svc] = {"image": image}
    if not services:
        return None
    override = snap.path / "override.images.yml"
    lines = ["services:"]
    for name, body in services.items():
        lines.append(f"  {name}:")
        for k, v in body.items():
            lines.append(f"    {k}: {v}")
    override.write_text("\n".join(lines) + "\n")
    return override
