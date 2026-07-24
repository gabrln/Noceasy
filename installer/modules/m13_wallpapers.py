"""13-wallpapers: download wallpaper pack from Google Drive."""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import tempfile
from pathlib import Path

from installer.core.config import get_config
from installer.infra import exec as exec_mod
from installer.infra.toml_cache import get_cache
from installer.modules.base import Module, RunContext
from installer.ui.logger import log


def _expand_path(template: str, user_home: Path) -> Path:
    if template.startswith("$HOME/"):
        result = user_home / template[len("$HOME/"):]
    elif template == "$HOME":
        result = user_home
    elif template.startswith("/"):
        result = Path(template)
    else:
        result = user_home / template

    # Guard against path traversal outside user_home
    resolved = result.resolve()
    expected = user_home.resolve()
    if expected not in resolved.parents and resolved != expected \
            and not str(resolved).startswith(str(expected) + "/"):
        raise ValueError(
            f"Path traversal detected: {template} resolves to {resolved}, "
            f"which is outside {expected}"
        )
    return result


def _curl_download(url: str, out: Path, timeout: int = 120) -> bool:
    return exec_mod.run(["curl", "-fsSL", "--retry", "3", "--retry-delay", "2",
                "-o", str(out), url], timeout=timeout).returncode == 0


def _aria2_download(url: str, out: Path, timeout: int = 300) -> bool:
    if shutil.which("aria2c") is None:
        return _curl_download(url, out, timeout=timeout)
    return exec_mod.run(["aria2c", "--quiet=true", "--console-log-level=warn",
                "-o", out.name, "-d", str(out.parent), url],
                timeout=timeout).returncode == 0


def _extract_drive_confirm(html: str) -> tuple[str | None, str | None]:
    """Parse a Google Drive download page for UUID and confirm token."""
    uuid = None
    confirm = None
    m = re.search(r'name="uuid" value="([^"]+)"', html)
    if m:
        uuid = m.group(1)
    m = re.search(r'confirm=([^&"]+)', html)
    if m:
        confirm = m.group(1)
    return uuid, confirm


def _build_drive_url(file_id: str, uuid: str | None,
                      confirm: str | None) -> str:
    if uuid:
        c = confirm or "t"
        return (f"https://drive.usercontent.google.com/download?"
                f"id={file_id}&export=download&confirm={c}&uuid={uuid}")
    return f"https://drive.google.com/uc?export=download&confirm=t&id={file_id}"


def _verify_sha256(path: Path, expected: str) -> bool:
    if not expected:
        return True
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual == expected:
        log("info", "SHA256 verified.")
        return True
    log("error", f"SHA256 mismatch: expected {expected}, got {actual}.")
    return False


def _detect_mime(path: Path) -> str:
    out = exec_mod.run(["file", "-b", "--mime-type", str(path)], timeout=5)
    return out.stdout.strip() if out.stdout else ""


def _fetch_drive_html(file_id: str) -> str:
    """GET the Drive download page to extract UUID/confirm tokens."""
    out = exec_mod.run(["curl", "-fsSL", "--max-time", "30",
               f"https://drive.google.com/uc?export=download&id={file_id}"],
               timeout=45)
    return out.stdout if out.returncode == 0 else ""


class WallpapersModule(Module):
    name = "13-wallpapers"
    manifest = "wallpapers.toml"

    def run(self, ctx: RunContext) -> None:
        if get_config("features.wallpapers", "true") != "true":
            log("info", "Wallpaper download disabled in config.toml. Skipping.")
            return

        cache = get_cache()
        file_id = cache.get("wallpapers.toml", "source.file_id", "")
        expected_sha = cache.get("wallpapers.toml", "source.sha256", "")
        wp_dir = _expand_path(
            cache.get("wallpapers.toml", "destination.path",
                       "Pictures/Wallpapers"),
            ctx.user_home,
        )

        if not file_id:
            log("warn", "No file_id in wallpapers.toml. Skipping.")
            return

        log("info", f"Ensuring wallpapers directory: {wp_dir}")
        wp_dir.mkdir(parents=True, exist_ok=True)
        exec_mod.run(["chown", f"{ctx.real_user}:{ctx.real_user}", str(wp_dir)])

        if any(wp_dir.iterdir()):
            log("success",
                "Wallpapers directory already contains files. Skipping download.")
            return

        log("info", "Downloading extra wallpapers...")
        fd, wp_tmp_str = tempfile.mkstemp(prefix="noceasy-wallpapers-", suffix=".zip")
        os.close(fd)
        wp_tmp = Path(wp_tmp_str)

        try:
            html = _fetch_drive_html(file_id)
            uuid, confirm = _extract_drive_confirm(html)
            url = _build_drive_url(file_id, uuid, confirm)
            log("info", f"URL: {url}")

            if not _aria2_download(url, wp_tmp):
                log("warn", "Download failed. Skipping extraction.")
                return

            if not _verify_sha256(wp_tmp, expected_sha):
                return

            # Sanity: must be a real zip
            size = wp_tmp.stat().st_size
            if size < 1024:
                log("warn",
                    f"File too small ({size} bytes). Probably an error page.")
                return

            mime = _detect_mime(wp_tmp)
            if "zip" not in mime and "archive" not in mime:
                log("warn", f"Not a zip ({mime}). See {wp_tmp}.")
                return

            log("info", f"Extracting {size // (1024 * 1024)} MB to {wp_dir}...")
            result = exec_mod.run(["unzip", "-o", "-j", str(wp_tmp), "-d", str(wp_dir)])
            if result.returncode == 0:
                log("success", f"Wallpapers extracted to {wp_dir}.")
            else:
                err = result.stderr.strip() or f"exit code {result.returncode}"
                log("warn", f"Extraction failed: {err}")
        finally:
            wp_tmp.unlink(missing_ok=True)
