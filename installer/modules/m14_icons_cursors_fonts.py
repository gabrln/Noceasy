"""14-icons-cursors-fonts: refresh font and icon caches."""

from __future__ import annotations

import subprocess
from pathlib import Path

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user, is_command
from installer.privilege import run_as_user


class IconsCursorsFontsModule(Module):
    name = "14-icons-cursors-fonts"

    def run(self, ctx: RunContext) -> None:
        log("info", "Updating font cache...")
        subprocess.run(["fc-cache", "-fv"], check=False, capture_output=True,
                        timeout=120)

        log("info", "Ensuring user icons directory...")
        icons_dir = ctx.user_home / ".local" / "share" / "icons"
        icons_dir.mkdir(parents=True, exist_ok=True)
        chown_user(icons_dir, ctx.real_user)

        if is_command("gtk-update-icon-cache"):
            log("info", "Updating gtk icon cache...")
            for d in icons_dir.iterdir():
                if d.is_dir():
                    run_as_user(
                        f"gtk-update-icon-cache -f -t '{d}' 2>/dev/null || true",
                        user=ctx.real_user, check=False,
                    )

        log("success", "Font and icon cache updated.")
