#!/usr/bin/env bash
# 12-hyprpm-manifest.sh - Gera bloco gerenciado de plugins hyprpm no autostart.lua

AUTOSTART_FILE="$USER_HOME/.config/hypr/modules/autostart.lua"

if [[ ! -f "$AUTOSTART_FILE" ]]; then
  log_warn "$AUTOSTART_FILE não encontrado. Pulando manifesto hyprpm."
  return 0
fi

log_info "Atualizando manifesto hyprpm em $AUTOSTART_FILE..."

python3 -c '
import sys, tomllib, re, textwrap
manifest_file, autostart_file = sys.argv[1], sys.argv[2]

with open(manifest_file, "rb") as f:
    data = tomllib.load(f)

plugins = data.get("plugins", [])
if not plugins:
    print("Nenhum plugin hyprpm configurado.")
    sys.exit(0)

lines = ["hl.exec_cmd([[bash -c '"]
inner = []
for plugin in plugins:
    name = plugin["name"]
    repo = plugin["repo"]
    inner.append(textwrap.dedent(f"""
        if ! hyprpm list 2>/dev/null | grep -q {name}; then
            if hyprpm update && hyprpm add https://github.com/{repo}.git && hyprpm enable {name}; then
                hyprpm reload 2>/dev/null || true
            else
                notify-send -u critical "HyprPM" "Falha ao instalar o plugin {name}. Verifique hyprpm manualmente."
            fi
        fi
    """).strip())

lines.append("\n".join(inner))
lines.append("']])")
new_block = "\n".join(lines)

begin_marker = "-- BEGIN gabrln-managed:hyprpm"
end_marker = "-- END gabrln-managed:hyprpm"

with open(autostart_file, "r") as f:
    content = f.read()

pattern = re.compile(rf"{re.escape(begin_marker)}.*?{re.escape(end_marker)}", re.DOTALL)
replacement = f"{begin_marker}\n{new_block}\n{end_marker}"

if pattern.search(content):
    content = pattern.sub(replacement, content)
else:
    # Insere antes do fechamento do hl.on("hyprland.start", function() ... end)
    # Procura o último "end)" do arquivo
    content = content.rstrip() + "\n\n" + replacement + "\n"

with open(autostart_file, "w") as f:
    f.write(content)

print(f"Manifesto hyprpm atualizado com {len(plugins)} plugin(s).")
' "$MANIFESTS_DIR/hyprpm.toml" "$AUTOSTART_FILE"

log_success "Manifesto hyprpm aplicado."
