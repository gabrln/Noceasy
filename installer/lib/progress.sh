#!/usr/bin/env bash
# progress.sh - Barra de progresso simples por módulo

set -euo pipefail

if [[ -n "${_LIB_PROGRESS_SH:-}" ]]; then return 0; fi
_LIB_PROGRESS_SH=1

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

_PROGRESS_TOTAL=0
_PROGRESS_CURRENT=0

progress_init() {
  _PROGRESS_TOTAL="$1"
  _PROGRESS_CURRENT=0
}

progress_step() {
  local message="$1"
  _PROGRESS_CURRENT=$((_PROGRESS_CURRENT + 1))

  local width=30
  local filled=$((_PROGRESS_CURRENT * width / _PROGRESS_TOTAL))
  local empty=$((width - filled))
  local bar
  bar=$(printf '%*s' "$filled" '' | tr ' ' '=')
  local space
  space=$(printf '%*s' "$empty" '' | tr ' ' '-')

  log_step "[$_PROGRESS_CURRENT/$_PROGRESS_TOTAL] [$bar$space] $message"
}

progress_done() {
  log_success "Concluído ($_PROGRESS_CURRENT/$_PROGRESS_TOTAL)."
}
