from pathlib import Path

from scripts.dotlocal_lib import audit


def test_append_writes_jsonl(tmp_path: Path):
    e1 = audit.Entry(cmd="apply", result="success", duration_s=1.5)
    e2 = audit.Entry(cmd="rollback", result="success", duration_s=2.5)
    audit.append(tmp_path, e1)
    audit.append(tmp_path, e2)
    entries = audit.read_all(tmp_path)
    assert len(entries) == 2
    assert entries[0]["cmd"] == "apply"
    assert entries[1]["cmd"] == "rollback"
    assert audit.latest(tmp_path)["cmd"] == "rollback"


def test_read_all_handles_missing_file(tmp_path: Path):
    assert audit.read_all(tmp_path) == []
    assert audit.latest(tmp_path) is None


def test_entry_round_trips_json(tmp_path: Path):
    e = audit.Entry(
        cmd="apply",
        snapshot="volumes/_apply/20260101T000000Z",
        summary={"create": 1, "recreate": 2},
        result="success",
        duration_s=3.14,
    )
    audit.append(tmp_path, e)
    [back] = audit.read_all(tmp_path)
    assert back["cmd"] == "apply"
    assert back["summary"] == {"create": 1, "recreate": 2}
    assert back["duration_s"] == 3.14
