# Phase 05: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Pattern Map

**Mapped:** 2026-09-17
**Files analyzed:** 4 (1 primary edit, 2 atomic-docs touch-ups, 1 explicitly no-change)
**Analogs found:** 3 / 4 (zstyle placement has no in-repo analog — planner uses RESEARCH.md sketch)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `zsh/.zshrc` (plugin block reorder + ownership block + zstyle/bindkey deltas + 2 dead-line deletions) | config (shell init) | event-driven (ZLE `line-pre-redraw` async hook, keymaps) | `zsh/.zshrc` itself, regions lines 290–344 (plugin block + fzf ladder) | exact (self-analog — single edit site per CONTEXT) |
| `README.md` + `AGENTS.md` (behavior-text touch-ups only) | docs | file-I/O | Prior atomic-docs commits' `Why:` comment + doc convention in `zsh/.zshrc` | role-match |
| `setup.sh` (NO change expected — D-18 finding) | config (installer) | batch | `setup.sh` lines 297–322, 433–441 (`DRY_RUN` preview idiom) | exact (contingency only) |
| *(no new files — D-13 forbids harness/probe files)* | — | — | — | no analog needed |

## Pattern Assignments

### `zsh/.zshrc` (config, event-driven)

**Analog:** `zsh/.zshrc` itself (445 lines; single edit site — all new code copies idioms from neighboring regions)

**Plugin-load pattern** (lines 290–314) — copy this `zi ice` + `zi light` shape for any load-order move. Note the `atinit`/`atload` quoting style (single-quoted multi-line strings):
```zsh
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

# Zsh autocomplete - Real-time type-ahead autocompletion
zi ice atload'
bindkey              "^I" menu-select
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
zi light marlonrichert/zsh-autocomplete
```

**fzf ladder pattern** (lines 316–344) — the version-branch + Debian-rung + warn-and-continue shape. The Phase-5 move keeps this exact body, only relocating it BEFORE the engine load and adding per-rung expendable-strips (see RESEARCH.md Code Examples for the strip snippet — no in-repo analog for `bindkey -r` exists):
```zsh
# -----------------------------------------------------------------------------
# FZF DEGRADATION LADDER (best-effort, never breaks autocomplete)
# -----------------------------------------------------------------------------
# Why: fzf is optional — autocomplete must survive total fzf absence. Probe the
# system binary, then branch on version with `sort -V` (numeric dotted compare):
# >=0.48 uses the native `fzf --zsh` integration, older releases use the legacy
# key-bindings file. Every probe failure falls through silently to warn-and-
# continue; no probe failure may return nonzero at top level.
if command -v fzf >/dev/null 2>&1; then
    _fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
    if [[ -n "${_fzf_ver:-}" ]] && [[ "$(printf '%s\n%s\n' "$_fzf_ver" "0.48" | sort -V | head -n1)" == "0.48" ]]; then
        source <(fzf --zsh) 2>/dev/null || true
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh 2>/dev/null || true
    elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        # Why: Debian-family fzf ships the legacy scripts under doc/examples,
        # not /usr/share/fzf — without this rung Ctrl+R would warn even though
        # fzf is installed (verified: fzf 0.44.1 on Debian has only this path).
        source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
    fi
    unset _fzf_ver
fi
# Unconditional Ctrl+R bind per split ownership (fzf-history-search owns ^R,
# autocomplete owns ^I — never rebind ^I here). Warns instead of leaving a
# silent dead key when the widget is absent (e.g. fzf not installed).
bindkey '^R' fzf-history-widget
if ! zle -l 2>/dev/null | grep -q fzf-history-widget; then
    print -P "%F{yellow}[WARN]%f fzf history widget missing — install fzf to enable Ctrl+R history search."
fi
```

**Ownership re-assertion pattern** (new block — copies the `bindkey '^R'` + split-ownership comment idiom from lines 338–341 above). Place AFTER the engine load AND after the fzf ladder; cite the split in a `Why:`/`Ownership (Phase 5):` comment. Sketch lives in RESEARCH.md § Code Examples (ownership + prefix-only + ghost-accept block); key lines to reuse verbatim:
```zsh
# Ownership (Phase 5): Tab belongs to autocomplete, Ctrl+R to fzf. Last writer
# wins in ZLE, so this block stays after ALL plugin/fzf loads.
bindkey '^I' menu-select
bindkey '^R' fzf-history-widget
```

