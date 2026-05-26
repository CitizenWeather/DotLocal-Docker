"""Argparse dispatch — the entry point invoked by `scripts/dotlocal`."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import __version__, apply as applymod, audit, engine, plan as planmod, snapshot


def _build_ctx(args: argparse.Namespace, *, with_auto: bool = False) -> engine.Context:
    return engine.Context(
        root=Path(args.root).resolve(),
        project=args.project,
        compose_files=engine.split_compose_files(args.compose_files),
        auto_approve=getattr(args, "auto_approve", False) if with_auto else False,
        skip_pull=getattr(args, "skip_pull", False),
        force=getattr(args, "force", False),
        allow_major=getattr(args, "allow_major", False),
        json_output=getattr(args, "json", False),
    )


def cmd_plan(args: argparse.Namespace) -> int:
    ctx = _build_ctx(args)
    p = planmod.compute_plan(ctx)
    if args.json:
        sys.stdout.write(p.to_json() + "\n")
    else:
        sys.stdout.write(planmod.render_text(p))
    return 0 if p.empty else 2  # exit 2 signals "changes pending" for scripting


def cmd_apply(args: argparse.Namespace) -> int:
    ctx = _build_ctx(args, with_auto=True)
    p = planmod.compute_plan(ctx)
    try:
        applymod.run_apply(ctx, p, source="apply")
    except engine.ApplyError as exc:
        sys.stderr.write(f"apply failed: {exc}\n")
        return 1
    return 0


def cmd_rollback(args: argparse.Namespace) -> int:
    ctx = _build_ctx(args, with_auto=True)
    root = Path(args.root).resolve()
    if args.snapshot:
        candidate = root / snapshot.SNAPSHOT_ROOT / args.snapshot
        if not candidate.is_dir():
            sys.stderr.write(f"no such snapshot: {candidate}\n")
            return 1
        snap = snapshot.Snapshot(path=candidate, timestamp=args.snapshot)
    else:
        snap = snapshot.latest(root)
        if snap is None:
            sys.stderr.write("no snapshots found under volumes/_apply/\n")
            return 1
    try:
        applymod.run_rollback(ctx, snap)
    except engine.ApplyError as exc:
        sys.stderr.write(f"rollback failed: {exc}\n")
        return 1
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    entry = audit.latest(root)
    if not entry:
        sys.stdout.write("no apply history yet.\n")
        return 0
    if args.json:
        sys.stdout.write(json.dumps(entry, indent=2) + "\n")
        return 0
    sys.stdout.write(
        f"Last apply: {entry['ts']}\n"
        f"  user:     {entry['user']}\n"
        f"  cmd:      {entry['cmd']}\n"
        f"  result:   {entry['result']}\n"
        f"  duration: {entry['duration_s']}s\n"
        f"  snapshot: {entry['snapshot']}\n"
    )
    if entry.get("error"):
        sys.stdout.write(f"  error:    {entry['error']}\n")
    return 0


def cmd_history(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    entries = audit.read_all(root)
    if args.prune:
        pruned = snapshot.prune(root)
        sys.stdout.write(f"pruned {len(pruned)} snapshot(s) older than retention.\n")
        return 0
    if args.json:
        sys.stdout.write(json.dumps(entries, indent=2) + "\n")
        return 0
    if not entries:
        sys.stdout.write("no apply history yet.\n")
        return 0
    sys.stdout.write(f"{'TIMESTAMP':<22} {'CMD':<20} {'RESULT':<8} {'DUR':>7} SNAPSHOT\n")
    for e in entries[-20:]:
        sys.stdout.write(
            f"{e['ts'][:19]:<22} {e['cmd'][:20]:<20} {e['result']:<8} "
            f"{e['duration_s']:>6.1f}s {e.get('snapshot') or ''}\n"
        )
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dotlocal")
    parser.add_argument("--root", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--compose-files", required=True,
                        help="space-separated `-f path` tokens")
    parser.add_argument("--version", action="version", version=f"dotlocal {__version__}")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("plan", help="show desired vs running diff")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_plan)

    a = sub.add_parser("apply", help="reconcile running stack to desired state")
    a.add_argument("--auto-approve", action="store_true")
    a.add_argument("--skip-pull", action="store_true")
    a.add_argument("--force", action="store_true",
                   help="continue past drain/smoke failures")
    a.add_argument("--allow-major", action="store_true",
                   help="permit recreate across major-version bumps on stateful services")
    a.set_defaults(func=cmd_apply)

    r = sub.add_parser("rollback", help="restore a previous snapshot")
    r.add_argument("snapshot", nargs="?", help="timestamp (default: most recent)")
    r.add_argument("--auto-approve", action="store_true")
    r.add_argument("--skip-pull", action="store_true", default=True)
    r.set_defaults(func=cmd_rollback)

    s = sub.add_parser("status", help="summarise the most recent apply")
    s.add_argument("--json", action="store_true")
    s.set_defaults(func=cmd_status)

    h = sub.add_parser("history", help="list / prune past applies")
    h.add_argument("--json", action="store_true")
    h.add_argument("--prune", action="store_true")
    h.set_defaults(func=cmd_history)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
