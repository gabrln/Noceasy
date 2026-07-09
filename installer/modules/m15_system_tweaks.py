"""15-system-tweaks: root theme symlinks + perms + cleanup."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user


def _replace_with_symlink(link_path: Path, target: Path) -> None:
    """Make `link_path` a symlink to `target`, removing anything in the way.

    If `link_path` is already a valid symlink to `target`, no-op.
    If it's a directory, rmtree. If it's a file or wrong symlink,
    unlink. Then create the symlink.
    """
    if link_path.is_symlink() and os.readlink(link_path) == str(target):
        log("info", f"  -> {link_path} (already correct)")
        return
    if link_path.is_dir() and not link_path.is_symlink():
        shutil.rmtree(link_path)
    elif link_path.is_symlink() or link_path.is_file():
        link_path.unlink()
    link_path.symlink_to(target)
    log("info", f"  -> {link_path}")


class SystemTweaksModule(Module):
    name = "15-system-tweaks"

    def run(self, ctx: RunContext) -> None:
        log("info", "Adjusting user config permissions...")
        cfg = ctx.user_home / ".config"
        if cfg.exists():
            chown_user(cfg, ctx.real_user)
        icons_dir = ctx.user_home / ".local" / "share" / "icons"
        icons_dir.mkdir(parents=True, exist_ok=True)
        chown_user(icons_dir, ctx.real_user)

        log("info", "Linking themes for root app accessibility...")
        Path("/root/.config").mkdir(parents=True, exist_ok=True)
        Path("/root/.local/share").mkdir(parents=True, exist_ok=True)

        for root_cfg in ("gtk-3.0", "gtk-4.0"):
            target = ctx.user_home / ".config" / root_cfg
            link_path = Path(f"/root/.config/{root_cfg}")
            if not target.exists():
                log("warn",
                    f"Target {target} does not exist; skipping {link_path}.")
                continue
            _replace_with_symlink(link_path, target)

        # Icons
        user_icons = ctx.user_home / ".local" / "share" / "icons"
        root_icons = Path("/root/.local/share/icons")
        if user_icons.exists():
            _replace_with_symlink(root_icons, user_icons)

        # Cleanup orphan configs
        log("info", "Cleaning orphan Noctalia configs...")
        qt5 = ctx.user_home / ".config" / "qt5ct"
        if qt5.exists():
            shutil.rmtree(qt5)
        qt6_qt6 = ctx.user_home / ".config" / "qt6ct" / "qt6ct"
        if qt6_qt6.is_symlink():
            qt6_qt6.unlink()
            log("info", "  -> circular symlink qt6ct/qt6ct removed")

        log("success", "System tweaks applied.")
