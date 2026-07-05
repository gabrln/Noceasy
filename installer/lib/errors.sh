#!/usr/bin/env bash
# errors.sh - Tratamento de erros, traps e cleanup

set -euo pipefail

if [[ -n "${_LIB_ERRORS_SH:-}" ]]; then return 0; fi
_LIB_ERRORS_SH=1

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

declare -a _CLEANUP_HOOKS=()

register_cleanup() {
  _CLEANUP_HOOKS+=("$1")
}

run_cleanup() {
  local hook
  for hook in "${_CLEANUP_HOOKS[@]}"; do
    eval "$hook" || true
  done
}

_error_handler() {
  local line="$1"
  local command="$2"
  local code="$3"
  log_error "Erro na linha $line (código $code): $command"
  run_cleanup
}

_exit_handler() {
  local code=$?
  run_cleanup
  exit "$code"
}

setup_traps() {
  trap '_error_handler "$LINENO" "$BASH_COMMAND" "$?"' ERR
  trap '_exit_handler' EXIT
  trap 'run_cleanup; exit 130' INT TERM HUP
}

exit_with_error() {
  local message="$1"
  local code="${2:-1}"
  log_error "$message"
  run_cleanup
  exit "$code"
}

# Cria uma regra temporária no sudoers para o usuário real não precisar digitar senha.
# Deve ser chamada como root. O cleanup remove o arquivo.
setup_temp_sudoers() {
  if [[ -z "${REAL_USER:-}" ]]; then
    log_warn "REAL_USER não definido; pulando regra temporária do sudoers."
    return 0
  fi

  local temp_sudoers="/etc/sudoers.d/99-arch-gabrln-installer-temp"
  echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" >"$temp_sudoers"
  chmod 440 "$temp_sudoers"
  register_cleanup "rm -f '$temp_sudoers'"
  log_info "Regra temporária do sudoers criada para $REAL_USER"
}
