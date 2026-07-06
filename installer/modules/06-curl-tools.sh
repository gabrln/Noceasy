#!/usr/bin/env bash
# 06-curl-tools.sh - Instala ferramentas via curl/sh

log_info "Verificando ferramentas de coding AI..."

# Garante que ~/.local/bin existe para receber os binários instalados via curl
LOCAL_BIN="$USER_HOME/.local/bin"
if [[ ! -d "$LOCAL_BIN" ]]; then
  log_info "Criando $LOCAL_BIN..."
  sudo -u "$REAL_USER" HOME="$USER_HOME" PATH="$PATH" mkdir -p "$LOCAL_BIN" \
    || log_warn "Não foi possível criar $LOCAL_BIN. As ferramentas podem falhar ao instalar."
fi

# Lê a lista de ferramentas do manifesto
tools_json=$(python3 -c '
import sys, json, tomllib
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
print(json.dumps(data.get("tools", [])))
' "$MANIFESTS_DIR/curl-tools.toml")

tool_count=$(echo "$tools_json" | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))')

for i in $(seq 0 $((tool_count - 1))); do
  name=$(echo "$tools_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['name'])")
  install_url=$(echo "$tools_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['install_url'])")
  env_var=$(echo "$tools_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i].get('env_var', ''))")
  env_value=$(echo "$tools_json" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i].get('env_value', ''))")

  # Coleta nomes de binários e caminhos de fallback
  mapfile -t binaries < <(echo "$tools_json" | python3 -c "import sys, json; [print(x) for x in json.load(sys.stdin)[$i].get('binaries', [])]")
  mapfile -t fallback_paths < <(echo "$tools_json" | python3 -c "import sys, json, os; home=sys.argv[1]; [print(os.path.expandvars(x).replace('~', home)) for x in json.load(sys.stdin)[$i].get('fallback_paths', [])]" "$USER_HOME")

  already_installed=false
  for bin_name in "${binaries[@]}"; do
    if is_command "$bin_name"; then
      already_installed=true
      break
    fi
  done

  for path in "${fallback_paths[@]}"; do
    if [[ -f "$path" ]]; then
      already_installed=true
      break
    fi
  done

  if [[ "$already_installed" == true ]]; then
    log_success "$name já está instalado. Pulando."
    continue
  fi

  log_info "Instalando $name..."
  env_prefix=""
  if [[ -n "$env_var" ]]; then
    env_prefix="$env_var='$env_value'"
  fi

  # shellcheck disable=SC2086
  # setsid -w cria uma nova sessão sem terminal de controle e espera o
  # processo terminar. Com stdin redirecionado de /dev/null, qualquer
  # isatty() do instalador de terceiros avalia falso, evitando prompts
  # que travariam a instalação. A saída fica em log por ferramenta
  # para auditoria em caso de falha.
  run_as_user "setsid -w bash -c \"$env_prefix curl -fsSL '$install_url' | bash\" </dev/null >>'$LOGS_DIR/curl-tools-$name.log' 2>&1" || true

  # Re-verifica
  installed_now=false
  for bin_name in "${binaries[@]}"; do
    if is_command "$bin_name"; then
      installed_now=true
      break
    fi
  done
  for path in "${fallback_paths[@]}"; do
    if [[ -f "$path" ]]; then
      installed_now=true
      break
    fi
  done

  if [[ "$installed_now" == true ]]; then
    log_success "$name instalado."
  else
    log_warn "$name pode não ter sido instalado corretamente. Verifique manualmente."
  fi
done

hash -r
log_success "Ferramentas via curl verificadas."
