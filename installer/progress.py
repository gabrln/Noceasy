"""Installer progress display (DankInstall-style TUI).

Single source of truth for:
    - TTY detection (used by logger.py and the TUI)
    - Marker protocol parsing (@STEP:, @CMD:, @PROGRESS:, @ADVANCE:)
    - Panel rendering via rich.live.Live + rich.progress.Progress
    - Output capture (stdout/stderr hijack during module execution)

Architecture
~~~~~~~~~~~~
    ProgressState   — plain dataclass (no Rich), testable without TTY
    MarkerParser    — parses @markers from captured output lines
    LivePanelRenderer — builds the Rich renderable from state + progress
    OutputCapture   — file-like that feeds markers + lines to the parser

Modules emit markers via print():

    print("@PROGRESS:5")       # set total steps for current task
    print("@ADVANCE:1")        # advance by 1
    print("@STEP:Building foo") # update step description
    print("@CMD:yay -S foo")   # update command info

Everything else goes to the Live Output area.
"""

from __future__ import annotations

import os
import shutil
import sys
from dataclasses import dataclass, field


# ── Tokyo Night palette (https://github.com/enkia/tokyo-night-vscode-theme) ──

TOKYO_NIGHT = {
    "bg":          "#1a1b26",
    "fg":          "#c0caf5",
    "fg_dark":     "#a9b1d6",
    "comment":     "#565f89",
    "border":      "#7aa2f7",  # blue
    "border_error": "#f7768e",  # red
    "title":       "#bb9af7",  # magenta
    "success":     "#9ece6a",  # green
    "error":       "#f7768e",  # red
    "warning":     "#e0af68",  # yellow
    "cyan":        "#7dcfff",
    "track":       "#3b4261",  # bar track (unfilled)
}

# Panel width: terminals are character cells, not pixels, so a literal
# "900x900" box has no direct equivalent. We instead pick a fixed
# column width that reads well (76 cols ≈ a squarish info box at
# typical font aspect ratios) and center it in the available
# terminal area, both horizontally and vertically.
PANEL_WIDTH = 76


# ── TTY detection (single source of truth) ───────────────────────────

def is_tty() -> bool:
    """Return True if the terminal supports interactive output.

    Checks stdout.isatty() (where the TUI renders) and respects
    NO_COLOR / TERM=dumb.
    """
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("TERM", "") == "dumb":
        return False
    return sys.stdout.isatty()


# ── ProgressState ────────────────────────────────────────────────────

@dataclass
class ProgressState:
    """Immutable-ish state for the progress display.

    No Rich dependencies — pure Python dataclass.
    """
    total_modules: int = 0
    module_idx: int = 0
    module_name: str = ""
    step: str = ""
    cmd: str = ""
    task_total: int = 1
    task_done: int = 0
    lines: list[str] = field(default_factory=list)
    error: str = ""

    @property
    def pct(self) -> float:
        return self.module_idx / self.total_modules if self.total_modules else 0


# ── MarkerParser ─────────────────────────────────────────────────────

# Protocol markers emitted by modules via print().
# Format: @TAG:value
_TAGS = {
    "STEP":     "step",
    "CMD":      "cmd",
    "PROGRESS": "task_total",
    "ADVANCE":  "advance",
}


def parse_marker(line: str, state: ProgressState) -> bool:
    """Parse a single line for a @TAG:value marker.

    Returns True if the line was a marker (consumed), False if it
    is regular output that should appear in the Live Output area.
    """
    if not line.startswith("@"):
        return False

    for tag, field_name in _TAGS.items():
        prefix = f"@{tag}:"
        if not line.startswith(prefix):
            continue

        value = line[len(prefix):]

        if tag == "STEP":
            state.step = value
        elif tag == "CMD":
            state.cmd = value
        elif tag == "PROGRESS":
            try:
                state.task_total = int(value)
                state.task_done = 0
            except ValueError:
                pass
        elif tag == "ADVANCE":
            try:
                state.task_done += int(value)
            except ValueError:
                pass
        return True

    # Unknown @TAG — treat as regular output
    return False


# ── LivePanelRenderer ────────────────────────────────────────────────

