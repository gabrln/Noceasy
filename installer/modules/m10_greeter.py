"""10-greeter: deploy greetd / Noctalia Greeter configs."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path

from installer import privesc
from installer.config import REPO_DIR
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext


def _create_greeter_user(ctx: RunContext) -> None:
    """Create the 'greeter' system user if it doesn't exist yet."""
    if run(["id", "-u", "greeter"]).returncode == 0:
        return

    log("info", "Creating greeter user...")
    privesc.run_privileged(
        ["useradd", "-r", "-s", "/usr/bin/nologin", "-M",
         "-d", "/var/lib/noctalia-greeter", "greeter"],
        ctx.sudo_password,
    )
    home = Path("/var/lib/noctalia-greeter")
    privesc.run_privileged(["mkdir", "-p", str(home)], ctx.sudo_password)
    privesc.run_privileged(
        ["chown", "greeter:greeter", str(home)], ctx.sudo_password,
    )
    privesc.run_privileged(["chmod", "755", str(home)], ctx.sudo_password)


def _backup_etc_file(path: Path) -> None:
    """Backup an /etc file before overwriting (once)."""
    bak = path.with_suffix(path.suffix + ".noceasy.bak")
    if path.exists() and not bak.exists():
        shutil.copy2(path, bak)
        bak.chmod(0o600)


def _ensure_log_file(path: Path, ctx: RunContext) -> None:
    """Touch a log file and chown it to the greeter user."""
    privesc.run_privileged(["touch", str(path)], ctx.sudo_password)
    privesc.run_privileged(
        ["chown", "greeter:greeter", str(path)], ctx.sudo_password,
    )
    privesc.run_privileged(["chmod", "644", str(path)], ctx.sudo_password)


def _atomic_system_copy(src: Path, dest: Path, ctx: RunContext) -> None:
    """Write *src* to *dest* via a temp file + ``install -m 644``."""
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp_path = Path(tmp.name)
    try:
        shutil.copy2(src, tmp_path)
        privesc.run_privileged(
            ["install", "-m", "644", str(tmp_path), str(dest)],
            ctx.sudo_password,
        )
    finally:
        tmp_path.unlink(missing_ok=True)


class GreeterModule(Module):
    name = "10-greeter"

    def run(self, ctx: RunContext) -> None:
        log("info", "Configuring greetd system files...")

        _create_greeter_user(ctx)

        # Backup /etc configs before overwriting
        for f in ("/etc/greetd/config.toml", "/etc/pam.d/greetd"):
            _backup_etc_file(Path(f))

        privesc.run_privileged(["mkdir", "-p", "/etc/greetd"], ctx.sudo_password)
        _atomic_system_copy(
            REPO_DIR / ".config" / "greetd" / "config.toml",
            Path("/etc/greetd/config.toml"),
            ctx,
        )
        _atomic_system_copy(
            REPO_DIR / ".config" / "greetd" / "pam_greetd",
            Path("/etc/pam.d/greetd"),
            ctx,
        )

        # Greeter home + config
        greeter_home = Path("/var/lib/noctalia-greeter")
        privesc.run_privileged(
            ["mkdir", "-p", str(greeter_home)], ctx.sudo_password,
        )
        _atomic_system_copy(
            REPO_DIR / ".config" / "greetd" / "greeter.toml",
            greeter_home / "greeter.toml",
            ctx,
        )
        privesc.run_privileged(
            ["chown", "-R", "greeter:greeter", str(greeter_home)],
            ctx.sudo_password,
        )

        # Log files required by Noctalia Greeter
        for log_path in ("/var/log/noctalia-greeter.log",
                          "/var/lib/noctalia-greeter/greeter.log"):
            _ensure_log_file(Path(log_path), ctx)

        log("success", "Greeter configured.")
