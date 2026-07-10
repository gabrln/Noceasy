"""Base class for all install modules."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path

from installer.state import State


@dataclass
class RunContext:
    """Context passed to every module's run() method.

    Provides the real user, the user home, and the state manager.
    Modules should not read environment variables directly; use
    this context instead.
    """

    real_user: str
    user_home: Path
    state: State
    sudo_password: str | None = None

    @property
    def home(self) -> Path:
        return self.user_home

    @property
    def user(self) -> str:
        return self.real_user


class Module(ABC):
    """Base class for install steps.

    Subclasses override `run()`. Optionally set `name` and
    `manifest`. `pre_check` and `post_check` can be overridden to
    short-circuit (return False to skip) or validate.
    """

    name: str = "unnamed"
    manifest: str | None = None  # e.g. "packages.toml"

    def __init__(self, manifest: str | None = None) -> None:
        if manifest is not None:
            self.manifest = manifest

    def pre_check(self, ctx: RunContext) -> bool:
        """Return False to skip this module (e.g. precondition not met)."""
        return True

    @abstractmethod
    def run(self, ctx: RunContext) -> None:
        """Run the module. Raise ModuleFailure on failure.

        The Runner catches ModuleFailure (and other Exception) and
        calls fatal(). For most internal errors, raise Exception
        with a clear message; the Runner logs the module name
        automatically.

        Progress reporting
        ~~~~~~~~~~~~~~~~~~
        During execution the module's stdout/stderr are captured by
        an OutputCapture. Special lines ("markers") are parsed and
        used to drive the live TUI panel. Everything else appears
        in the Live Output area.

        Markers (emit via ``print()``)::

            print("@STEP:Building foo")     # update step description
            print("@CMD:yay -S foo")        # show command being run
            print("@PROGRESS:5")            # set total steps
            print("@ADVANCE:1")             # advance progress by N

        Most modules do not need granular progress.  The runner
        creates a default 0→1 bar for every module; only modules
        with quantifiable work (package builds, file downloads)
        should emit ``@PROGRESS`` / ``@ADVANCE``.
        """
        ...

    def post_check(self, ctx: RunContext) -> None:
        """Validate after run; raise on failure."""
        return None
