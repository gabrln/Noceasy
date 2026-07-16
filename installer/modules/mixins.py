"""Helpers shared across modules."""

from __future__ import annotations

import os
import shutil
import subprocess
import time
from pathlib import Path
from typing import Sequence

from installer.backup import create as backup_create
from installer.config import (
    DEFAULT_MIN_FREE_BYTES,
    NETWORK_RETRY_ATTEMPTS,
    NETWORK_RETRY_BASE_SECONDS,
)
from installer.exec import run
from installer.logger import log
from installer import privesc
from installer.toml_cache import get_cache


def is_command(name: str) -> bool:
    """True if `name` is in the current PATH."""
    return shutil.which(name) is not None


def has_internet() -> bool:
    """True if github.com is reachable."""
    return run(["curl", "-fsSI", "--max-time", "5", "https://github.com"],
                timeout=10).returncode == 0


def has_free_space(paths: Sequence[Path],
                    min_bytes: int = DEFAULT_MIN_FREE_BYTES) -> bool:
    """True if all `paths` have at least `min_bytes` available."""
    ok = True
    for path in paths:
        if not path.exists():
            continue
        try:
            st = os.statvfs(path)
            available = st.f_bavail * st.f_frsize
            if available < min_bytes:
                log("warn",
                    f"Space on {path}: {available} bytes "
                    f"(minimum: {min_bytes}).")
                ok = False
        except OSError:
            pass
    return ok


def pkg_installed(pkg: str) -> bool:
    """True if `pkg` is installed via pacman."""
    return run(["pacman", "-Q", pkg]).returncode == 0


def systemd_unit_exists(unit: str) -> bool:
    """True if the systemd unit file is known."""
    return run(["systemctl", "list-unit-files", unit]).returncode == 0


def chown_user(path: Path, user: str, sudo_password: str | None = None) -> None:
    """chown -R `path` to `user:user`. Creates the path if missing."""
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
    privesc.run_privileged(
        ["chown", "-R", f"{user}:{user}", str(path)],
        sudo_password,
    )


def chown_user_path(path: Path, user: str, sudo_password: str | None = None) -> None:
    """Alias for chown_user (used in some modules for clarity)."""
    chown_user(path, user, sudo_password)


def retry_with_backoff(callable_fn, *args,
                        attempts: int = NETWORK_RETRY_ATTEMPTS,
                        base_seconds: int = NETWORK_RETRY_BASE_SECONDS,
                        **kwargs) -> bool:
    """Run `callable_fn(*args, **kwargs)` with exponential backoff.

    Returns True on first success, False after all attempts fail.
    """
    for i in range(attempts):
        if callable_fn(*args, **kwargs):
            return True
        if i < attempts - 1:
            time.sleep(base_seconds ** i)
    return False


def _collect_backup_paths(user_home: Path) -> list[Path]:
    """Collect all user config paths that should be backed up.

    Reads the dotfiles manifest to discover config directories and
    individual files, then appends system-wide paths that the
    installer overwrites.
    """
    cache = get_cache()

    paths: list[Path] = []

    # Config directories from dotfiles.toml
    for cfg in cache.get_list("dotfiles.toml", "directories.configs"):
        paths.append(user_home / ".config" / cfg)
    paths.append(user_home / ".config" / "zsh")

    # Individual files from dotfiles.toml
    dotfiles = cache.load("dotfiles.toml")
    home_str = str(user_home)
    for _src, dst in dotfiles.get("files", {}).items():
        expanded = os.path.expandvars(dst)
        if expanded.startswith("~"):
            expanded = home_str + expanded[1:]
        paths.append(Path(expanded))

    # System paths
    paths.append(Path("/etc/greetd"))
    paths.append(Path("/etc/pam.d/greetd"))

    return paths


def backup_user_files(user_home: Path, sudo_password: str | None = None) -> str | None:
    """Snapshot the user's existing config files before they're overwritten.

    Returns the snapshot name (or None if no paths to back up).
    """
    paths = _collect_backup_paths(user_home)
    result = backup_create("pre-install", paths, sudo_password=sudo_password)
    return result.name
