#!/usr/bin/env bash
# 09-hyprland-env.sh - Validação do ambiente Hyprland e permissões

log_info "Tornando scripts executáveis em ~/.config..."
find "$USER_HOME/.config" -type f \( -name "*.sh" -o -path "*/scripts/*" \) -exec chmod +x {} + 2>/dev/null || true

log_info "Validando configuração do Hyprland..."
if [[ ! -f "$USER_HOME/.config/hypr/hyprland.lua" ]]; then
  exit_with_error "hyprland.lua não encontrado em $USER_HOME/.config/hypr/. A configuração do Hyprland não foi copiada corretamente."
fi

log_success "Ambiente Hyprland validado."
