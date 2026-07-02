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
