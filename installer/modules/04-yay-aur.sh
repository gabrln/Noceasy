#!/usr/bin/env bash
# 04-yay-aur.sh - Instala pacotes AUR via yay

log_info "Lendo pacotes AUR do manifesto..."

mapfile -t AUR_PKGS < <(python3 -c '
import sys, tomllib
file, gaming = sys.argv[1], sys.argv[2] == "true"
with open(file, "rb") as f:
    data = tomllib.load(f)
for pkg in data.get("packages", []):
    tags = pkg.get("tags", [])
    if "gaming" in tags and not gaming:
        continue
    print(pkg["name"])
' "$MANIFESTS_DIR/aur.toml" "$GAMING")

if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
  log_warn "Nenhum pacote AUR a instalar."
  return 0
fi

log_info "Verificando pacotes AUR já instalados..."
# pacman -T retorna pacotes separados por newline; usamos mapfile para
# preservar a lista como array e evitar que newlines quebrem o comando shell
mapfile -t MISSING_ARR < <(pacman -T "${AUR_PKGS[@]}" 2>/dev/null || true)

if [[ ${#MISSING_ARR[@]} -eq 0 ]]; then
  log_success "Todos os pacotes AUR já estão instalados."
  return 0
fi

log_info "Instalando pacotes AUR pendentes via yay: ${MISSING_ARR[*]}"
# yay nunca deve rodar como root (recusa por padrão) -> run_as_user.
# Flags reais do yay para lote não-interativo (não existe um único "--silent"):
#   --noconfirm       não pede confirmação de instalação
#   --nocleanmenu     não mostra menu de limpeza de pacotes órfãos de build
#   --nodiffmenu      não mostra diff do PKGBUILD
#   --noeditmenu      não abre editor para o PKGBUILD
#   --noupgrademenu   não mostra menu de seleção de upgrades
#   --removemake      remove makedepends após o build (mantém sistema limpo)
quoted_args=$(printf '%q ' "${MISSING_ARR[@]}")
run_as_user "yay -S --needed --noconfirm --nocleanmenu --nodiffmenu --noeditmenu --noupgrademenu --removemake $quoted_args"

hash -r

mapfile -t STILL_MISSING < <(pacman -T "${MISSING_ARR[@]}" 2>/dev/null || true)
if [[ ${#STILL_MISSING[@]} -gt 0 ]]; then
  exit_with_error "Pacotes AUR não confirmados após instalação: ${STILL_MISSING[*]}"
fi

log_success "Pacotes AUR instalados e confirmados."
