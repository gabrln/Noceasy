"""Shared fixtures for Noceasy tests."""

from __future__ import annotations

import tempfile
from pathlib import Path

import pytest


@pytest.fixture
def tmp_state_dir(tmp_path: Path) -> Path:
    """Create a temporary state directory."""
    d = tmp_path / "state"
    d.mkdir()
    return d


@pytest.fixture
def tmp_config_file(tmp_path: Path) -> Path:
    """Create a temporary config.toml."""
    f = tmp_path / "config.toml"
    f.write_text('[flags]\nauto_backup = "true"\n')
    return f
