# Phase 03: polished-shell-theme-local-overrides - Pattern Map

**Mapped:** 2026-09-17
**Files analyzed:** 6 (4 modified in-place + 2 new templates)
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `zsh/.zshrc` (plugin block 299-305 + `^R` bind) | config (shell-init) | event-driven (interactive shell startup) | `zsh/.zshrc` itself, lines 284-305 | exact (in-place edit) |
| `zsh/.zshrc` (PATH `typeset -U` + tail `.local` guard) | config (shell-init) | event-driven (shell startup) | `zsh/.zshrc` itself, lines 24-40, 231-233, 327 | exact (in-place edit) |
| `nvim/.config/nvim/init.lua` (append `pcall(require,"local")`) | config (editor-init) | event-driven (editor startup) | `nvim/.config/nvim/lua/lang/init.lua` lines 39-43, 96-101 + `init.lua` lines 22-26, 84-87 | role-match |
| `setup.sh` (post-stow empty-file bootstrap) | utility (installer) | batch (deployment) | `setup.sh` itself: `run_stow()` lines 920-933, DRY_RUN guards lines 433-441, `install_keyd_privileged` lines 579-584 | exact (in-place edit) |
| `.gitignore` (`*.local`, `local.lua`, `zsh/.zsh_history`) | config | file-I/O (gitignore filtering) | `.gitignore` itself, lines 1-15 | exact (in-place edit) |
| `zsh/.zshrc.local.example` + `nvim/.config/nvim/lua/local.lua.example` (NEW) | config (docs template) | file-I/O | — none (no `*.example` exists in repo; glob verified zero hits) | no-analog — use RESEARCH.md code examples |

## Pattern Assignments

### `zsh/.zshrc` — plugin block repair + `^R` bind + PATH guard + `.local` tail (config, event-driven)

**Analog:** `zsh/.zshrc` itself (in-place edits at three sites; idioms copied from within the same file)

**Conditional-source idiom** (lines 24-25) — model for D-10 `~/.zshrc.local` guard:
```zsh
# Load custom configurations (only if files exist to avoid console output)
[[ -f "$HOME/.shell_aliases" ]] && source "$HOME/.shell_aliases"
[[ -f "$HOME/.shell_functions" ]] && source "$HOME/.shell_functions"
```

**PATH mutation sites to cover** (lines 36-40) — D-06 `typeset -U path` goes ABOVE line 36:
```zsh
# Local bins
export PATH="$HOME/.local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.local/sbin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
```

**Late PATH append + fpath** (lines 231-233, 276) — also covered by the top-of-file guard, do NOT rewrite:
```zsh
if [[ -d "$HOME/.local/share/zinit/polaris/bin" ]]; then
    export PATH="$HOME/.local/share/zinit/polaris/bin:$PATH"
fi
# ...
[[ -d "$HOME/.config/zsh/completions" ]] && fpath=("$HOME/.config/zsh/completions" $fpath)
```

**Working zinit plugin pattern** (lines 287-296) — copy for the fzf-history-search fix (each plugin gets its own `zi light`):
```zsh
# Auto-suggestions - Suggests commands as you type based on history
zi ice atload'_zsh_autosuggest_start' \
    atinit'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
bindkey "^_" autosuggest-execute
bindkey "^ " autosuggest-accept'
zi light zsh-users/zsh-autosuggestions

# Fast syntax highlighting - Real-time command validation
zi light-mode for \
    $ZI_REPO/fast-syntax-highlighting
```

**Broken block to fix** (lines 298-305) — bare `zi ice <repo>` with no `light` loads nothing; autocomplete must stay LAST:
```zsh
# FZF history search - Fuzzy search through command history
zi ice joshskidmore/zsh-fzf-history-search

# Zsh autocomplete - Real-time type-ahead autocompletion
zi ice atload'
bindkey              "^I" menu-select
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete'
zi light marlonrichert/zsh-autocomplete
```

**Existing bindkey idioms** (lines 94, 100-102) — model for unconditional `bindkey '^R' fzf-history-widget`:
```zsh
bindkey '^X^E' edit-command-line
bindkey '^Z' undo
bindkey '^Y' redo
```

**Tail insertion point** (lines 327-330) — `.local` guard goes BETWEEN p10k source and `apply_catppuccin`; p10k instant prompt (lines 15-17) stays at top, do not move:
```zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Apply Catppuccin rainbow latte theme
apply_catppuccin classic mocha
```

**Bun portability rider** (line 393) — rewrite absolute path with guard (Pitfall 6):
```zsh
[ -s "/home/shoyeb/.bun/_bun" ] && source "/home/shoyeb/.bun/_bun"
# becomes: [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
```

**Error handling pattern:** `print -P "%F{yellow}[WARN]%f ..."` warning (cf. lines 149-156 Zinit self-clone block); probe failures must fall through, never `return 1` at top level (would abort interactive shell).

---

### `nvim/.config/nvim/init.lua` (config, event-driven)

