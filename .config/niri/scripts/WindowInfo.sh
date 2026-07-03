#!/usr/bin/env bash
# WindowInfo.sh - Niri adaptation to display focused window details via notify-send

info=$(niri msg -j windows 2>/dev/null | jq -c '.[] | select(.is_focused == true)')

if [[ -z "$info" ]]; then
  notify-send -t 4000 -i dialog-error "Informações da Janela Ativa" "Nenhuma janela focada localizada no Niri."
  exit 1
fi

id=$(echo "$info" | jq -r '.id // "N/A"')
pid=$(echo "$info" | jq -r '.pid // "N/A"')
appid=$(echo "$info" | jq -r '.app_id // "N/A"')
title=$(echo "$info" | jq -r '.title // "N/A"')
workspace_id=$(echo "$info" | jq -r '.workspace_id // "N/A"')
floating=$(echo "$info" | jq -r '.is_floating // "false"')

# Get workspace name if available
ws_name=$(niri msg -j workspaces 2>/dev/null | jq -r ".[] | select(.id == ${workspace_id}) | .name // \"${workspace_id}\"")

msg="<b>ID:</b> $id\n<b>PID:</b> $pid\n<b>App ID (Classe):</b> $appid\n<b>Título:</b> $title\n<b>Área de Trabalho:</b> $ws_name\n<b>Flutuante:</b> $floating"

notify-send -t 8000 -i dialog-information "Informações da Janela Ativa" "$msg"
