"""13-wallpapers: download wallpaper pack from Google Drive."""

from __future__ import annotations

import hashlib
import os
import re
import subprocess
from pathlib import Path

from installer.config import get_config
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


def _curl(url: str, out: Path) -> bool:
    try:
        return subprocess.run(
            ["curl", "-fsSL", "--retry", "3", "--retry-delay", "2", "-o", str(out), url],
            check=False, capture_output=True, timeout=120,
        ).returncode == 0
    except subprocess.TimeoutExpired:
        return False


def _aria2(url: str, out: Path) -> bool:
    if subprocess.run(["command", "-v", "aria2c"], check=False,
                       capture_output=True).returncode != 0:
        return _curl(url, out)
    return subprocess.run(
        ["aria2c", "--quiet=true", "--console-log-level=warn",
         "-o", out.name, "-d", str(out.parent), url],
        check=False, capture_output=True, timeout=300,
    ).returncode == 0


class WallpapersModule(Module):
    name = "13-wallpapers"
    manifest = "wallpapers.toml"

    def run(self, ctx: RunContext) -> None:
        if get_config("features.wallpapers", "true") != "true":
            log("info", "Download de wallpapers desabilitado. Pulando.")
            return

        cache = get_cache()
        file_id = cache.get("wallpapers.toml", "source.file_id", "")
        expected_sha = cache.get("wallpapers.toml", "source.sha256", "")
        wp_dir = _expand_path(
            cache.get("wallpapers.toml", "destination.path", "Pictures/Wallpapers"),
            ctx.user_home,
        )

        if not file_id:
            log("warn", "Nenhum file_id em wallpapers.toml. Pulando.")
            return

        log("info", f"Garantindo diretório de wallpapers: {wp_dir}")
        wp_dir.mkdir(parents=True, exist_ok=True)
        subprocess.run(["chown", f"{ctx.real_user}:{ctx.real_user}", str(wp_dir)],
                        check=False, capture_output=True)

        if any(wp_dir.iterdir()):
            log("success", "Diretório de wallpapers já contém arquivos. Pulando download.")
            return

        log("info", "Baixando pacote de wallpapers extras...")
        wp_tmp = Path(f"/tmp/wallpapers_extra.{os.getpid()}.zip")

        # First GET: extract UUID and confirm token
        try:
            html_proc = subprocess.run(
                ["curl", "-fsSL", "--max-time", "30",
                 f"https://drive.google.com/uc?export=download&id={file_id}"],
                check=False, capture_output=True, text=True, timeout=45,
            )
            html = html_proc.stdout if html_proc.returncode == 0 else ""
        except subprocess.TimeoutExpired:
            html = ""

        uuid_match = re.search(r'name="uuid" value="([^"]+)"', html)
        confirm_match = re.search(r'confirm=([^&"]+)', html)
        uuid = uuid_match.group(1) if uuid_match else ""
        confirm = confirm_match.group(1) if confirm_match else ""

        if uuid:
            url = f"https://drive.usercontent.google.com/download?id={file_id}&export=download&confirm={confirm or 't'}&uuid={uuid}"
        else:
            url = f"https://drive.google.com/uc?export=download&confirm=t&id={file_id}"

        log("info", f"URL: {url}")
        if not _aria2(url, wp_tmp):
            log("warn", "Falha ao baixar wallpapers. Pulando extração.")
            wp_tmp.unlink(missing_ok=True)
            return

        # SHA256 check
        if expected_sha:
            actual_sha = hashlib.sha256(wp_tmp.read_bytes()).hexdigest()
            if actual_sha != expected_sha:
                log("error", f"SHA256 mismatch: esperado {expected_sha}, obtido {actual_sha}.")
                wp_tmp.unlink(missing_ok=True)
                return
            log("info", "SHA256 validado.")

        # Sanity check
        size = wp_tmp.stat().st_size
        if size < 1024:
            log("warn", f"Arquivo muito pequeno ({size} bytes). Provavelmente erro do Drive.")
            wp_tmp.unlink(missing_ok=True)
            return

        # Identify type
        try:
            file_proc = subprocess.run(
                ["file", "-b", "--mime-type", str(wp_tmp)],
                check=False, capture_output=True, text=True, timeout=5,
            )
            mime = file_proc.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError):
            mime = ""

        if "zip" not in mime and "archive" not in mime:
            log("warn", f"Arquivo não é zip ({mime}). Veja {wp_tmp}.")
            return

        log("info", f"Extraindo {size // (1024*1024)} MB para {wp_dir}...")
        run_as_user(
            f"unzip -o -j '{wp_tmp}' -d '{wp_dir}' 2>/dev/null || true",
            user=ctx.real_user, check=False,
        )
        wp_tmp.unlink(missing_ok=True)
        log("success", f"Wallpapers extraídos para {wp_dir}.")
