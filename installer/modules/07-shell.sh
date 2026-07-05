#!/usr/bin/env bash
# 07-shell.sh - Configura shell padrão e plugins do Zsh

log_info "Configurando shell padrão..."

if [[ "$(getent passwd "$REAL_USER" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
  log_info "Alterando shell padrão do usuário para Zsh..."
  chsh -s /usr/bin/zsh "$REAL_USER"
else
  log_info "Shell padrão já é Zsh."
fi

# Atualiza a variável SHELL no systemd user manager
REAL_UID=$(getent passwd "$REAL_USER" | cut -d: -f3)
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" systemctl --user set-environment SHELL=/usr/bin/zsh 2>/dev/null || true

log_info "Verificando plugins do Zsh..."
ZSH_PLUGINS_DIR="$USER_HOME/.config/zsh/plugins"
run_as_user "mkdir -p '$ZSH_PLUGINS_DIR'"

plugins_json=$(python3 -c '
import sys, json, tomllib
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
print(json.dumps(data.get("plugins", [])))
' "$MANIFESTS_DIR/zsh-plugins.toml")

plugin_count=$(echo "$plugins_json" | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))')

for i in $(seq 0 $((plugin_count - 1))); do
  name=$(echo "$plugins_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['name'])")
  repo=$(echo "$plugins_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['repo'])")
  entry=$(echo "$plugins_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['entry'])")
  plugin_path="$ZSH_PLUGINS_DIR/$name"

  if [[ -d "$plugin_path/$entry" || -f "$plugin_path/$entry" ]]; then
    log_success "Plugin $name já instalado. Pulando."
    continue
  fi

  log_info "Instalando plugin: $name..."
  if [[ -d "$plugin_path" ]]; then
    run_as_user "rm -rf '$plugin_path'"
  fi
  run_as_user "git clone --depth=1 'https://github.com/$repo.git' '$plugin_path'"
  log_success "Plugin $name instalado."
done

log_success "Shell e plugins configurados."
