"""14-icons-cursors-fonts: refresh font and icon caches."""

from __future__ import annotations

from installer.infra import exec as exec_mod
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user, is_command
from installer.ui.logger import log


class IconsCursorsFontsModule(Module):
    name = "14-icons-cursors-fonts"

    def run(self, ctx: RunContext) -> None:
        log("info", "Updating font cache...")
        exec_mod.run(["fc-cache", "-fv"], timeout=120)

        log("info", "Ensuring user icons directory...")
        icons_dir = ctx.user_home / ".local" / "share" / "icons"
        icons_dir.mkdir(parents=True, exist_ok=True)
        chown_user(icons_dir, ctx.real_user)

        if is_command("gtk-update-icon-cache"):
            log("info", "Updating gtk icon cache...")
            for d in icons_dir.iterdir():
                if d.is_dir():
                    result = exec_mod.run(["gtk-update-icon-cache", "-f", "-t", str(d)])
                    if result.returncode != 0:
                        log("warn", f"gtk-update-icon-cache failed for {d}: "
                                    f"{result.stderr.strip()}")

        log("success", "Font and icon cache updated.")
