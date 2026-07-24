"""Paths, constants and config.toml loader.

The bootstrap (install.sh) sets REPO_DIR by chdir to the repo root
and running `python3 -m installer`. INSTALLER_DIR is always
REPO_DIR/installer. All other paths are derived from INSTALLER_DIR
or from config.toml values under the ``[paths]`` section.
"""

from __future__ import annotations

import functools
import tomllib
from pathlib import Path
from typing import Any, cast


def _find_repo_root() -> Path:
    """Locate the repo root by walking up from this file.

    Looks for a `pyproject.toml` at the parent of `installer/`. If
    not found (running from a system install), falls back to two levels up.
    """
    here = Path(__file__).resolve().parent
    for candidate in (here.parent.parent, here.parent, here):
        if (candidate / "pyproject.toml").is_file():
            return candidate
    return here.parent.parent


REPO_DIR: Path = _find_repo_root()
INSTALLER_DIR: Path = REPO_DIR / "installer"
MANIFESTS_DIR: Path = INSTALLER_DIR / "manifests"
CONFIG_FILE: Path = INSTALLER_DIR / "config.toml"


@functools.lru_cache(maxsize=1)
def load_config() -> dict[str, Any]:
    """Read installer/config.toml. Cached after first call.

    Returns an empty dict if the file is missing or invalid.
    To force a re-read, call ``load_config.cache_clear()``.
    """
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


def _resolve_path(key: str, default: str) -> Path:
    """Resolve a ``[paths]`` key from config.toml relative to REPO_DIR."""
    cfg = load_config()
    rel = cast(str, cfg.get("paths", {}).get(key, default))
    return (REPO_DIR / rel).resolve()


STATE_DIR: Path = _resolve_path("state_dir", ".state")
BACKUPS_DIR: Path = _resolve_path("backups_dir", ".state/backups")
LOGS_DIR: Path = _resolve_path("logs_dir", ".logs")
STATE_FILE: Path = STATE_DIR / "state.json"

# Tunable limits (overridable via config.toml)
DEFAULT_MIN_FREE_BYTES: int = 5 * 1024**3  # 5 GiB
YAY_CHUNK_SIZE: int = 50
LOCK_TIMEOUT_SECONDS: int = 5
DEFAULT_MAX_BACKUP_BYTES: int = 500 * 1024 * 1024  # 500 MiB

# Retry policy for network operations
NETWORK_RETRY_ATTEMPTS: int = 3
NETWORK_RETRY_BASE_SECONDS: int = 2  # backoff: 1s, 2s, 4s, ...
