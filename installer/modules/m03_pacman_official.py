"""03-pacman-official: install official packages from packages.toml."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import List

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.toml_cache import get_cache


_CRITICAL_PACKAGES = {"zsh", "base", "base-devel", "git"}


def _cachyos_present() -> bool:
    """True if the system is CachyOS (kernel installed or repo enabled)."""
    try:
        out = subprocess.run(
            ["pacman", "-Qq"],
            check=True, capture_output=True, text=True, timeout=10,
        )
    except (subprocess.CalledProcessError, FileNotFoundError,
            subprocess.TimeoutExpired):
        return False
    if any(p.startswith("linux-cachyos") for p in out.stdout.split()):
        return True
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
        return out.stdout.strip().split()
    except FileNotFoundError:
        return []


def _which(name: str) -> bool:
    return shutil.which(name) is not None


class PacmanOfficialModule(Module):
    name = "03-pacman-official"
    manifest = "packages.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Reading official packages from manifest...")
        pkgs = get_cache().get_list_field("packages.toml", "packages", "name")

        # Filter linux-cachyos* if not on CachyOS
        if not _cachyos_present():
            log("info",
                "System is not CachyOS; filtering out linux-cachyos* packages.")
            pkgs = [p for p in pkgs if not p.startswith("linux-cachyos")]

        if not pkgs:
            log("warn", "No official packages to install.")
            return

        log("info", "Checking installed packages...")
        missing = _pacman_missing(pkgs)
        if not missing:
            log("success", "All official packages are already installed.")
            return

        log("info", f"Installing missing official packages: {' '.join(missing)}")
        if subprocess.run(
            ["pacman", "-S", "--needed", "--noconfirm", *missing],
            check=False,
        ).returncode != 0:
            log("warn", "pacman returned an error. Trying one by one...")
            for pkg in missing:
                subprocess.run(["pacman", "-S", "--needed", "--noconfirm", pkg],
                                check=False, capture_output=True)

        still_missing = _pacman_missing(missing)
        if still_missing:
            log("warn", f"Still missing: {' '.join(still_missing)}")
            critical = [p for p in still_missing if p in _CRITICAL_PACKAGES]
            if critical:
                fatal(f"Critical packages still missing: {' '.join(critical)}")

        if not _which("zsh") and not Path("/usr/bin/zsh").exists():
            fatal("zsh missing after official packages install.")

        log("success", "Official packages installed and confirmed.")
