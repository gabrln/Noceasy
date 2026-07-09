# Arch-gabrln

Ambiente Wayland para Arch/CachyOS: **Hyprland 0.55 + Noctalia V5**.
Stack de pacotes: `pacman` (oficial CachyOS) · `yay` (AUR) · `flatpak`.

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo bash
```

O instalador:

1. Detecta `SUDO_USER` e seu `$HOME`.
2. Clona (ou atualiza) o repositório em `~/Projects/Arch-gabrln`.
3. Executa o framework `gabrln`, que roda 16 módulos em ordem.

Requer Arch ou CachyOS e privilégio de root (uma única vez, no bootstrap).

## Flags do framework

| Flag | Efeito |
|---|---|
| `--dry-run` | Simula sem modificar nada (não executa módulos destrutivos) |
| `--verbose` | Habilita logs `DEBUG` |
| `--quiet` | Suprime `INFO`, mantém `ERROR/STEP` |
| `--force` | Re-executa módulos já concluídos (ignora `state.json`) |
| `--no-color` | Desabilita saída colorida |
| `-h`, `--help` | Mostra ajuda |

Variáveis de ambiente: `NO_COLOR=1` (mesmo efeito de `--no-color`), `VERBOSE=1`, `QUIET=1`.

## Atalhos principais

- `Super + T` — Terminal (Kitty)
- `Super + D` — Launcher
- `Alt + Tab` — Overview (hyprpm scrolloverview)
- `Super + B` — Firefox
- `Super + /` — Cheat sheet completo
- `Super + Q` — Fechar janela

## Arquitetura

```
install.sh                      # bootstrap (sudo bash)
└─ installer/gabrln             # entrypoint (script único de install)
   ├─ lib/                      # bibliotecas compartilhadas
   │  ├─ logger.sh              # logging estruturado (NO_COLOR, TTY)
   │  ├─ utils.sh               # helpers (toml, runuser, has_*)
   │  ├─ errors.sh              # traps, cleanup, polkit policy
   │  ├─ state.sh               # state.json atômico (flock + os.replace)
   │  ├─ backup.sh              # snapshot/restore com colisão .1/.2
   │  └─ progress.sh            # barra de progresso
   ├─ modules/                  # 16 módulos executados em ordem
   ├─ manifests/                # TOMLs declarativos (pacotes, dotfiles, AUR...)
   ├─ polkit/                   # templates da polkit policy
   │  ├─ 99-arch-gabrln-installer.rules
   │  ├─ org.archlinux.pkexec.gabrln.policy
   │  └─ gabrln-helper          # binary invocado via pkexec
   └─ config.toml               # paths, flags, features
