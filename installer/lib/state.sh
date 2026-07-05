#!/usr/bin/env bash
# state.sh - Gerenciamento de estado persistente entre execuções

set -euo pipefail

if [[ -n "${_LIB_STATE_SH:-}" ]]; then return 0; fi
_LIB_STATE_SH=1

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

STATE_DIR=""
STATE_FILE=""

state_init() {
  STATE_DIR="$1"
  STATE_FILE="$STATE_DIR/state.json"
  mkdir -p "$STATE_DIR"
  if [[ ! -f "$STATE_FILE" ]]; then
    echo '{}' >"$STATE_FILE"
  fi
}

# Calcula um hash simples (sha256) de um arquivo ou diretório.
state_hash() {
  local target="$1"
  if [[ -f "$target" ]]; then
    sha256sum "$target" | awk '{print $1}'
  elif [[ -d "$target" ]]; then
    find "$target" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
  else
    echo ""
  fi
}

# Lê um campo do estado de um módulo.
# Uso: state_get <module> <field>
state_get() {
  local module="$1"
  local field="$2"

  python3 -c '
import sys, json, pathlib
state_file, module, field = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.loads(pathlib.Path(state_file).read_text())
    print(data.get(module, {}).get(field, ""))
except Exception:
    print("")
' "$STATE_FILE" "$module" "$field"
}

# Define um campo do estado de um módulo.
# Uso: state_set <module> <field> <value>
state_set() {
  local module="$1"
  local field="$2"
  local value="$3"

  python3 -c '
import sys, json, pathlib
state_file, module, field, value = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
data = {}
try:
    data = json.loads(pathlib.Path(state_file).read_text())
except Exception:
    pass
if module not in data:
    data[module] = {}
data[module][field] = value
pathlib.Path(state_file).write_text(json.dumps(data, indent=2, sort_keys=True))
' "$STATE_FILE" "$module" "$field" "$value"
}

# Marca um módulo como concluído, armazenando o hash do manifesto.
state_mark_done() {
  local module="$1"
  local manifest="${2:-}"
  local hash_value=""
  if [[ -n "$manifest" && -e "$manifest" ]]; then
    hash_value=$(state_hash "$manifest")
  fi
  state_set "$module" "status" "done"
  state_set "$module" "manifest_hash" "$hash_value"
  state_set "$module" "completed_at" "$(date -Iseconds)"
}

# Verifica se um módulo já foi concluído com o mesmo manifesto.
state_is_up_to_date() {
  local module="$1"
  local manifest="${2:-}"
  local status
  status=$(state_get "$module" "status")
  [[ "$status" == "done" ]] || return 1

  if [[ -n "$manifest" && -e "$manifest" ]]; then
    local current_hash
    current_hash=$(state_hash "$manifest")
    local stored_hash
    stored_hash=$(state_get "$module" "manifest_hash")
    [[ "$current_hash" == "$stored_hash" ]]
  else
    return 0
  fi
}
