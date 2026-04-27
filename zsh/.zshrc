#!/usr/bin/env zsh

# =============================================================================
# ZSH Configuration File (.zshrc)
# A modern, clean setup with Zinit plugin manager and Powerlevel10k theme
# =============================================================================

# -----------------------------------------------------------------------------
# POWERLEVEL10K INSTANT PROMPT
# -----------------------------------------------------------------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------------------------------------------------------
# LOAD ALIAS
# -----------------------------------------------------------------------------

# Load custom configurations (only if files exist to avoid console output)
[[ -f "$HOME/.shell_aliases" ]] && source "$HOME/.shell_aliases"
[[ -f "$HOME/.shell_functions" ]] && source "$HOME/.shell_functions"

# -----------------------------------------------------------------------------
# ENVIRONMENT VARIABLES (imported from nushell)
# -----------------------------------------------------------------------------
# XDG Paths
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Local bins
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/sbin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Editor
export EDITOR=nvim

# Playwright
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

# n8n
export N8N_RESTRICT_FILE_ACCESS_TO=""

# -----------------------------------------------------------------------------
# ZOXIDE
# -----------------------------------------------------------------------------
eval "$(zoxide init zsh)"

# Aliases
alias c=clear
alias v=nvim

# vim keybindings
bindkey -v
set -o vi

bindkey '^[b' vi-backward-blank-word
bindkey '^[w' vi-forward-blank-word
bindkey -M vicmd 'gg' beginning-of-line
bindkey -M vicmd 'G' end-of-line

function zle-keymap-select {
  case $KEYMAP in
    vicmd) echo -ne '\e[2 q';;
    viins|main) echo -ne '\e[6 q';;
  esac
}
zle -N zle-keymap-select

function zle-line-init {
  echo -ne '\e[6 q'
}
zle -N zle-line-init

# Enable auto-cd
setopt AUTO_CD
# Turn off "no match" errors
setopt nonomatch

# -------------------------------------------
# Edit Command Buffer
# -------------------------------------------
# Open the current command in your $EDITOR (e.g., neovim)
# Press Ctrl+X followed by Ctrl+E to trigger
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# -------------------------------------------
# Undo in ZSH
# -------------------------------------------
# Press Ctrl+_ (Ctrl+Underscore) to undo
bindkey '^Z' undo
# Redo widget exists but has no default binding:
bindkey '^Y' redo

# -------------------------------------------
# Magic Space - Expand History
# -------------------------------------------
# Expands history expressions like !! or !$ when you press space
bindkey ' ' magic-space

# -------------------------------------------
# zmv - Advanced Batch Rename/Move
# -------------------------------------------
# Enable zmv
autoload -Uz zmv

# Usage examples:
# zmv '(*).log' '$1.txt'           # Rename .log to .txt
# zmv -w '*.log' '*.txt'           # Same thing, simpler syntax
# zmv -n '(*).log' '$1.txt'        # Dry run (preview changes)
# zmv -i '(*).log' '$1.txt'        # Interactive mode (confirm each)

# -------------------------------------------
# Custom Widgets
# -------------------------------------------

# # Copy current command buffer to clipboard
# function copy-buffer-to-clipboard() {
#   echo -n "$BUFFER" | wl-copy
#   zle -M "Copied to clipboard"
# }
#
# zle -N copy-buffer-to-clipboard
# bindkey '^X^C' copy-buffer-to-clipboard

# -----------------------------------------------------------------------------
# ZINIT PLUGIN MANAGER INSTALLATION
# -----------------------------------------------------------------------------
# Auto-install Zinit if not present
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    # Only show output if not using instant prompt
    if [[ -z "$P9K_INSTANT_PROMPT" ]]; then
        print -P "%F{33}Installing %F{220}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager...%f"

        # Create directory structure
        if command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"; then
            # Try to clone the repository
            if command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"; then
                print -P "%F{33}Installation successful.%f"
            else
                print -P "%F{160}Git clone failed. Please check your internet connection and try again.%f"
                return 1
            fi
        else
            print -P "%F{160}Failed to create zinit directory.%f"
            return 1
        fi
    else
        # Silent installation during instant prompt
        command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
        command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" >/dev/null 2>&1
    fi
fi

# Load Zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS (moved after instant prompt to avoid console output)
# -----------------------------------------------------------------------------
function error() {
    print -P "%F{red}[ERROR]%f: %F{yellow}$1%f" && return 1
}

function info() {
    print -P "%F{blue}[INFO]%f: %F{cyan}$1%f"
}

# -----------------------------------------------------------------------------
# ZINIT CONFIGURATION
# -----------------------------------------------------------------------------
# Zinit directory structure - UPDATED TO MATCH DEFAULT PATH
typeset -gAH ZINIT
ZINIT[HOME_DIR]="$HOME/.local/share/zinit"
ZINIT[BIN_DIR]="$ZINIT[HOME_DIR]/zinit.git"
ZINIT[COMPLETIONS_DIR]="$ZINIT[HOME_DIR]/completions"
ZINIT[SNIPPETS_DIR]="$ZINIT[HOME_DIR]/snippets"
ZINIT[ZCOMPDUMP_PATH]="$ZINIT[HOME_DIR]/zcompdump"
ZINIT[PLUGINS_DIR]="$ZINIT[HOME_DIR]/plugins"
ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1

