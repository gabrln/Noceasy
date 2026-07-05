#!/usr/bin/env bash
# install.sh - Bootstrap thin wrapper para o framework Arch-gabrln
# Uso: curl -fsSL .../install.sh | sudo bash

set -euo pipefail

REPO_URL="https://github.com/gabrln/Arch-gabrln.git"
CLONE_SUBDIR="Projects/Arch-gabrln"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error() {
  echo -e "${RED}[ERRO]${NC} $1" >&2
  exit "${2:-1}"
}

info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

# Identificar usuário real
if [[ $EUID -ne 0 ]]; then
  error "Execute este script com sudo. Ex: curl ... | sudo bash"
fi

if [[ -z "${SUDO_USER:-}" ]]; then
  error "Não foi possível determinar SUDO_USER. Execute via sudo."
fi

REAL_USER="$SUDO_USER"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
  error "Não foi possível determinar o HOME do usuário '$REAL_USER'."
fi

REPO_DIR="$USER_HOME/$CLONE_SUBDIR"

# Garantir git
if ! command -v git &>/dev/null; then
  info "Instalando git..."
  pacman -Sy --needed --noconfirm git
fi

# Clonar ou atualizar o repositório
if [[ -d "$REPO_DIR/.git" ]]; then
  info "Atualizando repositório em $REPO_DIR..."
  sudo -u "$REAL_USER" --preserve-env=PATH,HOME git -C "$REPO_DIR" pull
else
  info "Clonando repositório para $REPO_DIR..."
  mkdir -p "$(dirname "$REPO_DIR")"
  sudo -u "$REAL_USER" --preserve-env=PATH,HOME git clone "$REPO_URL" "$REPO_DIR"
fi

success "Repositório pronto em $REPO_DIR"
info "Executando o framework..."

# Delegar para o entrypoint real
exec "$REPO_DIR/installer/gabrln" install "$@"
