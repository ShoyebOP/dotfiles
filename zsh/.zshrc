# --- PHASE 1: INSTANT PROMPT (Keep at very top) ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- PHASE 2: CRITICAL EXPORTS (No I/O allowed here) ---
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export HISTSIZE=1000
export HISTFILE=~/.zsh_history
export SAVEHIST=$HISTSIZE
export HISTCONTROL=ignoreboth
export HISTIGNORE="&:[bf]g:c:clear:history:exit:q:pwd:* --help"

# --- PHASE 4: PLUGIN MANAGER (ZINIT) ---
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- PHASE 5: ASYNC PLUGINS (Turbo Mode) ---
# Load visuals first
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Load heavy plugins in background (Wait 0s after prompt)
zinit wait lucid light-mode for \
 atinit"zicompinit; zicdreplay" \
     zsh-users/zsh-syntax-highlighting \
 atload"_zsh_autosuggest_start" \
     zsh-users/zsh-autosuggestions \
     zsh-users/zsh-completions \
     Aloxaf/fzf-tab

# Configure autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history match_prev_cmd)

# --- PHASE 5.5: NEOVIM MODE (VI MODE) ---
# This makes the shell behave like Vim (jk to escape, v to edit, etc.)

# 1. Configuration (Must go BEFORE loading the plugin)
export ZVM_VI_INSERT_ESCAPE_BINDKEY=jk  # Press 'jk' quickly to exit Insert mode
export ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT # Start in Insert mode (like a normal shell)
export ZVM_LAZY_KEYBINDINGS=false       # improved performance

# 2. Load the plugin (Async)
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# 3. The "Edit in Nvim" feature
# When in Normal mode, press 'v' or 'vv' to open the current command in Neovim.
autoload -Uz edit-command-line
zle -N edit-command-line
# We bind this inside the zvm_after_init function to ensure it sticks
function zvm_after_init() {
  # 'vv' in normal mode opens the editor
  zvm_bindkey vicmd 'vv' edit-command-line 
}

# --- PHASE 6: SYSTEM INTEGRATIONS (Pacman versions) ---

# FZF (System/Pacman Version) - Faster than 'eval' on HDD
# We source the static files directly to avoid spawning processes.
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi

# Zoxide (Lazy Load)
# Prevents 'zoxide init' from slowing down every shell launch
function z cd {
    unfunction z cd
    eval "$(zoxide init zsh)"
    "$0" "$@"
}

# --- PHASE 7: CUSTOM FUNCTIONS (Pure ZSH) ---

# Python Venv Helpers
pythonv() {
  if [[ -x .venv/bin/python ]]; then .venv/bin/python "$@"
  elif [[ -x venv/bin/python ]]; then venv/bin/python "$@"
  else echo "No venv found"; return 1; fi
}

pipv() {
  if [[ -x .venv/bin/pip ]]; then .venv/bin/pip "$@"
  elif [[ -x venv/bin/pip ]]; then venv/bin/pip "$@"
  else echo "No venv found"; return 1; fi
}

act() {
  if [[ -f .venv/bin/activate ]]; then source .venv/bin/activate
  elif [[ -f venv/bin/activate ]]; then source venv/bin/activate
  else echo "No venv found"; return 1; fi
}

deact() {
  type deactivate >/dev/null 2>&1 && deactivate || echo "No active virtualenv"
}

# Source local env
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# --- HISTORY CONFIG ---
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups
setopt hist_save_no_dups hist_ignore_dups hist_find_no_dups

# Force Cursor Shape updates for XFCE/VTE terminals
# 1 = Block (Normal), 5 = Beam (Insert)
function zvm_after_select_vi_mode() {
  case $ZVM_MODE in
    $ZVM_MODE_NORMAL) echo -ne "\e[1 q" ;;
    $ZVM_MODE_INSERT) echo -ne "\e[5 q" ;;
    $ZVM_MODE_VISUAL) echo -ne "\e[1 q" ;;
    $ZVM_MODE_VISUAL_LINE) echo -ne "\e[1 q" ;;
  esac
}

