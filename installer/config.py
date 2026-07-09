"""Paths, constants and config.toml loader.

The bootstrap (install.sh) sets REPO_DIR by chdir to the repo root
and running `python3 -m installer`. INSTALLER_DIR is always
REPO_DIR/installer. All other paths are derived from INSTALLER_DIR
unless the user provides a config override.
"""

from __future__ import annotations

import os
import tomllib
from pathlib import Path
from typing import Any


def _find_repo_root() -> Path:
    """Locate the repo root by walking up from this file.

    Looks for a `pyproject.toml` at the parent of `installer/`. If
    not found (running from a system install), falls back to the
    parent of `installer/`.
    """
    here = Path(__file__).resolve().parent
    for candidate in (here.parent, here):
        if (candidate / "pyproject.toml").is_file():
            return candidate
    return here.parent


REPO_DIR: Path = _find_repo_root()
INSTALLER_DIR: Path = REPO_DIR / "installer"
MANIFESTS_DIR: Path = INSTALLER_DIR / "manifests"
MODULES_DIR: Path = INSTALLER_DIR / "modules"
POLKIT_DIR: Path = INSTALLER_DIR / "polkit"
STATE_DIR: Path = INSTALLER_DIR / "state"
BACKUPS_DIR: Path = STATE_DIR / "backups"
LOGS_DIR: Path = INSTALLER_DIR / "logs"
CONFIG_FILE: Path = INSTALLER_DIR / "config.toml"
STATE_FILE: Path = STATE_DIR / "state.json"

# Polkit policy install paths
POLKIT_RULES_PATH: Path = Path("/etc/polkit-1/rules.d/99-arch-gabrln-installer.rules")
POLKIT_POLICY_PATH: Path = Path("/usr/share/polkit-1/actions/org.archlinux.pkexec.gabrln.policy")
POLKIT_HELPER_PATH: Path = Path("/usr/local/bin/gabrln-helper")

# Tunable limits (overridable via config.toml)
DEFAULT_MIN_FREE_BYTES: int = 5 * 1024**3  # 5 GiB
YAY_CHUNK_SIZE: int = 50
MAX_BACKUP_RETENTION: int = 3
LOCK_TIMEOUT_SECONDS: int = 5

# Retry policy for network operations
NETWORK_RETRY_ATTEMPTS: int = 3
NETWORK_RETRY_BASE_SECONDS: int = 2  # backoff: 1s, 2s, 4s, ...


def load_config() -> dict[str, Any]:
    """Read installer/config.toml. Empty dict if missing or invalid."""
    if not CONFIG_FILE.is_file():
        return {}
    try:
        with CONFIG_FILE.open("rb") as f:
            return tomllib.load(f)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        # Log via stderr; logger may not be set up yet at import time
        import sys
        print(f"[warn] config.toml invalid: {exc}", file=sys.stderr)
        return {}


def get_config(path: str, default: Any = None) -> Any:
    """Resolve a dotted path like `flags.max_backups` from config.toml."""
    cfg = load_config()
    cur: Any = cfg
    for part in path.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return default
        cur = cur[part]
    return cur
