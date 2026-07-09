"""Module base class + the 16 install steps as Module subclasses.

To add a new module:
    1. Create installer/modules/mNN_name.py with a class inheriting
       from Module.
    2. Import and register it in build_default_pipeline() below.
"""

from installer.modules.base import Module, RunContext
from installer.modules.preflight import PreflightModule
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


def build_default_pipeline() -> list[Module]:
    """Return the 17 modules in install order."""
    return [
        PreflightModule(),
        BackupModule(),
        PacmanBootstrapModule(),
        PacmanOfficialModule(manifest="packages.toml"),
        YayAurModule(manifest="aur.toml"),
        FlatpakModule(manifest="flatpak.toml"),
        ShellModule(manifest="zsh-plugins.toml"),
        DotfilesModule(manifest="dotfiles.toml"),
        HyprlandEnvModule(),
        GreeterModule(),
        KeyringModule(),
        WallpapersModule(manifest="wallpapers.toml"),
        IconsCursorsFontsModule(),
        SystemTweaksModule(),
        ServicesModule(manifest="services.toml"),
        # Last: sync dev tools to ~/.local/bin so the user can run
        # them by name on subsequent edits without re-cd'ing into
        # the repo. No-op when installer/dev/ is empty.
        DevToolsModule(),
    ]


__all__ = [
    "Module",
    "RunContext",
    "build_default_pipeline",
]
