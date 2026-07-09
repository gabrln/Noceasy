"""Noceasy installer (Python).

Noceasy is a fast installer for Noctalia (Hyprland/Qt6 Wayland
shell) on Arch Linux / CachyOS. This package is the install
framework itself — the bootstrap lives in install.sh (a TTY has
no display server); everything from there on is Python.

Subpackages:
    modules: the 16 install steps (each a class subclassing Module)
"""

__version__ = "0.1.0"
