"""02-pacman-bootstrap: sync pacman + bootstrap packages + yay."""

from __future__ import annotations

from installer import privesc
from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command, pkg_installed
from installer.toml_cache import get_cache


class PacmanBootstrapModule(Module):
    name = "02-pacman-bootstrap"

    def run(self, ctx: RunContext) -> None:
        log("info", "Syncing pacman database...")
        privesc.run_privileged(["pacman", "-Sy"], ctx.sudo_password)

        log("info", "Ensuring bootstrap packages...")
        pkgs = [p for p in
                get_cache().get_list("config.toml", "install.bootstrap_packages")
                if p]
        if pkgs:
            privesc.run_privileged(
                ["pacman", "-S", "--needed", "--noconfirm", *pkgs],
                ctx.sudo_password,
            )

        log("info", "Ensuring yay (AUR helper)...")
        if pkg_installed("yay"):
            log("success", "yay is already installed.")
        else:
            log("warn", "yay not found. Installing via pacman (cachyos repo)...")
            if privesc.run_privileged(
                ["pacman", "-S", "--needed", "--noconfirm", "yay"],
                ctx.sudo_password,
            ).returncode != 0:
                fatal("Failed to install yay. Check [cachyos] in /etc/pacman.conf.")

        if not is_command("yay"):
            fatal("yay is not available after the install attempt.")

        log("success", "Bootstrap completed.")
