"""Tests for installer/cli.py — CLI parsing and main entrypoint."""

from __future__ import annotations

import os
from unittest.mock import patch

import pytest

from installer.cli import _print_help_header, build_parser, main


class TestBuildParser:
    def test_help_flag(self) -> None:
        p = build_parser()
        args = p.parse_args(["--help"])
        assert args.help is True

    def test_dry_run_flag(self) -> None:
        p = build_parser()
        args = p.parse_args(["--dry-run"])
        assert args.dry_run is True

    def test_force_flag(self) -> None:
        p = build_parser()
        args = p.parse_args(["--force"])
        assert args.force is True

    def test_verbose_flag(self) -> None:
        p = build_parser()
        args = p.parse_args(["--verbose"])
        assert args.verbose is True

    def test_quiet_flag(self) -> None:
        p = build_parser()
        args = p.parse_args(["--quiet"])
        assert args.quiet is True

    def test_no_color_flag(self) -> None:
        p = build_parser()
        args = p.parse_args(["--no-color"])
        assert args.no_color is True

    def test_version(self) -> None:
        p = build_parser()
        with pytest.raises(SystemExit):
            p.parse_args(["--version"])

    def test_defaults(self) -> None:
        p = build_parser()
        args = p.parse_args([])
        assert not args.dry_run
        assert not args.force
        assert not args.verbose
        assert not args.quiet
        assert not args.no_color


class TestPrintHelpHeader:
    def test_prints_usage(self, capsys: pytest.CaptureFixture) -> None:
        _print_help_header()
        captured = capsys.readouterr()
        assert "Usage" in captured.out
        assert "--dry-run" in captured.out
        assert "--force" in captured.out


class TestMain:
    def test_help_returns_zero(self) -> None:
        assert main(["--help"]) == 0

    def test_version_returns_zero(self) -> None:
        with pytest.raises(SystemExit):
            main(["--version"])

    def test_dry_run_passes_option(self) -> None:
        with patch("installer.cli.ModuleRunner") as mock_runner, \
                patch("installer.cli.build_default_pipeline"), \
                patch("installer.cli.detect_real_user",
                      return_value=("test", "/home/test")), \
                patch("installer.cli.setup_logging"), \
                patch("installer.cli.set_suppress_stderr"), \
                patch("installer.cli.install_signal_handlers"), \
                patch("installer.cli.log"):
            main(["--dry-run"])
            kwargs = mock_runner.call_args[1]
            assert kwargs["options"].dry_run is True

    def test_force_passes_option(self) -> None:
        with patch("installer.cli.ModuleRunner") as mock_runner, \
                patch("installer.cli.build_default_pipeline"), \
                patch("installer.cli.detect_real_user",
                      return_value=("test", "/home/test")), \
                patch("installer.cli.setup_logging"), \
                patch("installer.cli.set_suppress_stderr"), \
                patch("installer.cli.install_signal_handlers"), \
                patch("installer.cli.log"):
            main(["--force"])
            kwargs = mock_runner.call_args[1]
            assert kwargs["options"].force is True

    def test_verbose_priority_over_quiet(self) -> None:
        """When both are given, verbose wins (checked first in code)."""
        with patch("installer.cli.ModuleRunner"), \
                patch("installer.cli.build_default_pipeline"), \
                patch("installer.cli.detect_real_user",
                      return_value=("test", "/home/test")), \
                patch("installer.cli.setup_logging") as mock_setup, \
                patch("installer.cli.set_suppress_stderr"), \
                patch("installer.cli.install_signal_handlers"), \
                patch("installer.cli.log"):
            main(["--verbose", "--quiet"])
            kwargs = mock_setup.call_args[1]
            assert kwargs["level"].name == "DEBUG"

    def test_no_color_sets_env(self) -> None:
        os.environ.pop("NO_COLOR", None)
        with patch("installer.cli.ModuleRunner"), \
                patch("installer.cli.build_default_pipeline"), \
                patch("installer.cli.detect_real_user",
                      return_value=("test", "/home/test")), \
                patch("installer.cli.setup_logging"), \
                patch("installer.cli.set_suppress_stderr"), \
                patch("installer.cli.install_signal_handlers"), \
                patch("installer.cli.log"):
            main(["--no-color"])
        assert os.environ.get("NO_COLOR") == "1"
        os.environ.pop("NO_COLOR", None)

    def test_failure_calls_fatal(self) -> None:
        with patch("installer.cli.build_default_pipeline"), \
                patch("installer.cli.detect_real_user",
                      return_value=("test", "/home/test")), \
                patch("installer.cli.setup_logging"), \
                patch("installer.cli.set_suppress_stderr"), \
                patch("installer.cli.install_signal_handlers"), \
                patch("installer.cli.log"), \
                patch("installer.cli.ModuleRunner") as mock_runner:
            mock_runner.return_value.run_all.side_effect = \
                RuntimeError("boom")
            with patch("installer.cli.fatal") as mock_fatal:
                main([])
                mock_fatal.assert_called_once()
                assert "boom" in str(mock_fatal.call_args)
