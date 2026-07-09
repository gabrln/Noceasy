"""Privilege escalation helpers.

We expect to be running as root (the install.sh bootstrap is `sudo bash`).
For executing commands as the real (unprivileged) user, we use `runuser`,
which is part of `util-linux` and is always present on Arch.

Polkit policy:
    - Installs /etc/polkit-1/rules.d/99-arch-gabrln-installer.rules
      authorizing REAL_USER to run `gabrln-helper` via pkexec without
      re-auth.
    - Copied from installer/polkit/* on disk.
    - Removed on exit (see cleanup_polkit_policy).

Replaces the bash version's:
    - `sudo -u USER --preserve-env=PATH,HOME` -> `runuser -u USER --`
    - `setup_temp_sudoers` (NOPASSWD sudoers) -> polkit + runuser
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from typing import Sequence, Union

from installer.config import POLKIT_DIR
from installer.errors import fatal
from installer.logger import log


# ---------------------------------------------------------------------------
# runuser-based helpers
# ---------------------------------------------------------------------------

def run_as_user(
    cmd: Union[str, Sequence[str]],
    user: str,
    login: bool = True,
    check: bool = True,
    capture: bool = False,
) -> subprocess.CompletedProcess:
    """Execute `cmd` as `user` via runuser.

    If `cmd` is a string, it's passed to `bash -lc` (login shell) or
    `bash -c`. If it's a list, it's exec'd directly (no shell).

    Returns the CompletedProcess. If `check=True` (default), raises
    subprocess.CalledProcessError on non-zero exit.
    """
    if isinstance(cmd, str):
        shell_flag = "-lc" if login else "-c"
        argv = ["runuser", "-u", user, "--", "bash", shell_flag, cmd]
    else:
        argv = ["runuser", "-u", user, "--", *cmd]

    return subprocess.run(
        argv,
        check=check,
        capture_output=capture,
        text=capture,
    )


# ---------------------------------------------------------------------------
# Real user detection
# ---------------------------------------------------------------------------

def detect_real_user() -> tuple[str, str]:
    """Verify we're root and return (real_user, user_home).

    Exits via fatal() on error.
    """
    if os.geteuid() != 0:
        fatal("Este comando deve ser executado com sudo.")

    sudo_user = os.environ.get("SUDO_USER", "")
    if not sudo_user:
        fatal("Não foi possível determinar SUDO_USER. Execute via 'sudo bash install.sh'.")

    if sudo_user == "root":
        fatal("Execute como usuário normal com sudo. Ex: curl ... | sudo bash")

    # Resolve home via getent
    try:
        out = subprocess.run(
            ["getent", "passwd", sudo_user],
            check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        fatal(f"getent passwd falhou: {exc}")

    parts = out.stdout.strip().split(":")
    if len(parts) < 7 or not parts[5]:
        fatal(f"Não foi possível determinar o HOME do usuário '{sudo_user}'.")

    home = parts[5]
    if not Path(home).is_dir():
        fatal(f"Home do usuário '{sudo_user}' não existe: {home}")

    return sudo_user, home


# ---------------------------------------------------------------------------
# Polkit policy
# ---------------------------------------------------------------------------

POLKIT_RULES_PATH = Path("/etc/polkit-1/rules.d/99-arch-gabrln-installer.rules")
POLKIT_POLICY_PATH = Path("/usr/share/polkit-1/actions/org.archlinux.pkexec.gabrln.policy")
POLKIT_HELPER_PATH = Path("/usr/local/bin/gabrln-helper")

_polkit_installed = False


def setup_polkit_policy(real_user: str) -> None:
    """Install polkit rule + policy + helper binary. Idempotent."""
    global _polkit_installed

    if not shutil.which("pkexec"):
        log("warn", "pkexec não encontrado. Instale 'polkit' (já está no manifesto).")
        return

    if not POLKIT_DIR.is_dir():
        log("warn", f"Diretório de templates polkit não encontrado: {POLKIT_DIR}")
        return

    # 1. Rules file (auto-approve REAL_USER for our action)
    try:
        POLKIT_RULES_PATH.parent.mkdir(parents=True, exist_ok=True)
        template = (POLKIT_DIR / "99-arch-gabrln-installer.rules").read_text()
        rendered = template.replace("@REAL_USER@", real_user)
        POLKIT_RULES_PATH.write_text(rendered)
        POLKIT_RULES_PATH.chmod(0o644)
    except OSError as exc:
        log("warn", f"Não foi possível escrever {POLKIT_RULES_PATH}: {exc}")
        return

    # 2. Policy file (only if missing)
    if not POLKIT_POLICY_PATH.exists():
        src = POLKIT_DIR / "org.archlinux.pkexec.gabrln.policy"
        if src.is_file():
            try:
                POLKIT_POLICY_PATH.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, POLKIT_POLICY_PATH)
                POLKIT_POLICY_PATH.chmod(0o644)
            except OSError as exc:
                log("warn", f"Não foi possível copiar policy: {exc}")

    # 3. Helper binary (only if missing)
    if not POLKIT_HELPER_PATH.exists():
        src = POLKIT_DIR / "gabrln-helper"
        if src.is_file():
            try:
                shutil.copy2(src, POLKIT_HELPER_PATH)
                POLKIT_HELPER_PATH.chmod(0o755)
            except OSError as exc:
                log("warn", f"Não foi possível instalar gabrln-helper: {exc}")

    _polkit_installed = True
    log("info", f"Polkit policy instalada para {real_user}.")


def cleanup_polkit_policy() -> None:
    """Remove the rules file (helper + policy are kept)."""
    if not _polkit_installed:
        return
    try:
        if POLKIT_RULES_PATH.exists():
            POLKIT_RULES_PATH.unlink()
            log("debug", "Polkit policy removida.")
    except OSError as exc:
        log("debug", f"Erro removendo polkit policy: {exc}")
