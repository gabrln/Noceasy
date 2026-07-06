#!/usr/bin/env bash
# 12-hyprpm-manifest.sh - Instala plugins hyprpm declarados no manifesto
#
# A logica de hyprpm vive inteiramente aqui (no instalador) e NAO no
# autostart.lua. Rodar hyprpm no autostart tem dois problemas:
#   1. Faz o Hyprland esperar build+download de plugins a cada login
#      (3-10s atrasando a sessao grafica).
#   2. Se a rede cair, o login fica meio-funcional at voce corrigir.
# Como instalador, garantimos que os plugins estao prontos ANTES do
# primeiro login. Hyprpm opera em modo CLI independente do Hyprland
# estar rodando (ele manipula ~/.local/share/hyprpm/ e o hyprland.conf).

if ! is_command hyprpm; then
  log_warn "hyprpm não está instalado. Pulando manifesto de plugins."
  return 0
fi

mapfile -t PLUGINS < <(python3 -c '
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
for p in data.get("plugins", []):
    print(p["name"] + "|" + p["repo"])
' "$MANIFESTS_DIR/hyprpm.toml")

if [[ ${#PLUGINS[@]} -eq 0 ]]; then
  log_warn "Nenhum plugin hyprpm configurado. Pulando."
  return 0
fi

log_info "Sincronizando base do hyprpm..."
run_as_user "hyprpm update" || log_warn "hyprpm update falhou. Continuando mesmo assim."

for entry in "${PLUGINS[@]}"; do
  name="${entry%%|*}"
  repo="${entry#*|}"

  if run_as_user "hyprpm list 2>/dev/null | grep -q ${name}"; then
    log_success "Plugin $name já está instalado. Pulando."
    continue
  fi

  log_info "Instalando plugin hyprpm: $name (repo: $repo)..."
  if ! run_as_user "hyprpm add https://github.com/${repo}.git"; then
    log_warn "Falha ao adicionar $name. Continuando."
    continue
  fi
  if ! run_as_user "hyprpm enable ${name}"; then
    log_warn "Falha ao habilitar $name. Continuando."
    continue
  fi
  log_success "Plugin $name instalado e habilitado."
done

log_success "Manifesto hyprpm aplicado."
