"""Helpers shared across modules."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from typing import List, Optional, Sequence, Union

from installer.logger import log
from installer.privilege import run_as_user


def is_command(name: str) -> bool:
    return shutil.which(name) is not None


def is_command_user(name: str, user: str) -> bool:
    """Check if `name` is in the user's PATH."""
    proc = run_as_user(["command", "-v", name], user=user, login=False,
                        check=False, capture=True)
    return proc.returncode == 0


def has_internet() -> bool:
    try:
        return subprocess.run(
            ["curl", "-fsSI", "--max-time", "5", "https://github.com"],
            check=False, capture_output=True, timeout=10,
        ).returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def has_free_space(paths: Sequence[Path], min_bytes: int = 5 * 1024**3) -> bool:
    ok = True
    for path in paths:
        if not path.exists():
            continue
        try:
            st = os.statvfs(path)
            available = st.f_bavail * st.f_frsize
            if available < min_bytes:
                log("warn", f"Espaço em {path}: {available} bytes (mínimo: {min_bytes}).")
                ok = False
        except OSError:
            pass
    return ok


def pkg_installed(pkg: str) -> bool:
    try:
        return subprocess.run(
            ["pacman", "-Q", pkg],
            check=False, capture_output=True,
        ).returncode == 0
    except FileNotFoundError:
        return False


def systemd_unit_exists(unit: str) -> bool:
    try:
        return subprocess.run(
            ["systemctl", "list-unit-files", unit],
            check=False, capture_output=True,
        ).returncode == 0
    except FileNotFoundError:
        return False


def chown_user(path: Path, user: str) -> None:
    """chown `path` to `user:user`. Creates path if missing."""
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
    subprocess.run(["chown", "-R", f"{user}:{user}", str(path)],
                    check=False, capture_output=True)


def backup_user_files() -> Optional[str]:
    """Snapshot the user's existing config files before they're overwritten.

    Returns the snapshot name (or None if no paths to back up).
    Imported lazily to avoid circular imports.
    """
    from installer.backup import create
    from installer.config import MANIFESTS_DIR
    from installer.toml_cache import get_cache

    cache = get_cache()
    home = Path(os.environ["USER_HOME"])
    paths: List[Path] = []

    for cfg in cache.get_list("dotfiles.toml", "directories.configs"):
        paths.append(home / ".config" / cfg)
    paths.append(home / ".config" / "zsh")
    for f in cache.get_list("dotfiles.toml", "files"):
        # Files are stored as "key" -> "$HOME/.path"; we read the values
        # but the cache key is the source path. We rebuild from the toml.
        # Simpler: read the entire dotfiles.toml and resolve.
        pass
    # Read full dotfiles.toml for `files` map
    dotfiles = cache.load("dotfiles.toml")
    import os as _os
    home_str = str(home)
    for _src, dst in dotfiles.get("files", {}).items():
        expanded = _os.path.expandvars(dst)
        if expanded.startswith("~"):
            expanded = home_str + expanded[1:]
        paths.append(Path(expanded))
    paths.append(Path("/etc/greetd"))
    paths.append(Path("/etc/pam.d/greetd"))

    result = create("pre-install", paths)
    return result.name
