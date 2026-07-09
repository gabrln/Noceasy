"""04-yay-aur: install AUR packages via yay (chunked to avoid ARG_MAX)."""

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import time
from pathlib import Path

from installer.config import YAY_CHUNK_SIZE
from installer.errors import fatal
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.toml_cache import get_cache


# Build-system progress markers we can extract from makepkg's output
# to show *some* compile progress instead of a static spinner for
# the whole (potentially long) build. Not all AUR packages use
# these build systems, so this is best-effort: if no match, the
# step text just stays as "Building <pkg>".
_CMAKE_PCT_RE = re.compile(r"^\[\s*(\d{1,3})%\]")     # "[ 42%] Building CXX ..."
_NINJA_STEP_RE = re.compile(r"^\[(\d+)/(\d+)\]")        # "[123/456] Building CXX ..."

# Throttle @STEP updates during compilation: these can fire dozens of
# times per second on a fast build (ninja logs one line per object
# file). The Live display already redraws at 12 Hz; anything faster
# just wastes CPU parsing markers that will never be seen.
_STEP_UPDATE_INTERVAL = 0.1  # seconds


def _pacman_missing(pkgs: list[str]) -> list[str]:
    # `pacman -T` is a read-only, offline query -- it should return in
    # well under a second even for hundreds of packages. A generous
    # timeout here turns a silent, indefinite hang (previously: no
    # timeout at all) into a clear, actionable failure instead of a
    # panel that just sits there with no visible cause.
    try:
        out = run(["pacman", "-T", *pkgs], timeout=30)
    except subprocess.TimeoutExpired:
        fatal("'pacman -T' timed out after 30s while checking installed "
              "AUR packages -- the pacman database may be locked by "
              "another process.")
        return []  # unreachable: fatal() exits the process
    return out.stdout.strip().split() if out.stdout else []


def _setup_askpass(sudo_password: str | None) -> dict[str, str]:
    """Create a temporary SUDO_ASKPASS script and return an env dict.

    yay internally calls ``sudo pacman -U`` during AUR builds.  By
    setting ``SUDO_ASKPASS`` to a script that echoes the password,
    sudo -A can authenticate non-interactively.

    Security notes:
    - Password is passed via env var (SUDO_ASKPASS_PW), never
      interpolated into the script text (prevents shell injection).
    - File is created with 0700 via os.open() (atomic permission,
      no race window).
    - File is cleaned up in a try/finally block in YayAurModule.run().
    """
    env = os.environ.copy()
    if sudo_password is None:
        return env

    # Create with restrictive permissions and random name atomically.
    # mkstemp() uses O_CREAT|O_EXCL internally — fails if path
    # already exists (prevents symlink confused-deputy attacks on
    # a fixed /tmp path), and generates a random suffix.
    fd, askpass_path = tempfile.mkstemp(
        prefix=".noceasy-askpass-", suffix=".sh", dir="/tmp",
    )
    try:
        os.write(fd, b"#!/bin/sh\nprintf '%s\\n' \"$SUDO_ASKPASS_PW\"\n")
    finally:
        os.close(fd)
    os.chmod(askpass_path, 0o700)

    # Pass password via env var — the script reads it from there,
    # never from its own text. Prevents shell injection even if
    # the password contains quotes, semicolons, backticks, etc.
    env["SUDO_ASKPASS"] = askpass_path
    env["SUDO_ASKPASS_PW"] = sudo_password
    return env


def _teardown_askpass() -> None:
    """Remove any leftover SUDO_ASKPASS scripts from /tmp."""
    import glob as _glob
    for f in _glob.glob("/tmp/.noceasy-askpass-*.sh"):
        try:
            Path(f).unlink()
        except OSError:
            pass


def _install_streamed(cmd: list[str], sudo_password: str | None) -> bool:
    """Run a command, streaming output in real-time.

    Shows the package being built, and — when the underlying build
    system emits recognisable progress (CMake's "[ 42%]" or Ninja's
    "[123/456]" lines) — appends that to the step text so long
    compiles (noctalia-git, etc.) show real movement instead of a
    static spinner:

      Building noctalia-git (42%)
      Building noctalia-git (123/456)
    """
    env = _setup_askpass(sudo_password)
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        env=env,
    )
    current_pkg = ""
    last_update = 0.0
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            line = line.rstrip()
            if not line:
                continue

            if line.startswith("==>") and "Making package:" in line:
                current_pkg = line.split("Making package:")[1].split()[0]
                print(f"@STEP:Building {current_pkg}")
                print(f"@CMD:yay -S --needed --noconfirm --removemake {current_pkg}")
                print(line)
                last_update = time.monotonic()
                continue

            now = time.monotonic()

            # CMake/Ninja emit one progress line per compiled object —
            # too fast to print raw (would flood the scrolling log and
            # spend all our time re-rendering). Fold those into the
            # throttled @STEP marker instead of forwarding them as-is.
            m_cmake = _CMAKE_PCT_RE.match(line)
            if m_cmake and current_pkg:
                if now - last_update >= _STEP_UPDATE_INTERVAL:
                    print(f"@STEP:Building {current_pkg} ({m_cmake.group(1)}%)")
                    last_update = now
                continue

            m_ninja = _NINJA_STEP_RE.match(line)
            if m_ninja and current_pkg:
                if now - last_update >= _STEP_UPDATE_INTERVAL:
                    done, total = m_ninja.groups()
                    print(f"@STEP:Building {current_pkg} ({done}/{total})")
                    last_update = now
                continue

            # Everything else (==> Retrieving sources..., pacman/makepkg
            # messages, etc.) is real signal — forward it so the Live
            # Output area actually shows what's happening instead of
            # sitting empty for the whole build.
            print(line)
    except (OSError, ValueError):
        pass
    return proc.wait() == 0


def _install_chunk(chunk: list[str], sudo_password: str | None) -> bool:
    """Install one chunk of AUR packages. Returns True on success."""
    argv = [
        "bash", "-c",
        "printf '%s\\n' \"$@\" | xargs yay -S "
        "--needed --noconfirm --removemake",
        "bash", *chunk,
    ]
    return _install_streamed(argv, sudo_password)


def _install_one(pkg: str, sudo_password: str | None) -> bool:
    return _install_streamed(
        ["yay", "-S", "--needed", "--noconfirm", "--removemake", pkg],
        sudo_password,
    )


class YayAurModule(Module):
    name = "04-yay-aur"
    manifest = "aur.toml"

    def run(self, ctx: RunContext) -> None:
        # Fires immediately, before anything else, so the panel shows
        # life right away instead of sitting at a static 0/1 while
        # manifest loading / `pacman -T` run in the background -- if
        # this line never appears, the hang is before even this point
        # (module dispatch itself), which narrows things down a lot.
        print("@STEP:Checking AUR packages...")
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

        # Report real progress to the TUI: N packages to build.
        print(f"@PROGRESS:{len(missing)}")

        try:
            for i in range(0, len(missing), YAY_CHUNK_SIZE):
                chunk = missing[i:i + YAY_CHUNK_SIZE]
                if _install_chunk(chunk, ctx.sudo_password):
                    print(f"@ADVANCE:{len(chunk)}")
                    continue
                for pkg in chunk:
                    if not _install_one(pkg, ctx.sudo_password):
                        print(f"  failed: {pkg}")
                    print("@ADVANCE:1")
        finally:
            _teardown_askpass()

        still_missing = _pacman_missing(missing)
        if still_missing:
            fatal(f"AUR packages not confirmed after install: "
                  f"{' '.join(still_missing)}")

        log("success", "AUR packages installed and confirmed.")
