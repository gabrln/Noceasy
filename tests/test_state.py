"""Tests for installer.state — JsonStore and State."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from installer.state import JsonStore, State, hash_file


# ---------------------------------------------------------------------------
# JsonStore
# ---------------------------------------------------------------------------

class TestJsonStore:
    def test_read_empty_file(self, tmp_path: Path) -> None:
        p = tmp_path / "data.json"
        store = JsonStore(p)
        assert store.read() == {}

    def test_write_and_read(self, tmp_path: Path) -> None:
        p = tmp_path / "data.json"
        store = JsonStore(p)
        store.write({"key": "value"})
        assert store.read() == {"key": "value"}

    def test_atomic_write(self, tmp_path: Path) -> None:
        """No temp files left after write."""
        p = tmp_path / "data.json"
        store = JsonStore(p)
        store.write({"a": 1})
        leftovers = list(tmp_path.glob(".tmp"))
        assert leftovers == []

    def test_corruption_recovery(self, tmp_path: Path) -> None:
        p = tmp_path / "data.json"
        p.write_text("NOT JSON {{{")
        store = JsonStore(p)
        data = store.read()
        assert data == {}
        # File should be recreated
        assert p.exists()

    def test_get_set(self, tmp_path: Path) -> None:
        p = tmp_path / "data.json"
        store = JsonStore(p)
        store.set("mod1", "status", "done")
        assert store.get("mod1", "status") == "done"
        assert store.get("mod1", "missing") == ""

    def test_locking(self, tmp_path: Path) -> None:
        """Context manager acquires and releases lock."""
        p = tmp_path / "data.json"
        store = JsonStore(p)
        with store:
            store.write({"locked": True})
        assert store.read() == {"locked": True}

    def test_file_permissions(self, tmp_path: Path) -> None:
        p = tmp_path / "data.json"
        store = JsonStore(p)
        store.write({"perm": True})
        mode = oct(p.stat().st_mode)[-3:]
        assert mode == "600"


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

class TestState:
    def test_mark_done_and_check(self, tmp_state_dir: Path) -> None:
        state = State(
            path=tmp_state_dir / "state.json",
            dir_=tmp_state_dir,
        )
        state.mark_done("m01-backup", manifest=None)
        assert state.is_up_to_date("m01-backup", manifest=None) is True

    def test_mark_failed(self, tmp_state_dir: Path) -> None:
        state = State(
            path=tmp_state_dir / "state.json",
            dir_=tmp_state_dir,
        )
        state.mark_failed("m01-backup", "disk full")
        assert state.is_up_to_date("m01-backup", manifest=None) is False

    def test_get_set(self, tmp_state_dir: Path) -> None:
        state = State(
            path=tmp_state_dir / "state.json",
            dir_=tmp_state_dir,
        )
        state.set("m01-backup", "custom", "value")
        assert state.get("m01-backup", "custom") == "value"

    def test_manifest_hash(self, tmp_state_dir: Path) -> None:
        state = State(
            path=tmp_state_dir / "state.json",
            dir_=tmp_state_dir,
        )
        manifest = tmp_state_dir / "test.toml"
        manifest.write_text("[packages]\nfoo = 'bar'\n")
        state.mark_done("m01-backup", manifest=manifest)
        assert state.is_up_to_date("m01-backup", manifest=manifest) is True
        # Change manifest → no longer up to date
        manifest.write_text("[packages]\nfoo = 'baz'\n")
        assert state.is_up_to_date("m01-backup", manifest=manifest) is False


# ---------------------------------------------------------------------------
# hash_file
# ---------------------------------------------------------------------------

class TestHashFile:
    def test_hash_file(self, tmp_path: Path) -> None:
        f = tmp_path / "test.txt"
        f.write_text("hello")
        h = hash_file(f)
        assert len(h) == 64  # SHA256 hex
        # Deterministic
        assert hash_file(f) == h

    def test_hash_dir(self, tmp_path: Path) -> None:
        d = tmp_path / "mydir"
        d.mkdir()
        (d / "a.txt").write_text("aaa")
        (d / "b.txt").write_text("bbb")
        h = hash_file(d)
        assert len(h) == 64

    def test_hash_nonexistent(self, tmp_path: Path) -> None:
        assert hash_file(tmp_path / "nope.txt") == ""
