"""09-hyprland-env: validate hyprland config + chmod scripts."""

from __future__ import annotations

from installer.core.errors import fatal
from installer.infra import exec as exec_mod
from installer.modules.base import Module, RunContext
from installer.ui.logger import log


class HyprlandEnvModule(Module):
    name = "09-hyprland-env"

    def run(self, ctx: RunContext) -> None:
        log("info", "Making scripts executable in ~/.config/scripts/...")
        cfg_root = ctx.user_home / ".config"
        if cfg_root.is_dir():
            # Only chmod scripts under */scripts/* (not random .sh files).
            exec_mod.run(["find", str(cfg_root), "-path", "*/scripts/*", "-type", "f",
                 "-exec", "chmod", "+x", "{}", "+"])

        log("info", "Validating Hyprland configuration...")
        hypr_cfg = ctx.user_home / ".config" / "hypr" / "hyprland.lua"
        if not hypr_cfg.is_file():
            fatal(
                f"hyprland.lua not found in {ctx.user_home}/.config/hypr/. "
                f"Hyprland configuration was not copied correctly."
            )

        log("success", "Hyprland environment validated.")
