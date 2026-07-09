"""08-dotfiles: apply dotfiles from REPO/.config to USER_HOME/.config."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Optional

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
    """Copy src to a staging dir, then mv into dst. Returns True on success.

    On failure, `dst` is preserved (untouched). The staging dir is
    always cleaned up.
    """
    staging = Path(tempfile.mkdtemp(prefix="gabrln-dot-"))
    try:
        proc = run_as_user(
            ["cp", "-a", str(src), str(staging / dst.name)],
            user=user, check=False,
        )
        if proc.returncode != 0:
            return False
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
        log("warn", f"Atomic copy failed: {exc}")
        return False
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def _copy_dir(src: Path, dst: Path, ctx: RunContext) -> None:
    """Copy a directory from REPO to USER_HOME, with atomicity."""
    if not _atomic_copytree(src, dst, ctx.real_user):
        fatal(f"Failed to copy {src.name} to {dst}")
    _chown(dst, ctx.real_user)
    log("info", f"  -> {src.name}")


def _copy_zsh_with_plugins_backup(
    zsh_src: Path, zsh_dst: Path, plugins_dst: Path, ctx: RunContext,
) -> None:
    """Copy zsh config while preserving the user's existing plugins/."""
    plugins_backup: Optional[Path] = None
    if plugins_dst.is_dir():
        plugins_backup = Path(tempfile.mkdtemp(prefix="gabrln-zsh-"))
        try:
            shutil.copytree(plugins_dst, plugins_backup / "plugins")
        except OSError as exc:
            log("warn", f"Could not preserve plugins/: {exc}")
            shutil.rmtree(plugins_backup, ignore_errors=True)
            plugins_backup = None

    if not _atomic_copytree(zsh_src, zsh_dst, ctx.real_user):
        log("warn", "Failed to copy zsh - original destination preserved.")
        if plugins_backup:
            shutil.rmtree(plugins_backup, ignore_errors=True)
        return

    if plugins_backup and (plugins_backup / "plugins").is_dir():
        if plugins_dst.exists():
            shutil.rmtree(plugins_dst)
        (plugins_backup / "plugins").rename(plugins_dst)
        _chown(plugins_dst, ctx.real_user)
    _chown(zsh_dst, ctx.real_user)
    if plugins_backup:
        shutil.rmtree(plugins_backup, ignore_errors=True)


def _copy_avulso(src_rel: str, dst_template: str, ctx: RunContext) -> None:
    """Copy a single avulso file from REPO to USER_HOME."""
    src_path = REPO_DIR / src_rel
    expanded = os.path.expandvars(dst_template)
    if expanded.startswith("~"):
        expanded = str(ctx.user_home) + expanded[1:]
    dst_path = Path(expanded)

    if not src_path.exists():
        log("warn", f"Source not found, skipping: {src_rel}")
        return

    dst_path.parent.mkdir(parents=True, exist_ok=True)
    if dst_path.exists() and not dst_path.is_symlink():
        bak = dst_path.with_suffix(dst_path.suffix + f".gabrln.bak.{int(time.time())}")
        shutil.copy2(dst_path, bak)

    run_as_user(["cp", "-f", str(src_path), str(dst_path)],
                 user=ctx.real_user, check=False)
    log("info", f"  -> {dst_template}")


def _create_xdg_dir(d: str, ctx: RunContext) -> None:
    """Create an XDG directory owned by the real user."""
    expanded = os.path.expandvars(d)
    if expanded.startswith("~"):
        expanded = str(ctx.user_home) + expanded[1:]
    path = Path(expanded)
    path.mkdir(parents=True, exist_ok=True)
    _chown(path, ctx.real_user)
    log("info", f"  -> {path}")


class DotfilesModule(Module):
    name = "08-dotfiles"
    manifest = "dotfiles.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Ensuring ~/.config exists...")
        ctx.user_home.joinpath(".config").mkdir(parents=True, exist_ok=True)
        _chown(ctx.user_home / ".config", ctx.real_user)

        configs = get_cache().get_list("dotfiles.toml", "directories.configs")
        log("info", "Copying user configurations...")

        for cfg in configs:
            src = REPO_DIR / ".config" / cfg
            dst = ctx.user_home / ".config" / cfg
            if not src.exists():
                log("warn", f"Source not found, skipping: {cfg}")
                continue
            _copy_dir(src, dst, ctx)

        # Special case: zsh preserves plugins/
        log("info", "Applying special zsh configuration...")
        zsh_src = REPO_DIR / ".config" / "zsh"
        zsh_dst = ctx.user_home / ".config" / "zsh"
        if zsh_src.is_dir():
            _copy_zsh_with_plugins_backup(
                zsh_src, zsh_dst, zsh_dst / "plugins", ctx,
            )

        # Avulso files
        log("info", "Copying avulso files...")
        dotfiles = get_cache().load("dotfiles.toml")
        for src_rel, dst in dotfiles.get("files", {}).items():
            _copy_avulso(src_rel, dst, ctx)

        # XDG directories
        log("info", "Creating additional XDG directories...")
        run_as_user("xdg-user-dirs-update 2>/dev/null || true",
                     user=ctx.real_user, check=False)
        xdg = get_cache().load("dotfiles.toml").get("xdg_dirs", {}).get("extra", [])
        for d in xdg:
            _create_xdg_dir(d, ctx)

        log("success", "Dotfiles applied.")
