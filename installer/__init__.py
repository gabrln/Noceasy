"""Arch-gabrln installer (Python port).

Replaces the previous bash-based framework with a single Python package.
The bootstrap is still install.sh (because polkit has no agent at TTY
login); everything from there on is Python.

Subpackages:
    modules: the 16 install steps (each a class subclassing Module)
    polkit:  templates installed at runtime to /etc/polkit-1/
"""

__version__ = "0.1.0"
