"""00-preflight: pre-conditions check."""

from __future__ import annotations

import os
from pathlib import Path

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import has_free_space, has_internet
from installer.toml_cache import get_cache


class PreflightModule(Module):
    name = "00-preflight"

    def run(self, ctx: RunContext) -> None:
        log("info", "Checking pre-conditions...")

        if has_internet():
            log("success", "Internet connectivity confirmed.")
        else:
            log("warn", "Could not confirm internet connectivity. Continuing anyway.")

        min_bytes = get_cache().get(
            "config.toml", "install.min_free_space", 5 * 1024**3)
        if has_free_space([ctx.user_home, Path("/")], min_bytes=int(min_bytes)):
            log("success", "Sufficient disk space.")
        else:
            log("warn",
                f"Disk space may be insufficient (minimum: {min_bytes} bytes).")

        log("info", f"REAL_USER: {ctx.real_user}")
        log("info", f"USER_HOME: {ctx.user_home}")
        log("info", f"REPO_DIR: {os.environ.get('REPO_DIR', '?')}")
        log("success", "Pre-conditions verified.")
