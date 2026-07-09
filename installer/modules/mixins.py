"""Helpers shared across modules."""

from __future__ import annotations

import os
import shutil
import subprocess
import time
from pathlib import Path
from typing import List, Optional, Sequence

from installer.config import (
    DEFAULT_MIN_FREE_BYTES,
    NETWORK_RETRY_ATTEMPTS,
    NETWORK_RETRY_BASE_SECONDS,
)
from installer.logger import log
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def is_command(name: str) -> bool:
    """True if `name` is in the current PATH."""
    return shutil.which(name) is not None


def is_command_user(name: str, user: str) -> bool:
    """True if `name` is in `user`'s PATH."""
    proc = run_as_user(["command", "-v", name], user=user, login=False,
                        check=False, capture=True)
    return proc.returncode == 0


def has_internet() -> bool:
    """True if github.com is reachable."""
    try:
        return subprocess.run(
            ["curl", "-fsSI", "--max-time", "5", "https://github.com"],
            check=False, capture_output=True, timeout=10,
        ).returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


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
    try:
        return subprocess.run(
            ["pacman", "-Q", pkg],
            check=False, capture_output=True,
        ).returncode == 0
    except FileNotFoundError:
        return False


def systemd_unit_exists(unit: str) -> bool:
    """True if the systemd unit file is known."""
    try:
        return subprocess.run(
            ["systemctl", "list-unit-files", unit],
            check=False, capture_output=True,
        ).returncode == 0
    except FileNotFoundError:
        return False


def chown_user(path: Path, user: str) -> None:
    """chown -R `path` to `user:user`. Creates the path if missing."""
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
    subprocess.run(["chown", "-R", f"{user}:{user}", str(path)],
                    check=False, capture_output=True)


def chown_user_path(path: Path, user: str) -> None:
    """Alias for chown_user (used in some modules for clarity)."""
    chown_user(path, user)


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


def backup_user_files() -> Optional[str]:
    """Snapshot the user's existing config files before they're overwritten.

    Returns the snapshot name (or None if no paths to back up).
    Imported lazily to avoid circular imports.
    """
    from installer.backup import create
    from installer.config import MANIFESTS_DIR

    cache = get_cache()
    home = Path(os.environ["USER_HOME"])
    paths: List[Path] = []

    for cfg in cache.get_list("dotfiles.toml", "directories.configs"):
        paths.append(home / ".config" / cfg)
    paths.append(home / ".config" / "zsh")

    # Read full dotfiles.toml for `files` map
    dotfiles = cache.load("dotfiles.toml")
    home_str = str(home)
    for _src, dst in dotfiles.get("files", {}).items():
        expanded = os.path.expandvars(dst)
        if expanded.startswith("~"):
            expanded = home_str + expanded[1:]
        paths.append(Path(expanded))

    paths.append(Path("/etc/greetd"))
    paths.append(Path("/etc/pam.d/greetd"))

    result = create("pre-install", paths)
    return result.name