**Analog:** `nvim/.config/nvim/lua/lang/init.lua` (pcall + WARN pattern) + `init.lua` tail (insertion point)

**Insertion point** (`init.lua` lines 83-87) — append AFTER the `vim.schedule` colorscheme block, end of file:
```lua
-- CRITICAL: Apply colorscheme AFTER all plugins load
vim.schedule(function()
    local settings = require("settings")
    vim.cmd.colorscheme(settings.colorscheme)
end)
```

**pcall + WARN pattern to copy** (`lua/lang/init.lua` lines 42, 96-101):
```lua
local status_ok, lang_config = pcall(require, lang_module)
-- ...
    else
        vim.notify(
            "Failed to load: " .. lang_module .. "\nError: " .. tostring(lang_config),
            vim.log.levels.WARN
        )
    end
```

**Bootstrap-level pcall pattern** (`init.lua` lines 22-26) — same shape, ERROR level for hard deps; local override uses WARN + silent-when-absent:
```lua
local status_ok, lang_config = pcall(require, "lang")
if not status_ok then
    vim.notify("Failed to load language configs: " .. tostring(lang_config), vim.log.levels.ERROR)
    lang_config = { plugin_specs = {} }
end
```

**Code to write** (from RESEARCH.md § Code Examples, adapted to the WARN idiom above):
```lua
-- Machine-local overrides (deployed local.lua, gitignored): loaded last so machine tweaks win.
-- Absent file is a silent no-op; a present-but-erroring file warns instead of breaking startup.
local ok, err = pcall(require, "local")
if not ok and not tostring(err):match("module 'local' not found") then
  vim.notify("local.lua error: " .. tostring(err), vim.log.levels.WARN)
end
```

**Error handling:** absent module = silent no-op (do NOT notify on `module 'local' not found`); present-but-erroring = `vim.notify(..., WARN)`; never ERROR (must not break startup).

---

### `setup.sh` (utility, batch)

**Analog:** `setup.sh` itself (in-place addition to post-stow success path)

**File header conventions** (lines 1-8) — mandatory for any new function/code:
```bash
#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
```

**Insertion point** (lines 1997-2002) — new `ensure_local_files` call goes AFTER `run_stow` success, BEFORE/AFTER `post_verify`, inside `main` live path (never in the DRY_RUN early-return branch at lines 1940-1981):
```bash
    quarantine_scan
    if ! run_stow; then echo "Error: stow deployment failed." >&2; exit 1; fi
    if ! post_verify; then echo "Error: post-verify failed — deployment incomplete." >&2; exit 1; fi
    offer_chsh || true
    echo ""
    echo "Setup complete. Deployed: ${SELECTED_PACKAGES[*]}"
```

**DRY_RUN preview pattern to copy** (lines 437-441, `preview_selection` body):
```bash
        echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if command -v stow >/dev/null 2>&1; then echo "[DRY RUN] stow --no --verbose preview for $pkg:"; stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
        else echo "  (stow not found — would install via package manager first)"; fi
```

**DRY_RUN guard pattern to copy** (lines 579-580, `install_keyd_privileged`):
```bash
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ keyd"
```

**run_stow pattern** (lines 920-933) — quote `$HOME`/`$SCRIPT_DIR`, `return 1` on failure with stderr message:
```bash
run_stow() {
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            if ! install_keyd_privileged; then
                echo "Error: privileged keyd install failed." >&2
                return 1
            fi
            continue
        fi
        echo "Stowing $pkg -> \$HOME via stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if ! stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"; then echo "Error: stow failed for package '$pkg'" >&2; return 1; fi
    done
}
```

**Code to write** (from RESEARCH.md § Code Examples — `test -f || touch`, HOME-deployed path, never `$SCRIPT_DIR`):
```bash
# Post-stow success path only. Never truncate existing user files; never write under --dry-run.
if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: touch $HOME/.zshrc.local + deployed local.lua (if absent)"; return 0; fi
[[ -f "$HOME/.zshrc.local" ]] || touch "$HOME/.zshrc.local"
_local_lua="$HOME/.config/nvim/lua/local.lua"
[[ -f "$_local_lua" ]] || { mkdir -p "$(dirname "$_local_lua")" && touch "$_local_lua"; }
```

**Error handling:** `set -Eeuo pipefail` is file-global; new function must use `local` vars, quote all paths, `|| true` only where failure is tolerable; never truncate (`touch`, not `>`) an existing user file.

---

### `.gitignore` (config, file-I/O)

**Analog:** `.gitignore` itself (append-only edit)

**Existing pattern** (lines 1-15) — section comment + repo-relative paths:
```
nushell/.config/nushell/history.txt
nushell/.config/nushell/history.json

# Neovim
nvim/.config/nvim/lazy-lock.json
nvim/.config/nvim/.neoconf.json
nvim/.config/nvim/undo/
nvim/.config/nvim/shada/
nvim/.config/nvim/state/
nvim/.config/nvim/cache/
*.swp

# Installer quarantine (D-13/D-14) — timestamped collision backup, gitignored
.stow-conflicts/
.cache
```

