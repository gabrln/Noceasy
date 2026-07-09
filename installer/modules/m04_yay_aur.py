"""04-yay-aur: install AUR packages via yay (chunked to avoid ARG_MAX)."""

from __future__ import annotations

import subprocess
from pathlib import Path

from installer.config import YAY_CHUNK_SIZE
from installer.errors import fatal
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


_SUDOERS_NOCEASY = Path("/etc/sudoers.d/00-noceasy-yay")
_SUDOERS_CONTENT = "{user} ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/makepkg\n"

# Lines from yay that we want to show the user.
def _pacman_missing(pkgs: list[str]) -> list[str]:
    out = run(["pacman", "-T", *pkgs])
    return out.stdout.strip().split() if out.stdout else []


def _install_streamed(cmd: list[str], user: str) -> bool:
    """Run a command as the real user, streaming output in real-time.

    Only the '==> Making package: X' line from each build is shown
    on the terminal (one line per package). Everything else goes to
    the log file. This gives a DankLinux-style clean output:

      building noctalia-git
      building bibata-cursor-theme-bin
    """
    argv = ["runuser", "-u", user, "--", *cmd]
    proc = subprocess.Popen(
        argv,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            line = line.rstrip()
            # Only show the package name that is being built.
            if line.startswith("==>") and "Making package:" in line:
                pkg_name = line.split("Making package:")[1].split()[0]
                # Use markers that _OutputCapture picks up.
                print(f"@STEP:Building {pkg_name}")
                print(f"@CMD:yay -S --needed --noconfirm --removemake {pkg_name}")
    except (OSError, ValueError):
        pass
    return proc.wait() == 0


def _install_chunk(chunk: list[str], user: str) -> bool:
    """Install one chunk of AUR packages. Returns True on success."""
    argv = [
        "bash", "-c",
        "printf '%s\\n' \"$@\" | xargs yay -S "
        "--needed --noconfirm --removemake",
        "bash", *chunk,
    ]
    return _install_streamed(argv, user)


def _install_one(pkg: str, user: str) -> bool:
    return _install_streamed(
        ["yay", "-S", "--needed", "--noconfirm", "--removemake", pkg],
        user,
    )


def _grant_pacman_nopasswd(user: str) -> None:
    """Add a temporary sudoers entry so yay can install without password.

    yay calls `sudo pacman -U` internally. Without this entry, the user
    is prompted for their password during AUR builds. The entry is
    removed after the build (or on any exit path).
    """
    if _SUDOERS_NOCEASY.is_file():
        return
    try:
        _SUDOERS_NOCEASY.write_text(_SUDOERS_CONTENT.format(user=user))
        _SUDOERS_NOCEASY.chmod(0o440)
        visudo = run(["visudo", "-cf", str(_SUDOERS_NOCEASY)], timeout=5)
        if visudo.returncode != 0:
            log("warn", f"sudoers validation failed: {visudo.stderr.strip()}")
            _SUDOERS_NOCEASY.unlink(missing_ok=True)
    except OSError as exc:
        log("warn", f"Could not create {_SUDOERS_NOCEASY}: {exc}")


def _revoke_pacman_nopasswd() -> None:
    """Remove the temporary sudoers entry."""
    if _SUDOERS_NOCEASY.is_file():
        try:
            _SUDOERS_NOCEASY.unlink()
        except OSError:
            pass


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

        _grant_pacman_nopasswd(ctx.real_user)
        try:
            for i in range(0, len(missing), YAY_CHUNK_SIZE):
                chunk = missing[i:i + YAY_CHUNK_SIZE]
                if _install_chunk(chunk, ctx.real_user):
                    continue
                for pkg in chunk:
                    if not _install_one(pkg, ctx.real_user):
                        print(f"  failed: {pkg}")
        finally:
            _revoke_pacman_nopasswd()

        still_missing = _pacman_missing(missing)
        if still_missing:
            fatal(f"AUR packages not confirmed after install: "
                  f"{' '.join(still_missing)}")

        log("success", "AUR packages installed and confirmed.")
