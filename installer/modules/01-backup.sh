#!/usr/bin/env bash
# 01-backup.sh - Snapshot das configurações antes de modificá-las

auto_backup=$(toml_get "$CONFIG_FILE" "flags.auto_backup" "true")

if [[ "$auto_backup" != "true" ]]; then
  log_info "Backup automático desabilitado. Pulando."
  return 0
fi

log_info "Criando snapshot das configurações atuais..."

# Coleta caminhos a partir do manifesto de dotfiles
config_paths=()

# ~/.config/<config>
while IFS= read -r cfg; do
  [[ -n "$cfg" ]] && config_paths+=("$USER_HOME/.config/$cfg")
done < <(python3 -c '
import sys, tomllib
file = sys.argv[1]
with open(file, "rb") as f:
    data = tomllib.load(f)
for c in data.get("directories", {}).get("configs", []):
    print(c)
' "$MANIFESTS_DIR/dotfiles.toml")

# zsh (caso especial)
config_paths+=("$USER_HOME/.config/zsh")

# arquivos avulsos
while IFS= read -r f; do
  [[ -n "$f" ]] && config_paths+=("$f")
done < <(python3 -c '
import sys, tomllib, os
file = sys.argv[1]
home = sys.argv[2]
with open(file, "rb") as f:
    data = tomllib.load(f)
for src, dst in data.get("files", {}).items():
    expanded = os.path.expandvars(dst)
    if expanded.startswith("~"):
        expanded = home + expanded[1:]
    print(expanded)
' "$MANIFESTS_DIR/dotfiles.toml" "$USER_HOME")

# arquivos de sistema
config_paths+=("/etc/greetd")
config_paths+=("/etc/pam.d/greetd")

backup_name=$(backup_create "pre-install" "${config_paths[@]}")
log_success "Snapshot criado: $backup_name"
