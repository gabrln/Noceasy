#!/usr/bin/env bash
# 14-icons-cursors-fonts.sh - Atualiza cache de fontes e ícones

log_info "Atualizando cache de fontes..."
fc-cache -fv 2>/dev/null || true

log_info "Garantindo diretório de ícones do usuário..."
mkdir -p "$USER_HOME/.local/share/icons"
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.local"

log_success "Cache de fontes e ícones atualizado."
