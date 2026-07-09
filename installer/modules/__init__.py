"""Module base class + the 16 install steps as Module subclasses."""

from installer.modules.base import Module, RunContext
from installer.modules.preflight import PreflightModule
from installer.modules.m01_backup import BackupModule
from installer.modules.m02_pacman_bootstrap import PacmanBootstrapModule
from installer.modules.m03_pacman_official import PacmanOfficialModule
from installer.modules.m04_yay_aur import YayAurModule
from installer.modules.m05_flatpak import FlatpakModule
from installer.modules.m06_curl_tools import CurlToolsModule
from installer.modules.m07_shell import ShellModule
from installer.modules.m08_dotfiles import DotfilesModule
from installer.modules.m09_hyprland_env import HyprlandEnvModule
from installer.modules.m10_greeter import GreeterModule
from installer.modules.m11_keyring import KeyringModule
from installer.modules.m13_wallpapers import WallpapersModule
from installer.modules.m14_icons_cursors_fonts import IconsCursorsFontsModule
from installer.modules.m15_system_tweaks import SystemTweaksModule
from installer.modules.m16_services import ServicesModule


def build_default_pipeline() -> list[Module]:
    """Return the 16 modules in install order."""
    return [
        PreflightModule(),
        BackupModule(),
        PacmanBootstrapModule(),
        PacmanOfficialModule(manifest="packages.toml"),
        YayAurModule(manifest="aur.toml"),
        FlatpakModule(manifest="flatpak.toml"),
        CurlToolsModule(manifest="curl-tools.toml"),
        ShellModule(manifest="zsh-plugins.toml"),
        DotfilesModule(manifest="dotfiles.toml"),
        HyprlandEnvModule(),
        GreeterModule(),
        KeyringModule(),
        WallpapersModule(manifest="wallpapers.toml"),
        IconsCursorsFontsModule(),
        SystemTweaksModule(),
        ServicesModule(manifest="services.toml"),
    ]


__all__ = [
    "Module",
    "RunContext",
    "build_default_pipeline",
]
