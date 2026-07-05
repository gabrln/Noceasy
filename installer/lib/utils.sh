#!/usr/bin/env bash
# utils.sh - Utilitários compartilhados do framework Arch-gabrln

set -euo pipefail

if [[ -n "${_LIB_UTILS_SH:-}" ]]; then return 0; fi
_LIB_UTILS_SH=1

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Detecta o usuário real e seu HOME.
# Deve ser chamado após confirmar que o script roda com sudo.
detect_real_user() {
  if [[ "${EUID:-}" -ne 0 ]]; then
    log_error "Este comando deve ser executado com sudo."
    exit 1
  fi

  if [[ -z "${SUDO_USER:-}" ]]; then
    log_error "Não foi possível determinar SUDO_USER. Execute via 'sudo ./gabrln ...'."
    exit 1
  fi

  REAL_USER="$SUDO_USER"
  USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

  if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    log_error "Não foi possível determinar o HOME do usuário '$REAL_USER'."
    exit 1
  fi

  export REAL_USER USER_HOME
}

# Executa um comando como o usuário real, preservando PATH e HOME.
run_as_user() {
  local cmd="$1"
  shift || true
  if [[ "${EUID:-}" -eq 0 ]]; then
    # shellcheck disable=SC2024
    sudo -u "$REAL_USER" --preserve-env=PATH,HOME bash -c "$cmd" "$@"
  else
    bash -c "$cmd" "$@"
  fi
}

# Verifica se um comando existe no PATH.
is_command() {
  command -v "$1" &>/dev/null
}

# Verifica conectividade com a internet (github.com como referência).
has_internet() {
  curl -fsSI --max-time 5 https://github.com &>/dev/null
}

# Verifica espaço livre mínimo em disco (bytes).
has_free_space() {
  local path="${1:-$USER_HOME}"
  local min_bytes="${2:-1073741824}" # 1 GiB padrão
  local available
  available=$(df -B1 "$path" | awk 'NR==2 {print $4}')
  [[ "$available" -ge "$min_bytes" ]]
}

# Lê um valor simples de um TOML via Python tomllib.
# Uso: toml_get "arquivo.toml" "secao.chave" [default]
toml_get() {
  local file="$1"
  local key="$2"
  local default="${3:-}"

  if [[ ! -f "$file" ]]; then
    echo "$default"
    return 0
  fi

  python3 -c '
import sys, tomllib
file, key, default = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(file, "rb") as f:
        data = tomllib.load(f)
    for part in key.split("."):
        if not isinstance(data, dict) or part not in data:
            print(default)
            sys.exit(0)
        data = data[part]
    if isinstance(data, list):
        print("\n".join(str(x) for x in data))
    elif isinstance(data, bool):
        print("true" if data else "false")
    else:
        print(data)
except Exception:
    print(default)
' "$file" "$key" "$default"
}

# Lista as chaves de uma tabela TOML.
# Uso: toml_keys "arquivo.toml" "secao"
toml_keys() {
  local file="$1"
  local section="${2:-}"

  python3 -c '
import sys, tomllib
file, section = sys.argv[1], sys.argv[2]
try:
    with open(file, "rb") as f:
        data = tomllib.load(f)
    if section:
        for part in section.split("."):
            data = data.get(part, {})
    if isinstance(data, dict):
        print("\n".join(str(k) for k in data.keys()))
except Exception:
    pass
' "$file" "$section"
}

# Retorna 0 se o arquivo for um script executável ou estiver em scripts/.
needs_executable_bit() {
  local file="$1"
  [[ "$file" == *.sh ]] || [[ "$file" == */scripts/* ]]
}
