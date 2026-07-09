#!/usr/bin/env bash
# install.sh - Bootstrap thin wrapper para o framework Arch-gabrln
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo bash
#   sudo GABRLN_VERSION=v1.5.0 bash install.sh
#
# Variáveis de ambiente:
#   GABRLN_VERSION  Tag/branch a clonar (default: main)
#   GABRLN_SHA256   SHA256 do commit/tag (opcional, valida após clone)
#   NO_COLOR=1      Desabilita cores no Python também
#
# Comportamento:
#   1. Detecta arch, OS, modo root/SUDO_USER
#   2. Garante git e python (>= 3.11)
#   3. Instala python-rich (dep do framework Python)
#   4. Clona (ou atualiza) o repo em ~/Projects/Arch-gabrln
#   5. Valida SHA256 do commit se GABRLN_SHA256 foi setado
#   6. exec python3 -m installer "$@"

set -euo pipefail

REPO_URL="https://github.com/gabrln/Arch-gabrln.git"
CLONE_SUBDIR="Projects/Arch-gabrln"
GABRLN_VERSION="${GABRLN_VERSION:-main}"
GABRLN_SHA256="${GABRLN_SHA256:-}"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error() {
  printf '%b[ERRO]%b %s\n' "$RED" "$NC" "$1" >&2
  exit "${2:-1}"
}

info() {
  printf '%b[INFO]%b %s\n' "$YELLOW" "$NC" "$1"
}

success() {
  printf '%b[OK]%b %s\n' "$GREEN" "$NC" "$1"
}

# --- Detecção de arch -------------------------------------------------------

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_NAME="amd64" ;;
  aarch64) ARCH_NAME="arm64" ;;
  *)
    error "Arquitetura não suportada: $ARCH. Suportados: x86_64, aarch64."
    ;;
esac
info "Arquitetura: $ARCH ($ARCH_NAME)"

# --- Detecção de OS ---------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
  error "/etc/os-release não encontrado. Sistema não suportado."
fi

# shellcheck disable=SC1091
source /etc/os-release

case "${ID:-unknown}" in
  arch|cachyos)
    info "Sistema: ${PRETTY_NAME:-$ID}"
    ;;
  *)
    error "Distribuição não suportada: ${ID:-desconhecida}. Suportados: Arch, CachyOS."
    ;;
esac

# --- Verificação de root -----------------------------------------------------

if [[ $EUID -ne 0 ]]; then
  error "Execute este script com sudo. Ex: curl ... | sudo bash"
fi

if [[ -z "${SUDO_USER:-}" ]]; then
  error "Não foi possível determinar SUDO_USER. Execute via sudo."
fi

if [[ "$SUDO_USER" == "root" ]]; then
  error "Execute como usuário normal com sudo."
fi

REAL_USER="$SUDO_USER"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
  error "Não foi possível determinar o HOME do usuário '$REAL_USER'."
fi

# --- Verificação de dependências do sistema ---------------------------------

if ! command -v git &>/dev/null; then
  info "Instalando git..."
  pacman -Sy --needed --noconfirm git
fi

if ! command -v python3 &>/dev/null; then
  error "python3 não encontrado. Instale-o antes de prosseguir."
fi

# Confirma Python >= 3.11 (necessário para tomllib)
PYTHON_VERSION=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [[ "$PYTHON_MAJOR" -lt 3 ]] || { [[ "$PYTHON_MAJOR" -eq 3 ]] && [[ "$PYTHON_MINOR" -lt 11 ]]; }; then
  error "Python 3.11+ necessário (encontrado: $PYTHON_VERSION)."
fi

# Garante runuser (parte do util-linux; sempre presente em Arch)
if ! command -v runuser &>/dev/null; then
  error "Comando 'runuser' não encontrado. Instale 'util-linux'."
fi

