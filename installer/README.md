# Noceasy — internal docs

Framework internals. For end-user docs see [README.md](../README.md).

## Layout

```
install.sh                          bash bootstrap
└─ python3 -m installer
   ├─ cli.py                       argparse
   │
   ├─ core/                        execution engine & configuration
   │   ├─ config.py                paths, constants, config.toml loader
   │   ├─ errors.py                traps, fatal, InstallerError
   │   ├── runner.py               ModuleRunner loop
   │   └── state.py                state.json atomic (flock)
   │
   ├─ infra/                       I/O against external resources
   │   ├── backup.py               snapshot .1/.2 collision
   │   ├── exec.py                 run() subprocess helper
   │   └── toml_cache.py           manifests in memory
   │
   ├─ platform/                    OS / environment specific
   │   ├── privesc.py              on-demand privilege escalation
   │   └── user.py                 detect_real_user()
   │
   ├─ ui/                          user interface
   │   ├── logger.py               Rich logging
   │   └── progress.py             Rich Progress, prompt_password()
   │
   └─ modules/                     16 install steps
```

The installer runs as the **real user** — privilege escalation is
handled per-operation by `privesc.run_privileged()`, which auto-detects
`sudo`/`doas`/`run0` and asks for the password once at startup. The
user never needs to invoke the installer with `sudo`.

## Library quick reference

| Module | Path | Responsibility |
|---|---|---|
| `cli.py` | `installer/cli.py` | argparse, main() |
| `config.py` | `installer/core/config.py` | paths, config.toml, tunable constants |
| `errors.py` | `installer/core/errors.py` | fatal(), register_cleanup(), signal handlers, InstallerError hierarchy |
| `runner.py` | `installer/core/runner.py` | ModuleRunner loop |
| `state.py` | `installer/core/state.py` | state.json (flock + os.replace atomic) |
| `exec.py` | `installer/infra/exec.py` | run(), run_capture(), run_or_die() |
| `toml_cache.py` | `installer/infra/toml_cache.py` | in-memory manifest cache |
| `backup.py` | `installer/infra/backup.py` | snapshot, restore, retention |
| `privesc.py` | `installer/platform/privesc.py` | Tool enum, detect(), check_cached(), validate_password(), run_privileged() |
| `user.py` | `installer/platform/user.py` | detect_real_user() — resolves uid → (user, home) |
| `logger.py` | `installer/ui/logger.py` | Rich logging with NO_COLOR/TTY/levels |
| `progress.py` | `installer/ui/progress.py` | Rich Progress bar, prompt_password() |

## Module pipeline

The 16 modules run in this order (defined in `build_default_pipeline()`):

| #  | Module | Name | Manifest | Responsibility |
|----|--------|------|----------|----------------|
| 00 | `PreflightModule` | `00-preflight` | — | Internet, disk space, env checks |
| 01 | `BackupModule` | `01-backup` | `dotfiles.toml` | Snapshot configs before overwriting |
| 02 | `PacmanBootstrapModule` | `02-pacman-bootstrap` | — | Sync pacman, install git/base-devel/yay |
| 03 | `PacmanOfficialModule` | `03-pacman-official` | `packages.toml` | Install official repo packages |
| 04 | `YayAurModule` | `04-yay-aur` | `aur.toml` | Install AUR packages via yay |
| 05 | `FlatpakModule` | `05-flatpak` | `flatpak.toml` | Install Flatpak packages |
| 07 | `ShellModule` | `07-shell` | `zsh-plugins.toml` | chsh → zsh, clone plugins |
| 08 | `DotfilesModule` | `08-dotfiles` | `dotfiles.toml` | Apply `.config/` and avulso files |
| 09 | `HyprlandEnvModule` | `09-hyprland-env` | — | chmod scripts, validate hyprland.lua |
| 10 | `GreeterModule` | `10-greeter` | — | Deploy greetd / Noctalia Greeter |
| 11 | `KeyringModule` | `11-keyring` | — | Inject gnome-keyring into PAM |
| 13 | `WallpapersModule` | `13-wallpapers` | `wallpapers.toml` | Download wallpaper pack |
| 14 | `IconsCursorsFontsModule` | `14-icons-cursors-fonts` | — | fc-cache, gtk icon cache |
| 15 | `SystemTweaksModule` | `15-system-tweaks` | — | Root theme symlinks, orphans cleanup |
| 16 | `ServicesModule` | `16-services` | `services.toml` | Enable systemd services |
| 17 | `DevToolsModule` | `17-dev-tools` | — | Sync `installer/dev/` → `~/.local/bin` |

