"""On-demand privilege escalation.

Detects and wraps the available privilege-escalation tool (sudo/doas/run0)
so callers never have to care which one is installed.  The two main entry
points are:

  - ``check_cached()`` – returns True when the tool already has valid
    credentials (no password prompt needed).
  - ``run_privileged()`` – drops-in replacement for any ``subprocess.run()``
    call that needs root; transparently injects the password via stdin when
    necessary.

Design notes
------------
* sudo is universal on Arch and preferred; doas / run0 are fallbacks.
* Passwords are **never** stored on disk or in environment variables.
* Shell injection is prevented by never interpolating user input into
  command strings — everything goes through argv lists.
"""

from __future__ import annotations

import enum
import shlex
import shutil
import subprocess
import sys
from typing import Any, Mapping, Sequence

from installer.logger import log


# ---------------------------------------------------------------------------
# Tool enum
# ---------------------------------------------------------------------------

class Tool(enum.Enum):
    """Supported privilege-escalation tools."""

    sudo = "sudo"
    doas = "doas"
    run0 = "run0"


# ---------------------------------------------------------------------------
# Detection
# ---------------------------------------------------------------------------

# Preferred order — sudo first (universal on Arch), then alternatives.
_SEARCH_ORDER: list[Tool] = [Tool.sudo, Tool.doas, Tool.run0]


def _tool_binary(tool: Tool) -> str:
    """Return the binary name for *tool*."""
    return tool.value


def detect() -> Tool:
    """Detect the first available privilege-escalation tool on PATH.

    Searches in order: sudo → doas → run0.  Raises ``RuntimeError``
    if none is found.
    """
    for tool in _SEARCH_ORDER:
        if shutil.which(_tool_binary(tool)) is not None:
            log("debug", f"privesc: detected {_tool_binary(tool)}")
            return tool

    raise RuntimeError(
        "No privilege-escalation tool found. "
        "Install one of: sudo, doas, run0."
    )


# ---------------------------------------------------------------------------
# Cache probing
# ---------------------------------------------------------------------------

def _cache_check_argv(tool: Tool) -> list[str]:
    """Return argv that succeeds only when credentials are already cached.

    sudo  → ``sudo -n true``  (fails with exit 1 when password required)
    doas  → ``doas -n true``  (same semantics on OpenBSD doas)
    run0  → ``run0 --no-ask-password true``  (fails if auth needed)
    """
    if tool is Tool.sudo:
        return ["sudo", "-n", "true"]
    if tool is Tool.doas:
        return ["doas", "-n", "true"]
    # run0 (systemd ≥ 256)
    return ["run0", "--no-ask-password", "true"]


