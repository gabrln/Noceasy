#!/usr/bin/env bash

info=$(mmsg get focusing-client 2>/dev/null)

if [[ -z "$info" ]]; then
  notify-send -t 4000 -i dialog-error "Informações da Janela Ativa" "Compositor MangoWM não encontrado ou nenhuma janela focada."
  exit 1
fi

id=$(echo "$info" | jq -r '.id // "N/A"')
pid=$(echo "$info" | jq -r '.pid // "N/A"')
appid=$(echo "$info" | jq -r '.appid // "N/A"')
title=$(echo "$info" | jq -r '.title // "N/A"')
monitor=$(echo "$info" | jq -r '.monitor // "N/A"')
tags=$(echo "$info" | jq -r '.tags | join(", ") // "N/A"')
floating=$(echo "$info" | jq -r '.is_floating // "false"')
fullscreen=$(echo "$info" | jq -r '.is_fullscreen // "false"')

msg="<b>ID:</b> $id\n<b>PID:</b> $pid\n<b>App ID (Classe):</b> $appid\n<b>Título:</b> $title\n<b>Monitor:</b> $monitor\n<b>Área de Trabalho (Tags):</b> $tags\n<b>Flutuante:</b> $floating\n<b>Tela Cheia:</b> $fullscreen"

notify-send -t 8000 -i dialog-information "Informações da Janela Ativa" "$msg"
