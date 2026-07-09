"""Module orchestration: the loop that runs the modules in order."""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

from installer.errors import fatal, ModuleFailure
from installer.logger import log, set_suppress_stderr
from installer.modules.base import Module, RunContext
from installer.progress import LiveDisplay, OutputCapture, is_tty
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

        for idx, module in enumerate(self.modules, 1):
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
                    except (ModuleFailure, Exception) as exc:
                        tui.fail(str(exc))
                        sys.stdout = old_stdout
                        sys.stderr = old_stderr
                        set_suppress_stderr(False)
                        tui.stop()
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
                tui.stop()
                fatal(f"Module {module.name} failed: {exc}")

        tui.stop()
        from rich.console import Console
        Console(stderr=False).print(
            f"\n[bold green]✓ All {total} modules processed successfully.[/bold green]"
        )

    # ── Helpers ─────────────────────────────────────────────────────

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
