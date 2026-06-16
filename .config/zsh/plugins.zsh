ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"

_zplugin_load() {
  local repo="$1"
  local name="$2"
  local file_name="${3:-$name.plugin.zsh}"
  local plugin_path="${ZPLUGINDIR}/${name}"
  
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${name}..."
    git clone --depth=1 "https://github.com/${repo}/${name}" "$plugin_path" \
      || { echo "ERROR: failed to install ${name}" >&2; return 1; }
  fi
  
  # Check if main file exists, or fallback to any .zsh file inside
  if [[ -f "${plugin_path}/${file_name}" ]]; then
    source "${plugin_path}/${file_name}"
  else
    # Fallback: search for first .zsh file in root directory of plugin
    local fallback_file=$(find "$plugin_path" -maxdepth 1 -name "*.zsh" | head -n 1)
    if [[ -n "$fallback_file" ]]; then
      source "$fallback_file"
    fi
  fi
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

# Load plugins: check system path first for speed, fallback to auto-downloader

# 1. zsh-autosuggestions
if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  _zplugin_load zsh-users zsh-autosuggestions
fi

# 2. zsh-history-substring-search
if [[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
else
  _zplugin_load zsh-users zsh-history-substring-search
fi

# 3. fast-syntax-highlighting (better than system's zsh-syntax-highlighting)
_zplugin_load zdharma-continuum fast-syntax-highlighting fast-syntax-highlighting.plugin.zsh

# 4. zsh-vi-mode (highly integrated in bindings)
_zplugin_load jeffreytse zsh-vi-mode zsh-vi-mode.plugin.zsh
