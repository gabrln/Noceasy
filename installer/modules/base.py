"""Base class for all install modules."""

from __future__ import annotations

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

    @property
    def home(self) -> Path:
        return self.user_home

    @property
    def user(self) -> str:
        return self.real_user


class Module:
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

    def run(self, ctx: RunContext) -> None:
        """Run the module. Raise ModuleFailure on failure.

        The Runner catches ModuleFailure (and other Exception) and
        calls fatal(). For most internal errors, raise Exception
        with a clear message; the Runner logs the module name
        automatically.
        """
        raise NotImplementedError

    def post_check(self, ctx: RunContext) -> None:
        """Validate after run; raise on failure."""
        return None
