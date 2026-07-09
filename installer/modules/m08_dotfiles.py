"""08-dotfiles: apply dotfiles from REPO/.config to USER_HOME/.config."""

from __future__ import annotations

import os
import shutil
import tempfile
import time
from pathlib import Path

from installer.config import REPO_DIR
from installer.errors import fatal
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext
from installer.toml_cache import get_cache


def _atomic_copytree(src: Path, dst: Path) -> bool:
    """Copy src to a staging dir, then mv into dst. Returns True on success.

    On failure, `dst` is preserved (untouched). The staging dir is
    always cleaned up.
    """
    staging = Path(tempfile.mkdtemp(prefix="noceasy-dot-"))
    try:
        proc = run(
            ["cp", "-a", str(src), str(staging / dst.name)],
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
        shutil.move(str(staging / dst.name), str(dst))
        return True
    except OSError as exc:
        if "Invalid cross-device link" in str(exc) or exc.errno == 18:
            try:
                if dst.exists() or dst.is_symlink():
                    if dst.is_symlink() or dst.is_file():
                        dst.unlink()
                    else:
                        shutil.rmtree(dst)
                shutil.copytree(staging / dst.name, dst)
                return True
            except OSError as exc2:
                log("warn", f"Cross-device fallback copy failed: {exc2}")
                return False
        log("warn", f"Atomic copy failed: {exc}")
        return False
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def _copy_dir(src: Path, dst: Path, ctx: RunContext) -> None:
    """Copy a directory from REPO to USER_HOME, with atomicity."""
    if not _atomic_copytree(src, dst):
        fatal(f"Failed to copy {src.name} to {dst}")
    log("info", f"  -> {src.name}")


def _copy_zsh_with_plugins_backup(
    zsh_src: Path, zsh_dst: Path, plugins_dst: Path, ctx: RunContext,
) -> None:
    """Copy zsh config while preserving the user's existing plugins/."""
    plugins_backup: Path | None = None
    if plugins_dst.is_dir():
        plugins_backup = Path(tempfile.mkdtemp(prefix="noceasy-zsh-"))
        try:
            shutil.copytree(plugins_dst, plugins_backup / "plugins")
        except OSError as exc:
            log("warn", f"Could not preserve plugins/: {exc}")
            shutil.rmtree(plugins_backup, ignore_errors=True)
            plugins_backup = None

    if not _atomic_copytree(zsh_src, zsh_dst):
        log("warn", "Failed to copy zsh - original destination preserved.")
        if plugins_backup:
            shutil.rmtree(plugins_backup, ignore_errors=True)
        return

    if plugins_backup and (plugins_backup / "plugins").is_dir():
        if plugins_dst.exists():
            shutil.rmtree(plugins_dst)
        try:
            (plugins_backup / "plugins").rename(plugins_dst)
        except OSError:
            shutil.copytree(plugins_backup / "plugins", plugins_dst)
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
        bak = dst_path.with_suffix(dst_path.suffix + f".noceasy.bak.{int(time.time())}")
        shutil.copy2(dst_path, bak)

    run(["cp", "-f", str(src_path), str(dst_path)])
    log("info", f"  -> {dst_template}")


def _create_xdg_dir(d: str, ctx: RunContext) -> None:
    """Create an XDG directory owned by the real user."""
    expanded = os.path.expandvars(d)
    if expanded.startswith("~"):
        expanded = str(ctx.user_home) + expanded[1:]
    path = Path(expanded)
    path.mkdir(parents=True, exist_ok=True)
    log("info", f"  -> {path}")


class DotfilesModule(Module):
    name = "08-dotfiles"
    manifest = "dotfiles.toml"

    def run(self, ctx: RunContext) -> None:
        log("info", "Ensuring ~/.config exists...")
        ctx.user_home.joinpath(".config").mkdir(parents=True, exist_ok=True)

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
        run(["xdg-user-dirs-update"])
        xdg = get_cache().load("dotfiles.toml").get("xdg_dirs", {}).get("extra", [])
        for d in xdg:
            _create_xdg_dir(d, ctx)

        # If Hyprland is running, its inotify watcher may have tried
        # to reload while files were being written and entered an error
        # state. Force a clean reload now that everything is in place.
        run(["hyprctl", "reload"])

        log("success", "Dotfiles applied.")
