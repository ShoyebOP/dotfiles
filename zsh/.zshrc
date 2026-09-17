#!/usr/bin/env zsh

# =============================================================================
# ZSH Configuration File (.zshrc) — default shell, Nushell is backup
# A modern, clean setup with Zinit plugin manager and Powerlevel10k theme
# Zinit clones itself on first zsh launch via this block — no installer clone, no commit pin per D-12
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

# Why: dedupe every PATH mutation below (keep-first). `path`/`PATH` are a tied
# array/scalar pair, so `typeset -U` on the array covers later PATH exports too.
# Must precede the first PATH export — the unique attribute is forward-looking.
typeset -U path
# Local bins
export PATH="$HOME/.local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
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
    vicmd) echo -ne '\e[2 q' ;;
    viins | main) echo -ne '\e[6 q' ;;
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
# Zinit clones itself on first zsh launch via this block — no installer clone, no commit pin per D-12
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
((${+_comps})) && _comps[zinit]=_zinit

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

# Catppuccin p10k themes
zinit light tolkonepiu/catppuccin-powerlevel10k-themes

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
            COMP_CWORD=$((cword - 1))
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

# Why (D-12): dead staged-modifiers ice removed — a bare `zi ice` with no
# following load staged modifiers for a definitions repo that never loads
# (absent from the Zinit plugins dir); deleted, never converted into a load.

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
# Why: each plugin needs its own `zi light` — a bare `zi ice <repo>` with no
# following load command stages modifiers for the NEXT load and installs nothing
# (this plugin was silently never loading). Load order is load-bearing:
# fzf-history-search (owns Ctrl+R) BEFORE marlonrichert/zsh-autocomplete
# (owns Tab/^I); autocomplete stays the LAST plugin load.
zi light joshskidmore/zsh-fzf-history-search

# -----------------------------------------------------------------------------
# FZF DEGRADATION LADDER (best-effort, never breaks autocomplete)
# -----------------------------------------------------------------------------
# Why (D-11, D-12): ladder evaluates BEFORE the autocomplete engine load so no
# fzf init can clobber engine widgets/keymaps (last-writer-wins). Relocated
# here from after the engine; body unchanged.
# Why: fzf is optional — autocomplete must survive total fzf absence. Probe the
# system binary, then branch on version with `sort -V` (numeric dotted compare):
# >=0.48 uses the native `fzf --zsh` integration, older releases use the legacy
# key-bindings file. Every probe failure falls through silently to warn-and-
# continue; no probe failure may return nonzero at top level.
if command -v fzf >/dev/null 2>&1; then
    _fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
    if [[ -n "${_fzf_ver:-}" ]] && [[ "$(printf '%s\n%s\n' "$_fzf_ver" "0.48" | sort -V | head -n1)" == "0.48" ]]; then
        # Why (D-10): native rung — disable expendable Ctrl+T / Alt-C plus the
        # `**` completion trigger via official env mechanism (A1: trigger-disable
        # assumed; live verdict confirms). Ctrl+R deliberately kept.
        FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND= FZF_COMPLETION_TRIGGER='' source <(fzf --zsh) 2>/dev/null || true
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh 2>/dev/null || true
        # Why (D-10): legacy rung binds Ctrl+T / Alt-C unconditionally with zero
        # Tab binds — strip expendables, keep Ctrl+R.
        for _k in emacs viins vicmd; do
            bindkey -M "$_k" -r '^T' 2>/dev/null || true
            bindkey -M "$_k" -r '\ec' 2>/dev/null || true
        done; unset _k
    elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        # Why: Debian-family fzf ships the legacy scripts under doc/examples,
        # not /usr/share/fzf — without this rung Ctrl+R would warn even though
        # fzf is installed (verified: fzf 0.44.1 on Debian has only this path).
        source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
        # Why (D-10): same expendable strip as above — Ctrl+T / Alt-C removed,
        # Ctrl+R kept (D-10 non-negotiable).
        for _k in emacs viins vicmd; do
            bindkey -M "$_k" -r '^T' 2>/dev/null || true
            bindkey -M "$_k" -r '\ec' 2>/dev/null || true
        done; unset _k
    fi
    unset _fzf_ver
fi
# Why (D-12): Ctrl+R ownership moved to the Phase-5 ownership block after the
# engine (last-writer-wins) — never rebind Ctrl+R here, never rebind Tab here.

# Zsh autocomplete - Real-time type-ahead autocompletion
# Why (D-07, D-12): single main-map Tab binding entering menu-select; the
# menuselect backtab line was redundant (engine binds menuselect Tab/backtab
# itself) so it is deleted. Engine stays the LAST plugin load.
zi ice atload'bindkey "^I" menu-select'
zi light marlonrichert/zsh-autocomplete

# -----------------------------------------------------------------------------
# Ownership (Phase 5): Tab belongs to autocomplete, Ctrl+R to fzf
# -----------------------------------------------------------------------------
# Why (D-09, D-12): last-writer-wins in ZLE — this block stays AFTER all
# plugin/fzf loads so Tab and Ctrl+R survive any plugin rebind.
# Why (D-07): Tab enters menu-select (plugin default is complete-word);
# menu cycling (Tab/Shift-Tab/arrows) is stock — kept, zero vi-motion rebinds (D-15).
bindkey '^I' menu-select
# Why (D-12): Ctrl+R re-asserted last plus moved missing-widget warn (from the
# ladder) — warns instead of leaving a silent dead key when fzf is absent.
bindkey '^R' fzf-history-widget
if ! zle -l 2>/dev/null | grep -q fzf-history-widget; then
    print -P "%F{yellow}[WARN]%f fzf history widget missing — install fzf to enable Ctrl+R history search."
