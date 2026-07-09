# Framework de instalação — guia do contribuidor

Esta documentação descreve como o framework `gabrln` funciona internamente
e como adicionar/modificar módulos.

## Visão geral

```
curl | sudo bash install.sh
   ↓
install.sh (bootstrap)
   ↓ clone/pull + chown
   ↓
exec installer/gabrln
   ↓
source lib/{logger,utils,errors,state,backup,progress}.sh
   ↓
setup_traps → detect_real_user → setup_polkit_policy → init_framework
   ↓
for module in MODULES[]: run_module "$name" "$manifest"
   ↓ (cada módulo é sourced e compartilha o shell)
   ↓
progress_done → log_success
   ↓
trap EXIT → run_cleanup (polkit rules + toml cache)
```

## Bibliotecas

Todas as bibliotecas usam o guard `_LIB_*_SH=1` para evitar re-source.

### `lib/logger.sh`

Logging estruturado. Toda função grava no `LOG_FILE` e imprime colorido no TTY.

```bash
log_init <dir>            # cria <dir>/gabrln-TS.log
log_info|warn|error|success|step|debug|cmd "msg"
```

Honra: `NO_COLOR`, `TERM=dumb`, `-t 1 && -t 2`, `QUIET`, `VERBOSE`.

### `lib/utils.sh`

Helpers genéricos. Os mais usados pelos módulos:

```bash
detect_real_user                # exige root + SUDO_USER; seta REAL_USER/USER_HOME
run_as_user "cmd"               # runuser -u REAL_USER -- bash -lc "cmd"
run_as_user_fast "cmd"          # runuser -u REAL_USER -- bash -c "cmd" (sem login shell)
is_command <bin>                # command -v
has_internet                    # curl -fsSI https://github.com
has_free_space [min_bytes]      # df -B1 em $USER_HOME e /
toml_get <file> <key> [default]   # valor único, com cache
toml_list <file> <key>            # lista de strings, sem cache
toml_list_get <file> <key> <field> # campo específico de uma lista de tabelas
chown_user_path <path>          # mkdir + chown do user real
pkg_installed <pkg>             # pacman -Q
systemd_unit_exists <unit>      # systemctl list-unit-files
cachyos_installed_kernels       # lista linux-cachyos* instalados
```

### `lib/errors.sh`

```bash
setup_traps                       # registra ERR/EXIT/INT/TERM/HUP
run_cleanup                       # itera _CLEANUP_HOOKS
register_cleanup "cmd"            # adiciona hook
exit_with_error "msg" [code]      # log_error + run_cleanup + exit
is_benign_exit <code>             # 1, 2, 3, 64, 130, 141 são benignos
setup_polkit_policy               # instala rules + policy + gabrln-helper
```

### `lib/state.sh`

`state.json` é escrito atomicamente (temp file + `os.replace`) e serializado
com `flock` (5s timeout). Permissões 0600.

```bash
state_init <dir>                  # cria state.json (vazio se não existe)
state_is_up_to_date <mod> [manifest]  # 0 se já done com mesmo hash
state_mark_done <mod> [manifest]       # status=done + manifest_hash + ts
state_mark_failed <mod> <reason>       # status=failed (debug)
state_get|set <mod> <field> [value]    # acesso granular
state_clear <mod>                       # remove entrada
```

### `lib/backup.sh`

Snapshots com timestamp. `backup_create` retorna o nome em stdout (logs em
stderr), então use `name=$(backup_create "label" paths...)`.

```bash
backup_init <dir>                # mkdir, lê flags.max_backups
backup_create <label> <paths...> # copia com colisão .1/.2, retenção
backup_list                      # snapshots existentes (mais recente primeiro)
backup_restore <label>           # interativo, restore atômico via staging
```

### `lib/progress.sh`

Barra de progresso TTY-aware.

```bash
progress_init <total> [label]    # label vira prefixo "[label]"
progress_step "msg"              # avança e loga
progress_done ["msg"]            # log_success "msg (N/TOTAL)"
```

## Como adicionar um módulo

1. Criar `installer/modules/NN-nome.sh` (NN = próximo número livre).
2. Adicionar em `MODULES=()` no `installer/gabrln`:
   ```bash
   "NN-nome"                  # sem manifesto
   "NN-nome:manifesto.toml"   # com manifesto (cache por hash)
   ```
3. O módulo é `source`d (não executado), então herda `set -e`, todas as
   vars exportadas, e funções de todas as libs.

### Esqueleto de módulo

```bash
#!/usr/bin/env bash
# NN-nome.sh - Descrição curta

log_info "Iniciando ..."

# Pré-condições
if ! is_command algumacoisa; then
  log_warn "algumacoisa não está instalado. Pulando."
  return 0
fi

# Trabalho principal
run_as_user "comando como usuario"

# Sucesso — return 0 implícito
log_success "Módulo concluído."
```

**Convenções:**
- Use `log_*` para output (nunca `echo` direto).
- Use `run_as_user` para comandos que precisam de UID do user.
- Use `run_as_user_fast` para evitar o overhead de login shell.
- Use `chown_user_path` em vez de `chown -R` em paths do user.
- Se o módulo tem manifesto, edite o manifesto — o hash é a chave de cache.
- Se o módulo não tem side-effects perigosos, considere suportar `--dry-run`
  via `[[ "$DRY_RUN" -eq 1 ]]` e `return 0`.

## Como adicionar um manifesto

1. Criar `installer/manifests/nome.toml` com a estrutura que fizer sentido.
2. No módulo, ler via `toml_get` / `toml_list` / `toml_list_get`.
3. Adicionar o path em `MODULES=()` com `:nome.toml`.

## Polkit policy

A polkit policy é renderizada a partir de templates em `installer/polkit/`:

- `99-arch-gabrln-installer.rules` — regra JS (`@REAL_USER@` é substituído).
- `org.archlinux.pkexec.gabrln.policy` — metadata da action.
- `gabrln-helper` — binary em `/usr/local/bin/` invocado via `pkexec`.

`gabrln-helper` aceita:

```bash
pkexec gabrln-helper refresh-icon-cache
pkexec gabrln-helper update-hyprpm
pkexec gabrln-helper enable-service <unit>
pkexec gabrln-helper restart-user-service <unit>
pkexec gabrln-helper set-shell <user> [shell]
```

Para adicionar um subcomando, edite `installer/polkit/gabrln-helper` e
adicione um novo `case` no dispatch.

## Testes

Validar sintaxe:
```bash
for f in installer/gabrln installer/lib/*.sh installer/modules/*.sh install.sh installer/polkit/gabrln-helper; do
  bash -n "$f" || echo "FAIL: $f"
done
```

Validar help:
```bash
NO_COLOR=1 ./installer/gabrln --help
```

Dry-run sem root falha (esperado):
```bash
NO_COLOR=1 ./installer/gabrln --dry-run
# → [ERROR] Este comando deve ser executado com sudo.
```

Dry-run com root (precisa de sudo sem senha):
```bash
sudo NO_COLOR=1 ./installer/gabrln --dry-run
# → simula os 16 módulos
```

## Fluxo de erro

```
módulo falha (exit != 0)
  ↓
run_module captura rc
  ↓
state_mark_failed <mod> "exit <rc>"
  ↓
exit_with_error "Módulo <mod> falhou..."
  ↓
run_cleanup (polkit rules + toml cache)
  ↓
exit 1
```

`trap ERR _error_handler` em `errors.sh` filtra exit codes benignos
(1, 2, 3, 64, 130, 141) para não rodar cleanup pesado em falso positivo.
