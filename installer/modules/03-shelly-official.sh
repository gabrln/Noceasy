#!/usr/bin/env bash
# 03-shelly-official.sh - Instala pacotes oficiais via shelly

log_info "Lendo pacotes oficiais do manifesto..."

# Extrai nomes dos pacotes, respeitando a flag --gaming
mapfile -t OFFICIAL_PKGS < <(python3 -c '
import sys, tomllib
file, gaming = sys.argv[1], sys.argv[2] == "true"
with open(file, "rb") as f:
    data = tomllib.load(f)
for pkg in data.get("packages", []):
    tags = pkg.get("tags", [])
    if "gaming" in tags and not gaming:
        continue
    print(pkg["name"])
' "$MANIFESTS_DIR/packages.toml" "$GAMING")

if [[ ${#OFFICIAL_PKGS[@]} -eq 0 ]]; then
  log_warn "Nenhum pacote oficial a instalar."
  return 0
fi

log_info "Verificando pacotes já instalados..."
MISSING=$(pacman -T "${OFFICIAL_PKGS[@]}" 2>/dev/null || true)

if [[ -z "$MISSING" ]]; then
  log_success "Todos os pacotes oficiais já estão instalados."
  return 0
fi

log_info "Instalando pacotes oficiais pendentes via shelly..."
# shellcheck disable=SC2086
shelly install --no-confirm $MISSING

hash -r
log_success "Pacotes oficiais instalados."
