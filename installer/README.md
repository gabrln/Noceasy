# Framework Arch-gabrln — guia técnico

Documentação técnica do instalador. Cobre arquitetura, módulos,
manifestos, polkit, customização e contribuição.

## Instalação (para o usuário)

```bash
# Última versão do branch main
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo bash
```

### Pinar versão (opcional)

Por padrão, o `install.sh` clona o branch `main`. Se você quiser fixar
uma versão específica (por exemplo, antes de replicar o install em
várias máquinas, ou para garantir reprodutibilidade), use:

```bash
# Fixa na tag v1.5.0
sudo GABRLN_VERSION=v1.5.0 bash install.sh
```

A tag é verificada no GitHub antes do clone. Se não existir, o install
falha com mensagem clara. Isso **não** protege contra o GitHub ser
comprometido (ver SHA256 abaixo).

### Verificar SHA256 do commit (opcional, supply chain)

Se você quer garantia extra de que o código que roda na sua máquina é
exatamente o que você espera (e não um commit injetado por ataque ao
GitHub), passe o SHA256 do commit esperado:

```bash
sudo GABRLN_VERSION=v1.5.0 GABRLN_SHA256=abc123... bash install.sh
```

O install:
1. Faz clone **completo** (sem `--depth=1`) para que o SHA seja alcançável.
2. Após checkout, calcula `git rev-parse HEAD`.
3. Compara com o valor de `GABRLN_SHA256`. Se diferente, aborta.

O SHA pode ser obtido em https://github.com/gabrln/Arch-gabrln/commits/main
ou via `git rev-parse main` localmente.

## Flags do framework

| Flag | Efeito |
|---|---|
| `--dry-run` | Simula sem modificar nada |
| `--verbose` | Habilita logs DEBUG |
| `--quiet` | Suprime INFO, mantém ERROR/STEP |
| `--force` | Re-executa módulos já concluídos |
| `--no-color` | Desabilita saída colorida |
| `-h`, `--help` | Mostra ajuda |

Variáveis de ambiente: `NO_COLOR=1`, `GABRLN_VERSION`, `GABRLN_SHA256`.

## Arquitetura

```
install.sh                          # bash bootstrap (~140 linhas)
└─ python3 -m installer            # framework Python
   ├─ cli.py                       # argparse
   ├─ config.py                    # paths, config.toml
   ├─ logger.py                    # Rich-based logging
   ├─ errors.py                    # signal traps, cleanup
   ├─ privilege.py                 # runuser + polkit
   ├─ toml_cache.py                # manifests in-memory
   ├─ state.py                     # state.json atômico (flock)
   ├─ backup.py                    # snapshot com colisão .1/.2
   ├─ progress.py                  # Rich Progress
   ├─ runner.py                    # ModuleRunner
   └─ modules/                     # 16 módulos
      ├─ base.py                   # Module + RunContext
      ├─ mixins.py                 # helpers compartilhados
      ├─ preflight.py              # 00
      ├─ m01_backup.py             # 01
      ├─ m02_pacman_bootstrap.py   # 02
      ├─ m03_pacman_official.py    # 03
      ├─ m04_yay_aur.py            # 04
      ├─ m05_flatpak.py            # 05
      ├─ m06_curl_tools.py         # 06
      ├─ m07_shell.py              # 07
      ├─ m08_dotfiles.py           # 08
      ├─ m09_hyprland_env.py       # 09
      ├─ m10_greeter.py            # 10
      ├─ m11_keyring.py            # 11
      ├─ m13_wallpapers.py         # 13
      ├─ m14_icons_cursors_fonts.py # 14
      ├─ m15_system_tweaks.py      # 15
      └─ m16_services.py           # 16
```

### Como o privilégio é gerenciado

- **Bootstrap** (`install.sh`): precisa de `sudo bash` porque polkit não tem agent no TTY de login.
- **Durante o install**: já somos root. Para executar como o usuário real, usamos `runuser -u REAL_USER --` (substitui `sudo -u`).
- **Helpers invocados pelo user**: polkit policy em `/etc/polkit-1/rules.d/99-arch-gabrln-installer.rules` libera `pkexec gabrln-helper` para o `REAL_USER` sem prompt de senha. A regra é instalada em tempo de install e removida no `EXIT`.
- **`sudo -u`, `sudo -E`, `NOPASSWD` sudoers**: **não existem no framework**.

### Idempotência

Cada módulo é pulado se o manifesto correspondente não mudou (hash SHA256 em `installer/state/state.json`). Use `--force` para re-executar tudo.

### Logs

Cada execução grava em `installer/logs/installer-YYYYMMDD-HHMMSS.log` com timestamps e níveis.

## Módulos

Os 16 módulos são executados em ordem fixa. O campo `manifest` indica o arquivo TOML usado como chave de cache.

