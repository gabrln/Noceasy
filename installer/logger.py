"""Rich-based logging.

Respects NO_COLOR (https://no-color.org/), TERM=dumb, and TTY detection.
Levels: DEBUG, INFO, WARN, ERROR, STEP, SUCCESS.

The single public API is `log(level, message)`. Internally delegates
to a Rich Console + a file handler for the persistent log.
"""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path
from typing import Optional

from rich.console import Console
from rich.logging import RichHandler


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

_LEVEL_PRIORITY = {
    "debug": 0,
    "info": 1,
    "success": 1,
    "step": 1,    # STEP always shown unless QUIET
    "warn": 2,
    "error": 3,
    "cmd": 0,
}


@dataclass
class _LogState:
    console: Console
    file_console: Optional[Console]
    level: LogLevel
    log_file: Optional[Path]


_state: Optional[_LogState] = None


def _use_color() -> bool:
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("TERM", "") == "dumb":
        return False
    return sys.stderr.isatty()


def setup_logging(log_dir: Path, level: LogLevel = LogLevel.NORMAL) -> None:
    """Initialize the global logger. Idempotent."""
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


def _timestamp() -> str:
    from datetime import datetime
    return datetime.now().strftime("%Y%m%d-%H%M%S")


def _should_print(level_name: str) -> bool:
    assert _state is not None
    if _state.level == LogLevel.QUIET and level_name not in ("error", "step"):
        return False
    if level_name == "debug" and _state.level < LogLevel.DEBUG:
        return False
    return True


_STYLES = {
    "debug":   "dim",
    "info":    "cyan",
    "success": "bold green",
    "step":    "bold magenta",
    "warn":    "yellow",
    "error":   "bold red",
    "cmd":     "dim blue",
}


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

    # TTY: filtered by level
    if _should_print(level):
        _state.console.print(f"[{style}][{name}][/{style}] {message}",
                              highlight=False)


def get_log_file() -> Optional[Path]:
    if _state is None:
        return None
    return _state.log_file
