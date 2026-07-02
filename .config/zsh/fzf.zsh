if command -v fzf &>/dev/null && command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

  export FZF_DEFAULT_OPTS='
    --height=60%
    --layout=reverse
    --border=rounded
    --prompt="  "
    --pointer="  "
    --preview-window=right:65%:wrap:border-left
  '

  if command -v bat &>/dev/null; then
    export _FZF_PREVIEW_CMD='(file --mime-type -b {} | grep -q "^text/" && bat --color=always --style=plain,numbers --line-range=:500 {} || echo "  [Arquivo binário: $(file -b {})]")'
    export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"
  fi

  _fzf_file_no_hidden() {
    local cmd result
    cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
    if command -v bat &>/dev/null; then
      result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD")
    else
      result=$(eval "${cmd:-find . -type f}" | fzf)
    fi
    if [[ -n "$result" ]]; then
      LBUFFER+="$result"
    fi
    zle reset-prompt
  }
  zle -N _fzf_file_no_hidden
fi
