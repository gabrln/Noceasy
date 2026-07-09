"""03-pacman-official: install official packages from packages.toml."""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import List

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.toml_cache import get_cache


def _cachyos_present() -> bool:
    try:
        out = subprocess.run(
            ["pacman", "-Qq"],
            check=True, capture_output=True, text=True, timeout=10,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False
    installed = out.stdout.split()
    if any(p.startswith("linux-cachyos") for p in installed):
        return True
    # Check pacman.conf for [cachyos] section
    conf = Path("/etc/pacman.conf")
    if conf.is_file():
        return "[cachyos" in conf.read_text()
    return False


def _pacman_missing(pkgs: List[str]) -> List[str]:
    try:
        out = subprocess.run(
            ["pacman", "-T", *pkgs],
            check=False, capture_output=True, text=True,
        )
        missing = out.stdout.strip().split()
        return missing
    except FileNotFoundError:
        return []


class PacmanOfficialModule(Module):
    name = "03-pacman-official"
    manifest = "packages.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Lendo pacotes oficiais do manifesto...")
        pkgs = get_cache().get_list_field("packages.toml", "packages", "name")

        # Filter linux-cachyos* if not on CachyOS
        if not _cachyos_present():
            log("info", "Sistema não é CachyOS; filtrando pacotes linux-cachyos*.")
            pkgs = [p for p in pkgs if not p.startswith("linux-cachyos")]

        if not pkgs:
            log("warn", "Nenhum pacote oficial a instalar.")
            return

        log("info", "Verificando pacotes já instalados...")
        missing = _pacman_missing(pkgs)
        if not missing:
            log("success", "Todos os pacotes oficiais já estão instalados.")
            return

        log("info", f"Instalando pacotes oficiais pendentes: {' '.join(missing)}")
        if subprocess.run(
            ["pacman", "-S", "--needed", "--noconfirm", *missing],
            check=False,
        ).returncode != 0:
            log("warn", "pacman retornou erro. Tentando um por um...")
            for pkg in missing:
                subprocess.run(["pacman", "-S", "--needed", "--noconfirm", pkg],
                                check=False, capture_output=True)

        # Verify
        still_missing = _pacman_missing(missing)
        if still_missing:
            log("warn", f"Pacotes ainda ausentes: {' '.join(still_missing)}")
            critical = [p for p in still_missing if p in ("zsh", "base", "base-devel", "git")]
            if critical:
                fatal(f"Pacotes críticos ausentes: {' '.join(critical)}")

        # zsh must be present
        if not Path("/usr/bin/zsh").exists() and not _which("zsh"):
            fatal("zsh ausente após instalação de pacotes oficiais.")

        log("success", "Pacotes oficiais instalados e confirmados.")


def _which(name: str) -> bool:
    import shutil
    return shutil.which(name) is not None
