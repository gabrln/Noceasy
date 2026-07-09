"""Process execution helpers.

Centralizes the common `subprocess.run(check=False, capture_output=True)`
pattern that appears in 14+ files. Provides:

  - run(): the standard "fire and forget with logging" pattern
  - run_capture(): same but always captures output (returns it)
  - run_or_die(): like run() but exits via fatal() on failure
  - run_user(): shorthand for run_as_user() (re-export)

Use this when you want consistent timeout/capture/logging behavior
across the framework. For ad-hoc commands with specific return
handling, keep using subprocess.run directly.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Mapping, Optional, Sequence, Union

from installer.errors import fatal
from installer.logger import log
from installer.privilege import run_as_user


def run(
    argv: Sequence[str],
    *,
    timeout: Optional[int] = None,
    cwd: Optional[Path] = None,
    env: Optional[Mapping[str, str]] = None,
    log_cmd: bool = False,
) -> subprocess.CompletedProcess:
    """Run a command, capturing output and never raising on failure.

    Returns CompletedProcess with .returncode, .stdout, .stderr
    (all strings if capture, None otherwise).
    """
    if log_cmd:
        log("debug", " ".join(str(a) for a in argv))
    return subprocess.run(
        list(argv),
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
        cwd=cwd,
        env=env,
    )


def run_capture(
    argv: Sequence[str],
    *,
    timeout: Optional[int] = None,
) -> subprocess.CompletedProcess:
    """Like run() but always returns stdout/stderr as strings."""
    return run(argv, timeout=timeout)


def run_or_die(
    argv: Sequence[str],
    *,
    message: Optional[str] = None,
) -> subprocess.CompletedProcess:
    """Run a command. If it fails, log + fatal (no exception raised)."""
    proc = run(argv)
    if proc.returncode != 0:
        err = proc.stderr.strip() if proc.stderr else "unknown error"
        msg = message or f"Command failed: {' '.join(str(a) for a in argv)}"
        fatal(f"{msg} ({err})")
    return proc


# Re-export for convenience
__all__ = ["run", "run_capture", "run_or_die", "run_as_user"]
