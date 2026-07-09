"""Module orchestration: the loop that runs the modules in order.

Uses rich.live.Live for a TUI-style progress display (inspired by
DankInstall / Bubble Tea): spinner, progress bar, and filtered
live output — all in a single re-rendering block that replaces the
previous frame (no scrolling, no interleaving).
"""

from __future__ import annotations

import io
import os
import sys
import threading
import time
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import TextIO

from installer.errors import fatal, ModuleFailure
from installer.logger import log, set_suppress_stderr
from installer.modules.base import Module, RunContext
from installer.state import State


@dataclass
class RunnerOptions:
    dry_run: bool = False
    force: bool = False


# ── DankInstall-style TUI progress ──────────────────────────────────

def _is_tty() -> bool:
    return sys.stdout.isatty() and not os.environ.get("NO_COLOR")


def _render_frame(
    idx: int,
    total: int,
    module_name: str,
    spinner_char: str,
    build_lines: deque[str],
    step_text: str = "",
    cmd_info: str = "",
    bar_width: int = 30,
) -> str:
    """Render one frame of the TUI progress view.

    Matches DankInstall's install view layout:

      ⠹ Building noctalia-git
      [████████████░░░░░░░░░░░░░░░░░░] 42%
      $ yay -S --needed --noconfirm

      Live Output:
        ==> Making package: noctalia-git
    """
    lines = []

    # Spinner + step text
    display_step = step_text or module_name
    lines.append(f"{spinner_char} {display_step}")
    lines.append("")

    # Progress bar
    pct = idx / total if total else 0
    filled = int(bar_width * pct)
    empty = bar_width - filled
    bar = f"[{'█' * filled}{'░' * empty}] {pct * 100:.0f}%"
    lines.append(bar)
    lines.append("")

    # Command info
    if cmd_info:
        lines.append(f"$ {cmd_info}")
        lines.append("")

    # Live output (last 8 lines)
    if build_lines:
        lines.append("Live Output:")
        for line in list(build_lines)[-8:]:
            if line:
                lines.append(f"  {line}")

    return "\n".join(lines)


class _LiveTUI:
    """A DankInstall-style live TUI renderer using ANSI escape codes.

    Uses \033[?25l (hide cursor) and \033[2J (clear) to redraw the
    same area of the terminal. When the TUI is torn down, the cursor
    is restored and the output is flushed to stdout as a permanent
    record.
    """

    SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    SPINNER_INTERVAL = 0.08  # seconds between frames

    def __init__(self, total: int) -> None:
        self.total = total
        self.idx = 0
        self.module_name = ""
        self.step_text = ""
        self.cmd_info = ""
        self.build_lines: deque[str] = deque(maxlen=50)
        self._frame = 0
        self._running = False
        self._stop_event = threading.Event()
        self._thread: threading.Thread | None = None
        self._written_lines = 0
        self._final_output: list[str] = []

    # ── public API ────────────────────────────────────────────────

    def start(self) -> None:
        """Start the spinner animation and show the initial frame."""
        if not _is_tty():
            return
        self._running = True
        # Clear the screen and hide the cursor — matching DankInstall's
        # alt-screen behavior where the TUI owns the entire terminal.
        sys.stdout.write("\033[2J\033[H\033[?25l")
        sys.stdout.flush()
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._thread.start()

    def update_module(self, name: str, idx: int, step: str = "") -> None:
        """Switch to a new module."""
        self.module_name = name
        self.idx = idx
        self.step_text = step or f"Installing {name}"
        self.build_lines.clear()
        self._render()

    def update_step(self, step: str, cmd: str = "") -> None:
        """Update the step description and command info."""
        self.step_text = step
        if cmd:
            self.cmd_info = cmd
        self._render()

    def add_build_line(self, line: str) -> None:
        """Append a line from the current module's build output."""
        self.build_lines.append(line)
        self._render()

    def finish(self) -> None:
        """Stop the spinner and flush the final state."""
        if not self._running:
            return
        self._stop_event.set()
        if self._thread:
            self._thread.join(timeout=0.5)
        self._running = False
        self._render(final=True)
        # Record what was shown for permanent stdout output
        self._final_output.append(
            f"[{self.idx}/{self.total}] {self.module_name:<28} done"
        )
        sys.stdout.write("\033[?25h")  # show cursor
        sys.stdout.flush()

    def flush_final(self) -> None:
        """Print the final summary after TUI teardown."""
        if not _is_tty():
            return
        # Restore cursor, clear TUI, then print permanent summary
        sys.stdout.write("\033[2J\033[H")  # clear + home
        for line in self._final_output:
            sys.stdout.write(line + "\n")
        sys.stdout.flush()

    # ── internals ─────────────────────────────────────────────────

    def _spin(self) -> None:
        """Animate the spinner in a background thread."""
        while not self._stop_event.is_set():
            self._render()
            time.sleep(self.SPINNER_INTERVAL)

    def _render(self, final: bool = False) -> None:
        """Redraw the TUI frame."""
        if not _is_tty():
            return
        spinner = self.SPINNER_FRAMES[self._frame % len(self.SPINNER_FRAMES)]
        self._frame += 1

        frame = _render_frame(
            self.idx, self.total, self.module_name,
            spinner, self.build_lines,
            step_text=self.step_text,
            cmd_info=self.cmd_info,
        )

        # Move up to overwrite previous frame
        if self._written_lines > 0:
            sys.stdout.write(f"\033[{self._written_lines}A")
        # Clear each line
        for _ in range(self._written_lines):
            sys.stdout.write("\033[2K")
            sys.stdout.write("\033[1B")
        sys.stdout.write("\033[H")  # home
        # Write new frame
        self._written_lines = 0
        for line in frame.split("\n"):
            sys.stdout.write("\033[2K" + line + "\n")
            self._written_lines += 1
        sys.stdout.flush()


