"""State persistence (replaces installer/lib/state.sh).

Two layers:
  - ``JsonStore``: atomic JSON file with flock-based serialization.
  - ``State``: module status tracking (which modules have run).
"""

from __future__ import annotations

import fcntl
import hashlib
import json
import os
import tempfile
import time
from pathlib import Path

from installer.config import STATE_DIR, STATE_FILE, LOCK_TIMEOUT_SECONDS
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


def _iso_now() -> str:
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# JsonStore — atomic JSON with flock serialization
# ---------------------------------------------------------------------------


class JsonStore:
    """Atomic JSON file with flock-based serialization.

    Handles locking, atomic writes (tempfile + fsync + rename),
    and corruption recovery.  Does not know about modules or
    manifests — that logic lives in ``State``.
    """

    def __init__(self, path: Path, lock_path: Path | None = None):
        self.path = path
        self._lock_path = lock_path or path.parent / f".{path.name}.lock"
        self._lock_fd: int | None = None
        self.path.parent.mkdir(parents=True, exist_ok=True)

    # -- Context manager (lock) ------------------------------------------

    def __enter__(self) -> "JsonStore":
        self._lock_fd = os.open(str(self._lock_path),
                                os.O_CREAT | os.O_RDWR, 0o600)
        try:
            fcntl.flock(self._lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            deadline = time.monotonic() + LOCK_TIMEOUT_SECONDS
            while time.monotonic() < deadline:
                try:
                    fcntl.flock(self._lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    time.sleep(0.1)
            else:
                log("warn",
                    f"Could not acquire lock for {self.path.name} "
                    f"after {LOCK_TIMEOUT_SECONDS}s.")
        return self

    def __exit__(self, *args) -> None:
        if self._lock_fd is not None:
            fcntl.flock(self._lock_fd, fcntl.LOCK_UN)
            os.close(self._lock_fd)
            self._lock_fd = None

    # -- Read / Write ----------------------------------------------------

    def read(self) -> dict:
        """Read JSON, returning ``{}`` on any error.

        If the file is corrupted it is moved aside and an empty
        file is created.
        """
        try:
            return json.loads(self.path.read_text() or "{}")
        except (OSError, json.JSONDecodeError) as exc:
            log("warn", f"{self.path.name} corrupted: {exc}. Backing up.")
            backup = self.path.parent / \
                f"{self.path.name}.corrupt-{int(time.time())}"
            try:
                self.path.rename(backup)
            except OSError:
                pass
            self.write({})
            return {}

    def write(self, data: dict) -> None:
        """Write JSON atomically (tempfile + fsync + rename)."""
        dirpath = self.path.parent or Path(".")
        fd, tmp = tempfile.mkstemp(dir=str(dirpath), prefix=".", suffix=".tmp")
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

    # -- Generic key-value -----------------------------------------------

    def get(self, key: str, field: str) -> str:
        data = self.read()
        return str(data.get(key, {}).get(field, ""))

    def set(self, key: str, field: str, value: str) -> None:
        with self:
            data = self.read()
            data.setdefault(key, {})[field] = value
            self.write(data)


# ---------------------------------------------------------------------------
# State — module status tracking
# ---------------------------------------------------------------------------


class State:
    """Tracks which modules have been run via state.json.

    Uses ``JsonStore`` for persistence and locking.  Contains only
    module-specific logic (status, manifest hashing).
    """

    def __init__(self, path: Path = STATE_FILE, dir_: Path = STATE_DIR):
        self._dir = dir_
        self._dir.mkdir(parents=True, exist_ok=True)
        self._dir.chmod(0o700)
        self._store = JsonStore(path, lock_path=self._dir / ".state.lock")
        if not self._store.path.exists():
            self._store.write({})
            self._store.path.chmod(0o600)

    # -- Module status ---------------------------------------------------

    def is_up_to_date(self, module: str, manifest: Path | None) -> bool:
        data = self._store.read()
        if data.get(module, {}).get("status") != "done":
            return False
        if manifest is None or not manifest.exists():
            return True
        current = hash_file(manifest)
        stored = data.get(module, {}).get("manifest_hash", "")
        return current == stored

    def mark_done(self, module: str, manifest: Path | None) -> None:
        with self._store:
            data = self._store.read()
            entry = data.setdefault(module, {})
            entry["status"] = "done"
            entry["completed_at"] = _iso_now()
            entry["manifest_hash"] = (
                hash_file(manifest) if manifest and manifest.exists() else ""
            )
            self._store.write(data)

    def mark_failed(self, module: str, reason: str) -> None:
        with self._store:
            data = self._store.read()
            entry = data.setdefault(module, {})
            entry["status"] = "failed"
            entry["failure_reason"] = reason
            entry["failed_at"] = _iso_now()
            self._store.write(data)

    # -- Generic key-value (delegates to store) --------------------------

    def get(self, module: str, field: str) -> str:
        return self._store.get(module, field)

    def set(self, module: str, field: str, value: str) -> None:
        self._store.set(module, field, value)
