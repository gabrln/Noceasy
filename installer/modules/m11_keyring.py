"""11-keyring: integrate gnome-keyring with greetd's PAM stack."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext


PAM_FILE = Path("/etc/pam.d/greetd")


def _last_line_matching(content: str, pattern: str) -> int:
    """Return 1-based line number of the LAST line matching `pattern`.
    Returns 0 if no match."""
    last = 0
    for i, line in enumerate(content.splitlines(), start=1):
        if re.match(pattern, line):
            last = i
    return last


class KeyringModule(Module):
    name = "11-keyring"

    def run(self, ctx: RunContext) -> None:
        if not PAM_FILE.is_file():
            log("warn", f"{PAM_FILE} não encontrado. Pulando.")
            return

        log("info", "Verificando integração do gnome-keyring no greetd...")

        # Backup once
        bak = PAM_FILE.with_suffix(PAM_FILE.suffix + ".gabrln.bak")
        if not bak.exists():
            shutil.copy2(PAM_FILE, bak)
            bak.chmod(0o600)

        content = PAM_FILE.read_text()
        lines = content.splitlines(keepends=False)
        modified = False

        # Add auth line
        if not re.search(r"^auth\s+optional\s+pam_gnome_keyring\.so", content, re.M):
            log("info", "Adicionando pam_gnome_keyring.so à linha de auth...")
            target = _last_line_matching(content, r"^auth\s")
            new_line = "auth       optional     pam_gnome_keyring.so"
            if target == 0:
                lines.insert(0, new_line)
                log("warn", f"Nenhum bloco 'auth' em {PAM_FILE}; inserindo no topo.")
            else:
                lines.insert(target, new_line)
            modified = True

        # Add session line
        content = "\n".join(lines)
        if not re.search(r"^session\s+optional\s+pam_gnome_keyring\.so\s+auto_start",
                          content, re.M):
            log("info", "Adicionando pam_gnome_keyring.so auto_start à linha de session...")
            target = _last_line_matching(content, r"^session\s")
            new_line = "session    optional     pam_gnome_keyring.so auto_start"
            if target == 0:
                lines.insert(0, new_line)
                log("warn", f"Nenhum bloco 'session' em {PAM_FILE}; inserindo no topo.")
            else:
                lines.insert(target, new_line)
            modified = True

        if modified:
            PAM_FILE.write_text("\n".join(lines) + "\n")

        # Validate
        final = PAM_FILE.read_text()
        if not re.search(r"^auth\s", final, re.M) or not re.search(r"^session\s", final, re.M):
            log("error", f"{PAM_FILE} ficou sem linhas auth/session. Restaurando backup.")
            shutil.copy2(bak, PAM_FILE)
            fatal("Edição PAM falhou; backup restaurado.")

        log("success", "Keyring configurado.")
