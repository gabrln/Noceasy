"""Tests for installer/modules — verify command sequences and flags."""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from installer.core.state import State
from installer.modules.base import RunContext
from installer.modules.m01_backup import BackupModule
from installer.modules.m02_pacman_bootstrap import PacmanBootstrapModule
from installer.modules.m03_pacman_official import PacmanOfficialModule
from installer.modules.m04_yay_aur import YayAurModule
from installer.modules.m05_flatpak import FlatpakModule
from installer.modules.m07_shell import ShellModule
from installer.modules.m08_dotfiles import DotfilesModule
from installer.modules.m09_hyprland_env import HyprlandEnvModule
from installer.modules.m10_greeter import GreeterModule
from installer.modules.m11_keyring import KeyringModule
from installer.modules.m13_wallpapers import WallpapersModule
from installer.modules.m14_icons_cursors_fonts import IconsCursorsFontsModule
from installer.modules.m15_system_tweaks import SystemTweaksModule
from installer.modules.m16_services import ServicesModule
from installer.modules.m17_dev_tools import DevToolsModule
from installer.modules.preflight import PreflightModule


@pytest.fixture
def ctx() -> RunContext:
    return RunContext(
        real_user="test",
        user_home=Path("/home/test"),
        state=MagicMock(spec=State),
        sudo_password="pw",
    )


@pytest.fixture
def mock_run() -> Iterator[MagicMock]:
    with patch("installer.infra.exec.run") as m:
        m.return_value = MagicMock(returncode=0, stdout="", stderr="")
        yield m


@pytest.fixture
def mock_priv() -> Iterator[MagicMock]:
    with patch("installer.platform.privesc.run_privileged") as m:
        m.return_value = MagicMock(returncode=0, stdout="", stderr="")
        yield m


# ── m01_backup ───────────────────────────────────────────────────────


class TestBackupModule:
    def test_skip_when_disabled(self, ctx: RunContext) -> None:
        with patch("installer.modules.m01_backup.get_config",
                   return_value="false"):
            mod = BackupModule()
            with patch("installer.modules.m01_backup.backup_user_files") as m:
                mod.run(ctx)
                m.assert_not_called()

    def test_runs_when_enabled(self, ctx: RunContext) -> None:
        with patch("installer.modules.m01_backup.get_config",
                   return_value="true"):
            mod = BackupModule()
            with patch("installer.modules.m01_backup.backup_user_files",
                       return_value="snap-2025"):
                mod.run(ctx)


# ── m02_pacman_bootstrap ─────────────────────────────────────────────


class TestPacmanBootstrapModule:
    def test_runs_pacman_sy(self, ctx: RunContext, mock_priv: MagicMock,
                            mock_run: MagicMock) -> None:
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list.return_value = ["git", "base-devel"]
            with patch("installer.modules.m02_pacman_bootstrap.pkg_installed",
                       return_value=False):
                with patch("installer.modules.m02_pacman_bootstrap.is_command",
                           return_value=True):
                    mod = PacmanBootstrapModule()
                    mod.run(ctx)
        priv_calls = [c[0][0] for c in mock_priv.call_args_list]
        assert any("pacman" in c and "-Sy" in c for c in priv_calls)


# ── m03_pacman_official ──────────────────────────────────────────────


class TestPacmanOfficialModule:
    def test_skips_when_no_missing(self, ctx: RunContext,
                                    mock_run: MagicMock) -> None:
        mock_run.return_value.stdout = ""
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list_field.return_value = ["pkg1"]
            with patch("installer.infra.exec.run") as r:
                # pacman -T returns empty = all satisfied
                r.return_value = MagicMock(returncode=0, stdout="")
                mod = PacmanOfficialModule(manifest="packages.toml")
                mod.run(ctx)
        # Should not call privesc.run_privileged for install
        priv_calls = [c for c in mock_run.call_args_list
                      if "pacman" in str(c)]
        assert not any("-S" in str(c) for c in priv_calls)


# ── m04_yay_aur ──────────────────────────────────────────────────────


class TestYayAurModule:
    def test_skips_when_none_missing(self, ctx: RunContext,
                                     mock_run: MagicMock) -> None:
        mock_run.return_value.stdout = ""
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list_field.return_value = []
            mod = YayAurModule(manifest="aur.toml")
            mod.run(ctx)

    def test_installs_missing(self, ctx: RunContext,
                              mock_run: MagicMock) -> None:
        mock_run.return_value.stdout = "pkg1"
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list_field.return_value = ["pkg1"]
            mod = YayAurModule(manifest="aur.toml")
            with patch("installer.modules.m04_yay_aur._pacman_missing",
                       side_effect=[["pkg1"], []]):
                with patch("installer.modules.m04_yay_aur._install_chunk",
                           return_value=True) as chunk:
                    mod.run(ctx)
                    chunk.assert_called_once()


