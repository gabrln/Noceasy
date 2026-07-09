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
            log("info", "Backup automático desabilitado. Pulando.")
            return
        log("info", "Criando snapshot das configurações atuais...")
        name = backup_user_files()
        if name:
            log("success", f"Snapshot criado: {name}")
        else:
            log("warn", "Nenhum arquivo para backupear.")
