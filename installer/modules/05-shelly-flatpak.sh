#!/usr/bin/env bash
# 05-shelly-flatpak.sh - Instala pacotes Flatpak via shelly

if ! is_command flatpak; then
  log_warn "flatpak não está instalado. Pulando."
  return 0
fi

log_info "Configurando remote flathub..."
remote_url=$(toml_get "$MANIFESTS_DIR/flatpak.toml" "remote.url" "https://dl.flathub.org/repo/flathub.flatpakrepo")
flatpak remote-add --if-not-exists --system flathub "$remote_url"

mapfile -t FLATPAK_PKGS < <(python3 -c '
import sys, tomllib
file = sys.argv[1]
with open(file, "rb") as f:
    data = tomllib.load(f)
for pkg in data.get("packages", []):
    print(pkg["name"])
' "$MANIFESTS_DIR/flatpak.toml")

if [[ ${#FLATPAK_PKGS[@]} -eq 0 ]]; then
  log_warn "Nenhum pacote Flatpak a instalar."
  return 0
fi

missing_pkgs=()
for pkg in "${FLATPAK_PKGS[@]}"; do
  if ! flatpak info "$pkg" &>/dev/null; then
    missing_pkgs+=("$pkg")
  fi
done

if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
  log_success "Todos os pacotes Flatpak já estão instalados."
  return 0
fi

log_info "Instalando pacotes Flatpak pendentes: ${missing_pkgs[*]}"
for pkg in "${missing_pkgs[@]}"; do
  if ! shelly flatpak install -n "$pkg"; then
    log_warn "shelly falhou para $pkg. Tentando flatpak install direto..."
    flatpak install -y --system flathub "$pkg"
  fi
done

log_success "Pacotes Flatpak instalados."
