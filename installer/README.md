# Noceasy — internal docs

Framework internals. For end-user docs see [README.md](../README.md).

## Layout

```
install.sh                          bash bootstrap
└─ python3 -m installer
   ├─ cli.py                       argparse
   ├─ config.py                    paths, constants
   ├─ logger.py                    Rich logging
   ├─ errors.py                    traps, fatal, InstallerError
   ├─ exec.py                      run() subprocess helper
   ├─ privilege.py                 runuser, real-user detection
   ├─ toml_cache.py                manifests in memory
   ├─ state.py                     state.json atomic (flock)
   ├─ backup.py                    snapshot .1/.2 collision
   ├─ progress.py                  Rich Progress
   ├─ runner.py                    ModuleRunner
   └─ modules/                     16 install steps
```

## Pin and verify

```bash
# Pin a tag
sudo NOCEASY_VERSION=v0.1.0 bash install.sh

# Pin + verify commit SHA
sudo NOCEASY_VERSION=v0.1.0 NOCEASY_SHA256=5ba80b0... bash install.sh
```

`NOCEASY_VERSION` ensures `git clone` pulls that exact tag (no surprises).
`NOCEASY_SHA256` validates the commit SHA after clone (defense against
GitHub compromise). Both are optional; the defaults are `main` and
"no check".

## Library quick reference

| File | Responsibility |
|---|---|
| `cli.py` | argparse, main() |
| `config.py` | paths, config.toml, tunable constants |
| `logger.py` | Rich logging with NO_COLOR/TTY/levels |
| `errors.py` | fatal(), signal handlers, InstallerError hierarchy |
| `exec.py` | run(), run_capture(), run_or_die() |
| `privilege.py` | run_as_user, detect_real_user |
| `toml_cache.py` | in-memory manifest cache |
| `state.py` | state.json (flock + os.replace atomic) |
| `backup.py` | snapshot, restore, retention |
| `progress.py` | Rich Progress bar |
| `runner.py` | ModuleRunner loop |

## Add a module

1. Create `installer/modules/mNN_name.py` with a `Module` subclass.
2. Register it in `build_default_pipeline()` in `installer/modules/__init__.py`.

```python
from installer.errors import ModuleFailure
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext


class MyModule(Module):
    name = "NN-my-module"
    manifest = "my-manifest.toml"  # optional

    def run(self, ctx: RunContext) -> None:
        log("info", "Starting ...")
        proc = run(["some-command"])
        if proc.returncode != 0:
            raise ModuleFailure(self.name, f"some-command failed")
        log("success", "Done.")
```

## Dev tools

Module `m17_dev_tools` syncs every `*.py` in `installer/dev/` to
`~/.local/bin/<stem>` (the `.py` extension is stripped and the
target is made executable). The dev scripts are versioned in the
repo but installed system-wide, so they appear on `$PATH` for the
real user and survive `git pull` (next `install.sh` re-syncs).

Currently shipped:

- `gen_keyhints` — regenerates `~/.config/hypr/scripts/KeyHints.lua`
  from `keybinds.lua`. Usage:
  ```bash
  gen_keyhints                   # uses ~/Projects/Noceasy
  gen_keyhints --repo ~/dotfiles # custom repo path
  NOCEASY_REPO=~/dotfiles gen_keyhints --check  # CI / pre-commit
  ```

To add another dev tool, drop a `*.py` file with a `#!/usr/bin/env python3`
shebang into `installer/dev/`; it will be picked up on the next
`install.sh` run. The module is a no-op when the directory is empty.

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
run_cleanup() (log file close)
  ↓
sys.exit(1)
```

## Troubleshooting

| Error | Fix |
|---|---|
| `Unsupported distribution` | Only Arch and CachyOS are supported. |
| `Python 3.11+ required` | `pacman -S python` (Arch) or update your base. |
| `python-rich not found` | `pacman -S python-rich`. The bootstrap installs it automatically when missing, but a sandboxed install can fail silently. |
| `pacman: unable to find linux-cachyos` | You're on Arch, not CachyOS — the manifest filters these packages out automatically. Harmless. |
| `RuntimeError: hl.exec (no such field)` or `hl.exec: not a function` | The hyprland config (or a script under `~/.config/hypr/scripts/`) is calling a function that does not exist in your installed Hyprland version. The version on `main` targets Hyprland 0.55+; older versions need the legacy `bind = ...` syntax. |
| Stale `installer/state/state.json` blocks a re-run | Delete the file: `sudo rm installer/state/state.json` (or run `python3 -m installer --force`). |
| Logs in `installer/logs/` | Look for the most recent `installer-YYYYMMDD-HHMMSS.log`. Each curl-tool install also writes its own log named `curl-tools-<name>-<pid>.log`. |
