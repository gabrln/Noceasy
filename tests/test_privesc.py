"""Tests for installer.privesc — password validation fix."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from installer.privesc import Tool, validate_password


class TestValidatePassword:
    """validate_password() must capture stderr, timeout, and log rc."""

    @patch("installer.privesc.subprocess.run")
    def test_valid_password_returns_true(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            returncode=0, stdout="", stderr=""
        )
        assert validate_password("correct", Tool.sudo) is True

    @patch("installer.privesc.subprocess.run")
    def test_wrong_password_returns_false(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            returncode=1, stdout="", stderr="Sorry, try again."
        )
        assert validate_password("wrong", Tool.sudo) is False

    @patch("installer.privesc.subprocess.run")
    def test_timeout_returns_false(self, mock_run: MagicMock) -> None:
        import subprocess
        mock_run.side_effect = subprocess.TimeoutExpired(cmd="sudo", timeout=10)
        assert validate_password("pw", Tool.sudo) is False

    @patch("installer.privesc.subprocess.run")
    def test_missing_binary_returns_false(self, mock_run: MagicMock) -> None:
        mock_run.side_effect = FileNotFoundError
        assert validate_password("pw", Tool.sudo) is False

    @patch("installer.privesc.subprocess.run")
    def test_captures_stderr(self, mock_run: MagicMock) -> None:
        """The fix: stderr must be PIPE, not DEVNULL."""
        mock_run.return_value = MagicMock(
            returncode=1, stdout="", stderr="not in sudoers"
        )
        result = validate_password("pw", Tool.sudo)
        assert result is False
        # Verify subprocess.run was called with stderr=PIPE
        call_kwargs = mock_run.call_args
        assert call_kwargs.kwargs.get("stderr") == __import__("subprocess").PIPE

    @patch("installer.privesc.subprocess.run")
    def test_has_timeout(self, mock_run: MagicMock) -> None:
        """The fix: must pass timeout=10."""
        mock_run.return_value = MagicMock(
            returncode=0, stdout="", stderr=""
        )
        validate_password("pw", Tool.sudo)
        call_kwargs = mock_run.call_args
        assert call_kwargs.kwargs.get("timeout") == 10

    @patch("installer.privesc.subprocess.run")
    def test_sudo_argv_correct(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            returncode=0, stdout="", stderr=""
        )
        validate_password("mypass", Tool.sudo)
        argv = mock_run.call_args.args[0]
        assert argv == ["sudo", "-S", "-v"]

    @patch("installer.privesc.subprocess.run")
    def test_password_piped_via_stdin(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            returncode=0, stdout="", stderr=""
        )
        validate_password("secret", Tool.sudo)
        call_kwargs = mock_run.call_args
        assert call_kwargs.kwargs.get("input") == "secret\n"
