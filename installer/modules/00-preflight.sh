#!/usr/bin/env bash
# 00-preflight.sh - Checagens iniciais antes de qualquer modificação

log_info "Verificando pré-condições..."

# Conectividade
if has_internet; then
  log_success "Conectividade com a internet confirmada."
else
  log_warn "Não foi possível confirmar conectividade com a internet. Continuando mesmo assim."
fi

# Espaço em disco
min_space=$(toml_get "$CONFIG_FILE" "install.min_free_space" "5368709120")
if has_free_space "$USER_HOME" "$min_space"; then
  log_success "Espaço em disco suficiente."
else
  log_warn "Espaço em disco pode ser insuficiente (mínimo recomendado: $min_space bytes)."
fi

# Confirmação do ambiente
log_info "REAL_USER: $REAL_USER"
log_info "USER_HOME: $USER_HOME"
log_info "REPO_DIR: $REPO_DIR"

log_success "Pré-condições verificadas."
