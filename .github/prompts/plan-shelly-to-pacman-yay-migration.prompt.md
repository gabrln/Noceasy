# Plano de implementação: migração shelly → pacman + yay

**Repo:** Arch-gabrln · **Escopo:** `installer/modules/02-*` a `06-*`, `installer/config.toml`, `installer/manifests/*.toml`, `README.md`

## 0. Premissas confirmadas (não presumidas)

- `yay` é empacotado oficialmente no repo `cachyos` (mesmo repo de onde vem `linux-cachyos`), mantido pela própria CachyOS. **Não precisa de bootstrap via AUR/makepkg** — é `pacman -S yay` direto. Fonte: `packages.cachyos.org/package/cachyos/x86_64/yay`.
- `shelly` também é pacote oficial do repo `cachyos` (é inclusive o gerenciador gráfico padrão desde abril/2026). Isso sugere que o bootstrap atual via AUR (`shelly-bin`, clone+`makepkg -si`) em `02-pacman-bootstrap.sh` já era desnecessariamente complexo — poderia ter sido `pacman -S shelly` o tempo todo.
- Não há confirmação de que `shelly install --no-confirm pkg1 pkg2...` falha silenciosamente em pacotes individuais dentro de um lote — não achei documentação que descreva esse comportamento. O que É verificável é estrutural: o script só olha o exit code agregado do lote, nunca por pacote. A migração remove essa ambiguidade independente da causa raiz real.
- Flags reais do `yay` (confirmadas via `yay` man page / issues oficiais do `Jguer/yay`): `--noconfirm`, `--nocleanmenu`, `--nodiffmenu`, `--noeditmenu`, `--noupgrademenu`, `--removemake`. Não existe um único flag "silent" que agregue todos — precisam ser passados individualmente.
- Técnica de não-interatividade "sem terminal" (relatada por você como já usada antes): rodar o processo via `setsid` (nova sessão, sem terminal de controle) com stdin redirecionado de `/dev/null`. Isso faz qualquer `isatty(stdin)`/`isatty(stdout)` avaliar falso, o que é a checagem que a maioria dos instaladores `curl | sh` usa para decidir se deve prompt. É mais robusto que confiar em uma env var específica de cada instalador (que, como visto acima, nem sempre existe/documentada).

## 1. Fase 1 — Bootstrap (`installer/modules/02-pacman-bootstrap.sh`)

**Remove:** todo o bloco de detecção/clone/`makepkg -si` do `shelly-bin`.

**Novo conteúdo do módulo:**

```
#!/usr/bin/env bash
# 02-pacman-bootstrap.sh - Sincroniza pacman e garante dependências mínimas

log_info "Sincronizando base de dados do Pacman..."
pacman -Sy

log_info "Garantindo pacotes de bootstrap..."
# shellcheck disable=SC2046
pacman -S --needed --noconfirm $(toml_get "$CONFIG_FILE" "install.bootstrap_packages" "git base-devel zsh" | tr '\n' ' ')

log_info "Garantindo yay (AUR helper)..."
if is_command yay; then
  log_success "yay já está instalado."
else
  log_warn "yay não encontrado. Instalando via pacman (repo cachyos)..."
  if ! pacman -S --needed --noconfirm yay; then
    exit_with_error "Falha ao instalar yay via pacman. Verifique se o repositório [cachyos] está habilitado em /etc/pacman.conf."
  fi
fi

hash -r
if ! is_command yay; then
  exit_with_error "yay não está disponível após a tentativa de instalação."
fi

log_success "Bootstrap concluído."
```

**Mudança em `installer/config.toml`:**

```
- bootstrap_packages = ["git", "base-devel", "zsh"]
+ bootstrap_packages = ["git", "base-devel", "zsh"]   # sem alteração de conteúdo, só remove a dependência implícita do shelly
```

(Na prática este valor não muda — a única diferença é que `02-pacman-bootstrap.sh` deixa de precisar de `base-devel`/`git` especificamente *para compilar o shelly*, mas ainda são necessários para outras coisas do sistema, então mantém.)

**Teste isolado:** rodar `sudo ./gabrln install --force` interrompendo manualmente após o log "Bootstrap concluído." (ou testar o módulo isolado via `sudo bash -c 'source installer/lib/*.sh; source installer/modules/02-pacman-bootstrap.sh'` com as variáveis de ambiente exportadas manualmente) e confirmar `yay --version`.

## 2. Fase 2 — Pacotes oficiais (`03-shelly-official.sh` → `03-pacman-official.sh`)

**Git:** `git mv installer/modules/03-shelly-official.sh installer/modules/03-pacman-official.sh`
**`installer/gabrln`:** atualizar a chamada em `cmd_install()`:

```
- run_module "03-shelly-official" "$MANIFESTS_DIR/packages.toml"
+ run_module "03-pacman-official" "$MANIFESTS_DIR/packages.toml"
```

**Novo conteúdo (ponto central da correção do caso hyprland):**

