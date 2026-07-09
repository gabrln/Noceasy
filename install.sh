#!/usr/bin/env bash
# install.sh - Bootstrap for Noceasy (Noctalia quick installer)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/gabrln/Noceasy/main/install.sh | bash
#   NOCEASY_VERSION=v1.5.0 bash install.sh
#
# Environment variables:
#   NOCEASY_VERSION  Tag/branch to clone (default: main)
#   NOCEASY_SHA256   SHA256 of the commit/tag (optional, validates after clone)
#   NO_COLOR=1       Disables colors in Python too
#
# Behavior:
#   1. Detects arch, OS, current user
#   2. Ensures git and python (>= 3.11)
#   3. Installs python-rich (framework dep)
#   4. Clones (or updates) the repo in ~/Projects/Noceasy
#   5. Validates SHA256 of the commit if NOCEASY_SHA256 is set
#   6. exec python3 -m installer "$@"

set -euo pipefail

REPO_URL="https://github.com/gabrln/Noceasy.git"
CLONE_SUBDIR="Projects/Noceasy"
NOCEASY_VERSION="${NOCEASY_VERSION:-main}"
NOCEASY_SHA256="${NOCEASY_SHA256:-}"

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

# --- Architecture detection --------------------------------------------------

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_NAME="amd64" ;;
  aarch64) ARCH_NAME="arm64" ;;
  *)
    error "Unsupported architecture: $ARCH. Supported: x86_64, aarch64."
    ;;
esac
info "Architecture: $ARCH ($ARCH_NAME)"

# --- OS detection ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
  error "/etc/os-release not found. Unsupported system."
fi

# shellcheck disable=SC1091
source /etc/os-release

case "${ID:-unknown}" in
  arch|cachyos)
    info "System: ${PRETTY_NAME:-$ID}"
    ;;
  *)
    error "Unsupported distribution: ${ID:-unknown}. Supported: Arch, CachyOS."
    ;;
esac

# --- Current user detection ---------------------------------------------------

REAL_USER="$USER"
USER_HOME="$HOME"

if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
  error "Run as a normal user, not root."
fi

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
  error "Could not determine HOME for user '$REAL_USER'."
fi

# --- System deps -------------------------------------------------------------

if ! command -v git &>/dev/null; then
  info "Installing git..."
  sudo pacman -Sy --needed --noconfirm git
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

# Ensure runuser (part of util-linux; always present on Arch)
if ! command -v runuser &>/dev/null; then
  error "Command 'runuser' not found. Install 'util-linux'."
fi

# Ensure rich (framework TUI dep)
if ! python3 -c "import rich" &>/dev/null; then
  info "Installing python-rich..."
  if ! sudo pacman -S --needed --noconfirm python-rich; then
    error "Failed to install python-rich. Install manually: pacman -S python-rich"
  fi
fi

# --- Clone or update ---------------------------------------------------------

REPO_DIR="$USER_HOME/$CLONE_SUBDIR"
GIT_CLONE_ARGS=(--depth=1)

# For SHA pin, we can't use --depth=1 (we need the exact commit)
if [[ -n "$NOCEASY_SHA256" ]]; then
  GIT_CLONE_ARGS=()
fi

if [[ -d "$REPO_DIR/.git" ]]; then
  info "Updating repository in $REPO_DIR..."
  chown -R "$REAL_USER:$REAL_USER" "$REPO_DIR" 2>/dev/null || true

  if [[ -n "$NOCEASY_SHA256" ]]; then
      runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' fetch --unshallow" \
        >/dev/null 2>&1 || error "git fetch failed"
  fi

  runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' -c safe.directory='*' pull" \
    >/dev/null 2>&1 || error "git pull failed in $REPO_DIR"

  # If NOCEASY_VERSION is a tag/SHA, check it out
  if [[ "$NOCEASY_VERSION" != "main" ]] && [[ "$NOCEASY_VERSION" != "master" ]]; then
    info "Checking out $NOCEASY_VERSION..."
    runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' checkout '$NOCEASY_VERSION'" \
      || error "git checkout failed for $NOCEASY_VERSION"
  fi
else
  info "Cloning repository (version: $NOCEASY_VERSION) to $REPO_DIR..."
  if [[ ! -d "$USER_HOME" ]]; then
    error "HOME for user '$REAL_USER' does not exist: $USER_HOME"
  fi

  if ! mkdir -p "$USER_HOME/Projects" 2>/dev/null; then
    runuser -u "$REAL_USER" -- bash -lc "mkdir -p '$USER_HOME/Projects'" \
      || error "Failed to create $USER_HOME/Projects"
  fi
  chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Projects"

  if [[ -n "$NOCEASY_SHA256" ]]; then
    runuser -u "$REAL_USER" -- bash -lc "git clone '$REPO_URL' '$REPO_DIR'" \
      >/dev/null 2>&1 || error "git clone failed to $REPO_DIR"
    runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' checkout '$NOCEASY_VERSION'" \
      >/dev/null 2>&1 || error "git checkout failed for $NOCEASY_VERSION"
  else
    runuser -u "$REAL_USER" -- bash -lc "git clone --depth=1 --branch '$NOCEASY_VERSION' '$REPO_URL' '$REPO_DIR'" \
      >/dev/null 2>&1 || error "git clone failed to $REPO_DIR"
  fi

  chown -R "$REAL_USER:$REAL_USER" "$REPO_DIR"
fi

# --- Optional SHA256 validation ----------------------------------------------

if [[ -n "$NOCEASY_SHA256" ]]; then
  info "Validating commit SHA256..."
  ACTUAL_SHA=$(runuser -u "$REAL_USER" -- bash -lc "git -C '$REPO_DIR' rev-parse HEAD" | tr -d '[:space:]')
  if [[ "$ACTUAL_SHA" != "$NOCEASY_SHA256" ]]; then
    error "SHA256 mismatch: expected $NOCEASY_SHA256, got $ACTUAL_SHA"
  fi
  success "SHA256 validated: $ACTUAL_SHA"
fi

success "Repository ready in $REPO_DIR (version: $NOCEASY_VERSION)"

# --- Delegate to Python entrypoint -------------------------------------------

cd "$REPO_DIR"
export SUDO_USER USER_HOME REPO_DIR

# Disable 'set -e' for this call so we can inspect the exit code
# and print a clear error instead of silently returning to the shell.
set +e
env \
  SUDO_USER="$SUDO_USER" \
  USER_HOME="$USER_HOME" \
  REPO_DIR="$REPO_DIR" \
  NO_COLOR="${NO_COLOR:-}" \
  NOCEASY_VERSION="$NOCEASY_VERSION" \
  PYTHONIOENCODING="utf-8" \
  python3 -m installer "$@"
PY_EXIT=$?
set -e

if [[ $PY_EXIT -ne 0 ]]; then
  error "Python installer exited with code $PY_EXIT"
fi