**bindkey idiom catalog** (context lines for keymap-qualified binds — new `viins` Right-arrow and `menuselect ^G` binds copy these shapes):
```zsh
bindkey -v                                                          # line 65: vi mode entry
bindkey '^[b' vi-backward-blank-word                                # line 68: alt-chord in main map
bindkey -M vicmd 'gg' beginning-of-line                             # line 70: keymap-qualified rebind
bindkey '^X^E' edit-command-line                                    # line 98: ctrl-chord, custom widget
bindkey "^_" autosuggest-execute                                    # line 294: inside atinit quote
bindkey "^ " autosuggest-accept                                     # line 295: inside atinit quote
```

**menuselect + terminfo-guard pattern** (lines 311–314) — the existing `kcbt` line is REDUNDANT (engine binds menuselect Tab/backtab itself; RESEARCH § Suspect 2) and must be DELETED, but its replacement site copies the guard RESEARCH mandates (`[[ -n ${terminfo[kcbt]:-} ]]` — bare `$terminfo[kcbt]` is unsafe on terminals without backtab):
```zsh
zi ice atload'
bindkey              "^I" menu-select
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
```

**zstyle placement — NO ANALOG IN REPO.** Zero `zstyle` hits exist anywhere in the repo (verified via `rg`). All Phase-5 `:completion:` / `:autocomplete:` styles MUST go in the ownership block AFTER `zi light marlonrichert/zsh-autocomplete` (engine overwrites same-pattern defaults at load — last-set-wins; RESEARCH Pitfall 1). Planner copies the style values verbatim from RESEARCH.md § Code Examples, not from the codebase:
```zsh
# D-21: prefix-only matching — overrides engine fuzzy defaults (same pattern,
# later set wins; MUST stay after engine load).
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}'

# D-01/D-16: document first-char trigger; thousands-scale line cutoff.
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' list-lines 200
```

**Dead-code deletion pattern** (lines 346–359) — the commented `zicompinit`/`zicdreplay` finalize block is deleted outright (nothing turbo-loads; engine owns `compinit`). The dead `zi ice zsh-users/zsh-completions` line 288 (stages modifiers, loads nothing — confirmed absent from `~/.local/share/zinit/plugins/`) is deleted in the same pass. Copy the surrounding section-banner style for any replacement comment:
```zsh
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
```

**Frozen ordering constraints** (do NOT move these — planner must treat as fixed anchors):
```zsh
# TOP of file, lines 12-17 — p10k instant prompt stays first:
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```
```zsh
# .local sourcing, line 370 — new user-facing knobs must be overridable from here,
# so nothing in the Phase-5 block may assume it runs after ~/.zshrc.local:
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```
```zsh
# LAST PATH line, lines 440-445 — nothing PATH-relevant below this:
path=( $path )
```

**Conditional-source idiom** (lines 24–25, 370, 438) — model for any optional sourcing the fix adds:
```zsh
[[ -f "$HOME/.shell_aliases" ]] && source "$HOME/.shell_aliases"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
```

---

### `README.md` + `AGENTS.md` (docs, file-I/O)

**Analog:** `zsh/.zshrc` `Why:` rationale-comment convention + `zsh/.zshrc.local.example` header (the repo documents behavior inline and in the example template; Phase-1 atomic-docs rule requires doc touch-ups ship in the SAME commit as the behavior change).

**Comment voice to copy** (lines 319–323, 366–371, 440–444) — every behavior change gets a `Why:` line stating the reason, not just the what:
```zsh
# Why: fzf is optional — autocomplete must survive total fzf absence. Probe the
# Why: machine-local overrides (HOME-only, gitignored) load after every tool
# Why: converge PATH duplicate-free on every source pass (D-09). Scalar
```

**`.local` template pattern** (`zsh/.zshrc.local.example`, lines 1–14) — if the fix introduces user-tunable knobs (e.g. `list-lines` fallback), document the override as a commented example here following the existing shape:
```zsh
# Example: machine-specific PATH prepend (kept-first dedup preserves order)
# export PATH="$HOME/work/bin:$PATH"

# Example: prompt-element tweak (applies before p10k renders)
# typeset -g POWERLEVEL9K_TIME_FORMAT="%H:%M"
```

---

### `setup.sh` (config/installer, batch) — NO CHANGE EXPECTED

**Finding (RESEARCH § D-18):** `fzf` + `zsh` are already in the `common` toolchain on all three families (`setup.sh:194-202` per RESEARCH; `ALL_TOOLCHAIN` at `setup.sh:24` includes `fzf zsh`). No installer change is needed. The patterns below apply ONLY if the planner discovers installer wiring is required after all (D-18 permits it).

**Safety header pattern** (lines 1–4) — mandatory for any new `setup.sh` code:
```bash
#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit
```

