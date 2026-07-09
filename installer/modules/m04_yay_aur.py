"""04-yay-aur: install AUR packages via yay (chunked to avoid ARG_MAX)."""

from __future__ import annotations

import shutil
import subprocess
from typing import List

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import pkg_installed
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _pacman_missing(pkgs: List[str]) -> List[str]:
    try:
        out = subprocess.run(
            ["pacman", "-T", *pkgs],
            check=False, capture_output=True, text=True,
        )
        return out.stdout.strip().split()
    except FileNotFoundError:
        return []


class YayAurModule(Module):
    name = "04-yay-aur"
    manifest = "aur.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Lendo pacotes AUR do manifesto...")
        pkgs = get_cache().get_list_field("aur.toml", "packages", "name")
        if not pkgs:
            log("warn", "Nenhum pacote AUR a instalar.")
            return

        log("info", "Verificando pacotes AUR já instalados...")
        missing = _pacman_missing(pkgs)
        if not missing:
            log("success", "Todos os pacotes AUR já estão instalados.")
            return

        log("info", f"Instalando pacotes AUR pendentes via yay: {' '.join(missing)}")
        log("info", "Executando yay -S em chunks para evitar ARG_MAX...")

        # yay refuses to run as root → use runuser
        chunk_size = 50
        for i in range(0, len(missing), chunk_size):
            chunk = missing[i:i + chunk_size]
            proc = run_as_user(
                ["bash", "-c", "printf '%s\\n' \"$@\" | xargs yay -S --needed --noconfirm --removemake",
                 "bash", *chunk],
                user=ctx.real_user,
                login=False,
                check=False,
            )
            if proc.returncode != 0:
                log("warn", f"yay falhou em um chunk; tentando um por um...")
                for pkg in chunk:
                    run_as_user(
                        ["yay", "-S", "--needed", "--noconfirm", "--removemake", pkg],
                        user=ctx.real_user,
                        login=False,
                        check=False,
                        capture=False,
                    )

        # Verify
        still_missing = _pacman_missing(missing)
        if still_missing:
            fatal(f"Pacotes AUR não confirmados após instalação: {' '.join(still_missing)}")

        log("success", "Pacotes AUR instalados e confirmados.")
