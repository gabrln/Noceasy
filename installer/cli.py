"""CLI parsing and main entrypoint.

Usage:
  python3 -m installer                  # full install
  python3 -m installer --dry-run        # simulate
  python3 -m installer --verbose        # DEBUG logs
  python3 -m installer --quiet          # suppress INFO
  python3 -m installer --force          # re-run done modules
  python3 -m installer --no-color       # disable color
  python3 -m installer --help           # show this message

Environment variables:
  NO_COLOR=1            Disable colored output (https://no-color.org/)
Run via `bash install.sh` (escalates as needed).
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from installer import __version__
from installer.config import INSTALLER_DIR, REPO_DIR, LOGS_DIR
from installer.errors import install_signal_handlers, fatal
from installer.logger import LogLevel, setup_logging, log, set_suppress_stderr
from installer.privilege import detect_real_user
from installer.runner import ModuleRunner, RunnerOptions
from installer.modules import build_default_pipeline


def _print_help_header() -> None:
    """Print help text from the module docstring + a flag list."""
    import installer.cli as this
    doc = (this.__doc__ or "").strip()
    print(doc)
    print("")
    print("Flags:")
    print("  --dry-run    Simulate without modifying the system")
    print("  --verbose    Enable DEBUG logs")
    print("  --quiet      Suppress INFO, keep ERROR/STEP")
    print("  --force      Re-run modules already marked done")
    print("  --no-color   Disable colored output (or NO_COLOR=1)")
    print("  -h, --help   Show this message")
    print("  --version    Show version")
    print("")
    print("Run via `bash install.sh` (escalates as needed).")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="installer",
        description="Noceasy installer framework.",
        add_help=False,
    )
    p.add_argument("-h", "--help", action="store_true")
    p.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    p.add_argument("--dry-run", dest="dry_run", action="store_true",
                   help="Simulate without modifying the system")
    p.add_argument("--verbose", action="store_true", help="Enable DEBUG logs")
    p.add_argument("--quiet", action="store_true",
                   help="Suppress INFO, keep ERROR/STEP")
    p.add_argument("--force", action="store_true",
                   help="Re-run modules already marked done (ignore state.json)")
    p.add_argument("--no-color", action="store_true",
                   help="Disable colored output (equivalent to NO_COLOR=1)")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.help:
        _print_help_header()
        return 0

    # Setup logging first (so subsequent steps log to file)
    level = LogLevel.NORMAL
    if args.verbose:
        level = LogLevel.DEBUG
    elif args.quiet:
        level = LogLevel.QUIET
    if args.no_color:
        os.environ["NO_COLOR"] = "1"
    setup_logging(log_dir=LOGS_DIR, level=level)

    # Suppress stderr output from the start — the TUI handles all
    # terminal display. Log messages go to the file only.
    set_suppress_stderr(True)

    log("step", f"Noceasy installer v{__version__}")
    log("info", f"REPO_DIR: {REPO_DIR}")
    log("info", f"INSTALLER_DIR: {INSTALLER_DIR}")

    # Signal handlers + cleanup registration
    install_signal_handlers()

    # Detect the real (non-root) user
    real_user, user_home = detect_real_user()
    log("info", f"REAL_USER: {real_user}")
    log("info", f"USER_HOME: {user_home}")

    # Build pipeline of modules
    modules = build_default_pipeline()
    options = RunnerOptions(dry_run=args.dry_run, force=args.force)
    runner = ModuleRunner(
        modules=modules,
        options=options,
    )

    try:
        runner.run_all()
    except Exception as exc:
        fatal(f"Installer failed: {exc}")

    log("success", "Noceasy installation completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
