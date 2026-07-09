"""Privilege escalation helpers.

The installer runs as the real user; ``sudo`` is only used for
individual privileged operations inside each module.

For executing commands as the real (unprivileged) user, we use
``runuser``, which is part of ``util-linux`` and is always present
on Arch.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from installer.errors import fatal


# ---------------------------------------------------------------------------
# runuser-based helpers
# ---------------------------------------------------------------------------

# TODO(phase 6): remove run_as_user() — callers will use subprocess directly
# or delegate to privileged helpers instead.


def run_as_user(
    cmd: str | Sequence[str],
    user: str,
    login: bool = True,
    check: bool = True,
    capture: bool = False,
    env: dict | None = None,
) -> subprocess.CompletedProcess:
    """Execute `cmd` as `user` via runuser.

    If `cmd` is a string, it's passed to `bash -lc` (login shell)
    or `bash -c`. If it's a list, it's exec'd directly (no shell).

    Optional `env` dict is merged with the inherited environment
    (current env vars override the inherited ones).

    Returns the CompletedProcess. If `check=True` (default), raises
    subprocess.CalledProcessError on non-zero exit.
    """
    if isinstance(cmd, str):
        shell_flag = "-lc" if login else "-c"
        argv = ["runuser", "-u", user, "--", "bash", shell_flag, cmd]
    else:
        argv = ["runuser", "-u", user, "--", *cmd]

    # Merge env with current process env (callers can override PATH,
    # HOME, etc without losing everything else).
    full_env = None
    if env is not None:
        full_env = os.environ.copy()
        full_env.update(env)

    return subprocess.run(
        argv,
        check=check,
        capture_output=capture,
        text=capture,
        env=full_env,
    )


# ---------------------------------------------------------------------------
# Real user detection
# ---------------------------------------------------------------------------

def detect_real_user() -> tuple[str, str]:
    """Return (real_user, user_home) for the current user.

    Uses ``pwd.getpwuid`` to resolve the user without relying on
    environment variables like ``SUDO_USER``.
    """
    import pwd

    pw = pwd.getpwuid(os.getuid())
    real_user = pw.pw_name
    user_home = pw.pw_dir

    if not user_home or not Path(user_home).is_dir():
        fatal(f"User '{real_user}' HOME does not exist: {user_home}")

    return real_user, user_home