**`--help`-wins pre-scan + `${1-}` guards** (lines 60–71) — mandatory shape for any new flag parsing:
```bash
parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                usage
                exit 0
                ;;
        esac
    done
    while [[ $# -gt 0 ]]; do
        case "${1-}" in
```

**DRY_RUN preview pattern** (lines 297–322) — EVERY mutation needs the early-return preview BEFORE the live path; copy this exact `if/else` + `[DRY RUN] Would run:` shape:
```bash
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would run: sudo pacman -Sy"
            else
                if ! sudo pacman -Sy; then echo "Warning: pacman -Sy failed, continuing" >&2; fi
            fi
```
```bash
    if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"; return 0; fi
```

**Stow preview pattern** (lines 437–441) — model for any new stow-affecting installer code (preview via `stow --no --verbose`, close with "No changes made"):
```bash
        echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if command -v stow >/dev/null 2>&1; then echo "[DRY RUN] stow --no --verbose preview for $pkg:"; stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
        else echo "  (stow not found — would install via package manager first)"; fi
    done
    echo "[DRY RUN] No changes made. Re-run without --dry-run to apply."
```

---

## Shared Patterns

### Ordering / last-writer-wins
**Source:** `zsh/.zshrc` lines 302–314 (load-order comment) + RESEARCH Pattern 1
**Apply to:** plugin block move, fzf ladder relocation, ownership block placement
```zsh
# Load order is load-bearing:
# fzf-history-search (owns Ctrl+R) BEFORE marlonrichert/zsh-autocomplete
# (owns Tab/^I); autocomplete stays the LAST plugin load.
```
Rule: fzf ladder → engine LAST → ownership re-assertion block. p10k-instant-prompt stays TOP; `path=( $path )` stays LAST PATH line; `.local` sourcing stays where it is (line 370).

### `Why:` rationale comments
**Source:** `zsh/.zshrc` lines 319–323, 338–340, 366–369, 440–444
**Apply to:** every Phase-5 hunk (move, deletion, new bind, new zstyle)
Each behavior change carries a `Why:` comment citing the decision ID (D-01…D-21) and the failure mode it prevents. Deletions keep a one-line `Why:` (e.g. "redundant — engine binds menuselect Tab/backtab itself").

### Split ownership (Ctrl+R = fzf, Tab = autocomplete)
**Source:** `zsh/.zshrc` lines 338–341 + Phase-3 D-01 lock (relaxed only for ORDER per D-12)
**Apply to:** ownership block, fzf expendable-strip, `^R` re-bind
Never rebind `^I` in the fzf ladder; never rebind `^R` to anything but the fzf widget; fzf loses every other clash by default (D-09).

### Error handling (warn-and-continue, never break the shell)
**Source:** `zsh/.zshrc` lines 324–344 (ladder: `2>/dev/null || true`, `unset _fzf_ver`, widget-missing warn instead of dead key)
**Apply to:** all new `.zshrc` code — no probe failure may return nonzero at top level; missing-widget states warn visibly via `print -P "%F{yellow}[WARN]%f ..."`.

### Atomic docs (Phase-1 rule, via D-18)
**Source:** CONTEXT § Established Patterns + `zsh/.zshrc.local.example` header convention
**Apply to:** the single commit — behavior change + `Why:` comments + README/AGENTS.md touch-ups ship together. No separate docs commit.

## No Analog Found

| File / Construct | Role | Data Flow | Reason |
|------------------|------|-----------|--------|
| `zstyle ':completion:*'` / `zstyle ':autocomplete:*'` overrides | config (compsys) | event-driven | Zero `zstyle` lines exist anywhere in the repo (verified via `rg`) — planner uses RESEARCH.md § Code Examples verbatim (prefix-only completer/matcher-list, min-input 1, list-lines 200) |
| `bindkey -r` expendable-strip loop (legacy fzf rung) | config (keymap) | event-driven | No `bindkey -r` precedent in repo — planner uses RESEARCH.md legacy-rung strip sketch verbatim |
| Upstream engine internals (`.autocomplete__async`, knob defaults) | third-party | event-driven | Lives in `~/.local/share/zinit/plugins/`, not the repo — already enumerated in RESEARCH.md § D-item map; do not vendor or copy into the repo |

## Metadata

**Analog search scope:** `zsh/.zshrc` (full 445-line read), `zsh/.zshrc.local.example`, `setup.sh` (safety header, arg parsing, DRY_RUN/stow-preview regions), `README.md` (fzf/autocomplete mentions), `rg` sweeps for `zstyle` (0 hits) and `bindkey -r` (0 hits)
**Files scanned:** 6
**Pattern extraction date:** 2026-09-17