class LivePanelRenderer:
    """Builds the Rich renderable from ProgressState + Progress.

    This is the only class that imports Rich. Everything else
    (ProgressState, MarkerParser, OutputCapture) is Rich-free.

    Styling follows the Tokyo Night palette (see TOKYO_NIGHT).
    """

    def __init__(self, state: ProgressState, progress,
                 width: int = PANEL_WIDTH, height: int | None = None) -> None:
        self._state = state
        self._progress = progress  # rich.progress.Progress or None
        self._width = width
        self._height = height

    def render(self):
        """Return the Rich renderable for the current state, centered."""
        from rich.align import Align
        from rich.panel import Panel
        from rich.console import Group
        from rich.text import Text

        c = TOKYO_NIGHT
        parts = []

        # Progress bar
        if self._progress:
            parts.append(self._progress)
        parts.append("")

        # Error banner
        if self._state.error:
            parts.append(Text(f"✗ {self._state.error}", style=f"bold {c['error']}"))
            parts.append("")

        # Command info
        if self._state.cmd:
            parts.append(Text(f"$ {self._state.cmd}", style=c["comment"]))
            parts.append("")

        # Live output (last 8 lines)
        if self._state.lines:
            parts.append(Text("Live Output:", style=c["comment"]))
            for line in self._state.lines:
                parts.append(Text(f"  {line}", style=c["fg_dark"]))

        border = c["border_error"] if self._state.error else c["border"]
        title = (
            f"[bold {c['title']}]Noceasy Installer[/bold {c['title']}] "
            f"[{c['comment']}]{self._state.module_idx}/{self._state.total_modules}[/{c['comment']}]"
        )
        panel = Panel(
            Group(*parts),
            title=title,
            border_style=border,
            width=self._width,
            style=f"on {c['bg']}",
        )
        # Center horizontally AND vertically within the terminal.
        # Align needs an explicit height to center vertically —
        # without it, it only sizes to the renderable's own content
        # height and never uses the terminal's full height.
        return Align.center(panel, vertical="middle", height=self._height)


# ── OutputCapture ────────────────────────────────────────────────────

class OutputCapture:
    """File-like object that captures stdout/stderr.

    Routes @markers to the ProgressState and everything else to
    the live output lines. After each marker update, calls
    ``LiveDisplay.refresh()`` so the panel is repainted immediately.
    """

    def __init__(self, state: ProgressState, live: LiveDisplay | None = None) -> None:
        self._state = state
        self._live = live
        self._buf = b""
        self._in_write = False

    def write(self, s) -> int:
        n = len(s) if isinstance(s, str) else 0
        if self._in_write:
            return n
        self._in_write = True
        try:
            self._buf += (s if isinstance(s, (str, bytes)) else str(s)).encode()
            while b"\n" in self._buf:
                line, self._buf = self._buf.split(b"\n", 1)
                decoded = line.decode(errors="replace").rstrip()
                if not decoded:
                    continue
                if not parse_marker(decoded, self._state):
                    self._state.lines.append(decoded)
                    if len(self._state.lines) > 8:
                        self._state.lines = self._state.lines[-8:]
                # State is mutated; the Live refresh thread picks
                # it up on the next tick (≤83 ms). No explicit
                # refresh needed here — avoids re-entrancy with
                # Live's own render loop.
        finally:
            self._in_write = False
        return n

    def flush(self) -> None:
        pass

    def isatty(self) -> bool:
        return True

    def fileno(self):
        return -1


# ── LiveDisplay (orchestrator) ───────────────────────────────────────

