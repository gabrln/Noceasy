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