# --- CUSTOM KEYBINDINGS (FZF Search) ---
_fzf_history_search() {
    local current_buffer=$BUFFER
    local words=("${(z)current_buffer}")
    local search_term=""
    if [[ ${#words[@]} -gt 0 ]]; then
        [[ "${words[1]}" == "sudo" && ${#words[@]} -gt 1 ]] && search_term="${words[2]}" || search_term="${words[1]}"
    fi
    [[ -z "$search_term" ]] && { zle reset-prompt; return; }
    
    local selected=$(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | \
        awk -v term="$search_term" 'BEGIN { IGNORECASE=0 } {
            original=$0; normalized=$0; sub(/^sudo[[:space:]]+/, "", normalized);
            if (index(normalized, term) == 1) print original }' | \
        awk '!seen[$0]++' | \
        fzf --height=40% --reverse --query="$search_term " --prompt="History > " \
            --bind='ctrl-y:execute-silent(echo -n {} | xclip -selection clipboard)+abort' \
            --preview-window=hidden --exact --no-sort)
            
    if [[ -n "$selected" ]]; then BUFFER=$selected; CURSOR=${#BUFFER}; zle autosuggest-clear; fi
    zle reset-prompt
}
zle -N _fzf_history_search
bindkey '^[[1;5A' _fzf_history_search

# Smart Cycle Logic
_CYCLE_SEARCH_RESULTS=(); _CYCLE_SEARCH_INDEX=-1; _CYCLE_SEARCH_TERM=""; _CYCLE_ORIGINAL_BUFFER=""

_smart_cycle_history() {
    local direction=$1; local current_buffer=$BUFFER
    local words=("${(z)current_buffer}")
    local search_term=""
    if [[ ${#words[@]} -gt 0 ]]; then
        [[ "${words[1]}" == "sudo" && ${#words[@]} -gt 1 ]] && search_term="${words[2]}" || search_term="${words[1]}"
    fi
    [[ -z "$search_term" ]] && { zle beep; return; }

    if [[ "$search_term" != "$_CYCLE_SEARCH_TERM" ]] || [[ $_CYCLE_SEARCH_INDEX -eq -1 && "$current_buffer" == "$_CYCLE_ORIGINAL_BUFFER" ]]; then
        _CYCLE_SEARCH_TERM="$search_term"; _CYCLE_ORIGINAL_BUFFER="$current_buffer"; _CYCLE_SEARCH_INDEX=-1
        _CYCLE_SEARCH_RESULTS=()
        while IFS= read -r line; do
            local norm="${line#sudo }"; norm="${norm##+( )}"
            [[ "$norm" == "$search_term"* && "$line" != "$current_buffer" ]] && _CYCLE_SEARCH_RESULTS+=("$line")
        done < <(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++')
        [[ ${#_CYCLE_SEARCH_RESULTS[@]} -eq 0 ]] && { zle beep; return; }
    fi

    if [[ "$direction" == "up" ]]; then ((_CYCLE_SEARCH_INDEX++)); else ((_CYCLE_SEARCH_INDEX--)); fi
    
    if (( _CYCLE_SEARCH_INDEX < 0 )); then
        _CYCLE_SEARCH_INDEX=-1; BUFFER="$_CYCLE_ORIGINAL_BUFFER"; CURSOR=${#BUFFER}; zle beep
    elif (( _CYCLE_SEARCH_INDEX >= ${#_CYCLE_SEARCH_RESULTS[@]} )); then
        _CYCLE_SEARCH_INDEX=$((${#_CYCLE_SEARCH_RESULTS[@]} - 1)); zle beep
    else
        BUFFER="${_CYCLE_SEARCH_RESULTS[$_CYCLE_SEARCH_INDEX+1]}"; CURSOR=${#BUFFER}
    fi
    zle autosuggest-clear
}

_smart_cycle_up() { _smart_cycle_history "up"; }
_smart_cycle_down() { _smart_cycle_history "down"; }
zle -N _smart_cycle_up; zle -N _smart_cycle_down
bindkey '^[[1;6A' _smart_cycle_up; bindkey '^[[1;6B' _smart_cycle_down

# Aliases & Styles
alias ls='ls --color'
alias c='clear'
alias v='nvim'
alias ssh='TERM=xterm-256color ssh'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Load P10k config last
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
