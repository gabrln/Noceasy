#!/usr/bin/env bash
# logger.sh - Logging estruturado para o framework Arch-gabrln

set -euo pipefail

if [[ -n "${_LIB_LOGGER_SH:-}" ]]; then return 0; fi
_LIB_LOGGER_SH=1

# Cores
readonly C_RESET='\033[0m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[1;33m'
readonly C_RED='\033[0;31m'
readonly C_CYAN='\033[0;36m'

# Níveis
readonly L_INFO="INFO"
readonly L_WARN="WARN"
readonly L_ERROR="ERROR"
readonly L_SUCCESS="SUCCESS"

LOG_FILE=""

log_init() {
  local log_dir="$1"
  mkdir -p "$log_dir"
  LOG_FILE="$log_dir/gabrln-$(date +%Y%m%d-%H%M%S).log"
  touch "$LOG_FILE"
}

_log_raw() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local line="[$timestamp] [$level] $message"

  if [[ -n "$LOG_FILE" ]]; then
    echo "$line" >>"$LOG_FILE"
  fi
}

log_info() {
  local message="$1"
  _log_raw "$L_INFO" "$message"
  echo -e "${C_BLUE}[INFO]${C_RESET} $message"
}

log_warn() {
  local message="$1"
  _log_raw "$L_WARN" "$message"
  echo -e "${C_YELLOW}[WARN]${C_RESET} $message" >&2
}

log_error() {
  local message="$1"
  _log_raw "$L_ERROR" "$message"
  echo -e "${C_RED}[ERROR]${C_RESET} $message" >&2
}

log_success() {
  local message="$1"
  _log_raw "$L_SUCCESS" "$message"
  echo -e "${C_GREEN}[OK]${C_RESET} $message"
}

log_step() {
  local message="$1"
  _log_raw "$L_INFO" "STEP: $message"
  echo -e "${C_CYAN}==>${C_RESET} $message"
}

log_cmd() {
  local cmd="$*"
  _log_raw "$L_INFO" "EXEC: $cmd"
}
