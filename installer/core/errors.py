"""Error handling: signal traps, fatal(), cleanup registration."""

from __future__ import annotations

import atexit
import signal
import sys
from collections.abc import Callable

from installer.ui.logger import log, set_suppress_stderr


class InstallerError(Exception):
    """Base exception for installer-specific failures.

    The Runner catches this and calls fatal(). Subclasses provide
    more specific context (network, permission, module failure).
    """
    pass


class ModuleFailure(InstallerError):  # noqa: N818
    """Raised by a Module.run() to signal failure with context."""
    def __init__(self, module_name: str, reason: str):
        super().__init__(f"Module {module_name} failed: {reason}")
        self.module_name = module_name
        self.reason = reason

_cleanup_hooks: list[Callable[[], None]] = []


def register_cleanup(fn: Callable[[], None]) -> None:
    """Register a function to run on exit (always, even on fatal)."""
    _cleanup_hooks.append(fn)


def run_cleanup() -> None:
    """Run all registered cleanup hooks. Exceptions are swallowed."""
    for hook in _cleanup_hooks:
        try:
            hook()
        except Exception as exc:
            log("debug", f"cleanup hook failed: {exc}")


def fatal(message: str, code: int = 1) -> None:
    """Log an error, run cleanup, and exit.

    Explicitly lifts stderr suppression first: fatal errors must
    always reach the terminal, even if a module (or the TUI) left
    the suppressor engaged when it crashed.
    """
    set_suppress_stderr(False)
    log("error", message)
    run_cleanup()
    sys.exit(code)




def _on_signal(signum, frame):
    log("warn", f"Signal {signum} received. Cancelling...")
    run_cleanup()
    sys.exit(130)


def install_signal_handlers() -> None:
    """Trap SIGINT/SIGTERM for clean cancellation."""
    signal.signal(signal.SIGINT, _on_signal)
    signal.signal(signal.SIGTERM, _on_signal)
    atexit.register(run_cleanup)
