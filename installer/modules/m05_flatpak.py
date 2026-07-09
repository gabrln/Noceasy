"""05-flatpak: install flatpak packages from flatpak.toml."""

from __future__ import annotations

import time

from installer.config import NETWORK_RETRY_ATTEMPTS, NETWORK_RETRY_BASE_SECONDS
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import is_command
from installer.toml_cache import get_cache


def _install_with_retry(remote: str, pkg: str) -> bool:
    """Try `flatpak install` with exponential backoff. Returns True on success."""
    for attempt in range(NETWORK_RETRY_ATTEMPTS):
        if run(["flatpak", "install", "-y", "--system", remote, pkg]).returncode == 0:
            return True
        if attempt < NETWORK_RETRY_ATTEMPTS - 1:
            time.sleep(NETWORK_RETRY_BASE_SECONDS ** attempt)
    return False


class FlatpakModule(Module):
    name = "05-flatpak"
    manifest = "flatpak.toml"

    def run(self, ctx: RunContext) -> None:
        if not is_command("flatpak"):
            log("warn", "flatpak is not installed. Skipping.")
            return

        log("info", "Configuring flathub remote...")
        remote_url = get_cache().get(
            "flatpak.toml", "remote.url",
            "https://dl.flathub.org/repo/flathub.flatpakrepo")
        remote_name = get_cache().get("flatpak.toml", "remote.name", "flathub")
        run(["flatpak", "remote-add", "--if-not-exists", "--system",
             remote_name, remote_url])

        packages = get_cache().get_list_field("flatpak.toml", "packages", "name")
        if not packages:
            log("warn", "No Flatpak packages to install.")
            return

        missing: list[str] = []
        for pkg in packages:
            if run(["flatpak", "info", pkg]).returncode != 0:
                missing.append(pkg)

        if not missing:
            log("success", "All Flatpak packages are already installed.")
        else:
            log("info", f"Installing missing Flatpak packages: {' '.join(missing)}")
            for pkg in missing:
                if _install_with_retry(remote_name, pkg):
                    log("info", f"  -> {pkg} installed.")
                else:
                    log("warn",
                        f"flatpak failed for {pkg} after "
                        f"{NETWORK_RETRY_ATTEMPTS} attempts.")

        # GTK themes for Flatpak sandbox (recommended by Noctalia)
        log("info", "Installing adw-gtk3 themes for Flatpak...")
        for theme in ("org.gtk.Gtk3theme.adw-gtk3-dark",
                       "org.gtk.Gtk3theme.adw-gtk3"):
            _install_with_retry(remote_name, theme)

        log("success", "Flatpak packages configured.")