```

### Como o privilégio é gerenciado

- **Bootstrap** (`install.sh`): precisa de `sudo bash` porque polkit não tem agent no TTY de login.
- **Durante o install**: já somos root. Para executar como o usuário real, usamos `runuser -u REAL_USER --` (sem precisar de NOPASSWD sudoers).
- **Helpers invocados pelo user**: uma polkit policy em `/etc/polkit-1/rules.d/99-arch-gabrln-installer.rules` libera `pkexec gabrln-helper` para o `REAL_USER` sem prompt de senha. A regra é instalada em tempo de install e removida no `EXIT`.
- **`sudo -u`, `sudo -E`, `NOPASSWD` sudoers**: **não existem no framework**. Toda a migração está completa.

### Idempotência

Cada módulo é pulado se o manifesto correspondente não mudou (hash SHA256 em `installer/state/state.json`). Use `--force` para re-executar tudo.

### Logs

Cada execução grava em `installer/logs/gabrln-YYYYMMDD-HHMMSS.log` com timestamps e níveis.

## Módulos

Os 16 módulos são executados em ordem fixa. O sufixo `:manifesto.toml` indica que o módulo lê o manifesto e o usa como chave de cache (se o hash não mudou, o módulo é pulado).

| # | Módulo | Manifesto | O que faz |
|---|---|---|---|
| 00 | `preflight` | — | Conectividade (github), espaço em disco (`/` e `~`), log de contexto |
| 01 | `backup` | `dotfiles.toml` | Snapshot `pre-install` das configs antes de modificá-las |
| 02 | `pacman-bootstrap` | — | `pacman -Sy` + `git`/`base-devel`/`zsh` + `yay` (do repo cachyos) |
| 03 | `pacman-official` | `packages.toml` | `pacman -T` filtra instalados, `pacman -S` os faltantes, fallback per-pkg, filtra `linux-cachyos*` em sistemas não-CachyOS |
| 04 | `yay-aur` | `aur.toml` | Chunks de 50 via xargs (anti-ARG_MAX) + fallback per-pkg; roda como user (yay recusa root) |
| 05 | `flatpak` | `flatpak.toml` | `flatpak remote-add flathub` + install com retry+backoff; tema adw-gtk3 para sandbox |
| 06 | `curl-tools` | `curl-tools.toml` | Tools de coding AI via `curl|bash`, script wrapper em mktemp, pipefail ativo, log por PID |
| 07 | `shell` | `zsh-plugins.toml` | `chsh -s /usr/bin/zsh` + `systemctl --user set-environment` + `git clone` de plugins com 3 retries |
| 08 | `dotfiles` | `dotfiles.toml` | Backup-then-replace via mktemp staging; preserva `~/.config/zsh/plugins/`; copia files avulsos com backup `.gabrln.bak.<ts>` |
| 09 | `hyprland-env` | — | `chmod +x` em `*/scripts/*`, valida `hyprland.lua`, checa `hyprpm` |
| 10 | `greeter` | — | `useradd greeter` (com `-M -d`), copia `/etc/greetd/*` com `.gabrln.bak`, cria logs `noctalia-greeter.log` |
| 11 | `keyring` | — | Insere `pam_gnome_keyring.so` após ÚLTIMA linha `auth`/`session` (não a primeira); valida e restaura backup se PAM quebrar |
| 13 | `wallpapers` | `wallpapers.toml` | Google Drive (UUID+confirm para >100MB), aria2c fallback, SHA256 opcional, content-type/size sanity check |
| 14 | `icons-cursors-fonts` | — | `fc-cache -fv`, `gtk-update-icon-cache` em `~/.local/share/icons/*` |
| 15 | `system-tweaks` | — | Chown cirúrgico (não `~/.local` inteiro), symlinks `/root/.config/gtk-{3,4}.0` (preserva se já válido) |
| 16 | `services` | `services.toml` | `systemctl enable` com check de `list-unit-files` (skip silencioso de units ausentes) |

> Nota: o `12-` foi removido propositadamente (ver `ebb062e refactor(hyprpm)`).

## Manifestos

| Arquivo | Conteúdo |
|---|---|
| `packages.toml` | Pacotes `pacman` (oficial CachyOS), agrupados por categoria |
| `aur.toml` | Pacotes AUR via yay (noctalia-git, noctalia-greeter-git, bibata-cursor-theme-bin) |
| `flatpak.toml` | Remoto flathub + pacotes (easyeffects) |
| `curl-tools.toml` | Tools via `curl|bash` (agy, pi-coding-agent, herdr) |
| `zsh-plugins.toml` | Plugins clonados via git (autosuggestions, fast-syntax-highlighting, zsh-vi-mode) |
| `dotfiles.toml` | Diretórios de config, files avulsos, dirs XDG extras |
| `wallpapers.toml` | `source.file_id` (Google Drive), `destination.path`, `source.sha256` opcional |
| `services.toml` | Systemd services habilitados (docker, bluetooth, NetworkManager, greetd, spice-vdagent, qemu-guest-agent) |
| `hyprpm.toml` | Plugins do hyprpm declarativos |

## Configuração (`installer/config.toml`)

```toml
[paths]          # repo, logs, state, backups, manifests, modules
[install]        # clone_target, bootstrap_packages, min_free_space
[flags]          # skip_up_to_date, auto_backup, max_backups
[features]       # wallpapers, enable_polkit_helper
```

Exemplo de override: criar `installer/config.local.toml` e fazer source no gabrln (não implementado — edite `config.toml` diretamente).

## Customização

- **Pacotes**: edite `installer/manifests/packages.toml` (oficial) ou `aur.toml` (AUR).
- **Dotfiles**: edite `installer/manifests/dotfiles.toml` (lista de configs e files avulsos) e coloque os arquivos em `~/.config/<nome>` no repo.
- **Wallpapers**: troque `source.file_id` em `wallpapers.toml` (qualquer link compartilhado do Google Drive).
- **Serviços**: edite `services.toml` (lista de units systemd).
- **Polkit policy**: o `gabrln-helper` aceita subcomandos: `refresh-icon-cache`, `update-hyprpm`, `enable-service`, `restart-user-service`, `set-shell`. Adicione novos editando `installer/polkit/gabrln-helper`.

## Estado e backups

- `installer/state/state.json` — controla quais módulos já rodaram (`status`, `manifest_hash`, `completed_at`).
- `installer/state/backups/` — snapshots `pre-install-TS/` e `manual-TS/`. Retenção configurável via `flags.max_backups`.
- `installer/logs/` — log estruturado de cada execução.

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `pacman: unable to find linux-cachyos` | Sistema não é CachyOS | Módulo 03 já filtra automaticamente; o erro some |
| `permission denied` em `~/.config/*` | Módulo rodou parcialmente como root | Rode de novo com `sudo bash install.sh` |
| `polkit: ... authentication is required` | Agent do polkit não está rodando | Instale `polkit-gnome` (já no manifesto) e habilite `polkit-gnome-authentication-agent-1` no autostart |
| `hyprpm: command not found` | hyprland não instalado | Módulo 03 deve instalar; verifique o manifesto |
| `git pull failed` no bootstrap | Repo em estado inválido | `rm -rf ~/Projects/Arch-gabrln` e rode de novo |

## Licença

Ver `LICENSE` (se aplicável).
