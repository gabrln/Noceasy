"""11-keyring: integrate gnome-keyring with greetd's PAM stack."""

from __future__ import annotations

import re
import shutil
import tempfile
from pathlib import Path

from installer import privesc
from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext


PAM_FILE = Path("/etc/pam.d/greetd")

_AUTH_LINE = "auth       optional     pam_gnome_keyring.so"
_SESSION_LINE = "session    optional     pam_gnome_keyring.so auto_start"


def _last_line_matching(content: str, pattern: str) -> int:
    """Return 1-based line number of the LAST line matching `pattern`.
    Returns 0 if no match.
    """
    last = 0
    for i, line in enumerate(content.splitlines(), start=1):
        if re.match(pattern, line):
            last = i
    return last


def _has_line(content: str, pattern: str) -> bool:
    return re.search(pattern, content, re.MULTILINE) is not None


def _validate_pam(content: str) -> bool:
    """True if PAM still has auth and session blocks (sanity check)."""
    return re.search(r"^auth\s", content, re.M) is not None and \
        re.search(r"^session\s", content, re.M) is not None


def _insert_after_last(lines: list, pattern: str, new_line: str) -> bool:
    """Insert `new_line` after the last line matching `pattern`.
    Returns True if modified, False if pattern not found.
    """
    target = _last_line_matching("\n".join(lines), pattern)
    if target == 0:
        return False
    lines.insert(target, new_line)
    return True


def _atomic_pam_write(content: str, ctx: RunContext) -> None:
    """Write *content* to ``/etc/pam.d/greetd`` via temp file + install."""
    with tempfile.NamedTemporaryFile(mode="w", delete=False,
                                     suffix=".pam") as tmp:
        tmp.write(content)
        tmp_path = Path(tmp.name)
    try:
        privesc.run_privileged(
            ["install", "-m", "644", str(tmp_path), str(PAM_FILE)],
            ctx.sudo_password,
        )
    finally:
        tmp_path.unlink(missing_ok=True)

def _atomic_copy(src: Path, dest: Path, ctx: RunContext) -> None:
    """Copy *src* to *dest* via temp file + ``install`` (root-owned)."""
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp_path = Path(tmp.name)
    try:
        shutil.copy2(src, tmp_path)
        privesc.run_privileged(
            ["install", "-m", "644", str(tmp_path), str(dest)],
            ctx.sudo_password,
        )
    finally:
        tmp_path.unlink(missing_ok=True)



class KeyringModule(Module):
    name = "11-keyring"

    def pre_check(self, ctx: RunContext) -> bool:
        if not PAM_FILE.is_file():
            log("warn", f"{PAM_FILE} not found. Skipping keyring configuration.")
            return False
        return True

    def run(self, ctx: RunContext) -> None:
        log("info", "Checking gnome-keyring integration in greetd...")

        # Backup once (so we can restore if our edit breaks PAM)
        bak = PAM_FILE.with_suffix(PAM_FILE.suffix + ".noceasy.bak")
        if not bak.exists():
            _atomic_copy(PAM_FILE, bak, ctx)

        content = PAM_FILE.read_text()
        lines = content.splitlines(keepends=False)
        modified = False

        # Add auth line
        if not _has_line(content, r"^auth\s+optional\s+pam_gnome_keyring\.so"):
            log("info", "Adding pam_gnome_keyring.so to auth block...")
            if not _insert_after_last(lines, r"^auth\s", _AUTH_LINE):
                log("warn",
                    f"No 'auth' block in {PAM_FILE}; prepending auth line.")
                lines.insert(0, _AUTH_LINE)
            modified = True

        # Recompute content after potential edit
        content = "\n".join(lines)
        if not _has_line(content,
                          r"^session\s+optional\s+pam_gnome_keyring\.so\s+auto_start"):
            log("info", "Adding pam_gnome_keyring.so auto_start to session block...")
            if not _insert_after_last(lines, r"^session\s", _SESSION_LINE):
                log("warn",
                    f"No 'session' block in {PAM_FILE}; prepending session line.")
                lines.insert(0, _SESSION_LINE)
            modified = True

        if modified:
            _atomic_pam_write("\n".join(lines) + "\n", ctx)

        # Validate the result
        final = PAM_FILE.read_text()
        if not _validate_pam(final):
            log("error",
                f"{PAM_FILE} lost auth/session blocks. Restoring backup.")
            _atomic_pam_write(bak.read_text(), ctx)
            fatal("PAM edit failed; backup restored.")

        log("success", "Keyring configured.")
