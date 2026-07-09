"""05-flatpak: install flatpak packages from flatpak.toml."""

from __future__ import annotations

import subprocess
import time
from typing import List

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command
from installer.toml_cache import get_cache


class FlatpakModule(Module):
    name = "05-flatpak"
    manifest = "flatpak.toml"

    def run(self, ctx: RunContext) -> None:
        if not is_command("flatpak"):
            log("warn", "flatpak não está instalado. Pulando.")
            return

        log("info", "Configurando remote flathub...")
        remote_url = get_cache().get("flatpak.toml", "remote.url",
                                       "https://dl.flathub.org/repo/flathub.flatpakrepo")
        remote_name = get_cache().get("flatpak.toml", "remote.name", "flathub")
        subprocess.run(
            ["flatpak", "remote-add", "--if-not-exists", "--system", remote_name, remote_url],
            check=False, capture_output=True,
        )

        packages = get_cache().get_list_field("flatpak.toml", "packages", "name")
        if not packages:
            log("warn", "Nenhum pacote Flatpak a instalar.")
            return

        missing: List[str] = []
        for pkg in packages:
            if subprocess.run(["flatpak", "info", pkg],
                                check=False, capture_output=True).returncode != 0:
                missing.append(pkg)

        if not missing:
            log("success", "Todos os pacotes Flatpak já estão instalados.")
        else:
            log("info", f"Instalando pacotes Flatpak pendentes: {' '.join(missing)}")
            for pkg in missing:
                # Retry with backoff
                for attempt in range(3):
                    if subprocess.run(
                        ["flatpak", "install", "-y", "--system", remote_name, pkg],
                        check=False, capture_output=True,
                    ).returncode == 0:
                        break
                    time.sleep(2 ** attempt)
                else:
                    log("warn", f"flatpak falhou para {pkg} após 3 tentativas.")

        # GTK themes for Flatpak sandbox
        log("info", "Instalando temas adw-gtk3 para Flatpak...")
        subprocess.run(
            ["flatpak", "install", "-y", "--system", remote_name,
             "org.gtk.Gtk3theme.adw-gtk3-dark"],
            check=False, capture_output=True,
        )
        subprocess.run(
            ["flatpak", "install", "-y", "--system", remote_name,
             "org.gtk.Gtk3theme.adw-gtk3"],
            check=False, capture_output=True,
        )

        log("success", "Pacotes Flatpak configurados.")
