#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# SCRIPT: MagicMonitor.sh
# OBJETIVO: Ouvir o Hyprland e enviar notificações Toast para o Noctalia
# ═══════════════════════════════════════════════════════════════════════════

# Proteção: Verifica se o socat está instalado
if ! command -v socat &>/dev/null; then
  echo "ERRO: O socat não está instalado."
  exit 1
fi

# Ouve o canal de eventos do Hyprland continuamente
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do

  # ─── O MAGIC FOI ABERTO ───
  # Aspas no texto literal para proteger os '>>', e o asterisco fora para funcionar
  if [[ "$line" == "activespecial>>special:magic,"* ]]; then

    qs -c noctalia-shell ipc call toast send '{"title":"🪄 MODO MAGIC","body":"Workspace Especial Ativado","type":"notice","duration":3000}'

  # ─── O MAGIC FOI FECHADO ───
  elif [[ "$line" == "activespecial>>,"* ]]; then

    qs -c noctalia-shell ipc call toast send '{"title":"🪄 MODO MAGIC","body":"Workspace Especial Desativado","type":"notice","duration":2000}'

  fi

done
