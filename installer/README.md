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
   ├─ privilege.py                 runuser + polkit
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
| `privilege.py` | run_as_user, polkit install/cleanup |
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

## Polkit helper

`installer/polkit/noceasy-helper` is installed at `/usr/local/bin/`
and is invokable via `pkexec noceasy-helper <subcommand>`. The
polkit policy (`/etc/polkit-1/rules.d/99-noceasy-installer.rules`)
auto-approves the real user (set in the install bootstrap).

Subcommands: `refresh-icon-cache`, `update-hyprpm`, `enable-service`,
`restart-user-service`, `set-shell`.

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
run_cleanup() (polkit rules + log file close)
  ↓
sys.exit(1)
```
