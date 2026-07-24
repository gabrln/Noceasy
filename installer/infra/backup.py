"""Backup creation and retention (replaces installer/lib/backup.sh).

Differences from the bash version:
    - Collision suffix .1/.2/... when basenames collide
    - Different ownership handling: ~/.config/* preserves user
      ownership, /etc/* uses --no-preserve=ownership
    - max_backups retention (read from config.toml)
"""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from installer.core.config import BACKUPS_DIR, DEFAULT_MAX_BACKUP_BYTES, get_config
from installer.infra.exec import run
from installer.platform import privesc
from installer.ui.logger import log


def init_backups() -> Path:
    """Create the backup root directory. Returns the path."""
    BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
    return BACKUPS_DIR


def _unique_name(dest: Path, base: str) -> str:
    """Find a non-colliding name in `dest` (e.g. '.zshrc' -> '.zshrc.1')."""
    candidate = base
    n = 1
    while (dest / candidate).exists():
        candidate = f"{base}.{n}"
        n += 1
    return candidate


def _is_system_path(p: Path) -> bool:
    """System paths lose ownership; user paths keep it."""
    s = p.as_posix()
    return s.startswith(("/etc/", "/usr/", "/var/"))


def _timestamp() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S")


@dataclass
class _CreatedBackup:
    name: str
    copied: list[Path]


def create(label: str, paths: list[Path], sudo_password: str | None = None) -> _CreatedBackup:
    """Create a snapshot. Logs progress; returns the snapshot name."""
    if not BACKUPS_DIR.exists():
        init_backups()

    name = f"{label}-{_timestamp()}"
    dest = BACKUPS_DIR / name
    dest.mkdir(parents=True, exist_ok=True)

    log("info", f"Creating backup '{name}'...")
    copied: list[Path] = []

    for path in paths:
        if not path.exists():
            log("warn", f"  -> {path} does not exist, skipping.")
            continue
        base = path.name
        target_name = _unique_name(dest, base)
        target = dest / target_name
        if _is_system_path(path):
            # -a --no-preserve=ownership: copy attrs but force root
            argv = ["cp", "-a", "--no-preserve=ownership",
                    str(path), str(target)]
            proc = privesc.run_privileged(argv, sudo_password)
        else:
            # Preserve ownership (e.g. dotfiles in ~)
            argv = ["cp", "-a", str(path), str(target)]
            proc = run(argv)
        if proc.returncode == 0:
            log("info", f"  -> {path}")
            copied.append(target)
        else:
            err = proc.stderr.strip() if proc.stderr else "unknown error"
            log("warn", f"  -> failed to copy {path}: {err}")

    # Apply retention
    max_backups = get_config("flags.max_backups", 3)
    try:
        max_backups = int(max_backups)
    except (TypeError, ValueError):
        max_backups = 3
    if max_backups > 0:
        _apply_retention(label, max_backups)

    return _CreatedBackup(name=name, copied=copied)


def _apply_retention(label: str, max_keep: int) -> None:
    """Keep only the most recent `max_keep` snapshots with this label."""
    if max_keep <= 0:
        return
    snaps = sorted(
        [p for p in BACKUPS_DIR.iterdir()
         if p.is_dir() and p.name.startswith(f"{label}-")],
        key=lambda p: p.name,
        reverse=True,
    )

    # First: apply count limit
    for old in snaps[max_keep:]:
        log("info", f"  -> removing old backup (count limit): {old.name}")
        shutil.rmtree(old, ignore_errors=True)
        snaps.remove(old)

    # Second: apply size limit
    max_bytes = get_config("flags.max_backup_bytes", DEFAULT_MAX_BACKUP_BYTES)
    try:
        max_bytes = int(max_bytes)
    except (TypeError, ValueError):
        max_bytes = DEFAULT_MAX_BACKUP_BYTES

    if max_bytes > 0:
        total = sum(_dir_size(s) for s in snaps)
        while total > max_bytes and len(snaps) > 1:
            oldest = snaps.pop()
            size = _dir_size(oldest)
            log("info",
                f"  -> removing old backup (size limit): {oldest.name} "
                f"({size / 1024 / 1024:.1f} MiB)")
            shutil.rmtree(oldest, ignore_errors=True)
            total -= size


def _dir_size(path: Path) -> int:
    """Total size of a directory in bytes."""
    return sum(f.stat().st_size for f in path.rglob("*") if f.is_file())
