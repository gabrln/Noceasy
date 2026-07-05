#!/usr/bin/env bash
# 15-system-tweaks.sh - Ajustes finos de sistema e compatibilidade root

log_info "Ajustando permissões de configurações do usuário..."
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config" "$USER_HOME/.local"
mkdir -p "$USER_HOME/.local/share/icons"

log_info "Vinculando temas para acessibilidade de aplicativos root..."
mkdir -p /root/.config /root/.local/share
for root_cfg in gtk-3.0 gtk-4.0; do
  rm -rf "/root/.config/$root_cfg"
  ln -sfT "$USER_HOME/.config/$root_cfg" "/root/.config/$root_cfg"
  log_info "  → /root/.config/$root_cfg"
done
rm -rf /root/.local/share/icons
ln -sfT "$USER_HOME/.local/share/icons" /root/.local/share/icons
log_info "  → /root/.local/share/icons"

log_info "Limpando configurações órfãs do Noctalia..."
rm -rf "$USER_HOME/.config/qt5ct"
if [[ -L "$USER_HOME/.config/qt6ct/qt6ct" ]]; then
  rm -f "$USER_HOME/.config/qt6ct/qt6ct"
  log_info "  → symlink circular qt6ct/qt6ct removido"
fi

log_success "Ajustes de sistema aplicados."
