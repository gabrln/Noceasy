"""07-shell: configure zsh as default shell + clone zsh plugins."""

from __future__ import annotations

import subprocess
import time
from pathlib import Path

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _getent_shell(user: str) -> str:
    try:
        out = subprocess.run(
            ["getent", "passwd", user],
            check=True, capture_output=True, text=True,
        )
        parts = out.stdout.strip().split(":")
        if len(parts) >= 7:
            return parts[6]
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return ""


class ShellModule(Module):
    name = "07-shell"
    manifest = "zsh-plugins.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Configurando shell padrão...")

        if not Path("/usr/bin/zsh").exists():
            fatal("zsh não está instalado. Módulo 03 deveria ter instalado.")

        current = _getent_shell(ctx.real_user)
        if current != "/usr/bin/zsh":
            log("info", f"Alterando shell padrão de {current} para /usr/bin/zsh...")
            subprocess.run(["chsh", "-s", "/usr/bin/zsh", ctx.real_user],
                            check=False, capture_output=True)
        else:
            log("info", "Shell padrão já é Zsh.")

        # Update SHELL in systemd user manager (if available)
        try:
            uid = subprocess.run(
                ["id", "-u", ctx.real_user],
                check=True, capture_output=True, text=True,
            ).stdout.strip()
            runtime_dir = f"/run/user/{uid}"
            if Path(runtime_dir).is_dir():
                import os
                env = os.environ.copy()
                env["XDG_RUNTIME_DIR"] = runtime_dir
                run_as_user(
                    ["systemctl", "--user", "set-environment", "SHELL=/usr/bin/zsh"],
                    user=ctx.real_user,
                    check=False,
                )
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass

        log("info", "Verificando plugins do Zsh...")
        plugins_dir = ctx.user_home / ".config" / "zsh" / "plugins"
        plugins_dir.mkdir(parents=True, exist_ok=True)
        chown_user_compat(plugins_dir, ctx.real_user)

        plugins = get_cache().load("zsh-plugins.toml").get("plugins", [])
        for plugin in plugins:
            name = plugin["name"]
            repo = plugin["repo"]
            entry = plugin["entry"]
            plugin_path = plugins_dir / name

            if (plugin_path / entry).exists() or (plugin_path / entry).is_file():
                log("success", f"Plugin {name} já instalado. Pulando.")
                continue

            log("info", f"Instalando plugin: {name}...")
            if plugin_path.exists():
                run_as_user(f"rm -rf '{plugin_path}'", user=ctx.real_user, check=False)

            # Retry with backoff
            ok = False
            for attempt in range(3):
                proc = run_as_user(
                    ["git", "clone", "--depth=1", f"https://github.com/{repo}.git", str(plugin_path)],
                    user=ctx.real_user, check=False,
                )
                if proc.returncode == 0:
                    ok = True
                    break
                if attempt < 2:
                    log("warn", f"  Tentativa {attempt+1} falhou para {name}, retentando em {2**attempt}s...")
                    time.sleep(2 ** attempt)
            if ok:
                log("success", f"Plugin {name} instalado.")
            else:
                log("warn", f"Plugin {name} não pôde ser clonado após 3 tentativas.")

        log("success", "Shell e plugins configurados.")


def chown_user_compat(path: Path, user: str) -> None:
    import os
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
    import subprocess
    subprocess.run(["chown", "-R", f"{user}:{user}", str(path)],
                    check=False, capture_output=True)
