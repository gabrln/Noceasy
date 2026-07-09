"""04-yay-aur: install AUR packages via yay (chunked to avoid ARG_MAX)."""

from __future__ import annotations

import subprocess
from typing import List

from installer.config import YAY_CHUNK_SIZE
from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
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


def _install_chunk(chunk: List[str], user: str) -> bool:
    """Install one chunk of AUR packages. Returns True on success."""
    # bash -c with $@ preserves each arg as a separate xargs item
    proc = run_as_user(
        ["bash", "-c",
         "printf '%s\\n' \"$@\" | xargs yay -S "
         "--needed --noconfirm --removemake",
         "bash", *chunk],
        user=user, login=False, check=False,
    )
    return proc.returncode == 0


def _install_one(pkg: str, user: str) -> bool:
    proc = run_as_user(
        ["yay", "-S", "--needed", "--noconfirm", "--removemake", pkg],
        user=user, login=False, check=False,
    )
    return proc.returncode == 0


class YayAurModule(Module):
    name = "04-yay-aur"
    manifest = "aur.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Reading AUR packages from manifest...")
        pkgs = get_cache().get_list_field("aur.toml", "packages", "name")
        if not pkgs:
            log("warn", "No AUR packages to install.")
            return

        log("info", "Checking installed AUR packages...")
        missing = _pacman_missing(pkgs)
        if not missing:
            log("success", "All AUR packages are already installed.")
            return

        log("info",
            f"Installing missing AUR packages via yay: {' '.join(missing)}")
        log("info", f"Running yay -S in chunks of {YAY_CHUNK_SIZE}...")

        # yay refuses to run as root, so use runuser.
        for i in range(0, len(missing), YAY_CHUNK_SIZE):
            chunk = missing[i:i + YAY_CHUNK_SIZE]
            if _install_chunk(chunk, ctx.real_user):
                continue
            log("warn", "yay failed in a chunk; falling back to per-package.")
            for pkg in chunk:
                if not _install_one(pkg, ctx.real_user):
                    log("warn", f"yay failed for {pkg} (continuing).")

        still_missing = _pacman_missing(missing)
        if still_missing:
            fatal(f"AUR packages not confirmed after install: "
                  f"{' '.join(still_missing)}")

        log("success", "AUR packages installed and confirmed.")
