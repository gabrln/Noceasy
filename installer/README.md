# Framework de instalação — guia do contribuidor

Documentação interna do framework Python (`installer/`).
Para uso normal, leia o `README.md` da raiz.

## Visão geral

```
install.sh (bash, ~140 linhas)
  └─ detecção de arch, OS, python, rich
  └─ git clone/pull com GABRLN_VERSION + GABRLN_SHA256
  └─ exec python3 -m installer

python3 -m installer
  └─ cli.py: parse flags
  └─ logger.py: setup logging
  └─ errors.py: signal traps, cleanup
  └─ privilege.py: detect_real_user, setup_polkit_policy
  └─ runner.py: ModuleRunner
       └─ for module in build_default_pipeline():
            ├─ state.is_up_to_date? → skip
            ├─ --dry-run? → log step, return
            └─ module.run(ctx) + state.mark_done
```

## Bibliotecas

| Arquivo | Responsabilidade |
|---|---|
| `cli.py` | argparse, main(), help |
| `config.py` | Paths (REPO_DIR, INSTALLER_DIR, etc), loader de config.toml |
| `logger.py` | Rich-based logging com NO_COLOR, TTY, níveis |
| `errors.py` | `fatal()`, `install_signal_handlers()`, cleanup hooks |
| `privilege.py` | `run_as_user`, `detect_real_user`, `setup_polkit_policy`, `cleanup_polkit_policy` |
| `toml_cache.py` | `TomlCache` em memória (chamado 1x por manifesto) |
| `state.py` | `State` (state.json com flock + os.replace atômico) |
| `backup.py` | `create`, `restore`, `list_snapshots`, retenção |
| `progress.py` | `make_progress` (Rich Progress TTY-aware) |
| `runner.py` | `ModuleRunner` (loop de 16 módulos) |

## Como adicionar um módulo

1. Criar `installer/modules/mNN_nome.py` com uma classe que herda de `Module`.
2. Adicionar a classe em `build_default_pipeline()` em `installer/modules/__init__.py`.
3. Se o módulo lê um manifesto, declare `manifest = "nome.toml"` na classe.

### Esqueleto de módulo

```python
from installer.modules.base import Module, RunContext
from installer.logger import log

class MyModule(Module):
    name = "NN-my-module"
    manifest = "my-manifest.toml"  # opcional

    def run(self, ctx: RunContext) -> None:
        log("info", "Iniciando ...")
        # ctx.real_user, ctx.user_home, ctx.state
        # raise Exception em caso de erro
        log("success", "Concluído.")
```

**Convenções:**
- Use `log("info"|"warn"|"error"|"success"|"step"|"debug", msg)`.
- Use `ctx.real_user` em vez de `os.environ["SUDO_USER"]`.
- Use `is_command()`, `pkg_installed()`, `systemd_unit_exists()` para checks.
- Use `run_as_user(cmd, user=ctx.real_user)` para drop de privilégio.
- Se o módulo tem side-effects perigosos, use o flag `--dry-run` via `self.dry_run` (ou apenas skip com `return` em `pre_check`).
- O state (skip-if-done) é gerenciado pelo `Runner` automaticamente baseado no `manifest`.

## Como adicionar um manifesto

1. Criar `installer/manifests/nome.toml` com a estrutura que fizer sentido.
2. No módulo, ler via `get_cache().get(...)`, `get_list(...)`, `get_list_field(...)`.

```python
from installer.toml_cache import get_cache
data = get_cache().load("nome.toml")
pkgs = get_cache().get_list_field("nome.toml", "packages", "name")
val = get_cache().get("nome.toml", "section.key", default=None)
```

## Polkit policy

Templates em `installer/polkit/`:

- `99-arch-gabrln-installer.rules` — regra JS (renderizada com `@REAL_USER@` substituído).
- `org.archlinux.pkexec.gabrln.policy` — metadata da action.
- `gabrln-helper` — binary em `/usr/local/bin/` invocado via `pkexec`.

`gabrln-helper` aceita subcomandos: `refresh-icon-cache`, `update-hyprpm`, `enable-service`, `restart-user-service`, `set-shell`.

Para adicionar um subcomando, edite `installer/polkit/gabrln-helper` e adicione um novo `case` no dispatch.

## Validação

```bash
# Sintaxe Python
python3 -c "import ast, pathlib; [ast.parse(p.read_text()) for p in pathlib.Path('installer').rglob('*.py')]"

# Help
NO_COLOR=1 python3 -m installer --help

# Verificar pipeline
PYTHONPATH=./_mock python3 -c "from installer.modules import build_default_pipeline; print(len(build_default_pipeline()))"

# Dry-run (precisa root)
NO_COLOR=1 sudo python3 -m installer --dry-run
```

## Fluxo de erro

```
módulo.run() raise Exception
  ↓
Runner captura, state.mark_failed()
  ↓
errors.fatal("Módulo X falhou: ...")
  ↓
run_cleanup() (polkit rules + log file close)
  ↓
sys.exit(1)
```

`is_benign_exit(code)` em `errors.py` filtra exit codes benignos (1, 2, 3, 64, 130, 141) que não devem disparar cleanup pesado.

## Migrando do bash

Se você está portando um módulo bash para Python:

| Bash | Python |
|---|---|
| `log_info "msg"` | `log("info", "msg")` |
| `log_warn "msg"` | `log("warn", "msg")` |
| `is_command x` | `is_command("x")` (from `mixins`) |
| `pacman -Q x` | `pkg_installed("x")` |
| `run_as_user "cmd"` | `run_as_user("cmd", user=ctx.real_user)` |
| `toml_get f k default` | `get_cache().get("f.toml", "k", default)` |
| `state_mark_done m` | (automático no `Runner`) |
| `exit_with_error "msg"` | `raise Exception("msg")` |
