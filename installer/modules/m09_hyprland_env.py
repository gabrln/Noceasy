"""09-hyprland-env: validate hyprland config + chmod scripts."""

from __future__ import annotations

import subprocess
from pathlib import Path

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command


class HyprlandEnvModule(Module):
    name = "09-hyprland-env"

    def run(self, ctx: RunContext) -> None:
        log("info", "Tornando scripts executáveis em ~/.config/scripts/...")
        cfg_root = ctx.user_home / ".config"
        if cfg_root.is_dir():
            # chmod +x apenas em */scripts/*
            subprocess.run(
                ["find", str(cfg_root), "-path", "*/scripts/*", "-type", "f",
                 "-exec", "chmod", "+x", "{}", "+"],
                check=False, capture_output=True,
            )

        log("info", "Validando configuração do Hyprland...")
        hypr_cfg = ctx.user_home / ".config" / "hypr" / "hyprland.lua"
        if not hypr_cfg.is_file():
            fatal(f"hyprland.lua não encontrado em {ctx.user_home}/.config/hypr/.")

        if is_command("hyprpm"):
            try:
                out = subprocess.run(
                    ["hyprpm", "version"],
                    check=False, capture_output=True, text=True, timeout=5,
                )
                if out.returncode == 0:
                    log("info", f"hyprpm funcional: {out.stdout.strip().splitlines()[0]}")
                else:
                    log("warn", "hyprpm instalado mas não funcional. Tente 'hyprpm update'.")
            except subprocess.TimeoutExpired:
                log("warn", "hyprpm version timeout.")

        log("success", "Ambiente Hyprland validado.")
