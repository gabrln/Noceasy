"""07-shell: configure zsh as default shell + clone zsh plugins."""

from __future__ import annotations

from pathlib import Path

from installer.config import (
    NETWORK_RETRY_ATTEMPTS,
    NETWORK_RETRY_BASE_SECONDS,
)
from installer.errors import fatal
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user, retry_with_backoff
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _getent_shell(user: str) -> str:
    out = run(["getent", "passwd", user])
    if out.returncode == 0:
        parts = out.stdout.strip().split(":")
        if len(parts) >= 7:
            return parts[6]
    return ""


def _set_user_shell_env(user: str) -> None:
    """Update SHELL in the systemd user manager if the user is logged in."""
    out = run(["id", "-u", user])
    if out.returncode != 0:
        return
    uid = out.stdout.strip()
    runtime_dir = f"/run/user/{uid}"
    if not Path(runtime_dir).is_dir():
        return
    run_as_user(
        ["systemctl", "--user", "set-environment", "SHELL=/usr/bin/zsh"],
        user=user, check=False,
        env={"XDG_RUNTIME_DIR": runtime_dir},
    )


def _clone_plugin(user: str, repo: str, dest: Path) -> bool:
    proc = run_as_user(
        ["git", "clone", "--depth=1", f"https://github.com/{repo}.git",
         str(dest)],
        user=user, check=False,
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
            run(["chsh", "-s", "/usr/bin/zsh", ctx.real_user])
        else:
            log("info", "Default shell is already zsh.")

        _set_user_shell_env(ctx.real_user)

        log("info", "Checking zsh plugins...")
        plugins_dir = ctx.user_home / ".config" / "zsh" / "plugins"
        plugins_dir.mkdir(parents=True, exist_ok=True)
        chown_user(plugins_dir, ctx.real_user)

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
                run_as_user(f"rm -rf '{plugin_path}'",
                             user=ctx.real_user, check=False)

            ok = retry_with_backoff(
                _clone_plugin, ctx.real_user, repo, plugin_path,
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
