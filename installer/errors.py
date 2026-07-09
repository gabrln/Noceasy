"""Error handling: signal traps, fatal(), cleanup registration."""

from __future__ import annotations

import atexit
import signal
import sys
from typing import Callable

from installer.logger import log


class InstallerError(Exception):
    """Base exception for installer-specific failures.

    The Runner catches this and calls fatal(). Subclasses provide
    more specific context (network, permission, module failure).
    """
    pass


class ModuleFailure(InstallerError):
    """Raised by a Module.run() to signal failure with context."""
    def __init__(self, module_name: str, reason: str):
        super().__init__(f"Module {module_name} failed: {reason}")
        self.module_name = module_name
        self.reason = reason


class NetworkError(InstallerError):
    """Raised when a network operation fails after retries."""
    pass


class PermissionError_(InstallerError):
    """Raised when a privilege-related operation fails.

    Named with underscore to avoid shadowing builtin PermissionError.
    """
    pass


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
    """Log an error, run cleanup, and exit."""
    log("error", message)
    run_cleanup()
    sys.exit(code)


# Exit codes that are NOT considered fatal (e.g. `command -v` returns
# 1 when a binary is missing; that's expected and shouldn't trigger
# cleanup of state).
_BENIGN_EXIT_CODES = {1, 2, 3, 64, 130, 141}


def is_benign_exit(code: int) -> bool:
    return code in _BENIGN_EXIT_CODES


def _on_signal(signum, frame):
    log("warn", f"Signal {signum} received. Cancelling...")
    run_cleanup()
    sys.exit(130)


def install_signal_handlers() -> None:
    """Trap SIGINT/SIGTERM for clean cancellation."""
    signal.signal(signal.SIGINT, _on_signal)
    signal.signal(signal.SIGTERM, _on_signal)
    atexit.register(run_cleanup)
