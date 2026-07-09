"""Noceasy installer (Python).

Noceasy is a fast installer for Noctalia (Hyprland/Qt6 Wayland
shell) on Arch Linux / CachyOS. This package is the install
framework itself — the bootstrap lives in install.sh (because
polkit has no agent at TTY login); everything from there on is
Python.

Subpackages:
    modules: the 16 install steps (each a class subclassing Module)
    polkit:  templates installed at runtime to /etc/polkit-1/
"""

__version__ = "0.1.0"
