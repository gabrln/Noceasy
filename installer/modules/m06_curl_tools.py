"""06-curl-tools: install AI coding tools via curl|bash."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path


from installer.config import LOGS_DIR
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user, is_command
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _parse_tools() -> list[dict]:
    """Parse the entire curl-tools.toml into a list of dicts."""
    return get_cache().load("curl-tools.toml").get("tools", [])


def _expand_path(template: str, user_home: Path) -> str:
    """Expand $HOME and ~ in a path string."""
    expanded = os.path.expandvars(template)
    if expanded.startswith("~"):
        expanded = str(user_home) + expanded[1:]
    return expanded


def _is_installed(binaries: list[str], fallback_paths: list[str]) -> bool:
    """True if any binary in PATH or any fallback file exists."""
    for b in binaries:
        if b and is_command(b):
            return True
    for p in fallback_paths:
        if p and Path(p).is_file():
            return True
    return False


class CurlToolsModule(Module):
    name = "06-curl-tools"
    manifest = "curl-tools.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Checking AI coding tools...")

        local_bin = ctx.user_home / ".local" / "bin"
        if not local_bin.exists():
            log("info", f"Creating {local_bin}...")
            run_as_user(f"mkdir -p '{local_bin}'", user=ctx.real_user, check=False)
            chown_user(local_bin, ctx.real_user)

        tools = _parse_tools()
        if not tools:
            log("warn", "No tools configured in curl-tools.toml.")
            return

        LOGS_DIR.mkdir(parents=True, exist_ok=True)
        for tool in tools:
            name = tool["name"]
            install_url = tool["install_url"]
            binaries = tool.get("binaries", [])
            env_var = tool.get("env_var", "")
            env_value = tool.get("env_value", "")
            fallback_paths = [
                _expand_path(p, ctx.user_home)
                for p in tool.get("fallback_paths", [])
            ]

            if _is_installed(binaries, fallback_paths):
                log("success", f"{name} already installed. Skipping.")
                continue

            log("info", f"Installing {name}...")

            # Per-tool log file with PID suffix for retry safety
            log_file = LOGS_DIR / f"curl-tools-{name}-{os.getpid()}.log"
            log_file.touch()
            chown_user(log_file, ctx.real_user)

            # Write the wrapper script (avoids shell interpolation of URL)
            wrapper = Path(tempfile.mkstemp(prefix="noceasy-curl-", suffix=".sh")[1])
            wrapper.chmod(0o700)
            wrapper.write_text(
                "#!/usr/bin/env bash\n"
                "set -e -o pipefail\n"
                f'curl -fsSL "{install_url}" | bash\n'
            )

            # Build env vars to pass to the subshell
            extra_env = {}
            if env_var:
                extra_env[env_var] = env_value

            # Use login shell so $PATH is set up; pass wrapper via env var
            # NOTE: $WRAPPER must NOT be quoted — single quotes would
            # prevent shell expansion, causing 'No such file or directory'.
            cmd = (
                f"export WRAPPER='{wrapper}'\n"
                f"exec bash $WRAPPER < /dev/null"
            )
            proc = run_as_user(
                ["bash", "-lc", cmd],
                user=ctx.real_user, check=False,
                env=extra_env,
            )
            try:
                wrapper.unlink()
            except FileNotFoundError:
                pass

            if proc.returncode != 0:
                log("warn",
                    f"{name} may not have installed correctly. "
                    f"See {log_file}.")
                continue

            if _is_installed(binaries, fallback_paths):
                log("success", f"{name} installed.")
            else:
                log("warn", f"{name} may not have installed correctly.")

        log("success", "Curl-based tools verified.")
