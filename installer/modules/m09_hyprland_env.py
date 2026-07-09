"""09-hyprland-env: validate hyprland config + chmod scripts."""

from __future__ import annotations

from installer.errors import fatal
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command


def _check_hyprpm() -> None:
    """Verify hyprpm is functional, if installed."""
    if not is_command("hyprpm"):
        return
    out = run(["hyprpm", "version"], timeout=5)
    if out.returncode == 0 and out.stdout.strip():
        first_line = out.stdout.strip().splitlines()[0]
        log("info", f"hyprpm functional: {first_line}")
    else:
        log("warn",
            "hyprpm installed but not functional. "
            "Try 'hyprpm update' manually.")


class HyprlandEnvModule(Module):
    name = "09-hyprland-env"

    def run(self, ctx: RunContext) -> None:
        log("info", "Making scripts executable in ~/.config/scripts/...")
        cfg_root = ctx.user_home / ".config"
        if cfg_root.is_dir():
            # Only chmod scripts under */scripts/* (not random .sh files).
            run(["find", str(cfg_root), "-path", "*/scripts/*", "-type", "f",
                 "-exec", "chmod", "+x", "{}", "+"])

        log("info", "Validating Hyprland configuration...")
        hypr_cfg = ctx.user_home / ".config" / "hypr" / "hyprland.lua"
        if not hypr_cfg.is_file():
            fatal(
                f"hyprland.lua not found in {ctx.user_home}/.config/hypr/. "
                f"Hyprland configuration was not copied correctly."
            )

        _check_hyprpm()

        log("success", "Hyprland environment validated.")
