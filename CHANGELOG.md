# Changelog

All notable changes to Noceasy are documented here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [v0.3.0] - 2026-07-09

### Fixed
- **`bootstrap.lua` used nonexistent `hl.exec()`**, which would have
  crashed on first boot when `scrolloverview` was not yet installed.
  Renamed to `hl.exec_cmd()` (the actual Hyprland 0.55+ API name).
- **`require("noctalia")` would fail in `hyprland.lua`** on a fresh
  install or after Noctalia regenerated its theme file, aborting the
  entire config load. Now prepends `package.path` and wraps in `pcall`
  so a missing/regenerated `noctalia.lua` degrades gracefully.
- **`idle_inhibit` window-rule regex** was matching any class containing
  substrings like `mpv` or `zen` (e.g. `*zenity*` matched because it
  contains `zen`). Tightened to anchored alternation.
- **Game-mode class match** anchored `dota` to `dota2` to avoid false
  positives like `autoplace.exe`.
- **Notifications** in `automation.lua` were in PT-BR; translated to
  English. Removed two orphan `paplay` calls in the battery monitor.
- **Stale `SUPER + F2` mic-mute entry** in `KeyHints.lua`; the real
  binding is `SUPER + SHIFT + M` plus `XF86AudioMicMute`.
- **Bootstrap notification** still said "Arch-gabrln"; renamed to
  "Noceasy".

### Changed
- **scrolloverview plugin keywords** moved out of `settings.lua` and
  into `scripts/bootstrap.lua`, applied after `hyprpm enable` so the
  red error banner is gone on first boot.
- **SUPER + M** now uses `hl.dsp.layout("fit active")` (the real
  "maximize" in scrolling layout) instead of `colresize toend`.
- **Ctrl + Alt + Del** removed; session exit goes through the Noctalia
  session menu (Super + Shift + P).
- **Package manifest pruned** from 98 to 79 entries. Removed: snapper,
  duf, gping, procs, file-roller, rclone, vesktop, prismlauncher,
  spotify-launcher, protonup-qt, xdg-user-dirs-gtk, hwinfo, meld,
  fsarchiver, pv, python-defusedxml, python-packaging, rsync,
  spice-vdagent, qemu-guest-agent. Added `engrampa` (replaces
  file-roller). Kept per request: nano, openssh, wget, seahorse,
  nwg-look, swayimg, cava.
- **`mimeapps.list`** dropped the `vesktop` Discord handler and now
  points archive MIME types at `engrampa.desktop`.
- **`yazi.toml`** `open_archive` now delegates to `xdg-open` with an
  `unzip` fallback when no GUI archiver is registered.
- **`hyprland.lua`** comments translated to English.

### Added
- `installer/dev/gen_keyhints.py` — regenerates `KeyHints.lua` from
  `keybinds.lua` using a paren-balanced Lua parser. Handles
  `mod .. " + B"` concatenation patterns, the `for i = 1, N` loop
  shortcut (emits a single `SUPER + [1-9]` entry), and a `--check`
  mode for CI.
- `installer/manifests/hyprpm.toml` — declarative plugin list
  (single source of truth; `bootstrap.lua` mirrors it inline to avoid
  Python imports at compositor startup).

### Removed
- Root-level `gabrln` wrapper script (dead, dispatched to an
  already-deleted target).
- `xdg-user-dirs-gtk` and the `qt5ct/qt5ct` circular symlink.
- `installer/logs/` shipped logs (gitignored going forward).

### Validation
- `Hyprland --verify-config` on the full config: "config ok".
- `lua loadfile(...)` on all 4 scripts in `~/.config/hypr/scripts/`: OK.
- pcall on `hl.dsp.layout("+col")`, `"colresize toend"`, `"fit active"`,
  `"swapnext"`, etc.: all valid in Hyprland 0.55+.
- 9 commits, +727 / -268 lines.

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

