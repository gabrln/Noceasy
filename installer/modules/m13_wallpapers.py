"""13-wallpapers: download wallpaper pack from Google Drive."""

from __future__ import annotations

import hashlib
import os
import re
import subprocess
import time
from pathlib import Path
from typing import Optional

from installer.config import (
    NETWORK_RETRY_ATTEMPTS,
    NETWORK_RETRY_BASE_SECONDS,
    get_config,
)
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _expand_path(template: str, user_home: Path) -> Path:
    if template.startswith("$HOME/"):
        return user_home / template[len("$HOME/"):]
    if template == "$HOME":
        return user_home
    if template.startswith("/"):
        return Path(template)
    return user_home / template


def _curl_download(url: str, out: Path, timeout: int = 120) -> bool:
    try:
        return subprocess.run(
            ["curl", "-fsSL", "--retry", "3", "--retry-delay", "2",
             "-o", str(out), url],
            check=False, capture_output=True, timeout=timeout,
        ).returncode == 0
    except subprocess.TimeoutExpired:
        return False


def _aria2_download(url: str, out: Path, timeout: int = 300) -> bool:
    if subprocess.run(["command", "-v", "aria2c"],
                       check=False, capture_output=True).returncode != 0:
        return _curl_download(url, out, timeout=timeout)
    return subprocess.run(
        ["aria2c", "--quiet=true", "--console-log-level=warn",
         "-o", out.name, "-d", str(out.parent), url],
        check=False, capture_output=True, timeout=timeout,
    ).returncode == 0


def _extract_drive_confirm(html: str) -> tuple[Optional[str], Optional[str]]:
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


def _build_drive_url(file_id: str, uuid: Optional[str], confirm: Optional[str]) -> str:
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
    try:
        out = subprocess.run(
            ["file", "-b", "--mime-type", str(path)],
            check=False, capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def _fetch_drive_html(file_id: str) -> str:
    """GET the Drive download page to extract UUID/confirm tokens."""
    try:
        out = subprocess.run(
            ["curl", "-fsSL", "--max-time", "30",
             f"https://drive.google.com/uc?export=download&id={file_id}"],
            check=False, capture_output=True, text=True, timeout=45,
        )
        return out.stdout if out.returncode == 0 else ""
    except subprocess.TimeoutExpired:
        return ""


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
        subprocess.run(["chown", f"{ctx.real_user}:{ctx.real_user}", str(wp_dir)],
                        check=False, capture_output=True)

        if any(wp_dir.iterdir()):
            log("success",
                "Wallpapers directory already contains files. Skipping download.")
            return

        log("info", "Downloading extra wallpapers...")
        wp_tmp = Path(f"/tmp/wallpapers_extra.{os.getpid()}.zip")

        html = _fetch_drive_html(file_id)
        uuid, confirm = _extract_drive_confirm(html)
        url = _build_drive_url(file_id, uuid, confirm)
        log("info", f"URL: {url}")

        if not _aria2_download(url, wp_tmp):
            log("warn", "Download failed. Skipping extraction.")
            wp_tmp.unlink(missing_ok=True)
            return

        if not _verify_sha256(wp_tmp, expected_sha):
            wp_tmp.unlink(missing_ok=True)
            return

        # Sanity: must be a real zip
        size = wp_tmp.stat().st_size
        if size < 1024:
            log("warn",
                f"File too small ({size} bytes). Probably an error page.")
            wp_tmp.unlink(missing_ok=True)
            return

        mime = _detect_mime(wp_tmp)
        if "zip" not in mime and "archive" not in mime:
            log("warn", f"Not a zip ({mime}). See {wp_tmp}.")
            return

        log("info", f"Extracting {size // (1024 * 1024)} MB to {wp_dir}...")
        run_as_user(
            f"unzip -o -j '{wp_tmp}' -d '{wp_dir}' 2>/dev/null || true",
            user=ctx.real_user, check=False,
        )
        wp_tmp.unlink(missing_ok=True)
        log("success", f"Wallpapers extracted to {wp_dir}.")
