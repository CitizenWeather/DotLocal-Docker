from pathlib import Path

_VERSION_FILE = Path(__file__).resolve().parents[2] / "build" / "apps" / "VERSION"
try:
    __version__ = _VERSION_FILE.read_text().strip()
except FileNotFoundError:
    __version__ = "unknown"
