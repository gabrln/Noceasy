"""15-system-tweaks: root theme symlinks + perms + cleanup."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

from installer.logger import log
from installer.modules.base import Module, RunContext


def _chown(path: Path, user: str) -> None:
    subprocess.run(["chown", "-R", f"{user}:{user}", str(path)],
                    check=False, capture_output=True)


class SystemTweaksModule(Module):
    name = "15-system-tweaks"

    def run(self, ctx: RunContext) -> None:
        log("info", "Ajustando permissões de configurações do usuário...")
        cfg = ctx.user_home / ".config"
        if cfg.exists():
            _chown(cfg, ctx.real_user)
        icons_dir = ctx.user_home / ".local" / "share" / "icons"
        icons_dir.mkdir(parents=True, exist_ok=True)
        _chown(icons_dir, ctx.real_user)

        log("info", "Vinculando temas para acessibilidade de aplicativos root...")
        Path("/root/.config").mkdir(parents=True, exist_ok=True)
        Path("/root/.local/share").mkdir(parents=True, exist_ok=True)

        for root_cfg in ("gtk-3.0", "gtk-4.0"):
            target = ctx.user_home / ".config" / root_cfg
            link_path = Path(f"/root/.config/{root_cfg}")
            if not target.exists():
                log("warn", f"Alvo {target} não existe; pulando symlink {link_path}.")
                continue
            if link_path.is_symlink() and os.readlink(link_path) == str(target):
                log("info", f"  → {link_path} (já correto)")
                continue
            if link_path.is_dir() and not link_path.is_symlink():
                shutil.rmtree(link_path)
            elif link_path.is_symlink() or link_path.is_file():
                link_path.unlink()
            link_path.symlink_to(target)
            log("info", f"  → {link_path}")

        # Icons
        user_icons = ctx.user_home / ".local" / "share" / "icons"
        root_icons = Path("/root/.local/share/icons")
        if user_icons.exists():
            if root_icons.is_dir() and not root_icons.is_symlink():
                shutil.rmtree(root_icons)
            elif root_icons.is_symlink() or root_icons.is_file():
                root_icons.unlink()
            root_icons.symlink_to(user_icons)
            log("info", f"  → {root_icons}")

        # Cleanup orphan configs
        log("info", "Limpando configurações órfãs do Noctalia...")
        qt5 = ctx.user_home / ".config" / "qt5ct"
        if qt5.exists():
            shutil.rmtree(qt5)
        qt6_qt6 = ctx.user_home / ".config" / "qt6ct" / "qt6ct"
        if qt6_qt6.is_symlink():
            qt6_qt6.unlink()
            log("info", "  → symlink circular qt6ct/qt6ct removido")

        log("success", "Ajustes de sistema aplicados.")