| # | Módulo | Manifesto | O que faz |
|---|---|---|---|
| 00 | `preflight` | — | Conectividade, espaço em disco, log de contexto |
| 01 | `backup` | `dotfiles.toml` | Snapshot `pre-install` das configs |
| 02 | `pacman-bootstrap` | — | `pacman -Sy` + `git`/`base-devel`/`zsh` + `yay` |
| 03 | `pacman-official` | `packages.toml` | `pacman -T` filtra, instala faltantes, filtra `linux-cachyos*` |
| 04 | `yay-aur` | `aur.toml` | Chunks de 50 via xargs, fallback per-pkg |
| 05 | `flatpak` | `flatpak.toml` | `flatpak remote-add` + install com retry+backoff |
| 06 | `curl-tools` | `curl-tools.toml` | Tools via `curl|bash` com wrapper em mktemp |
| 07 | `shell` | `zsh-plugins.toml` | `chsh -s /usr/bin/zsh` + plugins com 3 retries |
| 08 | `dotfiles` | `dotfiles.toml` | Backup-then-replace via staging, preserva `~/.config/zsh/plugins/` |
| 09 | `hyprland-env` | — | `chmod +x` em `*/scripts/*`, valida `hyprland.lua` |
| 10 | `greeter` | — | `useradd greeter`, copia `/etc/greetd/*` com backup |
| 11 | `keyring` | — | Insere `pam_gnome_keyring.so` após ÚLTIMA linha auth/session |
| 13 | `wallpapers` | `wallpapers.toml` | GDrive (UUID+confirm), SHA256 opcional, aria2c fallback |
| 14 | `icons-cursors-fonts` | — | `fc-cache -fv`, `gtk-update-icon-cache` |
| 15 | `system-tweaks` | — | Chown cirúrgico, symlinks `/root/.config/gtk-*` |
| 16 | `services` | `services.toml` | `systemctl enable` com check de unit existente |

## Manifestos

| Arquivo | Conteúdo |
|---|---|
| `packages.toml` | Pacotes `pacman` (oficial CachyOS) |
| `aur.toml` | Pacotes AUR via yay (noctalia-git, noctalia-greeter-git, bibata-cursor-theme-bin) |
| `flatpak.toml` | Remoto flathub + pacotes (easyeffects) |
| `curl-tools.toml` | Tools via `curl|bash` (agy, pi-coding-agent, herdr) |
| `zsh-plugins.toml` | Plugins clonados via git |
| `dotfiles.toml` | Diretórios de config, files avulsos, dirs XDG extras |
| `wallpapers.toml` | `source.file_id` (Google Drive), `source.sha256` opcional |
| `services.toml` | Systemd services a habilitar |

## Configuração (`installer/config.toml`)

```toml
[paths]          # logs, state, backups, manifests, modules
[install]        # bootstrap_packages, min_free_space
[flags]          # skip_up_to_date, auto_backup, max_backups
[features]       # wallpapers, enable_polkit_helper
```

## Customização

- **Pacotes**: edite `installer/manifests/packages.toml` (oficial) ou `aur.toml` (AUR).
- **Dotfiles**: edite `installer/manifests/dotfiles.toml` + coloque os arquivos em `.config/<nome>` no repo.
- **Wallpapers**: troque `source.file_id` em `wallpapers.toml` (link compartilhado do Google Drive).
- **Serviços**: edite `services.toml`.
- **Polkit helper**: edite `installer/polkit/gabrln-helper` para adicionar subcomandos.

## Estado e backups

- `installer/state/state.json` — controle de quais módulos já rodaram.
- `installer/state/backups/` — snapshots `pre-install-TS/`. Retenção via `flags.max_backups`.
- `installer/logs/` — log estruturado de cada execução.

## Bibliotecas (referência rápida)

| Arquivo | Responsabilidade |
|---|---|
| `cli.py` | argparse, main(), help |
| `config.py` | Paths (REPO_DIR, INSTALLER_DIR, etc), loader de config.toml, tunable constants |
| `logger.py` | Rich-based logging com NO_COLOR, TTY, níveis |
| `errors.py` | `fatal()`, `install_signal_handlers()`, cleanup hooks, `InstallerError` hierarchy |
| `exec.py` | `run()`, `run_capture()`, `run_or_die()` subprocess helpers |
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
from installer.errors import ModuleFailure
from installer.exec import run
from installer.logger import log
from installer.modules.base import Module, RunContext


class MyModule(Module):
    name = "NN-my-module"
    manifest = "my-manifest.toml"  # optional

    def pre_check(self, ctx: RunContext) -> bool:
        # Return False to skip. Use for preconditions.
        return True

    def run(self, ctx: RunContext) -> None:
        log("info", "Starting ...")
        # Use run() for subprocess, run_as_user() for drop privilege.
        # Raise ModuleFailure on error for clean reporting.
        proc = run(["some-command", "--flag"])
        if proc.returncode != 0:
            raise ModuleFailure(self.name, f"some-command failed: {proc.stderr}")
        log("success", "Done.")
```

**Conventions:**
- Use `log("info"|"warn"|"error"|"success"|"step"|"debug", msg)`.
- Use `ctx.real_user` instead of `os.environ["SUDO_USER"]`.
- Use `is_command()`, `pkg_installed()`, `systemd_unit_exists()` for checks.
- Use `run_as_user(cmd, user=ctx.real_user)` to drop privileges.
- Use `run(argv)` for subprocess calls (in `installer/exec.py`).
- Raise `ModuleFailure(self.name, reason)` on clean failures.
- The state (skip-if-done) is managed by the `Runner` automatically based on `manifest`.

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

## Validation

```bash
# Python syntax
python3 -c "import ast, pathlib; [ast.parse(p.read_text()) for p in pathlib.Path('installer').rglob('*.py')]"

# Help
NO_COLOR=1 python3 -m installer --help

# Verify pipeline
python3 -c "from installer.modules import build_default_pipeline; print(len(build_default_pipeline()))"

# Dry-run (needs root)
NO_COLOR=1 sudo python3 -m installer --dry-run
```

## Error flow

```
module.run() raises Exception (or ModuleFailure)
  ↓
Runner catches it, state.mark_failed(module, reason)
  ↓
errors.fatal("Module X failed: ...")
  ↓
run_cleanup() (polkit rules + log file close)
  ↓
sys.exit(1)
```

`is_benign_exit(code)` in `errors.py` filters benign exit codes
(1, 2, 3, 64, 130, 141) that should not trigger heavy cleanup.
