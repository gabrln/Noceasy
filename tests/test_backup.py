"""Tests for installer/infra/backup.py — backup snapshot & retention."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

from installer.infra.backup import (
    _apply_retention,
    _dir_size,
    _is_system_path,
    _unique_name,
    create,
)


class TestUniqueName:
    def test_no_collision(self, tmp_path: Path) -> None:
        assert _unique_name(tmp_path, "file.txt") == "file.txt"

    def test_collision_appends_1(self, tmp_path: Path) -> None:
        (tmp_path / "file.txt").touch()
        assert _unique_name(tmp_path, "file.txt") == "file.txt.1"

    def test_multiple_collisions(self, tmp_path: Path) -> None:
        (tmp_path / "file.txt").touch()
        (tmp_path / "file.txt.1").touch()
        (tmp_path / "file.txt.2").touch()
        assert _unique_name(tmp_path, "file.txt") == "file.txt.3"




class TestIsSystemPath:
    def test_etc(self) -> None:
        assert _is_system_path(Path("/etc/greetd/config.toml")) is True

    def test_usr(self) -> None:
        assert _is_system_path(Path("/usr/share/icons")) is True

    def test_user_home(self) -> None:
        assert _is_system_path(Path("/home/user/.zshrc")) is False

    def test_config(self) -> None:
        assert _is_system_path(Path("/home/user/.config/hypr")) is False


class TestApplyRetention:
    def test_keeps_only_max(self, tmp_path: Path) -> None:
        d = tmp_path / "backups"
        d.mkdir()
        for i in range(5):
            (d / f"pre-install-20250101-{i:06d}").mkdir()
        with patch("installer.infra.backup.BACKUPS_DIR", d):
            _apply_retention("pre-install", 2)
        remaining = sorted(p.name for p in d.iterdir())
        assert len(remaining) == 2

    def test_keeps_all_when_max_is_0(self, tmp_path: Path) -> None:
        d = tmp_path / "backups"
        d.mkdir()
        for i in range(3):
            (d / f"pre-install-20250101-{i:06d}").mkdir()
        with patch("installer.infra.backup.BACKUPS_DIR", d):
            _apply_retention("pre-install", 0)
        remaining = list(d.iterdir())
        assert len(remaining) == 3

    def test_removes_oldest_by_size(self, tmp_path: Path) -> None:
        d = tmp_path / "backups"
        d.mkdir()
        for i in range(3):
            p = d / f"pre-install-20250101-{i:06d}"
            p.mkdir()
            (p / "file.txt").write_text("x" * (100 * 1024))
        with patch("installer.infra.backup.BACKUPS_DIR", d):
            with patch("installer.infra.backup.get_config",
                       side_effect=lambda k, d: d):
                _apply_retention("pre-install", 5)
        assert len(list(d.iterdir())) > 0


class TestDirSize:
    def test_empty_dir(self, tmp_path: Path) -> None:
        assert _dir_size(tmp_path) == 0

    def test_with_files(self, tmp_path: Path) -> None:
        (tmp_path / "a.txt").write_text("hello")
        (tmp_path / "sub").mkdir()
        (tmp_path / "sub" / "b.txt").write_text("world")
        assert _dir_size(tmp_path) > 0


class TestCreate:
    def test_skips_nonexistent_paths(self, tmp_path: Path) -> None:
        with patch("installer.infra.backup.BACKUPS_DIR", tmp_path / "bk"):
            (tmp_path / "bk").mkdir()
            result = create("test", [Path("/nonexistent/path")])
        assert len(result.copied) == 0

    def test_copies_existing_file(self, tmp_path: Path) -> None:
        src = tmp_path / "source.txt"
        src.write_text("data")
        with patch("installer.infra.backup.BACKUPS_DIR", tmp_path / "bk"):
            result = create("test", [src])
        assert len(result.copied) == 1
        assert result.name.startswith("test-")
