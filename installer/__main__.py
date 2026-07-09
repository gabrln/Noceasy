"""Entrypoint: `python3 -m installer [flags]`.

Bootstrap expects to run as root (called from install.sh via sudo bash).
SUDO_USER must be set; USER_HOME is derived from getent passwd.
"""

from installer.cli import main

if __name__ == "__main__":
    raise SystemExit(main())
