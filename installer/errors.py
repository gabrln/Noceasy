"""Error handling: signal traps, fatal(), cleanup registration."""

from __future__ import annotations

import atexit
import signal
import sys
import traceback
from typing import Callable, List

from installer.logger import log


_cleanup_hooks: List[Callable[[], None]] = []


def register_cleanup(fn: Callable[[], None]) -> None:
    """Register a function to run on exit (always, even on fatal)."""
    _cleanup_hooks.append(fn)


def run_cleanup() -> None:
    """Run all registered cleanup hooks. Exceptions are swallowed."""
    for hook in _cleanup_hooks:
        try:
            hook()
        except Exception as exc:
            log("debug", f"cleanup hook falhou: {exc}")


def fatal(message: str, code: int = 1) -> None:
    """Log an error, run cleanup, and exit."""
    log("error", message)
    run_cleanup()
    sys.exit(code)


# Exit codes that are NOT considered fatal (e.g. `command -v` returns 1
# when a binary is missing; that's expected and shouldn't trigger cleanup
# of state).
_BENIGN_EXIT_CODES = {1, 2, 3, 64, 130, 141}


def is_benign_exit(code: int) -> bool:
    return code in _BENIGN_EXIT_CODES


def _on_sigint(signum, frame):
    log("warn", f"Sinal {signum} recebido. Cancelando...")
    run_cleanup()
    sys.exit(130)


def install_signal_handlers() -> None:
    """Trap SIGINT/SIGTERM for clean cancellation."""
    signal.signal(signal.SIGINT, _on_sigint)
    signal.signal(signal.SIGTERM, _on_sigint)
    atexit.register(run_cleanup)
