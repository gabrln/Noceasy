"""Paths and constants used across the installer.

The bootstrap (install.sh) sets REPO_DIR by chdir to the repo root and
running `python3 -m installer`. INSTALLER_DIR is always REPO_DIR/installer.
All other paths are derived from INSTALLER_DIR unless the user provides
a config override.
"""

from __future__ import annotations

import os
import tomllib
from pathlib import Path
from typing import Any


def _find_repo_root() -> Path:
    """Locate the repo root by walking up from this file.

    Looks for a `pyproject.toml` at the parent of `installer/`. If not
    found (running from a system install), falls back to the parent
    of `installer/`.
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
        print(f"[warn] config.toml inválido: {exc}", file=sys.stderr)
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
