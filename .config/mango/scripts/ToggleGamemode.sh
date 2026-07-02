#!/usr/bin/env bash

source "$(dirname "$0")/lib_state.sh"

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
