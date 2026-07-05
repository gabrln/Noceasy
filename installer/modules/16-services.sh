#!/usr/bin/env bash
# 16-services.sh - Habilita serviços systemd declarados no manifesto

log_info "Lendo serviços do manifesto..."

mapfile -t SERVICES < <(python3 -c '
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
for svc in data.get("services", []):
    print(svc["name"])
' "$MANIFESTS_DIR/services.toml")

if [[ ${#SERVICES[@]} -eq 0 ]]; then
  log_warn "Nenhum serviço configurado. Pulando."
  return 0
fi

log_info "Habilitando serviços do Systemd..."
for svc in "${SERVICES[@]}"; do
  log_info "  → $svc"
  systemctl enable "$svc" 2>/dev/null || true
done

log_success "Serviços habilitados."
