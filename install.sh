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

if [[ "$REAL_USER" == "root" ]]; then
  error "Execute como usuário normal com sudo. Ex: curl ... | sudo bash"
fi

REPO_DIR="$USER_HOME/$CLONE_SUBDIR"

# Garantir git
if ! command -v git &>/dev/null; then
  info "Instalando git..."
  pacman -Sy --needed --noconfirm git
fi

# Clonar ou atualizar o repositório
# Usamos -c safe.directory="*" inline para evitar "fatal: detected dubious ownership"
# quando o repo foi clonado por root e depois usado por outro usuário.
# Isso não persiste em ~/.gitconfig; vale apenas para este comando.
# Criamos o diretório pai como root e ajustamos ownership — é mais previsível
# do que depender de sudo -u com HOME explícito em sudoers com env_reset.
if [[ -d "$REPO_DIR/.git" ]]; then
  info "Atualizando repositório em $REPO_DIR..."
  # Corrige ownership caso arquivos tenham ficado como root de execução anterior
  chown -R "$REAL_USER:$REAL_USER" "$REPO_DIR" 2>/dev/null || true
  sudo -u "$REAL_USER" HOME="$USER_HOME" PATH="$PATH" git -c safe.directory="*" -C "$REPO_DIR" pull
else
  info "Clonando repositório para $REPO_DIR..."
  # Garante que o HOME do usuário existe e pertence ao usuário
  if [[ ! -d "$USER_HOME" ]]; then
    error "HOME do usuário '$REAL_USER' não existe: $USER_HOME"
  fi
  # Cria o diretório pai como root e ajusta ownership
  if ! mkdir -p "$USER_HOME/Projects" 2>/dev/null; then
    # Se root não pode criar (pouco provável), tenta como o usuário
    sudo -u "$REAL_USER" HOME="$USER_HOME" PATH="$PATH" mkdir -p "$USER_HOME/Projects" \
      || error "Falha ao criar $USER_HOME/Projects. Verifique permissões do $USER_HOME."
  fi
  chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Projects"
  # Verifica se o diretório foi realmente criado e pertence ao usuário
  if [[ ! -d "$USER_HOME/Projects" ]]; then
    error "Diretório $USER_HOME/Projects não foi criado."
  fi
  sudo -u "$REAL_USER" HOME="$USER_HOME" PATH="$PATH" git -c safe.directory="*" clone "$REPO_URL" "$REPO_DIR"
  # Segurança extra: garante ownership correto no repositório clonado
  chown -R "$REAL_USER:$REAL_USER" "$REPO_DIR"
fi

success "Repositório pronto em $REPO_DIR"
info "Executando o framework..."

# Delegar para o entrypoint real (aceita flags posicionais --gaming, --force)
exec "$REPO_DIR/installer/gabrln" install "$@"
