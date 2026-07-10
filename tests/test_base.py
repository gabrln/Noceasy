"""Tests for installer.modules.base — Module ABC."""

from __future__ import annotations

import pytest

from installer.modules.base import Module, RunContext


class TestModuleABC:
    def test_cannot_instantiate_base(self) -> None:
        """Module is abstract — direct instantiation must fail."""
        with pytest.raises(TypeError, match="abstract"):
            Module()

    def test_concrete_subclass_works(self) -> None:
        """A subclass that implements run() can be instantiated."""
        class MyModule(Module):
            name = "test"
            def run(self, ctx: RunContext) -> None:
                pass

        m = MyModule()
        assert m.name == "test"

    def test_missing_run_raises(self) -> None:
        """A subclass that doesn't implement run() cannot be instantiated."""
        class Incomplete(Module):
            name = "incomplete"
            # run() not implemented

        with pytest.raises(TypeError, match="abstract"):
            Incomplete()

    def test_manifest_override(self) -> None:
        class WithManifest(Module):
            name = "wm"
            def run(self, ctx: RunContext) -> None:
                pass

        m = WithManifest(manifest="pkgs.toml")
        assert m.manifest == "pkgs.toml"

    def test_default_values(self) -> None:
        class Minimal(Module):
            def run(self, ctx: RunContext) -> None:
                pass

        m = Minimal()
        assert m.name == "unnamed"
        assert m.manifest is None

    def test_pre_check_returns_true(self) -> None:
        class Mod(Module):
            def run(self, ctx: RunContext) -> None:
                pass

        m = Mod()
        # pre_check takes ctx, but we can test default return
        # by mocking RunContext
        from unittest.mock import MagicMock
        ctx = MagicMock(spec=RunContext)
        assert m.pre_check(ctx) is True

    def test_post_check_returns_none(self) -> None:
        class Mod(Module):
            def run(self, ctx: RunContext) -> None:
                pass

        m = Mod()
        from unittest.mock import MagicMock
        ctx = MagicMock(spec=RunContext)
        assert m.post_check(ctx) is None
