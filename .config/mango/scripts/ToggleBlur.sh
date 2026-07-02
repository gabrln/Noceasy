#!/usr/bin/env bash

source "$(dirname "$0")/lib_state.sh"

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
