"""00-preflight: pre-conditions check."""

from __future__ import annotations

import os
from pathlib import Path

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import has_free_space, has_internet
from installer.toml_cache import get_cache


class PreflightModule(Module):
    name = "00-preflight"

    def run(self, ctx: RunContext) -> None:
        log("info", "Verificando pré-condições...")

        if has_internet():
            log("success", "Conectividade com a internet confirmada.")
        else:
            log("warn", "Não foi possível confirmar conectividade com a internet. Continuando mesmo assim.")

        min_bytes = get_cache().get("config.toml", "install.min_free_space", 5 * 1024**3)
        if has_free_space([ctx.user_home, Path("/")], min_bytes=int(min_bytes)):
            log("success", "Espaço em disco suficiente.")
        else:
            log("warn", f"Espaço em disco pode ser insuficiente (mínimo: {min_bytes} bytes).")

        log("info", f"REAL_USER: {ctx.real_user}")
        log("info", f"USER_HOME: {ctx.user_home}")
        log("info", f"REPO_DIR: {os.environ.get('REPO_DIR', '?')}")
        log("success", "Pré-condições verificadas.")
