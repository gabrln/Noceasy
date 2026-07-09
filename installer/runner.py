"""Module orchestration: the loop that runs the modules in order.

Uses rich.live.Live for a DankInstall-style progress display:
spinner, progress bar, and filtered live output — all in a
single re-rendering block that replaces the previous frame
(no scrolling, no interleaving).
"""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

from installer.errors import fatal, ModuleFailure
from installer.logger import log, set_suppress_stderr
from installer.modules.base import Module, RunContext
from installer.state import State


@dataclass
class RunnerOptions:
    dry_run: bool = False
    force: bool = False


# ── DankInstall-style TUI progress (rich.live) ──────────────────────

def _is_tty() -> bool:
    return sys.stdout.isatty() and not os.environ.get("NO_COLOR")


class _OutputCapture:
    """Captures stdout/stderr and routes special markers to the Live display.

    Markers:  @STEP:text  -> update step description
             @CMD:text   -> update command info
    Anything else goes to build_lines on the Live display.
    """

    def __init__(self, live_ctx) -> None:
        self._live = live_ctx
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
                if decoded.startswith("@STEP:"):
                    self._live.set_step(decoded[6:])
                elif decoded.startswith("@CMD:"):
                    self._live.set_cmd(decoded[5:])
                else:
                    self._live.add_line(decoded)
        finally:
            self._in_write = False
        return n

    def flush(self) -> None:
        pass

    def isatty(self) -> bool:
        return True

    def fileno(self):
        return -1


class _LiveDisplay:
    """Wraps rich.live.Live with a DankInstall-style panel.

    Renders:
      ⠹ Building noctalia-git
      [████████████░░░░░░░░░░░░░░░░░░] 42%
      $ yay -S --needed --noconfirm
      Live Output:
        ==> Making package: noctalia-git
    """

    SPINNER = "dots"

    def __init__(self, total: int) -> None:
        from rich.console import Console
        from rich.live import Live
        self._total = total
        self._idx = 0
        self._module = ""
        self._step = ""
        self._cmd = ""
        self._lines: list[str] = []
        self._live: Live | None = None
        self._console: Console | None = None
        self._final: list[str] = []

    def start(self) -> None:
        if not _is_tty():
            return
        from rich.console import Console
        from rich.live import Live
        self._console = Console(stderr=False)
        self._live = Live(
            self._build_renderable(),
            console=self._console,
            refresh_per_second=12,
            transient=False,
        )
        self._live.start()

    def update_module(self, name: str, idx: int) -> None:
        self._module = name
        self._idx = idx
        self._step = f"Installing {name}"
        self._cmd = ""
        self._lines.clear()
        self._refresh()

    def set_step(self, step: str) -> None:
        self._step = step
        self._refresh()

    def set_cmd(self, cmd: str) -> None:
        self._cmd = cmd
        self._refresh()

    def add_line(self, line: str) -> None:
        self._lines.append(line)
        if len(self._lines) > 8:
            self._lines = self._lines[-8:]
        self._refresh()

    def finish(self) -> None:
        if self._live:
            self._live.stop()
        self._final.append(
            f"[{self._idx}/{self._total}] {self._module:<28} done"
        )
        if self._console:
            self._console.print(
                f"[{self._idx}/{self._total}] {self._module:<28} [green]done[/green]"
            )

    def flush_final(self) -> None:
        pass  # finish() already prints per-module

    def _refresh(self) -> None:
        if self._live:
            self._live.update(self._build_renderable())

    def _build_renderable(self):
        from rich.panel import Panel
        from rich.spinner import Spinner
        from rich.text import Text
        from rich.progress import Progress, BarColumn, TextColumn

        parts = []

        # Spinner + step
        parts.append(Spinner(self.SPINNER, text=f" {self._step}"))
        parts.append("")

        # Progress bar
        pct = self._idx / self._total if self._total else 0
        filled = int(30 * pct)
        empty = 30 - filled
        bar = f"[{filled * '█'}{empty * '░'}] {pct * 100:.0f}%"
        parts.append(Text(bar))
        parts.append("")

        # Command info
        if self._cmd:
            parts.append(Text(f"$ {self._cmd}", style="dim"))
            parts.append("")

        # Live output
        if self._lines:
            parts.append(Text("Live Output:", style="dim"))
            for line in self._lines:
                parts.append(Text(f"  {line}"))

        from rich.console import Group
        return Panel(
            Group(*parts),
            title=f"Noceasy Installer [dim]{self._idx}/{self._total}[/dim]",
            border_style="cyan",
        )


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
        tui = _LiveDisplay(total)
        tui.start()

        for idx, module in enumerate(self.modules, 1):
            manifest_path = self._resolve_manifest(module)

            try:
                if not self.options.force and \
                        self.state.is_up_to_date(module.name, manifest_path):
                    tui.update_module(module.name, idx)
                    tui.add_line("skip (up to date)")
                    tui.finish()
                elif self.options.dry_run:
                    tui.update_module(module.name, idx)
                    tui.add_line("dry-run")
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
            except Exception as exc:
                tui.finish()
                fatal(f"Module {module.name} failed: {exc}")

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
