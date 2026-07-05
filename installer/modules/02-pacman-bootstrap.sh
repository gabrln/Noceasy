#!/usr/bin/env bash
# 02-pacman-bootstrap.sh - Sincroniza pacman e garante dependências mínimas

log_info "Sincronizando base de dados do Pacman..."
pacman -Sy

log_info "Garantindo pacotes de bootstrap..."
# shellcheck disable=SC2046
pacman -S --needed --noconfirm $(toml_get "$CONFIG_FILE" "install.bootstrap_packages" "git base-devel" | tr '\n' ' ')

log_info "Verificando gerenciador de pacotes shelly..."
if is_command shelly; then
  log_success "shelly já está instalado."
else
  log_warn "shelly não encontrado nos repositórios. Instalando via AUR..."
  run_as_user '
    rm -rf /tmp/shelly-bin
    env GIT_TERMINAL_PROMPT=0 git clone https://aur.archlinux.org/shelly-bin.git /tmp/shelly-bin
    cd /tmp/shelly-bin
    makepkg -si --noconfirm
    rm -rf /tmp/shelly-bin
  '
  hash -r
  if ! is_command shelly; then
    exit_with_error "Falha ao instalar o shelly."
  fi
  log_success "shelly instalado via AUR."
fi

hash -r
log_success "Bootstrap concluído."