```
#!/usr/bin/env bash
# 03-pacman-official.sh - Instala pacotes oficiais via pacman

log_info "Lendo pacotes oficiais do manifesto..."

mapfile -t OFFICIAL_PKGS < <(python3 -c '
import sys, tomllib
file, gaming = sys.argv[1], sys.argv[2] == "true"
with open(file, "rb") as f:
    data = tomllib.load(f)
for pkg in data.get("packages", []):
    tags = pkg.get("tags", [])
    if "gaming" in tags and not gaming:
        continue
    print(pkg["name"])
' "$MANIFESTS_DIR/packages.toml" "$GAMING")

if [[ ${#OFFICIAL_PKGS[@]} -eq 0 ]]; then
  log_warn "Nenhum pacote oficial a instalar."
  return 0
fi

log_info "Verificando pacotes já instalados..."
mapfile -t MISSING_ARR < <(pacman -T "${OFFICIAL_PKGS[@]}" 2>/dev/null || true)

if [[ ${#MISSING_ARR[@]} -eq 0 ]]; then
  log_success "Todos os pacotes oficiais já estão instalados."
  return 0
fi

log_info "Instalando pacotes oficiais pendentes: ${MISSING_ARR[*]}"
if ! pacman -S --needed --noconfirm "${MISSING_ARR[@]}"; then
  exit_with_error "pacman falhou ao instalar pacotes oficiais. Verifique repositórios e conectividade."
fi

hash -r

# Verificação individual: pacman -S pode sair com 0 mesmo tendo pulado algo
# em cenários de conflito resolvido automaticamente ou aviso não-fatal.
# Confirmamos pacote a pacote em vez de confiar só no exit code do lote —
# é exatamente o que faltava para pegar um caso como "hyprland não instalou".
mapfile -t STILL_MISSING < <(pacman -T "${MISSING_ARR[@]}" 2>/dev/null || true)
if [[ ${#STILL_MISSING[@]} -gt 0 ]]; then
  exit_with_error "Pacotes não confirmados após instalação: ${STILL_MISSING[*]}"
fi

# Verificação crítica: zsh deve estar instalado (dependência de chsh em 07-shell)
if ! command -v zsh &>/dev/null && [[ ! -x /usr/bin/zsh ]]; then
  exit_with_error "zsh ausente após instalação de pacotes oficiais."
fi

log_success "Pacotes oficiais instalados e confirmados."
```

**Teste isolado:** forçar um nome de pacote inexistente temporariamente em `packages.toml` (ex.: `pacote-que-nao-existe-123`) e confirmar que o módulo agora **para com `exit_with_error`** em vez de seguir adiante — esse é o teste que garante que o cenário do hyprland não se repete silenciosamente.

## 3. Fase 3 — Pacotes AUR (`04-shelly-aur.sh` → `04-yay-aur.sh`)

**Git:** `git mv installer/modules/04-shelly-aur.sh installer/modules/04-yay-aur.sh`
**`installer/gabrln`:** atualizar `run_module "04-shelly-aur" ...` → `run_module "04-yay-aur" ...` em `cmd_install()` **e** em `cmd_update()`.

```
#!/usr/bin/env bash
# 04-yay-aur.sh - Instala pacotes AUR via yay

log_info "Lendo pacotes AUR do manifesto..."

mapfile -t AUR_PKGS < <(python3 -c '
import sys, tomllib
file, gaming = sys.argv[1], sys.argv[2] == "true"
with open(file, "rb") as f:
    data = tomllib.load(f)
for pkg in data.get("packages", []):
    tags = pkg.get("tags", [])
    if "gaming" in tags and not gaming:
        continue
    print(pkg["name"])
' "$MANIFESTS_DIR/aur.toml" "$GAMING")

if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
  log_warn "Nenhum pacote AUR a instalar."
  return 0
fi

log_info "Verificando pacotes AUR já instalados..."
mapfile -t MISSING_ARR < <(pacman -T "${AUR_PKGS[@]}" 2>/dev/null || true)

if [[ ${#MISSING_ARR[@]} -eq 0 ]]; then
  log_success "Todos os pacotes AUR já estão instalados."
  return 0
fi

log_info "Instalando pacotes AUR pendentes via yay: ${MISSING_ARR[*]}"
# yay nunca deve rodar como root (recusa por padrão) -> run_as_user.
# Flags reais do yay para lote não-interativo (não existe um único "--silent"):
#   --noconfirm       não pede confirmação de instalação
#   --nocleanmenu     não mostra menu de limpeza de pacotes órfãos de build
#   --nodiffmenu      não mostra diff do PKGBUILD
#   --noeditmenu      não abre editor para o PKGBUILD
#   --noupgrademenu   não mostra menu de seleção de upgrades
#   --removemake      remove makedepends após o build (mantém sistema limpo)
quoted_args=$(printf '%q ' "${MISSING_ARR[@]}")
run_as_user "yay -S --needed --noconfirm --nocleanmenu --nodiffmenu --noeditmenu --noupgrademenu --removemake $quoted_args"

hash -r

mapfile -t STILL_MISSING < <(pacman -T "${MISSING_ARR[@]}" 2>/dev/null || true)
if [[ ${#STILL_MISSING[@]} -gt 0 ]]; then
  exit_with_error "Pacotes AUR não confirmados após instalação: ${STILL_MISSING[*]}"
fi

log_success "Pacotes AUR instalados e confirmados."
```