**Lines to add** (append a `# Machine-local overrides (Phase 3)` section):
```
# Machine-local overrides (Phase 3) — HOME-only, never committed; see *.example templates
*.local
nvim/.config/nvim/lua/local.lua
zsh/.zsh_history
```

**Note:** `*.local` covers both `~/.zshrc.local` accidents and any repo-side `*.local` file; the explicit `local.lua` line guards the deployed path even though `*.local` does not match it (`local.lua` ≠ `*.local`). `zsh/.zsh_history` untrack pairs with `git rm --cached zsh/.zsh_history` (keep working-tree file untouched; full history purge is deferred SECR-02 — do NOT attempt `filter-repo` here).

---

### `zsh/.zshrc.local.example` + `nvim/.config/nvim/lua/local.lua.example` (NEW, config/docs)

**Analog:** NONE — `Glob("**/*.example")` returns zero hits; no template precedent exists in the repo.

**Planner: use RESEARCH.md § Code Examples as the content source**, wrapped in the repo's rationale-comment style (`# NOTE:` / `-- why:`). Templates are docs only — never sourced/required:
- `zsh/.zshrc.local.example`: commented `export PATH` prepend example, `POWERLEVEL9K_*` tweak example, alias example; header must state "copy to `~/.zshrc.local` (HOME-only, gitignored); never commit a real `.local` file".
- `nvim/.config/nvim/lua/local.lua.example`: commented `vim.opt` tweak + `vim.keymap.set` example; header must state "copy to deployed `~/.config/nvim/lua/local.lua` (gitignored); absent file is a silent no-op".

**Closest content donors** (for example body material, not structure): `zsh/.zshrc` lines 36-40 (PATH shape), lines 333-390 (POWERLEVEL9K element list), `nvim/.config/nvim/lua/settings.lua` (`colorscheme` toggle shape).

---

## Shared Patterns

### Conditional source guard (zsh)
**Source:** `zsh/.zshrc` lines 24-25
**Apply to:** `~/.zshrc.local` tail insertion
```zsh
[[ -f "$HOME/.shell_aliases" ]] && source "$HOME/.shell_aliases"
```
Quoted `$HOME`, `[[ -f ... ]] && source` (not `|| true` — avoids "no such file" noise). Insertion order: after `zoxide init` region, before `source ~/.p10k.zsh` (line 327) so user tweaks win and prompt overrides render.

### pcall silent-absent / loud-broken (nvim)
**Source:** `nvim/.config/nvim/lua/lang/init.lua` lines 42, 96-101
**Apply to:** `init.lua` tail `pcall(require, "local")`
```lua
local status_ok, lang_config = pcall(require, lang_module)
-- on failure: vim.notify("Failed to load: " .. lang_module .. "\nError: " .. tostring(lang_config), vim.log.levels.WARN)
```
Absent `local.lua` = silent no-op (filter `module 'local' not found`); erroring file = `WARN`, never `ERROR`, never abort.

### DRY_RUN preview-before-write (installer)
**Source:** `setup.sh` lines 437-441, 579-584
**Apply to:** `setup.sh` local-file bootstrap
```bash
if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would run: ..."
```
`--dry-run` never mutates the filesystem; preview each write with `[DRY RUN] Would run:`; create only if absent (`[[ -f ... ]] || touch`, `mkdir -p "$(dirname ...)"`); write to `$HOME`-deployed paths, never into `$SCRIPT_DIR`.

### Installer safety boilerplate
**Source:** `setup.sh` lines 1-8
**Apply to:** any new `setup.sh` function
`set -Eeuo pipefail` + `shopt -s inherit_errexit` are global; use `local` vars, quote paths, stderr (`>&2`) + `return 1` on failure.

### Rationale comments + atomic docs
**Source:** `zsh/.zshrc` line 12 (`# Should stay close to the top...`), `setup.sh` lines 28-31, Phase 1 D-04 rule
**Apply to:** all Phase 3 edits
Every order-sensitive insertion (`typeset -U` top, plugin order, `.local` tail position, `pcall` after colorscheme) ships with a `# why:` rationale comment, plus its README/AGENTS.md/in-code comment update in the same commit. Theme files are explicitly NOT touched (D-13 intended drift).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `zsh/.zshrc.local.example` | config (docs template) | file-I/O | No `*.example` precedent in repo (glob: zero hits); planner should use RESEARCH.md examples + rationale-comment style |
| `nvim/.config/nvim/lua/local.lua.example` | config (docs template) | file-I/O | Same — no precedent; use RESEARCH.md `local.lua` example + content donors above |

## Metadata

**Analog search scope:** repo root (`zsh/.zshrc`, `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lua/lang/init.lua`, `setup.sh`, `.gitignore`), `Glob("**/*.example")`, `Grep("\.local|local\.lua|DRY_RUN|run_stow")`
**Files scanned:** ~8 (4 fully read, 2 grepped, 2 glob-searched)
**Pattern extraction date:** 2026-09-17
