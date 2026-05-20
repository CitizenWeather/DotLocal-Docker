"""Shared orchestration primitives: compose shell-out, logging, errors."""
from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


class ApplyError(RuntimeError):
    """Raised when the apply pipeline fails and rollback should be offered."""


@dataclass(frozen=True)
class Context:
    root: Path
    project: str
    compose_files: tuple[str, ...]   # already split tokens, e.g. ("-f", "a.yml", "-f", "b.yml")
    auto_approve: bool = False
    skip_pull: bool = False
    force: bool = False
    allow_major: bool = False
    json_output: bool = False

    @property
    def compose_args(self) -> list[str]:
        return ["docker", "compose", "--project-name", self.project, *self.compose_files]


def split_compose_files(raw: str) -> tuple[str, ...]:
    """Parse the COMPOSE_FILES string built by compose_files.sh."""
    return tuple(shlex.split(raw))


def log(msg: str, *, stream=sys.stderr) -> None:
    stream.write(msg.rstrip() + "\n")
    stream.flush()


def run(ctx: Context, *args: str, check: bool = True, capture: bool = False,
        env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    cmd = [*ctx.compose_args, *args]
    full_env = os.environ.copy()
    if env:
        full_env.update(env)
    if capture:
        proc = subprocess.run(cmd, cwd=ctx.root, env=full_env, check=False,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    else:
        proc = subprocess.run(cmd, cwd=ctx.root, env=full_env, check=False)
    if check and proc.returncode != 0:
        if capture:
            sys.stderr.write(proc.stderr or "")
        raise ApplyError(f"`docker compose {' '.join(args)}` failed (exit {proc.returncode})")
    return proc


def run_raw(cmd: Iterable[str], *, cwd: Path | None = None, check: bool = True,
            capture: bool = True, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    full_env = os.environ.copy()
    if env:
        full_env.update(env)
    proc = subprocess.run(
        list(cmd), cwd=cwd, env=full_env, check=False,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        text=True,
    )
    if check and proc.returncode != 0:
        if capture:
            sys.stderr.write(proc.stderr or "")
        raise ApplyError(f"command failed (exit {proc.returncode}): {' '.join(cmd)}")
    return proc


def compose_config_json(ctx: Context) -> dict:
    """Resolved compose configuration as a Python dict."""
    proc = run(ctx, "config", "--format", "json", capture=True)
    return json.loads(proc.stdout)


def compose_service_hash(ctx: Context, service: str) -> str | None:
    """Canonical config hash that `docker compose` would attach as a label.

    Returns None if the running compose version does not support `--hash`.
    """
    proc = run(ctx, "config", "--hash", service, capture=True, check=False)
    if proc.returncode != 0:
        return None
    out = proc.stdout.strip()
    if not out:
        return None
    # Output format: "<service> <hash>"
    parts = out.split()
    return parts[-1] if parts else None


def docker_ps_json(ctx: Context) -> list[dict]:
    """All compose containers in the project (running or stopped)."""
    proc = run(ctx, "ps", "--all", "--format", "json", capture=True)
    items: list[dict] = []
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            items.append(json.loads(line))
        except json.JSONDecodeError:
            # Older compose emits a single JSON array
            try:
                items.extend(json.loads(line))
            except json.JSONDecodeError:
                continue
    return items


def docker_inspect(container_id: str) -> dict:
    proc = run_raw(["docker", "inspect", container_id], capture=True)
    data = json.loads(proc.stdout)
    return data[0] if data else {}