# ── m05_flatpak ──────────────────────────────────────────────────────


class TestFlatpakModule:
    def test_skips_when_not_installed(self, ctx: RunContext,
                                      mock_run: MagicMock) -> None:
        with patch("installer.modules.m05_flatpak.is_command",
                   return_value=False):
            mod = FlatpakModule(manifest="flatpak.toml")
            mod.run(ctx)

    def configures_remote(self, ctx: RunContext,
                          mock_run: MagicMock) -> None:
        with patch("installer.modules.m05_flatpak.is_command",
                   return_value=True), \
                patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get.side_effect = ["flathub", "https://..."]
            cache.return_value.get_list_field.return_value = []
            mod = FlatpakModule(manifest="flatpak.toml")
            mod.run(ctx)
        add_remote_calls = [c for c in mock_run.call_args_list
                            if "remote-add" in str(c)]
        assert add_remote_calls


# ── m07_shell ────────────────────────────────────────────────────────


class TestShellModule:
    def test_runs_chsh(self, ctx: RunContext,
                       mock_priv: MagicMock) -> None:
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.load.return_value = {}
            with patch("installer.modules.m07_shell.Path") as mock_path:
                mock_path.return_value.is_file.return_value = True
                mod = ShellModule(manifest="zsh-plugins.toml")
                mod.run(ctx)
        chsh_calls = [c for c in mock_priv.call_args_list
                      if "chsh" in str(c)]
        assert chsh_calls


# ── m08_dotfiles ─────────────────────────────────────────────────────


class TestDotfilesModule:
    def test_copies_configs(self, ctx: RunContext,
                            mock_run: MagicMock) -> None:
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list.return_value = ["hypr"]
            cache.return_value.load.return_value = {"files": {},
                                                     "xdg_dirs": {}}
            with patch("installer.modules.m08_dotfiles.REPO_DIR",
                       Path("/repo")):
                with patch("installer.modules.m08_dotfiles.Path") as mock_p:
                    mock_p.return_value.is_dir.return_value = False
                    mock_src = MagicMock()
                    mock_src.exists.return_value = False
                    mock_p.return_value = mock_src
                    mod = DotfilesModule(manifest="dotfiles.toml")
                    mod.run(ctx)

    def test_skips_missing_sources(self, ctx: RunContext) -> None:
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list.return_value = ["missing"]
            cache.return_value.load.return_value = {}
            mod = DotfilesModule(manifest="dotfiles.toml")
            mod.run(ctx)


# ── m09_hyprland_env ─────────────────────────────────────────────────


class TestHyprlandEnvModule:
    def test_runs_find_chmod(self, ctx: RunContext) -> None:
        cfg = ctx.user_home / ".config"
        cfg.mkdir(parents=True, exist_ok=True)
        (cfg / "hypr").mkdir(parents=True, exist_ok=True)
        (cfg / "hypr" / "hyprland.lua").touch()
        mod = HyprlandEnvModule()
        with patch("installer.modules.m09_hyprland_env.run") as mock_run:
            mod.run(ctx)
        find_calls = [c for c in mock_run.call_args_list
                      if "find" in str(c[0][0])]
        assert find_calls

    def test_fails_if_no_config(self, ctx: RunContext) -> None:
        mod = HyprlandEnvModule()
        with patch.object(Path, "is_file", return_value=False):
            with pytest.raises(SystemExit):
                mod.run(ctx)


# ── m10_greeter ──────────────────────────────────────────────────────


class TestGreeterModule:
    def test_creates_greeter_user(self, ctx: RunContext,
                                  mock_run: MagicMock,
                                  mock_priv: MagicMock) -> None:
        mock_run.return_value.returncode = 1  # greeter user does not exist
        with patch("installer.infra.backup.BACKUPS_DIR",
                   Path("/tmp/bk")):
            mod = GreeterModule()
            mod.run(ctx)
        useradd_calls = [c for c in mock_priv.call_args_list
                         if "useradd" in str(c)]
        assert useradd_calls


# ── m11_keyring ──────────────────────────────────────────────────────


