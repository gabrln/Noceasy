#!/usr/bin/env bash
# install.sh - Bootstrap for Noceasy (Noctalia quick installer)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/gabrln/Noceasy/main/install.sh | bash
#
# Environment variables:
#   NO_COLOR=1       Disables colors in Python too
#
# Behavior:
#   1. Detects arch, OS, current user
#   2. Ensures git and python (>= 3.11)
#   3. Installs python-rich (framework dep) via sudo
#   4. Clones (or updates) the repo in ~/Projects/Noceasy
#   5. exec python3 -m installer "$@"

set -euo pipefail

REPO_URL="https://github.com/gabrln/Noceasy.git"
CLONE_SUBDIR="Projects/Noceasy"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error() {
  printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$1" >&2
  exit 1
}

info() {
  printf '%b[INFO]%b %s\n' "$YELLOW" "$NC" "$1"
}

success() {
  printf '%b[OK]%b %s\n' "$GREEN" "$NC" "$1"
}

# --- Architecture detection --------------------------------------------------

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  ARCH_NAME="x86_64" ;;
  aarch64)       ARCH_NAME="aarch64" ;;
  *)             error "Unsupported architecture: $ARCH" ;;
esac
info "Architecture: $ARCH ($ARCH_NAME)"

# --- OS detection ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
  error "/etc/os-release not found. Unsupported system."
fi

# shellcheck disable=SC1091
source /etc/os-release

case "${ID:-unknown}" in
  arch|cachyos) ;;
  *)             error "Unsupported distribution: ${ID:-unknown}. Only Arch and CachyOS are supported." ;;
esac
info "Distribution: ${PRETTY_NAME:-$ID}"

# --- Current user detection ---------------------------------------------------

REAL_USER="$USER"
USER_HOME="$HOME"

if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
  error "Run as a normal user, not root."
fi

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
  error "Could not determine HOME for user '$REAL_USER'."
fi

info "User: $REAL_USER ($USER_HOME)"

# --- System deps -------------------------------------------------------------

if ! command -v git &>/dev/null; then
  info "Installing git..."
  sudo pacman -S --needed --noconfirm git >/dev/null 2>&1 || error "Failed to install git."
fi

if ! command -v python3 &>/dev/null; then
  error "python3 not found. Install it before continuing."
fi

# Confirm Python >= 3.11 (needed for tomllib)
PYTHON_VERSION=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [[ "$PYTHON_MAJOR" -lt 3 ]] || { [[ "$PYTHON_MAJOR" -eq 3 ]] && [[ "$PYTHON_MINOR" -lt 11 ]]; }; then
  error "Python 3.11+ required (found: $PYTHON_VERSION)."
fi

# Ensure rich (framework TUI dep)
if ! python3 -c "import rich" &>/dev/null; then
  info "Installing python-rich..."
  sudo pacman -S --needed --noconfirm python-rich >/dev/null 2>&1 \
    || error "Failed to install python-rich. Install it manually: sudo pacman -S python-rich"
fi

# --- Clone or update ---------------------------------------------------------

REPO_DIR="$USER_HOME/$CLONE_SUBDIR"

if [[ -d "$REPO_DIR/.git" ]]; then
  info "Updating repository in $REPO_DIR..."
  git -C "$REPO_DIR" -c safe.directory='*' pull \
    >/dev/null 2>&1 || error "git pull failed in $REPO_DIR"
else
  info "Cloning repository to $REPO_DIR..."
  mkdir -p "$USER_HOME/Projects"
  git clone --depth=1 "$REPO_URL" "$REPO_DIR" \
    >/dev/null 2>&1 || error "git clone failed to $REPO_DIR"
fi

success "Repository ready in $REPO_DIR"

# --- Delegate to Python entrypoint -------------------------------------------

cd "$REPO_DIR"
export USER_HOME REPO_DIR

# Disable 'set -e' for this call so we can inspect the exit code
# and print a clear error instead of silently returning to the shell.
set +e
env \
  USER_HOME="$USER_HOME" \
  REPO_DIR="$REPO_DIR" \
  NO_COLOR="${NO_COLOR:-}" \
  PYTHONIOENCODING="utf-8" \
  python3 -m installer "$@"
PY_EXIT=$?
set -e

if [[ $PY_EXIT -ne 0 ]]; then
  error "Python installer exited with code $PY_EXIT"
fi
