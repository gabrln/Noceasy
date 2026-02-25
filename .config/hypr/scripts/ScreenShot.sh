#!/usr/bin/env bash

# Variáveis
time=$(date "+%d-%b_%H-%M-%S")
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${dir}/${active_window_file}"

# Contagem decrescente silenciosa
countdown() {
  for sec in $(seq $1 -1 1); do
    sleep 1
  done
}

# Funções de captura
shotnow() {
  cd "${dir}" && grim - | tee "$file" | wl-copy
}

shot5() {
  countdown '5'
  cd "${dir}" && grim - | tee "$file" | wl-copy
}

shot10() {
  countdown '10'
  cd "${dir}" && grim - | tee "$file" | wl-copy
}

shotwin() {
  w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
  w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
  cd "${dir}" && grim -g "$w_pos $w_size" - | tee "$file" | wl-copy
}

shotarea() {
  tmpfile=$(mktemp)
  grim -g "$(slurp)" - >"$tmpfile"

  if [[ -s "$tmpfile" ]]; then
    wl-copy <"$tmpfile"
    mv "$tmpfile" "${dir}/${file}"
  fi
}

shotactive() {
  hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "${active_window_path}"
}

shotswappy() {
  tmpfile=$(mktemp)
  grim -g "$(slurp)" - >"$tmpfile"

  if [[ -s "$tmpfile" ]]; then
    wl-copy <"$tmpfile"
    swappy -f "$tmpfile"
    rm "$tmpfile"
  fi
}

# Execução principal
if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
  shotnow
elif [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--in10" ]]; then
  shot10
elif [[ "$1" == "--win" ]]; then
  shotwin
elif [[ "$1" == "--area" ]]; then
  shotarea
elif [[ "$1" == "--active" ]]; then
  shotactive
elif [[ "$1" == "--swappy" ]]; then
  shotswappy
else
  echo -e "Opções disponíveis: --now --in5 --in10 --win --area --active --swappy"
fi

exit 0
