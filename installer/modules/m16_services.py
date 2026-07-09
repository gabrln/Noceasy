"""16-services: enable systemd services from services.toml."""

from __future__ import annotations

import subprocess
from typing import List

from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import systemd_unit_exists
from installer.toml_cache import get_cache


class ServicesModule(Module):
    name = "16-services"
    manifest = "services.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Lendo serviços do manifesto...")

        services: List[str] = get_cache().get_list_field("services.toml", "services", "name")
        if not services:
            log("warn", "Nenhum serviço configurado. Pulando.")
            return

        log("info", "Habilitando serviços do Systemd...")
        enabled = skipped = failed = 0
        for svc in services:
            if not systemd_unit_exists(svc):
                log("warn", f"  → {svc} (unit não encontrada, pulando)")
                skipped += 1
                continue
            if subprocess.run(["systemctl", "enable", svc],
                                check=False, capture_output=True).returncode == 0:
                log("info", f"  → {svc} habilitado")
                enabled += 1
            else:
                log("warn", f"  → {svc} falhou ao habilitar")
                failed += 1

        log("success", f"Serviços processados ({enabled} habilitados, {skipped} pulados, {failed} falhas).")