# Zinit variables
ZPFX="$ZINIT[HOME_DIR]/polaris"
ZI_REPO='zdharma-continuum'

# -----------------------------------------------------------------------------
# OH-MY-ZSH & PREZTO PLUGINS
# -----------------------------------------------------------------------------
# Load useful Oh My Zsh library functions and plugins
zi for is-snippet \
    OMZL::{compfix,completion,git}.zsh \
    PZT::modules/{history}

# Load completions for specific tools
zi as'completion' for \
    OMZP::{pip/_pip,terraform/_terraform}

# -----------------------------------------------------------------------------
# THEME - POWERLEVEL10K
# -----------------------------------------------------------------------------
# Install and load Powerlevel10k theme
zinit ice depth=1
zinit light romkatv/powerlevel10k

# -----------------------------------------------------------------------------
# ZINIT ANNEXES
# -----------------------------------------------------------------------------
# Load useful Zinit extensions
zi light-mode for \
    "$ZI_REPO"/zinit-annex-{binary-symlink,patch-dl,submods}

# -----------------------------------------------------------------------------
# CLI TOOLS (install manually if needed)
# -----------------------------------------------------------------------------
# Add ~/.local/share/zinit/polaris/bin to PATH if zinit binaries exist
if [[ -d "$HOME/.local/share/zinit/polaris/bin" ]]; then
    export PATH="$HOME/.local/share/zinit/polaris/bin:$PATH"
fi

# Install examples (uncomment and modify as needed):
# zinit ice from"gh-r" lbin"!" nocompile
# zinit load @junegunn/fzf
# zinit ice from"gh-r" lbin"!" nocompile
# zinit load @sharkdp/bat
# zinit ice from"gh-r" lbin"!" nocompile
# zinit load @eza-community/eza
# zinit ice from"gh-r" lbin"!" nocompile
# zinit load @sxyazi/yazi
# zinit ice from"gh-r" lbin"!lazydocker" nocompile
# zinit load @jesseduffield/lazydocker
# zinit ice from"gh-r" lbin"!lazygit" nocompile
# zinit load @jesseduffield/lazygit
# zi ice from'gh-r' lbin'!spoofdpi' nocompile
# zi light xvzc/SpoofDPI
# zi ice from'gh-r' lbin'!**/rg' nocompile
# zi light BurntSushi/ripgrep
# zi ice from'gh-r' lbin'!' nocompile atload'eval "$(zoxide init zsh --cmd cd)"'
# zi light ajeetdsouza/zoxide
# zi ice from'gh-r' lbin'!grex' nocompile
# zi light pemistahl/grex

# -----------------------------------------------------------------------------
# PYTHON CONFIGURATION
# -----------------------------------------------------------------------------
# Custom pip completion function
function _pip_completion() {
    local words cword
    read -Ac words
    read -cn cword
    reply=(
        $(
            COMP_WORDS="$words[*]"
            COMP_CWORD=$(( cword-1 ))
            PIP_AUTO_COMPLETE=1 $words 2>/dev/null
        )
    )
}
compctl -K _pip_completion pip3

# UV completions
[[ -d "$HOME/.config/zsh/completions" ]] && fpath=("$HOME/.config/zsh/completions" $fpath)
autoload -Uz _uv

# -----------------------------------------------------------------------------
# ZSH ENHANCEMENT PLUGINS
# -----------------------------------------------------------------------------

# Enhanced completions - Additional completion definitions
zi ice zsh-users/zsh-completions

# Auto-suggestions - Suggests commands as you type based on history
zi ice atload'_zsh_autosuggest_start' \
    atinit'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
bindkey "^_" autosuggest-execute
bindkey "^ " autosuggest-accept'
zi light zsh-users/zsh-autosuggestions

# Fast syntax highlighting - Real-time command syntax validation
zi light-mode for \
    $ZI_REPO/fast-syntax-highlighting


# FZF history search - Fuzzy search through command history
zi ice joshskidmore/zsh-fzf-history-search

# Zsh autocomplete - Real-time type-ahead autocompletion
zi ice atload'
bindkey              "^I" menu-select
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
zi light marlonrichert/zsh-autocomplete

# -----------------------------------------------------------------------------
# FINALIZATION
# -----------------------------------------------------------------------------
# Initialize completions and replay cached completions
# at the end of a Zinit configuration to ensure that after all plugins are loaded,
# the completion system is properly initialized and
# syntax highlighting/autosuggestion widgets are correctly bound
# zi for atload'
#       zicompinit; zicdreplay
#       _zsh_highlight_bind_widgets
#       _zsh_autosuggest_bind_widgets' \
    #     as'null' id-as'zinit/cleanup' lucid nocd wait \
    #   $ZI_REPO/null
#

unset ZI_REPO
# -----------------------------------------------------------------------------
# POWERLEVEL10K CUSTOMIZATION
# -----------------------------------------------------------------------------
# Load Powerlevel10k configuration (run `p10k configure` to customize)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