fi

# Why (D-21): prefix-only matching — overrides engine fuzzy defaults (same
# pattern, later set wins; MUST stay after engine load). Intentionally loses
# typo-correction (_correct/_approximate) per prefix-only requirement.
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}'

# Why (D-01): documentary first-char trigger — engine default min-input is 1,
# stated explicitly so the intent is grep-visible.
zstyle ':autocomplete:*' min-input 1
# Why (D-16): display-line cutoff — full list by default, engine shows its
# stock (MORE) marker past the cutoff; 200 with 60/16 fallbacks (live verdict).
zstyle ':autocomplete:*' list-lines 200

# Why (D-08): Right-arrow accepts ghost text in insert mode for both terminfo
# application-cursor sequences; binds go here after all plugins so the captured
# original is vi-forward-char, and the widget falls back to plain cursor
# movement when no suggestion is shown.
bindkey -M viins '^[[C' autosuggest-accept
bindkey -M viins '^[OC' autosuggest-accept

# Why (D-06 closest-achievable): Ctrl+C keeps stock SIGINT semantics (aborts the
# whole line, so it can never be a pure list-dismiss); buffer-preserving menu
# dismiss is Ctrl+G (send-break) confined to the menuselect keymap. Never rebind
# Ctrl+C, never touch Esc (D-06 stock vi).
bindkey -M menuselect '^G' send-break

# LIVE-JUDGMENT FLAGS (D-13: user verdict closes the phase in a live terminal):
# 1. Up-arrow history-menu scope (D-20-scope/A6): Up-arrow opening the history
#    menu on an explicit keypress is kept stock — confirm live it does not
#    violate the no-history-in-auto-show rule.
# 2. Final cutoff number (D-16/A4): list-lines 200 picked; fallbacks 60 then 16
#    if the live verdict reports lag.
# 3. Stock result ordering (D-22): upstream group-order/tag-order kept, no
#    overrides — user judges feel live.
# 4. Native-rung trigger disable (D-10/A1): FZF_COMPLETION_TRIGGER empty is
#    assumed to disable star-star Tab completion on the >=0.48 rung — confirm
#    live on Arch host; fallback is leaving the default trigger (needs explicit
#    star-star, no plain-Tab clash).

unset ZI_REPO
# -----------------------------------------------------------------------------
# POWERLEVEL10K CUSTOMIZATION
# -----------------------------------------------------------------------------
# Load Powerlevel10k configuration (run `p10k configure` to customize)
# Why: machine-local overrides (HOME-only, gitignored) load after every tool
# init (zoxide, fzf, completions) so user tweaks win, but before prompt apply
# so prompt/alias overrides render. Only HOME is sourced — nothing under the
# repo — so machine secrets never dirty git. Template: zsh/.zshrc.local.example.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Apply Catppuccin rainbow latte theme
apply_catppuccin classic mocha

# Restore vi_mode indicator and remove status tick after Catppuccin theme
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    command_execution_time
    background_jobs
    direnv
    asdf
    virtualenv
    anaconda
    pyenv
    goenv
    nodenv
    nvm
    nodeenv
    rbenv
    rvm
    fvm
    luaenv
    jenv
    plenv
    perlbrew
    phpenv
    scalaenv
    haskell_stack
    kubecontext
    terraform
    aws
    aws_eb_env
    azure
    gcloud
    google_app_cred
    toolbox
    context
    nordvpn
    ranger
    yazi
    nnn
    lf
    xplr
    vim_shell
    midnight_commander
    nix_shell
    chezmoi_shell
    todo
    timewarrior
    taskwarrior
    per_directory_history
    newline
    vi_mode
)

# Vi mode colors
typeset -g POWERLEVEL9K_VI_COMMAND_MODE_STRING=NORMAL
typeset -g POWERLEVEL9K_VI_MODE_NORMAL_FOREGROUND=106
typeset -g POWERLEVEL9K_VI_VISUAL_MODE_STRING=VISUAL
typeset -g POWERLEVEL9K_VI_MODE_VISUAL_FOREGROUND=68
typeset -g POWERLEVEL9K_VI_OVERWRITE_MODE_STRING=OVERTYPE
typeset -g POWERLEVEL9K_VI_MODE_OVERWRITE_FOREGROUND=172
typeset -g POWERLEVEL9K_VI_INSERT_MODE_STRING=INSERT
typeset -g POWERLEVEL9K_VI_MODE_INSERT_FOREGROUND=66

# bun completions
# Why: HOME-variable form keeps second-machine clones working (no hard-coded user).
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Why: converge PATH duplicate-free on every source pass (D-09). Scalar
# `export PATH=...` assignments do not dedupe at assignment time even with the
# top-of-file `typeset -U` guard set (verified on zsh 5.9); an array
# self-assignment under the still-set unique attribute retro-dedupes instead.
# Must stay the last PATH-relevant line — nothing below may mutate PATH.
path=( $path )
