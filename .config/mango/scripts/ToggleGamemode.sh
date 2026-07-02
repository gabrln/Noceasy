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

CURRENT_ANIMATIONS=$(get_val "animations" "1")

if [[ "$CURRENT_ANIMATIONS" == "1" ]]; then
  set_val "animations" "0"
  set_val "blur" "0"
  set_val "shadows" "0"
  set_val "gappih" "0"
  set_val "gappiv" "0"
  set_val "gappoh" "0"
  set_val "gappov" "0"
  mmsg dispatch reload_config
  notify-send "Modo Jogo Ativado" "Animações, blur, sombras e espaçamentos desativados." -t 2000
else
  set_val "animations" "1"
  set_val "blur" "1"
  set_val "shadows" "1"
  set_val "gappih" "5"
  set_val "gappiv" "5"
  set_val "gappoh" "5"
  set_val "gappov" "5"
  mmsg dispatch reload_config
  notify-send "Modo Jogo Desativado" "Configurações restauradas." -t 2000
fi