**Nota de segurança (não é regressão, é continuidade do comportamento atual):** pular diff/edit menu significa instalar PKGBUILDs da AUR sem revisão manual, igual o `shelly aur install --no-confirm` já fazia. Se quiser reduzir esse risco no futuro, dá para trocar `--nodiffmenu` por uma etapa de auditoria prévia dos PKGBUILDs dos 5 pacotes AUR do seu `aur.toml` (só 5, é revisável manualmente uma vez).

**Teste isolado:** rodar `gabrln update` (que já invoca esse módulo isoladamente) num pacote AUR pequeno e observar se trava esperando input — se travar, algum menu não foi coberto pelas flags acima.

## 4. Fase 4 — Flatpak (`05-shelly-flatpak.sh`)

Remove a tentativa `shelly flatpak install -n "$pkg"`, mantém só o `flatpak install -y --system` que já existia como fallback (ele passa a ser o caminho principal, não fallback). Resto do arquivo (remote add, temas adw-gtk3) fica igual.

## 5. Fase 5 — curl-tools sem interação garantida (`06-curl-tools.sh`)

Troca a linha de execução do instalador de cada ferramenta:

```
- run_as_user "$env_prefix curl -fsSL '$install_url' | bash" || true
+ run_as_user "setsid -w bash -c \"$env_prefix curl -fsSL '$install_url' | bash\" </dev/null >>'$LOGS_DIR/curl-tools-$name.log' 2>&1" || true
```

Por quê `setsid -w`: cria uma sessão nova sem terminal de controle e espera (`-w`) o processo terminar. Sem terminal de controle, qualquer chamada `isatty()` no instalador de terceiros retorna falso — é a mesma técnica que você já usou antes, e é estrutural (não depende de cada instalador reconhecer uma env var específica tipo `NONINTERACTIVE`, que confirmei não estar documentada nem para o `antigravity.google/cli/install.sh` nem para o `pi.dev/install.sh`).
Redirecionar para um log por ferramenta (em vez de silenciar com `/dev/null`) mantém a saída auditável em `installer/logs/` se algo falhar — hoje a saída do curl some completamente em caso de erro.

**Mantém** a lógica de reverificação pós-instalação (`already_installed`/`installed_now`) já existente — ela continua sendo a forma de saber se, apesar de tudo, a ferramenta não instalou.

**Item em aberto para você validar manualmente** (não vou presumir): mesmo sem terminal, alguns instaladores decidem interromper e sair com erro em vez de aplicar um default quando não conseguem prompt — nesse caso `setsid` sozinho não resolve, teria que ver o log específico da ferramenta que falhar. Sugiro rodar o módulo isolado uma vez em modo verboso antes de confiar nele no fluxo completo.

## 6. Fase 6 — Limpeza de manifests, config e docs

- `installer/config.toml`: nenhuma chave nova necessária (yay não precisa de config própria).
- `installer/manifests/packages.toml` / `aur.toml`: sem mudança de conteúdo.
- `README.md`: trocar `**Pacotes**: Shelly CLI (ALPM, AUR e Flatpak)` por `**Pacotes**: pacman (oficial) + yay (AUR) + flatpak`.
- Buscar por qualquer outra menção residual a "shelly" no repo (`grep -ri shelly -r .` depois de todas as fases) para garantir que não sobrou referência morta em comentários ou no `installer/lib/*.sh`.

## Ordem de execução recomendada

Bloco
Conteúdo
Por que separar

1
Fase 1 + Fase 2
Resolve diretamente o caso do hyprland não aparecer no greeter — é o de maior prioridade e menor risco (pacman puro, sem AUR).

2
Fase 3 + Fase 4
Depende do bloco 1 (precisa do `yay` já bootstrapado). Envolve builds AUR, que são mais lentos de testar.

3
Fase 5 + Fase 6
Independente dos outros dois, mas menos urgente — trata só de robustez de instaladores externos e limpeza de docs.

Cada bloco gera um patch próprio (como fiz com os 3 bugs), aplicável e testável isoladamente antes de eu seguir pro próximo — assim nenhum bloco fica pela metade se a conversa for interrompida no meio.

## Checklist de validação pós-migração

- [ ] `sudo ./gabrln doctor` sem divergências novas.
- [ ] `hyprland` (e demais pacotes do grupo `themes`) presentes: `pacman -Q hyprland`.
- [ ] `yay --version` funcional como usuário normal (não root).
- [ ] `gabrln update` roda `04-yay-aur` sem travar esperando input.
- [ ] Nenhuma ocorrência de `shelly` restante: `grep -ri shelly -r installer/ README.md`.
- [ ] Backups antigos (`gabrln backup` / `01-backup.sh`) continuam funcionando com o fix de `backup.sh` já aplicado — testar `gabrln rollback` uma vez em ambiente descartável (VM/container) antes de confiar em produção.
