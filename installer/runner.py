"""Module orchestration: the loop that runs the modules in order."""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

from installer.errors import fatal, ModuleFailure, register_cleanup
from installer.logger import log, set_suppress_stderr
from installer.modules.base import Module, RunContext
from installer.progress import LiveDisplay, OutputCapture, is_tty
from installer.privilege import detect_real_user
from installer.state import State


@dataclass
class RunnerOptions:
    dry_run: bool = False
    force: bool = False


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
        tui = LiveDisplay(total)
        tui.start()
        # Ensure tui.stop() runs on ANY exit path, including
        # SystemExit raised by fatal(). Without this, fatal()
        # inside a module leaves the terminal frozen on the
        # alternate screen buffer.
        register_cleanup(tui.stop)

        self._setup_privileges(ctx, tui)

        for idx, module in enumerate(self.modules, 1):
            self._run_single_module(module, idx, ctx, tui)

        tui.stop()
        from rich.console import Console
        Console(stderr=False).print(
            f"\n[bold green]✓ All {total} modules processed successfully.[/bold green]"
        )

    # ── Privilege escalation ───────────────────────────────────────

    def _setup_privileges(self, ctx: RunContext, tui: LiveDisplay) -> None:
        """Detect the privilege-escalation tool and validate the password."""
        from installer import privesc
        tool = privesc.get_tool()
        if privesc.check_cached(tool):
            ctx.sudo_password = None
        else:
            password = tui.prompt_password()
            if not privesc.validate_password(password, tool):
                tui.stop()
                fatal(
                    "Falha na validação da senha sudo. "
                    "O instalador não pode continuar sem privilégios root."
                )
            ctx.sudo_password = password

    # ── Module execution ───────────────────────────────────────────

    def _run_single_module(
        self, module: Module, idx: int, ctx: RunContext, tui: LiveDisplay
    ) -> None:
        """Execute one module: skip, dry-run, or full run."""
        manifest_path = self._resolve_manifest(module)

        try:
            if not self.options.force and \
                    self.state.is_up_to_date(module.name, manifest_path):
                tui.update_module(module.name, idx)
                tui.state.step = f"{module.name} — skip (up to date)"
                tui.finish()
            elif self.options.dry_run:
                tui.update_module(module.name, idx)
                tui.state.step = f"{module.name} — dry-run"
                tui.finish()
            else:
                tui.update_module(module.name, idx)
                self._capture_and_run(module, ctx, tui, manifest_path)
        except Exception as exc:
            tui.stop()
            fatal(f"Module {module.name} failed: {exc}")

    def _capture_and_run(
        self,
        module: Module,
        ctx: RunContext,
        tui: LiveDisplay,
        manifest_path: Path | None,
    ) -> None:
        """Run a module with stdout/stderr capture and error handling.

        Redirects stdout/stderr to an OutputCapture so the TUI can
        display module output. Restores streams on exit.
        """
        set_suppress_stderr(True)
        capture = OutputCapture(tui.state, live=tui)
        old_stdout = sys.stdout
        old_stderr = sys.stderr
        sys.stdout = capture
        sys.stderr = capture
        try:
            module.pre_check(ctx)
            module.run(ctx)
            module.post_check(ctx)
            self.state.mark_done(module.name, manifest_path)
        except Exception as exc:
            tui.fail(str(exc))
            if isinstance(exc, ModuleFailure):
                self.state.mark_failed(exc.module_name, exc.reason)
            else:
                self.state.mark_failed(module.name, str(exc))
            fatal(f"Module {module.name} failed: {exc}")
        finally:
            sys.stdout = old_stdout
            sys.stderr = old_stderr
            set_suppress_stderr(False)
            tui.finish()

    # ── Helpers ─────────────────────────────────────────────────────

    def _build_context(self) -> RunContext:
        real_user, user_home = detect_real_user()
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
