"""10-greeter: deploy greetd / Noctalia Greeter configs."""

from __future__ import annotations

import shutil
from pathlib import Path

from installer.config import REPO_DIR
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext


def _create_greeter_user() -> None:
    """Create the 'greeter' system user if it doesn't exist yet."""
    if run(["id", "-u", "greeter"]).returncode == 0:
        return

    log("info", "Creating greeter user...")
    run(["useradd", "-r", "-s", "/usr/bin/nologin", "-M",
         "-d", "/var/lib/noctalia-greeter", "greeter"])
    home = Path("/var/lib/noctalia-greeter")
    home.mkdir(parents=True, exist_ok=True)
    run(["chown", "greeter:greeter", str(home)])
    home.chmod(0o755)


def _backup_etc_file(path: Path) -> None:
    """Backup an /etc file before overwriting (once)."""
    bak = path.with_suffix(path.suffix + ".noceasy.bak")
    if path.exists() and not bak.exists():
        shutil.copy2(path, bak)
        bak.chmod(0o600)


def _ensure_log_file(path: Path) -> None:
    """Touch a log file and chown it to the greeter user."""
    path.touch()
    run(["chown", "greeter:greeter", str(path)])
    path.chmod(0o644)


class GreeterModule(Module):
    name = "10-greeter"

    def run(self, ctx: RunContext) -> None:
        log("info", "Configuring greetd system files...")

        _create_greeter_user()

        # Backup /etc configs before overwriting
        for f in ("/etc/greetd/config.toml", "/etc/pam.d/greetd"):
            _backup_etc_file(Path(f))

        Path("/etc/greetd").mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO_DIR / ".config" / "greetd" / "config.toml",
                      Path("/etc/greetd/config.toml"))
        shutil.copy2(REPO_DIR / ".config" / "greetd" / "pam_greetd",
                      Path("/etc/pam.d/greetd"))
        Path("/etc/greetd/config.toml").chmod(0o644)
        Path("/etc/pam.d/greetd").chmod(0o644)

        # Greeter home + config
        greeter_home = Path("/var/lib/noctalia-greeter")
        greeter_home.mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            REPO_DIR / ".config" / "greetd" / "greeter.toml",
            greeter_home / "greeter.toml",
        )
        run(["chown", "-R", "greeter:greeter", str(greeter_home)])
        (greeter_home / "greeter.toml").chmod(0o644)

        # Log files required by Noctalia Greeter
        for log_path in ("/var/log/noctalia-greeter.log",
                          "/var/lib/noctalia-greeter/greeter.log"):
            _ensure_log_file(Path(log_path))

        log("success", "Greeter configured.")
