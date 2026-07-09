"""Module orchestration: the loop that runs the 16 modules in order."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from installer.errors import fatal, ModuleFailure
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.progress import make_progress
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
        progress = make_progress(total=len(self.modules), label="install")

        if progress is not None:
            with progress:
                self._loop(ctx, progress)
        else:
            self._loop(ctx, progress=None)

    def _loop(self, ctx: RunContext, progress) -> None:
        for module in self.modules:
            manifest_path = self._resolve_manifest(module)

            task = None
            if progress is not None:
                task = progress.add_task(module.name, total=1)

            try:
                if not self.options.force and \
                        self.state.is_up_to_date(module.name, manifest_path):
                    log("info", f"Module {module.name} already up to date. Skipping.")
                elif self.options.dry_run:
                    log("step", f"[dry-run] {module.name} would be executed")
                else:
                    log("step", f"Running module {module.name}")
                    module.pre_check(ctx)
                    module.run(ctx)
                    module.post_check(ctx)
                    self.state.mark_done(module.name, manifest_path)
            except ModuleFailure as exc:
                self.state.mark_failed(exc.module_name, exc.reason)
                fatal(str(exc))
            except Exception as exc:
                self.state.mark_failed(module.name, str(exc))
                fatal(f"Module {module.name} failed: {exc}")
            finally:
                if progress is not None and task is not None:
                    progress.update(task, completed=1)

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