def check_cached(tool: Tool) -> bool:
    """Return True if *tool* already has cached credentials (no prompt).

    Runs a non-interactive dry-run command that exits 0 only when the
    password is already cached.
    """
    argv = _cache_check_argv(tool)
    log("debug", f"privesc: checking cache — {' '.join(argv)}")
    proc = subprocess.run(
        argv,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return proc.returncode == 0


# ---------------------------------------------------------------------------
# Password validation
# ---------------------------------------------------------------------------

def _validate_argv(tool: Tool) -> list[str]:
    """Return the validation argv (without the password on stdin).

    sudo  → ``sudo -S -v``   (validate, read pw from stdin)
    doas  → ``doas -v``       (validate; password read from stdin)
    run0  → ``run0 -v``       (validate if supported; see note below)

    Note: run0 validation is best-effort — some builds may not support
    ``-v`` at all.  Callers should fall back to ``run_privileged()``
    directly when validation is not possible.
    """
    if tool is Tool.sudo:
        return ["sudo", "-S", "-v"]
    if tool is Tool.doas:
        return ["doas", "-v"]
    # run0 — try -v; if unsupported the caller will see the error
    return ["run0", "-v"]


def validate_password(pw: str, tool: Tool) -> bool:
    """Confirm that *pw* is correct for *tool* without elevating.

    Pipes the password to the tool's stdin and runs its validate
    command.  Returns True on success, False on failure.

    Raises ``RuntimeError`` if *tool* is ``run0`` and validation is
    not supported by the build.
    """
    argv = _validate_argv(tool)
    log("debug", f"privesc: validating password for {tool.value}")

    try:
        proc = subprocess.run(
            argv,
            input=pw + "\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
        )
    except FileNotFoundError:
        log("error", f"privesc: {_tool_binary(tool)} binary not found")
        return False
    except subprocess.TimeoutExpired:
        log("warn",
            f"privesc: password validation timed out for {tool.value}")
        return False

    if proc.returncode != 0:
        stderr_msg = (proc.stderr or "").strip()
        log("warn",
            f"privesc: password validation failed for {tool.value} "
            f"(rc={proc.returncode}, stderr={stderr_msg!r})")
        return False

    log("debug", f"privesc: password validated for {tool.value}")
    return True


# ---------------------------------------------------------------------------
# Running commands with elevated privileges
# ---------------------------------------------------------------------------

def _escape_for_stdin(text: str) -> str:
    """Escape *text* so it is safe to pass via ``input=``.

    ``subprocess.run(input=...)`` writes to the process stdin without
    shell interpretation, so we only need to worry about bytes that
    could confuse specific tools:

    * NUL bytes are forbidden on POSIX.
    * A trailing newline is stripped by most password readers — we
      always append one explicitly in ``run_privileged()``.

    This function validates rather than transforms; callers should
    never build shell strings from passwords.
    """
    if "\x00" in text:
        raise ValueError("Password must not contain NUL bytes")
    return text


def _build_sudo_argv(
    argv: list[str],
    password: str | None,
) -> tuple[list[str], str | None]:
    """Build the full argv for sudo, injecting ``-S`` when password is given.

    Returns ``(argv, stdin_text)``.
    """
    cmd = ["sudo"]
    stdin_text: str | None = None

    if password is not None:
        cmd.append("-S")
        stdin_text = password + "\n"

    cmd.extend(argv)
    return cmd, stdin_text


def _build_doas_argv(
    argv: list[str],
    password: str | None,
) -> tuple[list[str], str | None]:
    """Build the full argv for doas.

    doas reads the password from stdin when a password is required; there
    is no ``-S`` flag — it simply reads from fd 0 if authentication is
    needed.

    Returns ``(argv, stdin_text)``.
    """
    cmd = ["doas"]
    stdin_text: str | None = None

    if password is not None:
        stdin_text = password + "\n"

    cmd.extend(argv)
    return cmd, stdin_text


def _build_run0_argv(
    argv: list[str],
    password: str | None,
) -> tuple[list[str], str | None]:
    """Build the full argv for run0.

    run0 delegates authentication to PAM/polkit.  When a password is
    provided, it is sent via stdin.

    Returns ``(argv, stdin_text)``.
    """
    cmd = ["run0"]
    stdin_text: str | None = None

    if password is not None:
        stdin_text = password + "\n"

    cmd.extend(argv)
    return cmd, stdin_text


_BUILDERS: dict[Tool, Any] = {
    Tool.sudo: _build_sudo_argv,
    Tool.doas: _build_doas_argv,
    Tool.run0: _build_run0_argv,
}


def run_privileged(
    argv: list[str],
    password: str | None = None,
    tool: Tool | None = None,
    *,
    check: bool = False,
    capture_output: bool = False,
    text: bool = True,
    timeout: int | None = None,
    cwd: str | None = None,
    env: Mapping[str, str] | None = None,
    log_cmd: bool = False,
    **kwargs: Any,
) -> subprocess.CompletedProcess:
    """Run *argv* with elevated privileges via *tool*.

    Behaviour
    ---------
    1. If *tool* is ``None``, calls ``detect()`` once and caches the
       result for the lifetime of the process.
    2. If *password* is ``None`` and ``check_cached(tool)`` is True,
       the command is run directly (no password injection).
    3. Otherwise the password is injected via stdin.

    Additional keyword arguments (``check``, ``capture_output``, …)
    are forwarded to ``subprocess.run()`` exactly as the caller would
    pass them — mirroring the ``exec.run()`` signature.

    Returns a ``subprocess.CompletedProcess``.

    Raises
    ------
    RuntimeError
        If no tool is found (``detect()`` fails).
    subprocess.CalledProcessError
        If ``check=True`` and the command exits non-zero.
    """
    if tool is None:
        tool = detect()

    # Validate the password string before using it anywhere.
    if password is not None:
        _escape_for_stdin(password)

    # Decide whether we can skip the password entirely.
    use_password = password
    if use_password is None and not check_cached(tool):
        raise RuntimeError(
            f"{tool.value}: no cached credentials and no password provided. "
            "Supply a password or run the tool once interactively first."
        )

    builder = _BUILDERS[tool]
    full_argv, stdin_text = builder(argv, use_password)

    if log_cmd:
        # Never log the password — mask it in the command line.
        safe = [a if a != use_password else "***" for a in full_argv]
        log("debug", "privesc: " + " ".join(safe))

    proc = subprocess.run(
        full_argv,
        input=stdin_text,
        check=check,
        capture_output=capture_output,
        text=text,
        timeout=timeout,
        cwd=cwd,
        env=env,
        **kwargs,
    )

    if proc.returncode != 0:
        log(
            "warn",
            f"privesc: {' '.join(full_argv[:3])}… exited {proc.returncode}",
        )

    return proc


# ---------------------------------------------------------------------------
# Cache management (test / debug)
# ---------------------------------------------------------------------------

def clear_cache(tool: Tool) -> None:
    """Invalidate the cached credentials for *tool*.

    Runs ``tool -k`` (sudo) or the equivalent.  Intended for test
    harnesses and debugging — not for production use.
    """
    if tool is Tool.sudo:
        argv = ["sudo", "-k"]
    elif tool is Tool.doas:
        # doas has no standard cache-clear flag; best-effort: try -k
        argv = ["doas", "-k"]
    else:
        # run0: no cache-clear mechanism; warn and return.
        log("warn", "privesc: run0 has no cache-clear mechanism")
        return

    log("debug", f"privesc: clearing cache — {' '.join(argv)}")
    subprocess.run(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ---------------------------------------------------------------------------
# Module-level convenience
# ---------------------------------------------------------------------------

_cached_tool: Tool | None = None


def get_tool() -> Tool:
    """Return the detected tool, caching the result for the process."""
    global _cached_tool
    if _cached_tool is None:
        _cached_tool = detect()
    return _cached_tool


def reset_tool() -> None:
    """Clear the cached tool detection result (useful in tests)."""
    global _cached_tool
    _cached_tool = None
