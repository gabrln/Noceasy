#!/usr/bin/env bash
# 08-dotfiles.sh - Aplica as configurações do repositório no HOME do usuário

log_info "Garantindo diretório ~/.config..."
mkdir -p "$USER_HOME/.config"
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config"

# Lê lista de diretórios de config do manifesto
mapfile -t CONFIGS < <(python3 -c '
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
for c in data.get("directories", {}).get("configs", []):
    print(c)
' "$MANIFESTS_DIR/dotfiles.toml")

log_info "Copiando configurações do usuário..."
for cfg in "${CONFIGS[@]}"; do
  source_path="$REPO_DIR/.config/$cfg"
  target_path="$USER_HOME/.config/$cfg"

  if [[ ! -d "$source_path" && ! -f "$source_path" ]]; then
    log_warn "Fonte não encontrada, pulando: $cfg"
    continue
  fi

  rm -rf "$target_path"
  run_as_user "cp -rfT '$source_path' '$target_path'"

  if [[ ! -e "$target_path" ]]; then
    exit_with_error "Falha ao copiar $cfg para $target_path"
  fi
  log_info "  → $cfg"
done

# Caso especial: zsh preserva plugins/ existentes
log_info "Aplicando configuração especial do Zsh..."
ZSH_SRC="$REPO_DIR/.config/zsh"
ZSH_DST="$USER_HOME/.config/zsh"
if [[ -d "$ZSH_SRC" ]]; then
  # Preserva plugins existentes
  if [[ -d "$ZSH_DST/plugins" ]]; then
    tmp_plugins=$(mktemp -d)
    cp -a "$ZSH_DST/plugins" "$tmp_plugins/"
    rm -rf "$ZSH_DST"
    run_as_user "cp -rfT '$ZSH_SRC' '$ZSH_DST'"
    rm -rf "$ZSH_DST/plugins"
    mv "$tmp_plugins/plugins" "$ZSH_DST/plugins"
    rm -rf "$tmp_plugins"
  else
    rm -rf "$ZSH_DST"
    run_as_user "cp -rfT '$ZSH_SRC' '$ZSH_DST'"
  fi

  if [[ ! -e "$ZSH_DST" ]]; then
    exit_with_error "Falha ao copiar zsh para $ZSH_DST"
  fi
  log_info "  → zsh (plugins preservados)"
fi

# Arquivos avulsos
log_info "Copiando arquivos avulsos..."
while IFS='|' read -r src dst; do
  [[ -z "$src" ]] && continue
  src_path="$REPO_DIR/$src"
  dst_path=$(echo "$dst" | sed "s|\\$HOME|$USER_HOME|g")

  mkdir -p "$(dirname "$dst_path")"
  run_as_user "cp -f '$src_path' '$dst_path'"
  log_info "  → $dst"
done < <(python3 -c '
import sys, tomllib, os
file, home = sys.argv[1], sys.argv[2]
with open(file, "rb") as f:
    data = tomllib.load(f)
for src, dst in data.get("files", {}).items():
    expanded = os.path.expandvars(dst)
    if expanded.startswith("~"):
        expanded = home + expanded[1:]
    print(f"{src}|{expanded}")
' "$MANIFESTS_DIR/dotfiles.toml" "$USER_HOME")

# Atualiza diretórios XDG e cria extras
log_info "Criando diretórios XDG adicionais..."
run_as_user "xdg-user-dirs-update 2>/dev/null || true"

while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  expanded=$(echo "$dir" | sed "s|\\$HOME|$USER_HOME|g")
  mkdir -p "$expanded"
  chown "$REAL_USER:$REAL_USER" "$expanded"
  log_info "  → $expanded"
done < <(python3 -c '
import sys, tomllib, os
file, home = sys.argv[1], sys.argv[2]
with open(file, "rb") as f:
    data = tomllib.load(f)
for d in data.get("xdg_dirs", {}).get("extra", []):
    expanded = os.path.expandvars(d)
    if expanded.startswith("~"):
        expanded = home + expanded[1:]
    print(expanded)
' "$MANIFESTS_DIR/dotfiles.toml" "$USER_HOME")

log_success "Dotfiles aplicados."
