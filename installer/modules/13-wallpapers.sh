#!/usr/bin/env bash
# 13-wallpapers.sh - Baixa e extrai pacote de wallpapers extras

wallpapers_enabled=$(toml_get "$CONFIG_FILE" "features.wallpapers" "true")
if [[ "$wallpapers_enabled" != "true" ]]; then
  log_info "Download de wallpapers desabilitado em config.toml. Pulando."
  return 0
fi

file_id=$(toml_get "$MANIFESTS_DIR/wallpapers.toml" "source.file_id" "")
wp_dir=$(toml_get "$MANIFESTS_DIR/wallpapers.toml" "destination.path" "$USER_HOME/Pictures/Wallpapers")
wp_dir=$(echo "$wp_dir" | sed "s|\\$HOME|$USER_HOME|g")

if [[ -z "$file_id" ]]; then
  log_warn "Nenhum file_id configurado em wallpapers.toml. Pulando."
  return 0
fi

log_info "Garantindo diretório de wallpapers: $wp_dir"
mkdir -p "$wp_dir"
chown "$REAL_USER:$REAL_USER" "$wp_dir"

# Só baixa se o diretório estiver vazio
if [[ -n "$(ls -A "$wp_dir" 2>/dev/null)" ]]; then
  log_success "Diretório de wallpapers já contém arquivos. Pulando download."
  return 0
fi

log_info "Baixando pacote de wallpapers extras..."
WP_TMP="/tmp/wallpapers_extra.zip"

GDRIVE_HTML=$(curl -sL "https://drive.google.com/uc?export=download&id=${file_id}")
GDRIVE_UUID=$(echo "$GDRIVE_HTML" | grep -o 'name="uuid" value="[^"]*' | cut -d'"' -f4 || true)

if [[ -n "$GDRIVE_UUID" ]]; then
  curl -L -o "$WP_TMP" "https://drive.usercontent.google.com/download?id=${file_id}&export=download&confirm=t&uuid=${GDRIVE_UUID}"
else
  curl -L -o "$WP_TMP" "https://drive.google.com/uc?export=download&confirm=t&id=${file_id}"
fi

if [[ ! -f "$WP_TMP" ]]; then
  log_warn "Falha ao baixar wallpapers. Pulando extração."
  return 0
fi

if file "$WP_TMP" | grep -i -E "zip|archive" &>/dev/null; then
  run_as_user "unzip -o -j '$WP_TMP' -d '$wp_dir' 2>/dev/null || true"
  rm -f "$WP_TMP"
  log_success "Wallpapers extraídos para $wp_dir."
else
  log_warn "Arquivo baixado não parece ser um zip. Pulando extração."
fi
