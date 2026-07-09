"""06-curl-tools: install AI coding tools via curl|bash."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import List

from installer.config import LOGS_DIR
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import chown_user, is_command
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _parse_tools() -> List[dict]:
    """Parse the entire curl-tools.toml into a list of dicts."""
    data = get_cache().load("curl-tools.toml")
    return data.get("tools", [])


class CurlToolsModule(Module):
    name = "06-curl-tools"
    manifest = "curl-tools.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Verificando ferramentas de coding AI...")

        local_bin = ctx.user_home / ".local" / "bin"
        if not local_bin.exists():
            log("info", f"Criando {local_bin}...")
            run_as_user(f"mkdir -p '{local_bin}'", user=ctx.real_user, check=False)
            chown_user(local_bin, ctx.real_user)

        tools = _parse_tools()
        if not tools:
            log("warn", "Nenhuma ferramenta configurada em curl-tools.toml.")
            return

        LOGS_DIR.mkdir(parents=True, exist_ok=True)
        for tool in tools:
            name = tool["name"]
            install_url = tool["install_url"]
            binaries = tool.get("binaries", [])
            fallback_paths = tool.get("fallback_paths", [])
            env_var = tool.get("env_var", "")
            env_value = tool.get("env_value", "")

            # Resolve fallback paths (expand ~ and $HOME)
            resolved_fallbacks = []
            for fp in fallback_paths:
                expanded = os.path.expandvars(fp)
                if expanded.startswith("~"):
                    expanded = str(ctx.user_home) + expanded[1:]
                resolved_fallbacks.append(expanded)

            # Skip if already installed
            already = False
            for bin_name in binaries:
                if is_command(bin_name):
                    already = True
                    break
            if not already:
                for path in resolved_fallbacks:
                    if Path(path).is_file():
                        already = True
                        break
            if already:
                log("success", f"{name} já está instalado. Pulando.")
                continue

            log("info", f"Instalando {name}...")

            # Write a wrapper script so we don't interpolate $install_url
            # into a shell string (avoids command injection).
            log_file = LOGS_DIR / f"curl-tools-{name}-{os.getpid()}.log"
            log_file.touch()
            chown_user(log_file, ctx.real_user)

            wrapper = Path(tempfile.mkstemp(prefix="gabrln-curl-", suffix=".sh")[1])
            wrapper.chmod(0o700)
            wrapper.write_text(
                "#!/usr/bin/env bash\n"
                "set -e -o pipefail\n"
                f'curl -fsSL "{install_url}" | bash\n'
            )

            env_args = []
            if env_var:
                env_args = [f"{env_var}={env_value}"]

            env_export = " ".join(f"{k}" for k in env_args)
            env_export += " " if env_export else ""
            proc = run_as_user(
                ["bash", "-lc",
                 f"set -e -o pipefail; {env_export}WRAPPER='{wrapper}' bash -c 'exec \"$WRAPPER\"' < /dev/null"],
                user=ctx.real_user,
                check=False,
            )
            try:
                wrapper.unlink()
            except FileNotFoundError:
                pass

            if proc.returncode != 0:
                log("warn", f"{name} pode não ter sido instalado. Veja {log_file}.")
                continue

            # Re-verify
            installed = any(is_command(b) for b in binaries) or \
                         any(Path(p).is_file() for p in resolved_fallbacks)
            if installed:
                log("success", f"{name} instalado.")
            else:
                log("warn", f"{name} pode não ter sido instalado corretamente.")

        log("success", "Ferramentas via curl verificadas.")