The module numbering is historical; gaps (06, 12) correspond to
modules that were removed. The pipeline order is defined in
`installer/modules/__init__.py`.

## Add a module

1. Create `installer/modules/mNN_name.py` with a `Module` subclass.
2. Register it in `build_default_pipeline()` in `installer/modules/__init__.py`.

```python
from installer.platform import privesc
from installer.core.errors import ModuleFailure
from installer.infra.exec import run
from installer.ui.logger import log
from installer.modules.base import Module, RunContext


class MyModule(Module):
    name = "NN-my-module"
    manifest = "my-manifest.toml"  # optional

    def run(self, ctx: RunContext) -> None:
        log("info", "Starting ...")

        # Non-privileged — use exec.run()
        proc = run(["some-command"])
        if proc.returncode != 0:
            raise ModuleFailure(self.name, "some-command failed")

        # Privileged — use privesc.run_privileged()
        proc = privesc.run_privileged(
            ["pacman", "-S", "--needed", "--noconfirm", "pkg"],
            ctx.sudo_password,
        )
        if proc.returncode != 0:
            raise ModuleFailure(self.name, "privileged command failed")

        log("success", "Done.")
```

## Dev tools

Module `m17_dev_tools` syncs every `*.py` in `installer/dev/` to
`~/.local/bin/<stem>` (the `.py` extension is stripped and the
target is made executable). The dev scripts are versioned in the
repo but installed system-wide, so they appear on `$PATH` for the
real user and survive `git pull` (next `install.sh` re-syncs).

If `installer/dev/` is empty, the module is a no-op.
## Validation

```bash
# Python syntax
python3 -c "import ast, pathlib; [ast.parse(p.read_text()) for p in pathlib.Path('installer').rglob('*.py')]"

# Help
NO_COLOR=1 python3 -m installer --help

# Verify pipeline
python3 -c "from installer.modules import build_default_pipeline; print(len(build_default_pipeline()))"
```

## Error flow

```
module.run() raises Exception (or ModuleFailure)
  ↓
Runner catches, state.mark_failed(module, reason)
  ↓
errors.fatal(...)
  ↓
run_cleanup() — runs all hooks registered via register_cleanup()
  e.g. register_cleanup(tui.stop) ensures the Rich TUI is
  torn down even when fatal() raises SystemExit
  ↓
sys.exit(1)
```

## Troubleshooting

| Error | Fix |
|---|---|
| `Unsupported distribution` | Only Arch and CachyOS are supported. |
| `Python 3.11+ required` | `pacman -S python` (Arch) or update your base. |
| `python-rich not found` | `pacman -S python-rich`. The bootstrap installs it automatically when missing, but a sandboxed install can fail silently. |
| `No privilege-escalation tool found` | Install `sudo`, `doas`, or ensure `run0` (systemd ≥ 256) is available. The installer auto-detects which one is present. |
| `Falha na validação da senha` | The password was rejected. Re-run and enter the correct password for your user. |
| `no cached credentials and no password provided` | A privileged command needs root but no password was supplied. This typically means `check_cached()` returned False and no password was passed. Re-run the installer. |
| `pacman: unable to find linux-cachyos` | You're on Arch, not CachyOS — the manifest filters these packages out automatically. Harmless. |
| `RuntimeError: hl.exec (no such field)` or `hl.exec: not a function` | The hyprland config (or a script under `~/.config/hypr/scripts/`) is calling a function that does not exist in your installed Hyprland version. The version on `main` targets Hyprland 0.55+; older versions need the legacy `bind = ...` syntax. |
| Stale `installer/state/state.json` blocks a re-run | Delete the file: `rm installer/state/state.json` (or run `python3 -m installer --force`). No sudo needed — the state file is owned by the user. |
| Logs in `installer/logs/` | Look for the most recent `installer-YYYYMMDD-HHMMSS.log`. |
