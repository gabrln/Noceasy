"""Privilege escalation helpers.

The installer runs as the real user; ``sudo`` is only used for
individual privileged operations inside each module.
"""

from __future__ import annotations

import os
from pathlib import Path

from installer.errors import fatal


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
