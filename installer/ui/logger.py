"""Rich-based logging.

Respects NO_COLOR (https://no-color.org/), TERM=dumb, and TTY
detection. Levels: DEBUG, INFO, WARN, ERROR, STEP, SUCCESS.

The single public API is `log(level, message)`. Internally delegates
to a Rich Console (TTY) + a file handler (persistent log).

Note: setup_logging() is not thread-safe. The installer is
single-threaded so this is fine in practice.
"""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path

from rich.console import Console


class LogLevel(IntEnum):
    QUIET = 0    # only STEP + ERROR
    NORMAL = 1   # STEP + ERROR + WARN + INFO + SUCCESS
    DEBUG = 2    # everything


_LEVEL_NAMES = {
    "debug": "DEBUG",
    "info": "INFO",
    "warn": "WARN",
    "error": "ERROR",
    "step": "STEP",
    "success": "SUCCESS",
    "cmd": "EXEC",
}


_STYLES = {
    "debug":   "dim",
    "info":    "cyan",
    "success": "bold green",
    "step":    "bold magenta",
    "warn":    "yellow",
    "error":   "bold red",
    "cmd":     "dim blue",
}


@dataclass
class _LogState:
    console: Console
    file_console: Console | None
    level: LogLevel
    log_file: Path | None


_state: _LogState | None = None
_suppress_stderr = False  # True while a module runs (logs go to file only)
_redirect_file = None     # When set, TTY output goes here instead of Console


def _use_color() -> bool:
    # Logger writes to stderr — check that stream specifically.
    # progress.is_tty() checks stdout (where the TUI renders).
    # When stdout is redirected but stderr is a terminal, logs
    # should still show colors.
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("TERM", "") == "dumb":
        return False
    return sys.stderr.isatty()


def _timestamp() -> str:
    from datetime import datetime
    return datetime.now().strftime("%Y%m%d-%H%M%S")


def setup_logging(log_dir: Path, level: LogLevel = LogLevel.NORMAL) -> None:
    """Initialize the global logger. Idempotent (not thread-safe)."""
    global _state
    if _state is not None:
        return

    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"installer-{_timestamp()}.log"
    log_file.touch()

    console = Console(
        stderr=True,
        force_terminal=_use_color(),
        no_color=not _use_color(),
    )

    file_console = Console(
        file=open(log_file, "w", encoding="utf-8"),
        force_terminal=False,
        no_color=True,
        width=200,
    )

    _state = _LogState(console=console, file_console=file_console,
                       level=level, log_file=log_file)


def set_suppress_stderr(suppress: bool) -> None:
    """Temporarily suppress TTY output. Logs still go to the file.

    Call this with True before running a module so that the module's
    verbose log() calls don't fight with the runner's clean stdout
    progress lines. Reset to False afterward.
    """
    global _suppress_stderr
    _suppress_stderr = suppress


def _should_print(level_name: str) -> bool:
    assert _state is not None
    # 'error' always reaches the terminal, even while the TUI has
    # suppressed regular module output. A silently swallowed fatal
    # error is worse than a TUI glitch.
    if level_name == "error":
        return True
    if _suppress_stderr:
        return False
    if _state.level == LogLevel.QUIET and level_name not in ("error", "step"):
        return False
    if level_name == "debug" and _state.level < LogLevel.DEBUG:
        return False
    return True


def redirect_log_output(file) -> None:
    """Redirect TTY log output to *file* (an OutputCapture)."""
    global _redirect_file
    _redirect_file = file


def reset_log_output() -> None:
    """Stop redirecting — TTY output goes back to the Rich Console."""
    global _redirect_file
    _redirect_file = None


def log(level: str, message: str) -> None:
    """Print a log line to stderr (TTY) and to the log file (always)."""
    if _state is None:
        # Logger not yet initialized; fallback to plain print
        print(f"[{level.upper()}] {message}", file=sys.stderr)
        return

    name = _LEVEL_NAMES.get(level, level.upper())
    style = _STYLES.get(level, "white")

    # File: always with timestamp
    if _state.file_console is not None:
        from datetime import datetime
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        _state.file_console.print(f"[{ts}] [{name}] {message}", highlight=False)

    # Redirect: plain text to the capture (for Live Output panel)
    if _redirect_file is not None and _should_print(level):
        _redirect_file.write(f"[{name}] {message}\n")
        return

    # TTY: filtered by level (Rich Console)
    if _should_print(level):
        _state.console.print(f"[{style}][{name}][/{style}] {message}",
                              highlight=False)


