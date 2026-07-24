"""Tests for installer/ui/progress.py — TUI and output capture."""

from __future__ import annotations

import sys
from unittest.mock import patch

import pytest

from installer.ui.progress import LiveDisplay, OutputCapture, ProgressState


class TestProgressState:
    def test_defaults(self) -> None:
        s = ProgressState(total_modules=5)
        assert s.total_modules == 5
        assert s.step == ""
        assert s.task_total == 1



class TestOutputCapture:
    def test_captures_print(self) -> None:
        state = ProgressState(total_modules=1)
        cap = OutputCapture(state)
        cap.write("hello world\n")
        assert len(state.lines) >= 1

    def test_step_marker(self) -> None:
        state = ProgressState(total_modules=1)
        cap = OutputCapture(state)
        cap.write("@STEP:Building foo\n")
        assert state.step == "Building foo"

    def test_cmd_marker(self) -> None:
        state = ProgressState(total_modules=1)
        cap = OutputCapture(state)
        cap.write("@CMD:yay -S foo\n")
        assert state.cmd == "yay -S foo"

    def test_progress_marker(self) -> None:
        state = ProgressState(total_modules=1)
        cap = OutputCapture(state)
        cap.write("@PROGRESS:10\n")
        assert state.task_total == 10

    def test_advance_marker(self) -> None:
        state = ProgressState(total_modules=1)
        cap = OutputCapture(state)
        cap.write("@ADVANCE:3\n")
        assert state.task_done == 3


class TestPromptPassword:
    def test_raises_when_not_tty(self) -> None:
        tui = LiveDisplay(total=1)
        with patch.object(sys.stdin, "isatty", return_value=False):
            with pytest.raises(SystemExit):
                tui.prompt_password()

    def test_returns_password_when_tty(self) -> None:
        tui = LiveDisplay(total=1)
        with patch.object(sys.stdin, "isatty", return_value=True), \
                patch("getpass.getpass", return_value="secret"):
            assert tui.prompt_password() == "secret"
