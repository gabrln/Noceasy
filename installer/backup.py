"""Backup creation and restore (replaces installer/lib/backup.sh).

Differences from the bash version:
    - Collision suffix .1/.2/... when basenames collide
    - Different ownership handling: ~/.config/* preserves user ownership,
      /etc/* uses --no-preserve=ownership
    - max_backups retention (read from config.toml)
    - Atomic restore via staging directory
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from installer.config import BACKUPS_DIR, CONFIG_FILE, get_config
from installer.logger import log


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
    s = str(p)
    return s.startswith(("/etc/", "/usr/", "/var/"))


def _timestamp() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S")


@dataclass
class _CreatedBackup:
    name: str
    copied: List[Path]


def create(label: str, paths: List[Path]) -> _CreatedBackup:
    """Create a snapshot. Logs to stdout/stderr, returns the snapshot name."""
    if not BACKUPS_DIR.exists():
        init_backups()

    name = f"{label}-{_timestamp()}"
    dest = BACKUPS_DIR / name
    dest.mkdir(parents=True, exist_ok=True)

    log("info", f"Criando backup '{name}'...")
    copied: List[Path] = []

    for path in paths:
        if not path.exists():
            log("warn", f"  → {path} não existe, pulando.")
            continue
        base = path.name
        target_name = _unique_name(dest, base)
        target = dest / target_name
        try:
            if _is_system_path(path):
                # -a --no-preserve=ownership: copy attrs but force root
                subprocess.run(
                    ["cp", "-a", "--no-preserve=ownership", str(path), str(target)],
                    check=True, capture_output=True,
                )
            else:
                # Preserve ownership (e.g. dotfiles in ~)
                subprocess.run(
                    ["cp", "-a", str(path), str(target)],
                    check=True, capture_output=True,
                )
            log("info", f"  → {path}")
            copied.append(target)
        except subprocess.CalledProcessError as exc:
            log("warn", f"  → falha ao copiar {path}: {exc.stderr.decode().strip()}")

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
    snaps = sorted(
        [p for p in BACKUPS_DIR.iterdir() if p.is_dir() and p.name.startswith(f"{label}-")],
        key=lambda p: p.name,
        reverse=True,
    )
    for old in snaps[max_keep:]:
        log("info", f"  → removendo backup antigo: {old.name}")
        shutil.rmtree(old, ignore_errors=True)


def list_snapshots(label: Optional[str] = None) -> List[str]:
    """List snapshot names, most recent first. Optionally filtered by label."""
    if not BACKUPS_DIR.exists():
        return []
    all_snaps = sorted(
        [p.name for p in BACKUPS_DIR.iterdir() if p.is_dir()],
        reverse=True,
    )
    if label:
        return [n for n in all_snaps if n.startswith(f"{label}-")]
    return all_snaps


def restore(label: str) -> bool:
    """Restore the most recent snapshot with the given label."""
    snaps = list_snapshots(label=label)
    if not snaps:
        log("error", f"Nenhum backup encontrado com label '{label}'.")
        return False

    latest = snaps[0]
    src = BACKUPS_DIR / latest
    log("warn", f"Isso sobrescreverá os arquivos atuais com o backup '{latest}'.")

    # Interactive confirmation
    if not _confirm("Continuar com o rollback?"):
        log("info", "Rollback cancelado.")
        return True

    log("info", f"Restaurando backup '{latest}'...")
    for item in src.iterdir():
        target = _resolve_target(item.name)
        if target is None:
            log("warn", f"  → destino desconhecido para {item.name}, pulando.")
            continue

        # Atomic restore: copy to staging, then rm + mv
        staging = Path(tempfile.mkdtemp(prefix="gabrln-restore-"))
        try:
            shutil.copytree(item, staging / target.name)
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() or target.is_symlink():
                if target.is_symlink() or target.is_file():
                    target.unlink()
                else:
                    shutil.rmtree(target)
            (staging / target.name).rename(target)
        except OSError as exc:
            log("warn", f"  → falha ao restaurar {item.name}: {exc}")
            continue
        finally:
            shutil.rmtree(staging, ignore_errors=True)

        # Restore ownership for user paths
        if not _is_system_path(target):
            try:
                import os
                uid = int(os.environ.get("SUDO_UID", "0"))
                gid = int(os.environ.get("SUDO_GID", "0"))
                if uid and gid:
                    subprocess.run(
                        ["chown", "-R", f"{uid}:{gid}", str(target)],
                        check=False, capture_output=True,
                    )
            except (ValueError, OSError):
                pass

        log("info", f"  → {target}")

    log("success", f"Backup '{latest}' restaurado.")
    return True


def _confirm(prompt: str, default_yes: bool = False) -> bool:
    """Read a y/N confirmation from stdin."""
    suffix = "[Y/n]" if default_yes else "[y/N]"
    try:
        response = input(f"{prompt} {suffix} ").strip().lower()
    except EOFError:
        return False
    if not response:
        return default_yes
    return response in ("y", "s", "yes", "sim")


def _resolve_target(name: str) -> Optional[Path]:
    """Map a backup item basename to its original target path."""
    import os
    user_home = Path(os.environ.get("USER_HOME", "/root"))

    # Strip .N collision suffix for matching
    stripped = name
    for i in range(100, -1, -1):
        suffix = f".{i}" if i > 0 else ""
        if stripped.endswith(suffix):
            stripped = stripped[: -len(suffix)] if suffix else stripped
            break

    if stripped == ".config":
        return user_home / ".config"
    if stripped == "greetd":
        return Path("/etc/greetd")
    if stripped == "pam_greetd":
        return Path("/etc/pam.d/greetd")
    return user_home / stripped
