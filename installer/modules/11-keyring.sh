#!/usr/bin/env bash
# 11-keyring.sh - Garante integração do gnome-keyring com greetd

PAM_FILE="/etc/pam.d/greetd"

if [[ ! -f "$PAM_FILE" ]]; then
  log_warn "$PAM_FILE não encontrado. Pulando configuração de keyring."
  return 0
fi

log_info "Verificando integração do gnome-keyring no greetd..."

# Garante linha de auth
if ! grep -qE '^auth\s+optional\s+pam_gnome_keyring\.so' "$PAM_FILE"; then
  log_info "Adicionando pam_gnome_keyring.so à linha de auth..."
  # Adiciona após a última linha auth
  sed -i '/^auth /a auth       optional     pam_gnome_keyring.so' "$PAM_FILE"
fi

# Garante linha de session
if ! grep -qE '^session\s+optional\s+pam_gnome_keyring\.so\s+auto_start' "$PAM_FILE"; then
  log_info "Adicionando pam_gnome_keyring.so auto_start à linha de session..."
  # Adiciona após a última linha session
  sed -i '/^session /a session    optional     pam_gnome_keyring.so auto_start' "$PAM_FILE"
fi

log_success "Keyring configurado."
