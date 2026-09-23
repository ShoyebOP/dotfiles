# Phase 05: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Pattern Map

**Mapped:** 2026-09-22
**Files analyzed:** 6 (4 repo files to modify, 1 new file, 1 hand-executed procedure)
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `zsh/.zshrc` (modify) | config (shell rc) | event-driven (ZLE hooks, keymaps, async list) | `zsh/.zshrc` itself (own `^R` re-assert + fzf ladder idioms) | exact (self) |
| `zsh/.zshenv` (NEW) | config (shell env) | batch (single-shot startup eval) | `zsh/.zprofile` | role-match |
| `setup.sh` (modify) | utility (installer) | file-I/O (symlink deployment) | `setup.sh` itself (own stow call sites + `post_verify`) | exact (self) |
| `README.md` (modify) | config (docs) | — (static doc, no flow) | `README.md` itself (own stow blocks + tables) | exact (self) |
| `nvim/.config/` sibling eviction (`opencode/`, `lazygit/`, `context7/`, `gh/` → `~/.config/`) | config (stow package tree) | file-I/O (`mv`, never delete) | `nvim/.config/nvim/` tree shape (package-mirror convention) | role-match |
| `$HOME` live repair (executor hands, never installer code) | utility (manual runbook) | file-I/O | — (no repo analog; reference is RESEARCH.md §D-26 runbook) | none — see No Analog Found |

## Pattern Assignments

### `zsh/.zshrc` (config, event-driven)

**Analog:** `zsh/.zshrc` itself — all new code copies in-file idioms. Git-tracked ✓ (`git ls-files` confirms).

**Plugin block pattern** (lines 283–314) — new `zstyle` knobs go just above line 283; ladder comment (D-31) goes at top of this section ~line 283:
```zsh
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
```

**`^R` re-assert precedent — THE pattern Tab copies** (lines 338–344). Fix = identical treatment for `^I` after the fzf ladder:
```zsh
# Unconditional Ctrl+R bind per split ownership (fzf-history-search owns ^R,
# autocomplete owns ^I — never rebind ^I here). Warns instead of leaving a
# silent dead key when the widget is absent (e.g. fzf not installed).
bindkey '^R' fzf-history-widget
if ! zle -l 2>/dev/null | grep -q fzf-history-widget; then
    print -P "%F{yellow}[WARN]%f fzf history widget missing — install fzf to enable Ctrl+R history search."
fi
```

**fzf ladder pattern** (lines 324–337) — version branch via `sort -V`, silent fallthrough, `|| true` on every source. Free to rework per D-11, except Ctrl+R ownership:
```zsh
if command -v fzf >/dev/null 2>&1; then
    _fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
    if [[ -n "${_fzf_ver:-}" ]] && [[ "$(printf '%s\n%s\n' "$_fzf_ver" "0.48" | sort -V | head -n1)" == "0.48" ]]; then
        source <(fzf --zsh) 2>/dev/null || true
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh 2>/dev/null || true
```

**Autocomplete atload binds** (lines 310–314) — `^I → menu-select` lives here TODAY but is clobbered by line 327. Keep this block; add the re-assert AFTER line 341:
```zsh
# Zsh autocomplete - Real-time type-ahead autocompletion
zi ice atload'
bindkey              "^I" menu-select
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
zi light marlonrichert/zsh-autocomplete
```

**Commented finalize block — prime suspect, must become a why-it-stays-out comment** (lines 346–359). Do NOT uncomment (Anti-Pattern: upstream requires removing compinit calls):
```zsh
# zi for atload'
#       zicompinit; zicdreplay
#       _zsh_highlight_bind_widgets
#       _zsh_autosuggest_bind_widgets' \
#     as'null' id-as'zinit/cleanup' lucid nocd wait \
#   $ZI_REPO/null
```

**Ordering invariants — never move** (planner must preserve):
```zsh
# lines 9-17: p10k instant prompt stays at top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# line 65: bindkey -v stays before plugin loads (else main-keymap binds land in emacs)
bindkey -v
# line 370: .zshrc.local sourcing stays after tool inits / before p10k apply
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# lines 440-445: tail PATH retro-dedupe stays the LAST PATH-relevant line
path=( $path )
```

**Conditional-source idiom** (lines 24–25, 280) — model for any optional config the fix adds:
```zsh
[[ -f "$HOME/.shell_aliases" ]] && source "$HOME/.shell_aliases"
[[ -d "$HOME/.config/zsh/completions" ]] && fpath=("$HOME/.config/zsh/completions" $fpath)
```

