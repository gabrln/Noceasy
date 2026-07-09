"""10-greeter: deploy greetd / Noctalia Greeter configs."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from installer.config import REPO_DIR
from installer.logger import log
from installer.modules.base import Module, RunContext


class GreeterModule(Module):
    name = "10-greeter"

    def run(self, ctx: RunContext) -> None:
        log("info", "Configurando arquivos de sistema do greetd...")

        # Create greeter user if missing
        try:
            subprocess.run(
                ["id", "-u", "greeter"],
                check=True, capture_output=True,
            )
        except (subprocess.CalledProcessError, FileNotFoundError):
            log("info", "Criando usuário greeter...")
            subprocess.run(
                ["useradd", "-r", "-s", "/usr/bin/nologin", "-M",
                 "-d", "/var/lib/noctalia-greeter", "greeter"],
                check=False, capture_output=True,
            )
            Path("/var/lib/noctalia-greeter").mkdir(parents=True, exist_ok=True)
            subprocess.run(
                ["chown", "greeter:greeter", "/var/lib/noctalia-greeter"],
                check=False, capture_output=True,
            )
            subprocess.run(
                ["chmod", "755", "/var/lib/noctalia-greeter"],
                check=False, capture_output=True,
            )

        # Backup /etc configs before overwriting
        for f in ("/etc/greetd/config.toml", "/etc/pam.d/greetd"):
            p = Path(f)
            bak = Path(f + ".gabrln.bak")
            if p.exists() and not bak.exists():
                shutil.copy2(p, bak)
                bak.chmod(0o600)

        Path("/etc/greetd").mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO_DIR / ".config" / "greetd" / "config.toml",
                      Path("/etc/greetd/config.toml"))
        shutil.copy2(REPO_DIR / ".config" / "greetd" / "pam_greetd",
                      Path("/etc/pam.d/greetd"))
        Path("/etc/greetd/config.toml").chmod(0o644)
        Path("/etc/pam.d/greetd").chmod(0o644)

        Path("/var/lib/noctalia-greeter").mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            REPO_DIR / ".config" / "greetd" / "greeter.toml",
            Path("/var/lib/noctalia-greeter/greeter.toml"),
        )
        subprocess.run(
            ["chown", "-R", "greeter:greeter", "/var/lib/noctalia-greeter"],
            check=False, capture_output=True,
        )
        Path("/var/lib/noctalia-greeter/greeter.toml").chmod(0o644)

        # Log files
        for log_path in ("/var/log/noctalia-greeter.log",
                          "/var/lib/noctalia-greeter/greeter.log"):
            p = Path(log_path)
            p.touch()
            subprocess.run(
                ["chown", "greeter:greeter", str(p)],
                check=False, capture_output=True,
            )
            p.chmod(0o644)

        log("success", "Greeter configurado.")
