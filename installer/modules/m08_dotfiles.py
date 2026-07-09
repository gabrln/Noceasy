"""08-dotfiles: apply dotfiles from REPO/.config to USER_HOME/.config."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from installer.config import REPO_DIR
from installer.errors import fatal
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.privilege import run_as_user
from installer.toml_cache import get_cache


def _chown(path: Path, user: str) -> None:
    subprocess.run(["chown", "-R", f"{user}:{user}", str(path)],
                    check=False, capture_output=True)


def _atomic_copytree(src: Path, dst: Path, user: str) -> bool:
    """Copy src to a staging dir, then mv into dst. Returns True on success."""
    staging = Path(tempfile.mkdtemp(prefix="gabrln-dot-"))
    try:
        # Run the copy as the user (preserves ownership of contained files
        # in case they're already user-owned)
        run_as_user(
            ["cp", "-a", str(src), str(staging / dst.name)],
            user=user, check=False,
        )
        if not (staging / dst.name).exists():
            return False
        if dst.exists() or dst.is_symlink():
            if dst.is_symlink() or dst.is_file():
                dst.unlink()
            else:
                shutil.rmtree(dst)
        (staging / dst.name).rename(dst)
        return True
    except OSError as exc:
        log("warn", f"Falha em atomic copy: {exc}")
        return False
    finally:
        shutil.rmtree(staging, ignore_errors=True)


class DotfilesModule(Module):
    name = "08-dotfiles"
    manifest = "dotfiles.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Garantindo diretório ~/.config...")
        ctx.user_home.joinpath(".config").mkdir(parents=True, exist_ok=True)
        _chown(ctx.user_home / ".config", ctx.real_user)

        configs = get_cache().get_list("dotfiles.toml", "directories.configs")
        log("info", "Copiando configurações do usuário...")

        for cfg in configs:
            src = REPO_DIR / ".config" / cfg
            dst = ctx.user_home / ".config" / cfg
            if not src.exists():
                log("warn", f"Fonte não encontrada, pulando: {cfg}")
                continue
            if not _atomic_copytree(src, dst, ctx.real_user):
                fatal(f"Falha ao copiar {cfg} para {dst}")
            _chown(dst, ctx.real_user)
            log("info", f"  → {cfg}")

        # Special case: zsh preserves plugins/
        log("info", "Aplicando configuração especial do Zsh...")
        zsh_src = REPO_DIR / ".config" / "zsh"
        zsh_dst = ctx.user_home / ".config" / "zsh"
        if zsh_src.is_dir():
            plugins_backup = None
            if (zsh_dst / "plugins").is_dir():
                plugins_backup = Path(tempfile.mkdtemp(prefix="gabrln-zsh-"))
                shutil.copytree(zsh_dst / "plugins", plugins_backup / "plugins")

            if _atomic_copytree(zsh_src, zsh_dst, ctx.real_user):
                if plugins_backup and (plugins_backup / "plugins").is_dir():
                    plugins_dst = zsh_dst / "plugins"
                    if plugins_dst.exists():
                        shutil.rmtree(plugins_dst)
                    (plugins_backup / "plugins").rename(plugins_dst)
                    _chown(plugins_dst, ctx.real_user)
                _chown(zsh_dst, ctx.real_user)
            else:
                log("warn", "Falha ao copiar zsh — destino original preservado.")
            if plugins_backup:
                shutil.rmtree(plugins_backup, ignore_errors=True)

        # Avulsos files
        log("info", "Copiando arquivos avulsos...")
        dotfiles = get_cache().load("dotfiles.toml")
        home_str = str(ctx.user_home)
        for src_rel, dst in dotfiles.get("files", {}).items():
            src_path = REPO_DIR / src_rel
            expanded = os.path.expandvars(dst)
            if expanded.startswith("~"):
                expanded = home_str + expanded[1:]
            dst_path = Path(expanded)
            if not src_path.exists():
                log("warn", f"Fonte não encontrada, pulando: {src_rel}")
                continue
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            if dst_path.exists() and not dst_path.is_symlink():
                backup = dst_path.with_suffix(dst_path.suffix + f".gabrln.bak.{int(__import__('time').time())}")
                shutil.copy2(dst_path, backup)
            run_as_user(
                ["cp", "-f", str(src_path), str(dst_path)],
                user=ctx.real_user, check=False,
            )
            log("info", f"  → {dst}")

        # XDG dirs
        log("info", "Criando diretórios XDG adicionais...")
        run_as_user("xdg-user-dirs-update 2>/dev/null || true",
                     user=ctx.real_user, check=False)
        xdg = get_cache().load("dotfiles.toml").get("xdg_dirs", {}).get("extra", [])
        for d in xdg:
            expanded = os.path.expandvars(d)
            if expanded.startswith("~"):
                expanded = home_str + expanded[1:]
            path = Path(expanded)
            path.mkdir(parents=True, exist_ok=True)
            _chown(path, ctx.real_user)
            log("info", f"  → {path}")

        log("success", "Dotfiles aplicados.")