# ── Module output capture ───────────────────────────────────────────

class _OutputCapture:
    """A file-like that captures lines and feeds them to a TUI.

    Recognises special markers:
      @STEP:text   -> update the step description
      @CMD:text    -> update the command info line
      (anything else) -> add to the live output buffer
    """

    def __init__(self, tui: _LiveTUI) -> None:
        self._tui = tui
        self._buf = b""

    def write(self, s) -> int:
        n = len(s) if isinstance(s, str) else 0
        self._buf += (s if isinstance(s, (str, bytes)) else str(s)).encode()
        while b"\n" in self._buf:
            line, self._buf = self._buf.split(b"\n", 1)
            decoded = line.decode(errors="replace").rstrip()
            if not decoded:
                continue
            if decoded.startswith("@STEP:"):
                self._tui.update_step(decoded[6:])
            elif decoded.startswith("@CMD:"):
                self._tui.update_step(self._tui.step_text, cmd=decoded[5:])
            else:
                self._tui.add_build_line(decoded)
        return n

    def flush(self) -> None:
        pass

    def isatty(self) -> bool:
        return True  # So modules don't suppress output

    def fileno(self):
        return -1  # Not a real fd


# ── Runner ──────────────────────────────────────────────────────────

class ModuleRunner:
    """Executes a list of Modules in order with progress reporting."""

    def __init__(
        self,
        modules: list[Module],
        options: RunnerOptions | None = None,
    ):
        self.modules = modules
        self.options = options or RunnerOptions()
        self.state = State()

    def run_all(self) -> None:
        ctx = self._build_context()
        total = len(self.modules)
        tui = _LiveTUI(total)
        tui.start()

        for idx, module in enumerate(self.modules, 1):
            manifest_path = self._resolve_manifest(module)

            if not self.options.force and \
                    self.state.is_up_to_date(module.name, manifest_path):
                tui.update_module(module.name, idx)
                tui.add_build_line("skip (up to date)")
                tui.finish()
            elif self.options.dry_run:
                tui.update_module(module.name, idx)
                tui.add_build_line("dry-run")
                tui.finish()
            else:
                tui.update_module(module.name, idx)
                set_suppress_stderr(True)
                capture = _OutputCapture(tui)
                old_stdout = sys.stdout
                old_stderr = sys.stderr
                sys.stdout = capture
                sys.stderr = capture
                try:
                    module.pre_check(ctx)
                    module.run(ctx)
                    module.post_check(ctx)
                    self.state.mark_done(module.name, manifest_path)
                except (ModuleFailure, Exception) as exc:
                    tui.finish()
                    sys.stdout = old_stdout
                    sys.stderr = old_stderr
                    set_suppress_stderr(False)
                    if isinstance(exc, ModuleFailure):
                        self.state.mark_failed(exc.module_name, exc.reason)
                        fatal(str(exc))
                    else:
                        self.state.mark_failed(module.name, str(exc))
                        fatal(f"Module {module.name} failed: {exc}")
                finally:
                    sys.stdout = old_stdout
                    sys.stderr = old_stderr
                    set_suppress_stderr(False)
                    tui.finish()

        tui.flush_final()
        print(f"[OK] All {total} modules processed.")

    def _build_context(self) -> RunContext:
        real_user = os.environ.get("SUDO_USER", "")
        user_home = os.environ.get("USER_HOME", "")
        if not real_user or not user_home:
            from installer.config import STATE_DIR as _sd
            real_user = real_user or "root"
            user_home = user_home or str(Path(_sd).parent)
        return RunContext(
            real_user=real_user,
            user_home=Path(user_home),
            state=self.state,
        )

    def _resolve_manifest(self, module: Module) -> Path | None:
        if not module.manifest:
            return None
        from installer.config import MANIFESTS_DIR
        p = Path(module.manifest)
        if not p.is_absolute():
            p = MANIFESTS_DIR / p
        return p

    def _build_context(self) -> RunContext:
        real_user = os.environ.get("SUDO_USER", "")
        user_home = os.environ.get("USER_HOME", "")
        if not real_user or not user_home:
            # detect_real_user should have set these; fall back to
            # repo-relative defaults if not (e.g. running --help).
            from installer.config import STATE_DIR as _sd
            real_user = real_user or "root"
            user_home = user_home or str(Path(_sd).parent)
        return RunContext(
            real_user=real_user,
            user_home=Path(user_home),
            state=self.state,
        )

    def _resolve_manifest(self, module: Module) -> Path | None:
        if not module.manifest:
            return None
        from installer.config import MANIFESTS_DIR
        p = Path(module.manifest)
        if not p.is_absolute():
            p = MANIFESTS_DIR / p
        return p
