# Arch-gabrln

Ambiente Wayland para Arch/CachyOS: **Hyprland 0.55 + Noctalia V5**.
Stack de pacotes: `pacman` (oficial CachyOS) · `yay` (AUR) · `flatpak`.

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo bash
```

Pinar versão (opcional):
```bash
sudo GABRLN_VERSION=v1.5.0 bash install.sh
```

Validar integridade (opcional):
```bash
sudo GABRLN_VERSION=v1.5.0 GABRLN_SHA256=abc123... bash install.sh
```

O instalador:
1. Detecta arch, OS, modo root/SUDO_USER.
2. Garante `git`, `python` (≥3.11), `python-rich`.
3. Clona (ou atualiza) o repositório em `~/Projects/Arch-gabrln`.
4. Valida SHA256 do commit (se `GABRLN_SHA256` foi setado).
5. Executa o framework Python, que roda 16 módulos em ordem.

Requer Arch ou CachyOS e privilégio de root (uma única vez, no bootstrap).

## Flags do framework

| Flag | Efeito |
|---|---|
| `--dry-run` | Simula sem modificar nada |
| `--verbose` | Habilita logs `DEBUG` |
| `--quiet` | Suprime `INFO`, mantém `ERROR/STEP` |
| `--force` | Re-executa módulos já concluídos |
| `--no-color` | Desabilita saída colorida (ou `NO_COLOR=1`) |
| `-h`, `--help` | Mostra ajuda |

Variáveis de ambiente: `NO_COLOR=1`, `VERBOSE=1`, `QUIET=1`, `GABRLN_VERSION`, `GABRLN_SHA256`.

## Atalhos principais

- `Super + T` — Terminal (Kitty)
- `Super + D` — Launcher
- `Alt + Tab` — Overview (hyprpm scrolloverview)
- `Super + B` — Firefox
- `Super + /` — Cheat sheet completo
- `Super + Q` — Fechar janela

## Arquitetura

```
install.sh                          # bootstrap bash (≈140 linhas)
└─ python3 -m installer            # framework Python (entrypoint)
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

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Python 3.11+ necessário` | Python muito antigo | `pacman -S python` |
| `python-rich não encontrado` | Dep não instalada | `pacman -S python-rich` |
| `Distribuição não suportada` | Não é Arch/CachyOS | Apenas Arch/CachyOS são suportados |
| `pacman: unable to find linux-cachyos` | Não é CachyOS | Módulo 03 filtra automaticamente |
| `polkit: ... authentication required` | Agent não rodando | Instale `polkit-gnome` e habilite no autostart |
| `hyprpm: command not found` | hyprland não instalado | Módulo 03 deve instalar; verifique o manifesto |

## Contribuindo

Ver `installer/README.md` para detalhes sobre como adicionar módulos/manifestos.
