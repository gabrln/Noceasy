# Changelog

All notable changes to Noceasy are documented here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [v0.2.0] - 2026-07-09

### Changed
- **Project renamed to Noceasy** (portmanteau of "Noctalia" + "easy"). All polkit action IDs, helper binaries, env vars, temp file prefixes, and backup suffixes updated.
- **All docs and code comments translated to English.**
- `README.md` (root) reduced to ~25 lines.
- `installer/README.md` reduced to ~95 lines.

### Added
- `installer/exec.py` with `run()` / `run_capture()` / `run_or_die()` helpers. Consolidates ~30 `subprocess.run(check=False, capture_output=True)` call sites.
- `InstallerError` hierarchy with `ModuleFailure(module_name, reason)` for structured error reporting.
- `run_as_user` now accepts an `env=...` dict for safe env var passing.
- `m11_keyring` uses `pre_check()` to fail fast on missing PAM file.

### Refactored
- Modernized type hints to PEP 604 syntax (`X | None` instead of `Optional[X]`).
- Constants extracted to `installer/config.py` (`YAY_CHUNK_SIZE`, `NETWORK_RETRY_*`, `LOCK_TIMEOUT_SECONDS`, `DEFAULT_MIN_FREE_BYTES`).
- `m13_wallpapers` broken into 7 private methods for testability.
- `backup._strip_collision_suffix` uses regex instead of a 100-iteration loop.
- 7 commits, +1136 / -881 lines.

## [v0.1.0] - 2026-07-09

### Added
- Initial release of the Python-based installer framework.
- `install.sh` bootstrap (bash, ~140 lines) with arch and OS detection.
- `installer/` package with 6 libraries (`cli`, `config`, `logger`, `errors`, `privilege`, `exec`-style helpers, `toml_cache`, `state`, `backup`, `progress`, `runner`).
- 16 install modules: `00-preflight`, `01-backup`, `02-pacman-bootstrap`, `03-pacman-official`, `04-yay-aur`, `05-flatpak`, `06-curl-tools`, `07-shell`, `08-dotfiles`, `09-hyprland-env`, `10-greeter`, `11-keyring`, `13-wallpapers`, `14-icons-cursors-fonts`, `15-system-tweaks`, `16-services`.
- Polkit policy with auto-installation and cleanup.
- `GABRLN_VERSION` / `GABRLN_SHA256` env vars for pinning (renamed to `NOCEASY_*` in v0.2.0).

### Changed
- **Migrated from bash to Python**: 6 bash lib files and 15 bash modules removed; replaced by ~2500 LOC of typed Python.
- Logic preserved: state skip-if-done, atomic backups with collision suffix, `sudo` -> `runuser` + polkit migration.

[v0.2.0]: https://github.com/gabrln/Noceasy/compare/v0.1.0...v0.2.0
[v0.1.0]: https://github.com/gabrln/Noceasy/releases/tag/v0.1.0
