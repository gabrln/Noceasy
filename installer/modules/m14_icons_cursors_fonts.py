"""14-icons-cursors-fonts: refresh font and icon caches."""

from __future__ import annotations

import subprocess
from pathlib import Path

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command
from installer.privilege import run_as_user


class IconsCursorsFontsModule(Module):
    name = "14-icons-cursors-fonts"

    def run(self, ctx: RunContext) -> None:
        log("info", "Atualizando cache de fontes...")
        subprocess.run(["fc-cache", "-fv"], check=False, capture_output=True, timeout=120)

        log("info", "Garantindo diretório de ícones do usuário...")
        icons_dir = ctx.user_home / ".local" / "share" / "icons"
        icons_dir.mkdir(parents=True, exist_ok=True)
        subprocess.run(["chown", "-R", f"{ctx.real_user}:{ctx.real_user}", str(icons_dir)],
                        check=False, capture_output=True)

        if is_command("gtk-update-icon-cache"):
            log("info", "Atualizando cache de ícones gtk...")
            for d in icons_dir.iterdir():
                if d.is_dir():
                    run_as_user(
                        f"gtk-update-icon-cache -f -t '{d}' 2>/dev/null || true",
                        user=ctx.real_user, check=False,
                    )

        log("success", "Cache de fontes e ícones atualizado.")
