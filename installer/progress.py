"""Rich-based progress display.

Two modes:
    - TTY:    Animated bar with current/total counter
    - Non-TTY: log lines (one per step)

Modules report progress via the Runner. This module is mostly internal
to the Runner; consumers don't usually need to call it directly.
"""

from __future__ import annotations

import os
import sys
from typing import Optional

from rich.console import Console
from rich.progress import (
    BarColumn,
    MofNCompleteColumn,
    Progress,
    TextColumn,
    TimeElapsedColumn,
)


def _is_tty() -> bool:
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("TERM", "") == "dumb":
        return False
    return sys.stderr.isatty()


def make_progress(total: int, label: str = "install") -> Optional[Progress]:
    """Create a Rich Progress bar (or None if not TTY).

    Use as a context manager:

        with make_progress(16, "install") as progress:
            for module in modules:
                task = progress.add_task(module.name, total=1)
                ...
                progress.update(task, completed=1)
    """
    if not _is_tty():
        return None

    return Progress(
        TextColumn(f"[bold magenta]{label}[/bold magenta]"),
        BarColumn(),
        MofNCompleteColumn(),
        TextColumn("[progress.description]{task.description}"),
        TimeElapsedColumn(),
        console=Console(stderr=True, force_terminal=True),
        transient=False,
    )
