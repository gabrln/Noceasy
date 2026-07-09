"""02-pacman-bootstrap: sync pacman + bootstrap packages + yay."""

from __future__ import annotations

import subprocess
from pathlib import Path

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command, pkg_installed
from installer.toml_cache import get_cache


class PacmanBootstrapModule(Module):
    name = "02-pacman-bootstrap"

    def run(self, ctx: RunContext) -> None:
        log("info", "Sincronizando base de dados do Pacman...")
        subprocess.run(["pacman", "-Sy"], check=False, capture_output=True)

        log("info", "Garantindo pacotes de bootstrap...")
        pkgs = get_cache().get_list("config.toml", "install.bootstrap_packages")
        # Filter empty
        pkgs = [p for p in pkgs if p]
        if pkgs:
            subprocess.run(
                ["pacman", "-S", "--needed", "--noconfirm", *pkgs],
                check=False, capture_output=True,
            )

        log("info", "Garantindo yay (AUR helper)...")
        if pkg_installed("yay"):
            log("success", "yay já está instalado.")
        else:
            log("warn", "yay não encontrado. Instalando via pacman (repo cachyos)...")
            if subprocess.run(
                ["pacman", "-S", "--needed", "--noconfirm", "yay"],
                check=False,
            ).returncode != 0:
                fatal("Falha ao instalar yay. Verifique [cachyos] em /etc/pacman.conf.")

        if not is_command("yay"):
            fatal("yay não está disponível após a tentativa de instalação.")

        log("success", "Bootstrap concluído.")