# Garante rich (TUI do framework)
if ! python3 -c "import rich" &>/dev/null; then
  info "Instalando python-rich..."
  if ! pacman -S --needed --noconfirm python-rich; then
    error "Falha ao instalar python-rich. Instale manualmente: pacman -S python-rich"
  fi
fi

# --- Clone ou update do repositório -----------------------------------------

REPO_DIR="$USER_HOME/$CLONE_SUBDIR"
GIT_CLONE_ARGS=(--depth=1)

# Para pin por SHA, não podemos usar --depth=1 (precisamos do commit exato)
if [[ -n "$GABRLN_SHA256" ]]; then
  GIT_CLONE_ARGS=()
fi

if [[ -d "$REPO_DIR/.git" ]]; then
  info "Atualizando repositório em $REPO_DIR..."
  chown -R "$REAL_USER:$REAL_USER" "$REPO_DIR" 2>/dev/null || true

  if [[ -n "$GABRLN_SHA256" ]]; then
    # Fetch completo para validar SHA
    runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' fetch --unshallow" \
      || error "git fetch falhou"
  fi

  runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' -c safe.directory='*' pull" \
    || error "git pull falhou em $REPO_DIR"

  # Se GABRLN_VERSION for uma tag/SHA, faz checkout
  if [[ "$GABRLN_VERSION" != "main" ]] && [[ "$GABRLN_VERSION" != "master" ]]; then
    info "Checkout para $GABRLN_VERSION..."
    runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' checkout '$GABRLN_VERSION'" \
      || error "git checkout falhou para $GABRLN_VERSION"
  fi
else
  info "Clonando repositório (versão: $GABRLN_VERSION) para $REPO_DIR..."
  if [[ ! -d "$USER_HOME" ]]; then
    error "HOME do usuário '$REAL_USER' não existe: $USER_HOME"
  fi

  if ! mkdir -p "$USER_HOME/Projects" 2>/dev/null; then
    runuser -u "$REAL_USER" -- bash -lc "mkdir -p '$USER_HOME/Projects'" \
      || error "Falha ao criar $USER_HOME/Projects"
  fi
  chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Projects"

  # Clone (full se SHA256 esperado, shallow caso contrário)
  if [[ -n "$GABRLN_SHA256" ]]; then
    runuser -u "$REAL_USER" -- bash -lc "git clone '$REPO_URL' '$REPO_DIR'" \
      || error "git clone falhou para $REPO_DIR"
    runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' checkout '$GABRLN_VERSION'" \
      || error "git checkout falhou para $GABRLN_VERSION"
  else
    runuser -u "$REAL_USER" -- bash -lc "git clone --depth=1 --branch '$GABRLN_VERSION' '$REPO_URL' '$REPO_DIR'" \
      || error "git clone falhou para $REPO_DIR"
  fi

  chown -R "$REAL_USER:$REAL_USER" "$REPO_DIR"
fi

# --- Validação opcional de SHA256 do commit ---------------------------------

if [[ -n "$GABRLN_SHA256" ]]; then
  info "Validando SHA256 do commit..."
  ACTUAL_SHA=$(runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' rev-parse HEAD" | tr -d '[:space:]')
  if [[ "$ACTUAL_SHA" != "$GABRLN_SHA256" ]]; then
    error "SHA256 mismatch: esperado $GABRLN_SHA256, obtido $ACTUAL_SHA"
  fi
  success "SHA256 validado: $ACTUAL_SHA"
fi

success "Repositório pronto em $REPO_DIR (versão: $GABRLN_VERSION)"
info "Executando o framework Python..."

# --- Delegar para o entrypoint Python ---------------------------------------

cd "$REPO_DIR"
export SUDO_USER USER_HOME REPO_DIR
exec env \
  SUDO_USER="$SUDO_USER" \
  USER_HOME="$USER_HOME" \
  REPO_DIR="$REPO_DIR" \
  NO_COLOR="${NO_COLOR:-}" \
  GABRLN_VERSION="$GABRLN_VERSION" \
  python3 -m installer "$@"
