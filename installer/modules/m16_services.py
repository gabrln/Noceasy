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
        log("info", "Reading services from manifest...")

        services: List[str] = get_cache().get_list_field(
            "services.toml", "services", "name")
        if not services:
            log("warn", "No services configured. Skipping.")
            return

        log("info", "Enabling systemd services...")
        enabled = skipped = failed = 0
        for svc in services:
            if not systemd_unit_exists(svc):
                log("warn", f"  -> {svc} (unit not found, skipping)")
                skipped += 1
                continue
            if subprocess.run(["systemctl", "enable", svc],
                                check=False, capture_output=True).returncode == 0:
                log("info", f"  -> {svc} enabled")
                enabled += 1
            else:
                log("warn", f"  -> {svc} failed to enable")
                failed += 1

        log("success",
            f"Services processed ({enabled} enabled, "
            f"{skipped} skipped, {failed} failed).")