class LiveDisplay:
    """Orchestrates the DankInstall-style TUI.

    Combines ProgressState, rich.live.Live, rich.progress.Progress,
    and LivePanelRenderer into a single coherent interface.

    Typical usage::

        tui = LiveDisplay(total=17)
        tui.start()
        tui.update_module("04-yay-aur", 5)
        # ... module runs, OutputCapture feeds state ...
        tui.finish()     # mark current module done
        tui.stop()       # tear down the TUI
    """

    def __init__(self, total: int) -> None:
        self._total = total
        self._state = ProgressState(total_modules=total)
        self._live = None
        self._console = None
        self._progress = None
        self._task_id = None
        self._final: list[str] = []
        self._panel_width = PANEL_WIDTH
        self._panel_height: int | None = None

    # ── Lifecycle ───────────────────────────────────────────────────

    def start(self) -> None:
        if not is_tty():
            return
        from rich.console import Console
        from rich.live import Live
        from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn

        # CRITICAL: rich.console.Console resolves sys.stdout
        # DYNAMICALLY on every write (it stores a file only if
        # explicitly given). If we let it default, then once the
        # runner swaps sys.stdout = OutputCapture during module
        # execution, the Live background thread starts writing its
        # render frames into OutputCapture instead of the real
        # terminal — the panel appears frozen because nothing
        # after this point reaches the terminal.
        #
        # Fix: capture the real stdout now (before any swap) and
        # pin the Console to that exact file handle.
        real_stdout = sys.stdout
        # force_terminal=True only bypasses the isatty() check; it does
        # NOT guarantee color rendering. Under `sudo` (especially via
        # `curl | sudo bash`), the environment may lack a proper
        # locale/TERM, causing Rich's "auto" color_system detection to
        # downgrade to no-color. Force truecolor explicitly since the
        # Tokyo Night palette uses hex/RGB colors.
        self._console = Console(
            file=real_stdout,
            force_terminal=True,
            color_system="truecolor",
        )

        # Fit the panel to the terminal: cap at PANEL_WIDTH, but
        # shrink on narrow terminals so it never overflows/wraps.
        term_cols, term_rows = shutil.get_terminal_size(fallback=(PANEL_WIDTH + 4, 24))
        self._panel_width = max(40, min(PANEL_WIDTH, term_cols - 4))
        self._panel_height = term_rows

        c = TOKYO_NIGHT
        self._progress = Progress(
            SpinnerColumn(style=c["border"]),
            TextColumn(f"[{c['fg']}]{{task.description}}"),
            BarColumn(bar_width=30, complete_style=c["border"],
                     finished_style=c["success"], style=c["track"]),
            TextColumn(f"[{c['comment']}]" + "{task.percentage:>3.0f}%"),
            TextColumn(f"[{c['comment']}]" + "({task.completed}/{task.total})"),
            transient=False,
            console=self._console,
        )
        # screen=True switches to the terminal's alternate screen
        # buffer (like `vim`/`less`) — this is the Rich equivalent of
        # Bubble Tea's tea.WithAltScreen(). Anything printed to the
        # terminal before start() (e.g. install.sh's bash output)
        # stays intact in the main buffer, hidden while the TUI is
        # active, and reappears untouched once stop() restores it.
        self._live = Live(
            self._render(),
            console=self._console,
            refresh_per_second=12,
            transient=False,
            screen=True,
        )
        self._live.start()
        # Force immediate render so the panel is visible
        # before the first refresh tick.
        self._live.update(self._render(), refresh=True)

    def stop(self) -> None:
        if self._live:
            self._live.stop()
            self._live = None

    # ── Module lifecycle ────────────────────────────────────────────

    def update_module(self, name: str, idx: int) -> None:
        """Switch to a new module. Resets state, creates a new progress task."""
        self._state.module_idx = idx
        self._state.module_name = name
        self._state.step = f"Installing {name}"
        self._state.cmd = ""
        self._state.lines.clear()
        self._state.error = ""
        self._state.task_total = 1
        self._state.task_done = 0
        if self._progress and self._task_id is not None:
            self._progress.stop_task(self._task_id)
        if self._progress:
            self._task_id = self._progress.add_task(name, total=1)
        self._refresh()

    def finish(self) -> None:
        """Complete the current module's progress (success)."""
        if self._progress and self._task_id is not None:
            self._progress.update(self._task_id, completed=self._state.task_total)
        self._refresh()

    def fail(self, error: str) -> None:
        """Mark the current module as failed (visual error state)."""
        self._state.error = error
        self._refresh()

    # ── Public API for OutputCapture ────────────────────────────────

    @property
    def state(self) -> ProgressState:
        return self._state

    def refresh(self) -> None:
        """Public refresh — called by OutputCapture after marker updates.

        Syncs progress.update(completed=state.task_done) so the bar
        advances incrementally as @ADVANCE:1 markers arrive.
        """
        if self._progress and self._task_id is not None:
            self._progress.update(
                self._task_id,
                completed=min(self._state.task_done, self._state.task_total),
            )
        self._refresh()

    # ── Internals ───────────────────────────────────────────────────

    def _refresh(self) -> None:
        if self._live:
            self._live.update(self._render())

    def _render(self):
        if self._progress:
            self._state.task_total = self._progress.tasks[
                self._task_id
            ].total if self._task_id is not None else 1
        renderer = LivePanelRenderer(
            self._state, self._progress,
            width=self._panel_width, height=self._panel_height,
        )
        return renderer.render()
