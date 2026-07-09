"""TOML manifest cache.

Loads all manifests once into memory at startup. Modules then read
from this cache instead of re-parsing the TOML on every access.
"""

from __future__ import annotations

import tomllib
from pathlib import Path
from typing import Any

from installer.config import MANIFESTS_DIR


class TomlCache:
    """In-memory cache of manifest TOML files."""

    def __init__(self) -> None:
        self._cache: dict[str, dict] = {}
        self._loaded: set[str] = set()

    @staticmethod
    def _resolve(name: str) -> Path:
        """Resolve a manifest name like 'packages.toml' to a Path."""
        p = Path(name)
        if p.is_absolute():
            return p
        return MANIFESTS_DIR / name

    def load(self, name: str) -> dict:
        """Load and cache a manifest by name (e.g. 'packages.toml')."""
        path = self._resolve(name)
        if name in self._loaded:
            return self._cache.get(name, {})
        try:
            with path.open("rb") as f:
                self._cache[name] = tomllib.load(f)
        except (OSError, tomllib.TOMLDecodeError):
            self._cache[name] = {}
        self._loaded.add(name)
        return self._cache[name]

    def get(self, name: str, dotted_key: str, default: Any = None) -> Any:
        """Get a value at `dotted_key` from manifest `name`."""
        data = self.load(name)
        cur: Any = data
        for part in dotted_key.split("."):
            if not isinstance(cur, dict) or part not in cur:
                return default
            cur = cur[part]
        return cur

    def get_list(self, name: str, dotted_key: str) -> list[str]:
        """Get a list of strings at `dotted_key`. Empty list if missing."""
        data = self.get(name, dotted_key)
        if data is None:
            return []
        if isinstance(data, list):
            return [str(x) for x in data]
        return [str(data)]

    def get_list_field(self, name: str, table_key: str, field: str) -> list[str]:
        """Get `field` from each table in a list-of-tables at `table_key`."""
        data = self.load(name)
        cur = data
        for part in table_key.split("."):
            cur = cur.get(part, {}) if isinstance(cur, dict) else {}
        if not isinstance(cur, list):
            return []
        out: list[str] = []
        for item in cur:
            if isinstance(item, dict) and field in item and item[field] is not None:
                out.append(str(item[field]))
        return out


_cache: TomlCache | None = None


def get_cache() -> TomlCache:
    global _cache
    if _cache is None:
        _cache = TomlCache()
    return _cache
