"""Tests for installer.config — load_config cache."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from installer import config


class TestLoadConfig:
    def test_load_valid_toml(self, tmp_config_file: Path) -> None:
        config.load_config.cache_clear()
        with patch.object(config, "CONFIG_FILE", tmp_config_file):
            cfg = config.load_config()
        assert cfg["flags"]["auto_backup"] == "true"

    def test_missing_file_returns_empty(self, tmp_path: Path) -> None:
        config.load_config.cache_clear()
        with patch.object(config, "CONFIG_FILE", tmp_path / "nope.toml"):
            cfg = config.load_config()
        assert cfg == {}

    def test_invalid_toml_returns_empty(self, tmp_path: Path) -> None:
        bad = tmp_path / "bad.toml"
        bad.write_text("{{invalid}}")
        config.load_config.cache_clear()
        with patch.object(config, "CONFIG_FILE", bad):
            cfg = config.load_config()
        assert cfg == {}

    def test_cache_returns_same_object(self, tmp_config_file: Path) -> None:
        config.load_config.cache_clear()
        with patch.object(config, "CONFIG_FILE", tmp_config_file):
            first = config.load_config()
            second = config.load_config()
        assert first is second  # cached, same object


class TestGetConfig:
    def test_dotted_path(self, tmp_config_file: Path) -> None:
        config.load_config.cache_clear()
        with patch.object(config, "CONFIG_FILE", tmp_config_file):
            val = config.get_config("flags.auto_backup")
        assert val == "true"

    def test_missing_path_returns_default(self, tmp_config_file: Path) -> None:
        config.load_config.cache_clear()
        with patch.object(config, "CONFIG_FILE", tmp_config_file):
            val = config.get_config("flags.nonexistent", "fallback")
        assert val == "fallback"
