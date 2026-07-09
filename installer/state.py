"""State persistence (replaces installer/lib/state.sh).

state.json tracks which modules have been run. Writes are atomic
(tempfile + os.replace) and serialized with fcntl.flock.
"""

from __future__ import annotations

import fcntl
import hashlib
import json
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from installer.config import STATE_DIR, STATE_FILE
from installer.errors import fatal
from installer.logger import log


def hash_file(path: Path) -> str:
    """SHA256 of a file or directory (deterministic)."""
    if path.is_file():
        h = hashlib.sha256()
        with path.open("rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        return h.hexdigest()
    if path.is_dir():
        h = hashlib.sha256()
        for sub in sorted(path.rglob("*")):
            if sub.is_file():
                with sub.open("rb") as f:
                    for chunk in iter(lambda: f.read(1 << 20), b""):
                        h.update(chunk)
        return h.hexdigest()
    return ""


@dataclass
class _LockedFile:
    """File handle held while flock is acquired."""

    fd: int


class State:
    """state.json wrapper with atomic writes and flock serialization."""

    def __init__(self, path: Path = STATE_FILE, dir_: Path = STATE_DIR):
        self.path = path
        self.dir = dir_
        self.dir.mkdir(parents=True, exist_ok=True)
        self.dir.chmod(0o700)
        if not self.path.exists():
            self._write_unlocked({})
            self.path.chmod(0o600)
        self._lock_path = self.dir / ".state.lock"
        self._lock_fd: Optional[int] = None

    def _read_unlocked(self) -> dict:
        try:
            return json.loads(self.path.read_text() or "{}")
        except (OSError, json.JSONDecodeError) as exc:
            import time
            log("warn", f"state.json corrompido: {exc}. Fazendo backup e recriando.")
            backup = self.dir / f"state.json.corrupt-{int(time.time())}"
            try:
                self.path.rename(backup)
            except OSError:
                pass
            self._write_unlocked({})
            return {}

    def _write_unlocked(self, data: dict) -> None:
        fd, tmp = tempfile.mkstemp(
            dir=str(self.dir), prefix=".state.", suffix=".tmp"
        )
        try:
            with os.fdopen(fd, "w") as f:
                json.dump(data, f, indent=2, sort_keys=True)
                f.flush()
                os.fsync(f.fileno())
            os.chmod(tmp, 0o600)
            os.replace(tmp, self.path)
        except Exception:
            if os.path.exists(tmp):
                os.unlink(tmp)
            raise

    def __enter__(self) -> "State":
        self._lock_fd = os.open(str(self._lock_path), os.O_CREAT | os.O_RDWR, 0o600)
        fcntl.flock(self._lock_fd, fcntl.LOCK_EX)
        return self

    def __exit__(self, *args) -> None:
        if self._lock_fd is not None:
            fcntl.flock(self._lock_fd, fcntl.LOCK_UN)
            os.close(self._lock_fd)
            self._lock_fd = None

    def get(self, module: str, field: str) -> str:
        data = self._read_unlocked()
        return str(data.get(module, {}).get(field, ""))

    def set(self, module: str, field: str, value: str) -> None:
        with self:
            data = self._read_unlocked()
            data.setdefault(module, {})[field] = value
            self._write_unlocked(data)

    def is_up_to_date(self, module: str, manifest: Optional[Path]) -> bool:
        with self:
            data = self._read_unlocked()
        if data.get(module, {}).get("status") != "done":
            return False
        if manifest is None or not manifest.exists():
            return True
        current = hash_file(manifest)
        stored = data.get(module, {}).get("manifest_hash", "")
        return current == stored

    def mark_done(self, module: str, manifest: Optional[Path]) -> None:
        with self:
            data = self._read_unlocked()
            entry = data.setdefault(module, {})
            entry["status"] = "done"
            entry["completed_at"] = _iso_now()
            entry["manifest_hash"] = hash_file(manifest) if manifest and manifest.exists() else ""
            self._write_unlocked(data)

    def mark_failed(self, module: str, reason: str) -> None:
        with self:
            data = self._read_unlocked()
            entry = data.setdefault(module, {})
            entry["status"] = "failed"
            entry["failure_reason"] = reason
            entry["failed_at"] = _iso_now()
            self._write_unlocked(data)


def _iso_now() -> str:
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()
