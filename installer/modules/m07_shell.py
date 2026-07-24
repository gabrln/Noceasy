"""07-shell: configure zsh as default shell + clone zsh plugins."""

from __future__ import annotations

from pathlib import Path

from installer.core.config import (
    NETWORK_RETRY_ATTEMPTS,
    NETWORK_RETRY_BASE_SECONDS,
)
from installer.core.errors import fatal
from installer.infra import exec as exec_mod
from installer.infra.toml_cache import get_cache
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user, retry_with_backoff
from installer.platform import privesc
from installer.ui.logger import log


def _getent_shell(user: str) -> str:
    out = exec_mod.run(["getent", "passwd", user])
    if out.returncode == 0 and out.stdout:
        parts = str(out.stdout).strip().split(":")
        if len(parts) >= 7:
            return parts[6]
    return ""


def _set_user_shell_env(user: str) -> None:
    """Update SHELL in the systemd user manager if the user is logged in."""
    out = exec_mod.run(["id", "-u", user])
    if out.returncode != 0:
        return
    uid = out.stdout.strip()
    runtime_dir = f"/run/user/{uid}"
    if not Path(runtime_dir).is_dir():
        return
    exec_mod.run(
        ["systemctl", "--user", "set-environment", "SHELL=/usr/bin/zsh"],
        env={"XDG_RUNTIME_DIR": runtime_dir},
    )


def _clone_plugin(repo: str, dest: Path) -> bool:
    proc = exec_mod.run(
        ["git", "clone", "--depth=1", f"https://github.com/{repo}.git",
         str(dest)],
    )
    return proc.returncode == 0


class ShellModule(Module):
    name = "07-shell"
    manifest = "zsh-plugins.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Configuring default shell...")

        if not Path("/usr/bin/zsh").exists():
            fatal("zsh is not installed. Module 03 should have installed it.")

        current = _getent_shell(ctx.real_user)
        if current != "/usr/bin/zsh":
            log("info", f"Changing default shell of {current} to /usr/bin/zsh...")
            privesc.run_privileged(
                ["chsh", "-s", "/usr/bin/zsh", ctx.real_user],
                ctx.sudo_password,
            )
        else:
            log("info", "Default shell is already zsh.")

        _set_user_shell_env(ctx.real_user)

        log("info", "Checking zsh plugins...")
        plugins_dir = ctx.user_home / ".config" / "zsh" / "plugins"
        plugins_dir.mkdir(parents=True, exist_ok=True)
        chown_user(plugins_dir, ctx.real_user, ctx.sudo_password)

        plugins = get_cache().load("zsh-plugins.toml").get("plugins", [])
        for plugin in plugins:
            name = plugin["name"]
            repo = plugin["repo"]
            entry = plugin["entry"]
            plugin_path = plugins_dir / name

            if (plugin_path / entry).exists() or (plugin_path / entry).is_file():
                log("success", f"Plugin {name} already installed. Skipping.")
                continue

            log("info", f"Installing plugin: {name}...")
            if plugin_path.exists():
                exec_mod.run(["rm", "-rf", str(plugin_path)])

            ok = retry_with_backoff(
                _clone_plugin, repo, plugin_path,
                attempts=NETWORK_RETRY_ATTEMPTS,
                base_seconds=NETWORK_RETRY_BASE_SECONDS,
            )
            if ok:
                log("success", f"Plugin {name} installed.")
            else:
                log("warn",
                    f"Plugin {name} could not be cloned after "
                    f"{NETWORK_RETRY_ATTEMPTS} attempts.")

        log("success", "Shell and plugins configured.")
