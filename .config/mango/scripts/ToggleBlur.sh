#!/usr/bin/env bash

STATE_FILE="$HOME/.config/mango/dyn_settings.conf"
mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"

get_val() {
  local key=$1
  local default=$2
  local val=$(grep -E "^${key}=" "$STATE_FILE" | cut -d= -f2)
  if [[ -n "$val" ]]; then
    echo "$val"
  else
    echo "$default"
  fi
}

set_val() {
  local key=$1
  local val=$2
  if grep -q -E "^${key}=" "$STATE_FILE"; then
    sed -i "s/^${key}=.*/${key}=${val}/" "$STATE_FILE"
  else
    echo "${key}=${val}" >> "$STATE_FILE"
  fi
}

CURRENT_BLUR=$(get_val "blur" "1")

if [[ "$CURRENT_BLUR" == "1" ]]; then
  set_val "blur" "0"
  mmsg dispatch reload_config
  notify-send "Blur Desativado" "Efeito de desfoque das janelas desativado." -t 2000
else
  set_val "blur" "1"
  mmsg dispatch reload_config
  notify-send "Blur Ativado" "Efeito de desfoque das janelas ativado." -t 2000
fi