**Ghost-accept wiring — DO NOT TOUCH** (lines 291–296 + upstream defaults). `l`/Right-arrow come from autosuggest defaults (`forward-char`, `vi-forward-char` in `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS`), zero local config. Fix must never set `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS` or `ZSH_AUTOSUGGEST_STRATEGY=completion` (the latter's setup runs `bindkey '^I' autosuggest-capture-completion` — the only autosuggest-side Tab-bind vector).

**D-01 baseline zstyle block** (from RESEARCH.md §Code Examples — place just above the plugin section ~line 283; `zstyle` is read dynamically at event time so placement is free, unlike `bindkey`):
```zsh
# Find-as-you-type auto-show (D-01..D-04): first char triggers, no added delay.
# min-input 1 == upstream default; stated explicitly so intent is locked.
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' delay 0
# Thousands-scale cutoff (D-16, researcher pick): screen-fit binds anyway;
# (MORE) marker is automatic on partial lists.
zstyle -e ':autocomplete:*:*' list-lines 'reply=( 300 )'
```

**Ladder comment block** (from RESEARCH.md §Code Examples — D-31, top of plugin section ~line 283):
```zsh
# Key-ownership ladder (highest first — new clashes resolve downward):
#   1. autocomplete: Tab/menu (Tab ALWAYS menu-select, never ghost-accept)
#   2. autosuggestions: ghost-accept (Right-arrow, vicmd-l, Ctrl+Space, Ctrl+_)
#   3. fzf: Ctrl+R (+ expendable **/Ctrl+T/Alt+C extras — droppable per D-10)
#   4. stock vi/zle: everything undecided (core motions hjkl/wb/ggG untouchable)
# Load-order rule: plugin binds, then atload overrides, then fzf ladder, then
# owned keys are RE-ASSERTED (^I like ^R) because fzf --zsh rebinds ^I last.
```

**Tab re-assert fix** (from RESEARCH.md Pattern 1 — goes immediately after the existing line 341 `^R` bind):
```zsh
# Autocomplete-first (D-30): re-assert AFTER fzf — fzf unconditionally binds ^I.
bindkey '^I' menu-select            # Tab enters menu, never ghost-accepts (D-29)
bindkey '^R' fzf-history-widget     # existing line 341, unchanged owner
```
Plus preset BEFORE the fzf source (line 324): `fzf_default_completion=menu-select` (keeps the `**`-fallback on menu-select even if order shifts).

---

### `zsh/.zshenv` (NEW file — config, batch)

**Analog:** `zsh/.zprofile` (git-tracked ✓). Only existing top-level zsh startup file; copy its minimal shape — comment header + intentionally-small body.

**Analog excerpt** (`zsh/.zprofile`, full file, 1 line):
```zsh
# Zsh login profile — intentionally empty.
```

**New file pattern** (from RESEARCH.md H-7 — Ubuntu `skip_global_compinit=1` per upstream README; harmless on Arch which has no global compinit):
```zsh
# Zsh environment — loaded for ALL zsh invocations (before .zshrc).
# skip_global_compinit=1: Ubuntu-family /etc/zsh/zshrc runs system compinit
# unless this is set; marlonrichert/zsh-autocomplete owns compinit itself at
# first precmd ("Remove any calls to compinit" — upstream README), so the
# system call would double-initialize. No-op on Arch (no global compinit).
skip_global_compinit=1
```
Stow note: new file auto-deploys as `~/.zshenv` under the existing `zsh` package (same `pkg/.config`-mirror convention — here a top-level dotfile like `.zshrc`/`.zprofile`, no installer change needed beyond the file's existence).

---

### `setup.sh` (utility, file-I/O)

**Analog:** `setup.sh` itself (git-tracked ✓, 2027 lines). Every D-24/D-33 edit copies an existing call-site form. All line numbers below are current (pre-edit) positions.

**Safety header — mandatory for any touched function** (lines 1–6):
```bash
#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit
```

**All stow call sites needing `--no-folding`** (grep-verified; D-24 mandates uniform flag on install AND uninstall):

| # | Site | Lines | Current form → change |
|---|------|-------|----------------------|
| 1 | keyd privileged preview (`--no --verbose`) | 420–422 | `stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd` → insert `--no-folding` after `--dir/--target` |
| 2 | keyd DRY_RUN echo | 433 | `echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ keyd"` → echo string gains `--no-folding` |
| 3 | per-pkg DRY_RUN echo + preview | 437–438 | echo line 437 + live preview line 438 (`stow ... --no --verbose "$pkg"`) both gain flag |
| 4 | keyd install preview | 564–566 | same shape as site 1 (lines 564–566) → add flag |
| 5 | keyd install DRY_RUN echo | 580 | same shape as site 2 → echo string gains flag |
| 6 | keyd live `sudo stow [--adopt] -t /` | 635, 637 | `sudo stow --dir="$SCRIPT_DIR" --target=/ --adopt keyd` / `sudo stow --dir="$SCRIPT_DIR" --target=/ keyd` → add flag (harmless under `-t /`, uniform per D-24) |
| 7 | `run_stow` live `--restow` | 949–950 | `echo "Stowing $pkg -> \$HOME via stow ... --restow $pkg"` + `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"` → add flag to BOTH echo and live command |
| 8 | uninstall DRY_RUN echoes + previews | 842–844, 855 | `stow ... --delete $pkg` echo (842) + `--no --verbose --delete` preview (844) + keyd `--delete` echo (855) → gain flag |
| 9 | uninstall live `-D` (+ keyd `-D -t /`) | 904, 911 | `stow --dir="$SCRIPT_DIR" --target="$HOME" -D "$pkg"` / `sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd` → add flag (`--no-folding -D` cleanly removes even legacy folded trees — sandbox-verified) |

**Canonical live-stow form to copy** (lines 949–950):
```bash
echo "Stowing $pkg -> \$HOME via stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
if ! stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"; then echo "Error: stow failed for package '$pkg'" >&2; return 1; fi
```

**`mkdir -p` guard placement** (from RESEARCH.md §Code Examples — start of `run_stow`, lines 939–941; plain mkdir, never inspects/repairs symlinks per D-26):
```bash
run_stow() {
    local pkg
    # D-24: parent-dir guard — plain mkdir (never inspects/repairs symlinks, D-26).
    mkdir -p "$HOME/.config"
    for pkg in "${SELECTED_PACKAGES[@]}"; do
```

**`post_verify` fold-detector addition** (from RESEARCH.md §Code Examples — inside `post_verify`, setup.sh:506–524; per-file `readlink -f` checks at 493–504 pass UNCHANGED under `--no-folding`, the required addition is the intermediate-dir walk):
```bash
# D-24/D-33: fail loudly on folded intermediate dirs (e.g. ~/.config as a
# symlink). Detection only — NEVER repair here (D-26: hand-repair by executor).
rel_dir="$(dirname "$rel")"
if [[ "$rel_dir" != "." ]]; then
    prefix="$HOME"; IFS=/ read -ra parts <<< "$rel_dir"
    for part in "${parts[@]}"; do
        prefix="$prefix/$part"
        if [[ -L "$prefix" ]]; then
            echo "FOLDED: $prefix is a symlink (stow folded a parent dir)" >&2
            echo "  Hand-repair required (see README); installer will not auto-fix." >&2
            failed=$((failed + 1)); break
        fi
    done
fi
```
Minimal targeted variant (also acceptable per RESEARCH.md): when any selected package contains `.config/...` paths, assert `[[ ! -L $HOME/.config ]]` with a D-26 pointer message.

**`assert_linked` — extend, don't replace** (lines 493–504):
```bash
assert_linked() {
    local rel="$1"
    local pkg="$2"
    local abs="$HOME/$rel"
    local got=""
    if [[ ! -e "$abs" ]]; then echo "MISSING: $rel (expected from package $pkg) -> $abs does not exist" >&2; echo "  Expected target: $SCRIPT_DIR/$pkg/$rel" >&2; return 1; fi
    if ! got=$(readlink -f "$abs" 2>/dev/null); then echo "UNRESOLVABLE: $rel -> $abs (readlink -f failed)" >&2; return 1; fi
    case "$got" in
        "$SCRIPT_DIR/$pkg/"*|"$SCRIPT_DIR/$pkg") echo "ok: $rel -> $got"; return 0 ;;
        *) echo "MISMATCH: $rel -> $got (expected under $SCRIPT_DIR/$pkg/)" >&2; echo "  Link: $abs -> $got" >&2; echo "  Expected target prefix: $SCRIPT_DIR/$pkg/" >&2; return 1 ;;
    esac
}
```

**`ensure_local_files` ordering + DRY_RUN idiom** (lines 779–793) — `mkdir -p ~/.config` guard must precede `run_stow`; DRY_RUN echoes the mkdir:
```bash
ensure_local_files() {
    local shell_local="$HOME/.zshrc.local"
    local nvim_local="$HOME/.config/nvim/lua/local.lua"
    local nvim_local_dir="$HOME/.config/nvim/lua"
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: touch HOME ~/.zshrc.local (if absent) and deployed nvim lua/local.lua (if absent)"
        return 0
    fi
```

**Prevention-only rule (D-26)** — `setup.sh` gains prevention only, with an explicit comment/docs rule that it must NEVER attempt to detect-and-fix a broken `~/.config` symlink. Sandbox proof: `--no-folding -S` against a symlinked `~/.config` aborts loudly (`existing target is not owned by stow`, rc=1, zero writes) — stow's own conflict error IS the detection; no custom repair code.

**DRY_RUN echo-update rule** — every live-command flag change must update its paired `[DRY RUN] Would run:` echo string (sites 2, 3, 5, 8) so previews stay honest.

---

### `README.md` (config/docs, static)

**Analog:** `README.md` itself (git-tracked ✓). Two edit targets, both copying existing block shapes.

**Manual stow one-liners — append `--no-folding`** (lines 83–102, atomic-docs per D-33):
```bash
# Core (Zsh default)
stow --dir=. --target="$HOME" --restow nvim zsh starship

# Nushell backup instead of Zsh
stow --dir=. --target="$HOME" --restow nvim nushell starship

# GUI extras (local mode)
stow --dir=. --target="$HOME" --restow alacritty
```
Full-deploy line 101 (`stow --dir=. --target="$HOME" --restow nvim zsh starship alacritty`) likewise gains the flag. Explicit `--dir`/`--target` form is what `bash setup.sh` does internally (line 85) — keep that sentence, extend with the `--no-folding` rationale (leaf-links only, never swallows `~/.config`).

**New key-ownership table (D-31)** — goes in a Zsh section (no dedicated Zsh behavior section exists today; nearest anchors are `#### Zsh Plugin Manager` at line 122 and the `## Tech Stack` shell row at 163–164). Copy the pipe-table idiom from lines 144–147:
```markdown
| File | Destination | Sourced/Loaded |
|------|-------------|----------------|
| Shell | `~/.zshrc.local` | Sourced at the tail of `~/.zshrc` (after tool inits, before the p10k prompt apply) |
```
Table content = D-30 ladder (autocomplete Tab/menu > autosuggestions ghost-accept > fzf Ctrl+R+extras > stock vi/zle) + the Tab-never-ghost-accepts / Right-arrow-menuselect-wins / Ctrl+C-dismisses rows + offline-first-prompt note (Pitfall 7: zasync auto-clone needs network+git or the async list silently never starts).

**keyd block reference** (lines 106–114) — privileged-preview-then-confirm prose shape to mirror if the stow-containment note needs a similar preview/confirm paragraph. Its `stow --dir=. --target=/ --no --verbose keyd` preview one-liners (lines 110, 112–113) also gain `--no-folding` for doc/code parity.

---

### `nvim/.config/` sibling eviction (config tree, file-I/O)

**Analog:** the `nvim/.config/nvim/` tree shape itself — Stow package-mirror convention (`pkg/.config/...` mirrors the deployment target; all XDG packages share this shape). Git-tracked ✓ (`git ls-files nvim/.config/` lists only `nvim/...` paths).

**Eviction facts (verified):** `git status --short` shows all four strays as untracked (`?? nvim/.config/{context7,gh,lazygit,opencode}/`), so eviction is plain `mv` — no `git rm`, zero git-history impact. Live tree confirmed: `nvim/.config/` contains `context7/ gh/ lazygit/ nvim/ opencode/`.

**Ordering constraint (Pitfall 4):** move strays OUT of the package BEFORE re-stowing — else `--no-folding` leaf-links every stray file into `~/.config/` as stow-owned links. `opencode/` is ~80MB — preview with `du -sh` first. Destinations are the same `~/.config/<name>` paths users already see through the fold (move, never copy-delete, never delete).

**Post-eviction invariant:** the nvim package keeps ONLY `.config/nvim/`.

---

## Shared Patterns

### Bash safety header
**Source:** `setup.sh` lines 1–6
**Apply to:** any `setup.sh` function touched by this phase (no new scripts are created)
```bash
#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit
```

### DRY_RUN preview-before-mutation
**Source:** `setup.sh` lines 437–439 (per-pkg), 579–585 (keyd install), 837–875 (uninstall)
**Apply to:** every `setup.sh` edit in this phase — new flags previewable via `[DRY RUN] Would run:` echoes; echo strings must be updated alongside live commands
```bash
echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
if command -v stow >/dev/null 2>&1; then echo "[DRY RUN] stow --no --verbose preview for $pkg:"; stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
else echo "  (stow not found — would install via package manager first)"; fi
```

### Explicit stow invocation form
**Source:** `setup.sh` lines 949–950; `README.md` line 85
**Apply to:** all stow call sites (install, preview, uninstall, keyd) + README one-liners
```bash
stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"
# README manual form: stow --dir=. --target="$HOME" --restow nvim zsh starship
```
D-24 addition: `--no-folding` inserted after `--dir/--target` on every invocation, uniformly.

### Zsh conditional-source / probe-fallthrough
**Source:** `zsh/.zshrc` lines 24–25, 280, 324–337
**Apply to:** any optional config the fix adds (probes must never return nonzero at top level; every `source` gets `2>/dev/null || true`)
```zsh
[[ -f "$HOME/.shell_aliases" ]] && source "$HOME/.shell_aliases"
source <(fzf --zsh) 2>/dev/null || true
```

### Comment-where-order-matters
**Source:** `zsh/.zshrc` lines 303–307 (load-order rationale), 331–334 (Debian rung rationale), 440–444 (tail-PATH rationale); `setup.sh` lines 412–413, 551–553
**Apply to:** ladder comment (D-31), why-zicompinit-stays-out comment, `fzf_default_completion` preset, `mkdir -p` guard, fold-detector, prevention-only rule — every load-order-sensitive or surprising line gets a `Why:`/rationale comment in the same style.

### Phase-1 atomic-docs rule
**Source:** CONTEXT.md D-18/D-31/D-33 (invoked explicitly)
**Apply to:** every behavior change ships with its `README.md` + in-code comment update in the same commit (`zsh/.zshrc` ladder comment + README key-ownership table; stow flags + README one-liners; `skip_global_compinit` + comment).

### Error-handling: warn-and-continue, never hard-fail interactive shell
**Source:** `zsh/.zshrc` lines 341–344 (`^R` widget-missing warn); `setup.sh` lines 904–905 (`stow -D` non-zero → warning, continue)
**Apply to:** new `zsh/.zshrc` binds (Tab re-assert needs no guard — `menu-select` is a builtin — but any new widget probe follows the `zle -l | grep -q` + `[WARN]` shape); `setup.sh` `--no-folding` additions follow existing warn-vs-abort levels (no behavior change to gates).

## No Analog Found

| File / Procedure | Role | Data Flow | Reason |
|------------------|------|-----------|--------|
| `$HOME` hand-repair runbook (break `~/.config` symlink → `mkdir` → `mv` strays → re-stow `--no-folding` → verify) | utility (manual) | file-I/O | Executor-hands procedure, never repo code per D-26; no existing repair script in the codebase to copy from. Planner uses the RESEARCH.md §D-26 runbook (8 ordered steps with preview commands) verbatim. |

## Metadata

**Analog search scope:** repo root (`zsh/`, `setup.sh`, `README.md`, `nvim/.config/`), `.planning/` (CONTEXT, RESEARCH, STATE, REQUIREMENTS, codebase docs); installed plugin sources cited via RESEARCH.md line references (not repo analogs — upstream code, read-only).
**Files scanned:** `zsh/.zshrc` (445 lines, full read), `setup.sh` (2027 lines — ranges 1–60, 405–658, 776–1008 via grep-located offsets), `README.md` (lines 72–176), `zsh/` dir listing, `nvim/.config/` dir listing; `git ls-files` tracking checks for all named analogs.
**Tracked-source gate:** every emitted analog path verified via `git ls-files` — `zsh/.zshrc`, `zsh/.zprofile`, `setup.sh`, `README.md`, `nvim/.config/nvim/init.lua` all tracked; `nvim/.config/{context7,gh,lazygit,opencode}/` confirmed untracked (`??`); `zsh/.zshenv` confirmed absent (new file, no mirror path emitted).
**Pattern extraction date:** 2026-09-22
