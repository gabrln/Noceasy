"""01-backup: snapshot of pre-existing config files."""

from __future__ import annotations

from installer.config import get_config
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.modules.mixins import backup_user_files


class BackupModule(Module):
    name = "01-backup"
    manifest = "dotfiles.toml"

    def run(self, ctx: RunContext) -> None:
        if get_config("flags.auto_backup", "true") != "true":
            log("info", "Auto backup disabled. Skipping.")
            return
        log("info", "Creating snapshot of current configurations...")
        name = backup_user_files(ctx.user_home, ctx.sudo_password)
        if name:
            log("success", f"Snapshot created: {name}")
        else:
            log("warn", "No files to back up.")
