#!/usr/bin/env bash
# backup.sh - Snapshot e rollback de configurações

set -euo pipefail

if [[ -n "${_LIB_BACKUP_SH:-}" ]]; then return 0; fi
_LIB_BACKUP_SH=1

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

BACKUP_DIR=""

backup_init() {
  BACKUP_DIR="$1"
  mkdir -p "$BACKUP_DIR"
}

# Cria um backup com timestamp de uma lista de caminhos.
# Uso: backup_create <label> <caminho1> [caminho2] ...
backup_create() {
  local label="$1"
  shift
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local name="${label}-${timestamp}"
  local dest="$BACKUP_DIR/$name"

  mkdir -p "$dest"
  log_info "Criando backup '$name'..."

  local path
  for path in "$@"; do
    if [[ -e "$path" ]]; then
      local rel
      rel=$(basename "$path")
      local target="$dest/$rel"
      if [[ -d "$path" ]]; then
        cp -a "$path" "$target"
      else
        cp -a "$path" "$target"
      fi
      log_info "  → $path"
    else
      log_warn "  → $path não existe, pulando."
    fi
  done

  echo "$name"
}

# Lista os backups existentes, do mais recente para o mais antigo.
backup_list() {
  find "$BACKUP_DIR" -maxdepth 1 -type d -name '*-[0-9]*' -printf '%f\n' 2>/dev/null | sort -r
}

# Restaura o backup mais recente com o label dado.
# Uso: backup_restore <label>
backup_restore() {
  local label="$1"
  local latest
  latest=$(backup_list | grep "^${label}-" | head -n1)

  if [[ -z "$latest" ]]; then
    log_error "Nenhum backup encontrado com label '$label'."
    return 1
  fi

  local src="$BACKUP_DIR/$latest"
  log_warn "Isso sobrescreverá os arquivos atuais com o backup '$latest'."
  read -r -p "Continuar? [s/N] " confirm
  if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    log_info "Rollback cancelado."
    return 0
  fi

  log_info "Restaurando backup '$latest'..."
  local item
  for item in "$src"/*; do
    [[ -e "$item" ]] || continue
    local rel
    rel=$(basename "$item")
    local target

    # Restaura paths conhecidos para seus destinos originais
    case "$rel" in
      .config)
        target="$USER_HOME/.config"
        ;;
      greetd)
        target="/etc/greetd"
        ;;
      pam_greetd)
        target="/etc/pam.d/greetd"
        ;;
      *)
        target="$USER_HOME/$rel"
        ;;
    esac

    rm -rf "$target"
    cp -a "$item" "$target"
    log_info "  → $target"
  done

  log_success "Backup '$latest' restaurado."
}