class TestKeyringModule:
    def test_skips_when_pam_missing(self, ctx: RunContext) -> None:
        with patch("installer.modules.m11_keyring.PAM_FILE") as mock_pf:
            mock_pf.is_file.return_value = False
            mod = KeyringModule()
            assert mod.pre_check(ctx) is False

    def test_adds_auth_lines(self, ctx: RunContext,
                             mock_priv: MagicMock) -> None:
        with patch("installer.modules.m11_keyring.PAM_FILE") as mock_pf:
            mock_pf.is_file.return_value = True
            mock_pf.read_text.return_value = "auth required\nsession required\n"
            with patch("installer.modules.m11_keyring.Path") as mock_path:
                mock_path.return_value.with_suffix.return_value = \
                    MagicMock(exists=MagicMock(return_value=False))
                mod = KeyringModule()
                mod.run(ctx)


# ── m13_wallpapers ───────────────────────────────────────────────────


class TestWallpapersModule:
    def test_skip_when_disabled(self, ctx: RunContext) -> None:
        with patch("installer.modules.m13_wallpapers.get_config",
                   return_value="false"):
            mod = WallpapersModule(manifest="wallpapers.toml")
            mod.run(ctx)

    def test_runs_when_enabled(self, ctx: RunContext,
                               mock_run: MagicMock) -> None:
        with patch("installer.modules.m13_wallpapers.get_cache") as cache:
            cache.return_value.get.side_effect = ["file_id", "sha256",
                                                   "Pictures/Wallpapers"]
            with patch("tempfile.mkstemp", return_value=(1, "/tmp/x.zip")):
                mod = WallpapersModule(manifest="wallpapers.toml")
                mod.run(ctx)


# ── m14_icons_cursors_fonts ──────────────────────────────────────────


class TestIconsCursorsFontsModule:
    def test_runs_fc_cache(self, ctx: RunContext) -> None:
        mod = IconsCursorsFontsModule()
        with patch("installer.modules.m14_icons_cursors_fonts.run") as mock_run, \
                patch("installer.modules.m14_icons_cursors_fonts.chown_user"):
            mod.run(ctx)
        fc_calls = [c for c in mock_run.call_args_list
                    if "fc-cache" in str(c)]
        assert fc_calls


# ── m15_system_tweaks ────────────────────────────────────────────────


class TestSystemTweaksModule:
    def test_runs_privileged(self, ctx: RunContext) -> None:
        mod = SystemTweaksModule()
        with patch("installer.modules.m15_system_tweaks.privesc") as mock_p, \
                patch("installer.modules.m15_system_tweaks.chown_user"), \
                patch("installer.modules.m15_system_tweaks."
                      "_replace_with_symlink"):
            mod.run(ctx)
        mkdir_calls = [c for c in mock_p.run_privileged.call_args_list
                       if "mkdir" in str(c[0][0])]
        assert mkdir_calls


# ── m16_services ─────────────────────────────────────────────────────


class TestServicesModule:
    def test_enables_services(self, ctx: RunContext,
                              mock_priv: MagicMock) -> None:
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list_field.return_value = ["sshd"]
            with patch("installer.modules.m16_services.systemd_unit_exists",
                       return_value=True):
                mod = ServicesModule(manifest="services.toml")
                mod.run(ctx)
        enable_calls = [c for c in mock_priv.call_args_list
                        if "systemctl" in str(c)]
        assert enable_calls

    def test_skips_missing_units(self, ctx: RunContext,
                                 mock_priv: MagicMock) -> None:
        with patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get_list_field.return_value = ["missing"]
            with patch(
                "installer.modules.m16_services.systemd_unit_exists",
                    return_value=False):
                mod = ServicesModule(manifest="services.toml")
                mod.run(ctx)
        mock_priv.assert_not_called()


# ── m17_dev_tools ────────────────────────────────────────────────────


class TestDevToolsModule:
    def test_skips_when_empty(self, ctx: RunContext) -> None:
        with patch("installer.modules.m17_dev_tools.DEV_SRC") as mock_src:
            mock_src.is_dir.return_value = False
            mod = DevToolsModule()
            mod.run(ctx)

    def test_copies_scripts(self, ctx: RunContext) -> None:
        with patch("installer.modules.m17_dev_tools.DEV_SRC") as mock_src, \
                patch("installer.modules.m17_dev_tools.chown_user"):
            mock_src.is_dir.return_value = True
            mock_src.glob.return_value = [MagicMock(spec=Path,
                                                      name="tool.py")]
            mod = DevToolsModule()
            mod.run(ctx)


# ── preflight ────────────────────────────────────────────────────────


class TestPreflightModule:
    def test_runs_checks(self, ctx: RunContext) -> None:
        with patch("installer.modules.preflight.has_internet",
                   return_value=True), \
                patch("installer.modules.preflight.has_free_space",
                      return_value=True), \
                patch("installer.infra.toml_cache.get_cache") as cache:
            cache.return_value.get.return_value = 5 * 1024**3
            mod = PreflightModule()
            mod.run(ctx)
