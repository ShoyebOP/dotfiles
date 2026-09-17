---
phase: 03-polished-shell-theme-local-overrides
reviewed: 2026-09-17T13:25:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - zsh/.zshrc
  - nvim/.config/nvim/init.lua
  - .gitignore
  - setup.sh
  - README.md
  - zsh/.zshrc.local.example
  - nvim/.config/nvim/lua/local.lua.example
findings:
  critical: 2
  warning: 17
  info: 7
  total: 26
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-09-17T13:25:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed the 7 Phase 3 files at standard depth: full reads of `zsh/.zshrc` (445 lines),
`nvim/.config/nvim/init.lua` (94 lines), `.gitignore`, both `*.example` templates, and
`README.md`, plus a targeted review of the Phase 3-relevant paths in `setup.sh`
(`ensure_local_files`, local-override wiring, run/uninstall interplay) with spot checks
elsewhere in the 2025-line installer. `bash -n`, `zsh -n`, and `luac -p` all pass, and
pattern greps found no hardcoded secrets, TODOs, or empty catches — but per-file tracing
surfaced 2 startup-breaking defects and 17 robustness/correctness warnings. The dominant
themes: (1) shell/editor init sequences that break on the exact fresh-clone path this
project promises to support (unguarded `source`, unchecked `git clone`); (2) the new
"local overrides load last so tweaks win" contract is violated in both shells by
ordering bugs (scheduled colorscheme runs after `local.lua`; hardcoded
`POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` clobbers `~/.zshrc.local` and `p10k configure`
output); (3) stow packaging has no `.stow-local-ignore`, so live history and example
templates ship as deployed dotfiles; (4) `ensure_local_files` writes for deselected
packages, with default umask permissions, through stow symlinks back into the repo tree
it claims to never touch.

## Critical Issues

### CR-01: Unguarded Zinit `source` breaks every shell after a silent install failure

**File:** `zsh/.zshrc:144-170`
**Issue:** The silent install branch (lines 163-166, taken when `$P9K_INSTANT_PROMPT`
is set — i.e. precisely on re-sourced shells using instant prompt) swallows
`mkdir`/`git clone` failures (`>/dev/null 2>&1`, no status check, no `return`), then
falls through to the unconditional `source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"`
at line 170. If the clone failed (no network on a fresh clone, disk error), the sourced
file does not exist: every interactive shell prints a `source: no such file` error and
then fails on every subsequent `zi`/`zinit` command, the `apply_catppuccin` call, and
all plugin-provided widgets — a broken prompt on the project's core "fresh clone →
working Zsh" path. The verbose branch `return 1`s on failure (itself aborting the rest
of `.zshrc`, see WR-07), so the two branches fail in two different ways.
**Fix:**
```zsh
# Load Zinit — guard: never source a file that may not exist
if [[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
    source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
    autoload -Uz _zinit
    ((${+_comps})) && _comps[zinit]=_zinit
else
    print -P "%F{red}[ERROR]%f zinit not installed — plugins disabled. Re-run with network."
    return 0
fi
```
and make the silent branch check clone status and fall into this same guard instead of
proceeding.

### CR-02: Unchecked lazy.nvim bootstrap clone aborts all of `init.lua`

**File:** `nvim/.config/nvim/init.lua:3-13`
**Issue:** `vim.fn.system({... git clone ...})` return value and `vim.v.shell_error`
are never checked. On a fresh machine without network (or without `git`), the clone
fails, `lazypath` does not exist, and `require("lazy").setup(specs, opts)` at line 79
errors — aborting `init.lua` before `require("base")` (line 81), so options, keymaps,
and autocmds never load. The editor opens in a half-initialized state with an obscure
loader error instead of a clear diagnostic. Same fresh-clone failure class as CR-01.
**Fix:**
```lua
if not vim.loop.fs_stat(lazypath) then
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
    if vim.v.shell_error ~= 0 then
        vim.notify("lazy.nvim bootstrap failed (check network/git): " .. tostring(out),
            vim.log.levels.ERROR)
        return
    end
end
```

## Warnings

### WR-01: `zi ice zsh-users/zsh-completions` stages modifiers but never loads anything

**File:** `zsh/.zshrc:287-288`
**Issue:** This is the exact anti-pattern the file's own comment at lines 303-307
documents ("a bare `zi ice <repo>` with no following load command stages modifiers for
the NEXT load and installs nothing (this plugin was silently never loading)"). Line 288
is a bare `zi ice zsh-users/zsh-completions` with no following `zi light`, so the
completions plugin is silently never installed, and the staged ice is consumed by the
next load (`zsh-autosuggestions` at line 296). Extra completions are missing with no
visible error.
**Fix:**
```zsh
zi light zsh-users/zsh-completions
```

### WR-02: Unconditional `bindkey '^R'` creates a dead key when the widget is absent

**File:** `zsh/.zshrc:341-344`
**Issue:** Line 341 binds Ctrl-R to `fzf-history-widget` unconditionally, then lines
342-344 merely *warn* if the widget does not exist (fzf not installed, WR-01-style load
failure, minimal environment). The binding still points at a nonexistent widget, so
Ctrl-R is a dead key that errors on press. The warn-but-don't-fix pattern leaves every
fzf-less shell with a broken primary history key.
**Fix:**
```zsh
if zle -l 2>/dev/null | grep -q fzf-history-widget; then
    bindkey '^R' fzf-history-widget
else
    bindkey '^R' history-incremental-search-backward
fi
```

### WR-03: Unguarded `apply_catppuccin` errors when the theme plugin is missing

**File:** `zsh/.zshrc:373-374`
**Issue:** `apply_catppuccin classic mocha` is invoked with no existence check. The
function is provided at runtime by the `tolkonepiu/catppuccin-powerlevel10k-themes`
plugin (no definition exists in-repo), so any plugin-load failure (CR-01, offline
first run) turns every shell start into `command not found: apply_catppuccin`. Cosmetic
theming must never be load-bearing for shell startup.
**Fix:**
```zsh
if command -v apply_catppuccin >/dev/null 2>&1; then
    apply_catppuccin classic mocha
fi
```

### WR-04: Hardcoded prompt block clobbers `~/.zshrc.local` and `p10k configure` output

**File:** `zsh/.zshrc:366-424`
**Issue:** The comment at lines 366-368 promises local overrides "win" because they
load "before prompt apply". In fact lines 374 (`apply_catppuccin`) and 377-424 (47-element
`POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` assignment) run *after* both `~/.zshrc.local`
(line 370) and `~/.p10k.zsh` (line 371). Any `RIGHT_PROMPT_ELEMENTS` (or other theme)
customization in the local file — or regenerated by the user's own `p10k configure` —
is silently overwritten on the next shell. The documented ordering guarantee is false
for exactly the prompt settings users most often tweak (the template's own
`POWERLEVEL9K_TIME_FORMAT` example survives only by luck of not being in the list).
**Fix:** Move the Catppuccin apply + `RIGHT_PROMPT_ELEMENTS` defaults *above* the
local/p10k sources and guard them so user config wins, e.g.:
```zsh
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# shipped prompt defaults apply only when the user has not set their own
if (( ${+POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS} == 0 )); then
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=( ... )
fi
```
and update the comment/template to state precisely which settings survive.

### WR-05: Unguarded `eval "$(zoxide init zsh)"` on a possibly-missing binary

**File:** `zsh/.zshrc:57-58`
**Issue:** On a fresh machine before `bash setup.sh` installs dependencies, `zoxide`
is absent: every shell prints `command not found: zoxide` from the command
substitution. Harmless but noisy on the exact first-run path, and `eval` on external
output should be gated as a matter of hygiene.
**Fix:**
```zsh
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
```

### WR-06: `bindkey '^Z' undo` steals job-control suspend; comment/code disagree

**File:** `zsh/.zshrc:100-106`, `zsh/.zshrc:291-296`
**Issue:** Two compounding problems. (a) Ctrl-Z is the terminal suspend key (`SIGTSTP`);
rebinding it to `undo` removes background/suspend with no note, surprising anyone who
uses job control. (b) The comment on lines 103-104 says "Press Ctrl+_ … to undo" but
line 104 binds `^Z`, not `^_`; meanwhile line 294 binds `^_` to `autosuggest-execute`,
so the documented undo key is actually stolen by autosuggestions and `undo` lives on
an undocumented key. Users get neither the documented behavior nor suspend.
**Fix:** Bind undo to a non-suspend key and make comments match reality, e.g.
```zsh
bindkey '^_' undo   # Ctrl+/ — undo (Ctrl-Z suspend left intact)
bindkey '^Y' redo
```
and drop or relocate the `autosuggest-execute` binding on `^_` (or document the
trade-off explicitly).

### WR-07: Zinit bootstrap aborts the whole `.zshrc` on failure; unpinned HEAD clone

**File:** `zsh/.zshrc:144-167`
**Issue:** (a) Lines 156 and 160 `return 1` from a sourced `.zshrc`, discarding the
entire remainder (prompt, completions, keybindings, local overrides) because one
network operation failed — a single-point-of-failure for the whole shell. A degraded
shell with a clear error is strictly better than no configuration at all.
(b) Both clone commands pull unpinned upstream `HEAD` with full history (no
`--depth=1`, no commit pin; the "no commit pin per D-12" comment acknowledges the
choice). Every fresh machine executes whatever upstream HEAD contains at install time
— a supply-chain and reproducibility exposure for code sourced by every shell.
**Fix:** Replace `return 1` with a warning + fallthrough to the CR-01 guard so the
shell still configures; add `--depth=1 --branch=master` (or chosen ref) to bound the
clone; record the intended pinning policy (or explicit non-pinning acceptance with
review cadence) next to the D-12 comment.

### WR-08: Completion finalization is commented out; deprecated `compctl` in use

**File:** `zsh/.zshrc:264-281`, `zsh/.zshrc:353-359`
**Issue:** The `zicompinit; zicdreplay` finalization block (lines 353-359) is fully
commented out, so Zinit annexes and replayed completions depend entirely on transitive
`compinit` from the OMZ snippet — fragile and undocumented. Separately, `_pip_completion`
uses `compctl` (line 277), superseded by the `compdef`/`compsys` system decades ago;
under some completion states `compctl` registrations are ignored or conflict with
`compinit`. And `autoload -Uz _uv` (line 281) silently does nothing useful without an
initialized completion system.
**Fix:** Uncomment/repair the null-plugin finalization stanza (or document why OMZ
`compinit` ordering makes it unnecessary), and migrate the pip completion to
`compdef _pip_completion pip3` (or drop it if `zsh-completions` already ships pip).

### WR-09: Scheduled colorscheme runs after `local.lua` — local theme tweaks lose

**File:** `nvim/.config/nvim/init.lua:83-94`
**Issue:** The colorscheme is applied inside `vim.schedule` (deferred to the main-loop
tick), while `local.lua` is `require`d synchronously at lines 91-94. Deferred
callbacks run *after* the synchronous tail, so the shipped `settings.colorscheme`
overwrites any colorscheme/theme choice a user sets in `local.lua` — the inverse of
the file's own "loaded last so machine tweaks win" comment (line 89) and of the
README's "machine tweaks win" table. Additionally, `require("settings")` and
`vim.cmd.colorscheme(...)` inside the scheduled callback have no `pcall`, so a bad
colorscheme name errors asynchronously post-startup.
**Fix:**
```lua
-- apply colorscheme synchronously BEFORE local overrides so machine tweaks win
local ok, settings = pcall(require, "settings")
if ok then pcall(vim.cmd.colorscheme, settings.colorscheme) end
-- ...then load local.lua last (existing pcall block)
```

### WR-10: Overbroad `disabled_plugins` risks breaking filetype behavior

**File:** `nvim/.config/nvim/init.lua:44-76`
**Issue:** The disabled list includes `ftplugin`, `syntax`, and `compiler`. Disabling
`ftplugin` suppresses all filetype plugin behavior (indent rules, buffer-local
settings language modules may assume); disabling `syntax` removes the legacy syntax
fallback some plugins still touch. lazy.nvim's recommended minimal list is narrower;
each extra entry is a latent "why is filetype X misbehaving" report.
**Fix:** Shrink to the known-safe set (netrw/tar/zip/gzip/matchit/tohtml/tutor etc.)
and re-add `ftplugin`, `syntax`, `compiler` unless a measured startup problem justifies
each one — with a comment citing the measurement.

### WR-11: `require("local")` uses a collision-prone generic module name

**File:** `nvim/.config/nvim/init.lua:91-94`
**Issue:** `local` is about as generic as a Lua module name gets; any plugin on the
runtimepath shipping a top-level `local` module shadows or collides with the
machine-override file, and the `"module 'local' not found"` string-match then
misclassifies the failure. The failure mode is silent loading of the wrong file.
**Fix:** Namespace it, e.g. `pcall(require, "user.local")` with the deployed path
`lua/user/local.lua` (updating `.gitignore`, `ensure_local_files`, README, and the
template path together).

### WR-12: `ensure_local_files` ignores selection, permissions, and the stow symlink

**File:** `setup.sh:779-793`
**Issue:** Three defects in one function. (a) It unconditionally creates *both* local
files even when the corresponding package was unticked — a user who deselected `nvim`
still gets `~/.config/nvim/lua/` created, violating the strict "untick never installs
and never stows/writes" tick semantics README promises. (b) Files are created with
default-umask permissions via bare `touch`; these files are documented homes for
machine-specific (potentially secret-bearing) content and should be `chmod 600`.
(c) The "never writes under the repo dir" comment is false once stowed: after
`run_stow`, `$HOME/.config/nvim` is a symlink into `nvim/.config/nvim`, so
`touch "$HOME/.config/nvim/lua/local.lua"` creates `nvim/.config/nvim/lua/local.lua`
in the working tree (gitignored, but repo-resident, left behind by `stow -D`, and
visible to the next `quarantine_scan`/`post_verify` pass).
**Fix:**
```bash
ensure_local_files() {
    if [[ "$DRY_RUN" == true ]]; then ...; return 0; fi
    if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx zsh; then
        [[ -f "$HOME/.zshrc.local" ]] || { touch "$HOME/.zshrc.local"; chmod 600 "$HOME/.zshrc.local"; }
    fi
    if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then
        # resolve through stow symlink: if deployed path links into the repo, the
        # file intentionally lives there (gitignored); document this instead of
        # claiming HOME-only
        ...
    fi
}
```
at minimum gate on selection, set restrictive mode, and correct the comment/README
claim.

### WR-13: Stow packages ship live history and example templates (no `.stow-local-ignore`)

**File:** `zsh/.zshrc` (packaging), `setup.sh:quarantine_scan/post_verify/run_stow`
**Issue:** No `.stow-local-ignore` exists at repo root or per package (verified absent),
so `stow --restow zsh` deploys *every* file under `zsh/`, including the 68 KB live
`zsh/.zsh_history` present in the working tree and `zsh/.zshrc.local.example`
(clutter as `~/.zshrc.local.example`). Consequences: the deployed `~/.zsh_history`
symlink points into the repo, so shell history is written through the symlink into the
working tree; on a second machine, `quarantine_scan` will *move the user's real
`~/.zsh_history`* into `.stow-conflicts/` and replace it with this machine's history
symlink — startling and, for shell history, effectively data confusion (quarantine
preserves bytes, but the shell's history appears replaced). Same class for
`nvim/.../local.lua.example` (deployed clutter inside the Neovim runtimepath).
**Fix:** Add `zsh/.stow-local-ignore` (and audit `nvim/`) containing at minimum:
```
\.zsh_history
\.zshrc\.local\.example
```
(or root `.stow-local-ignore` with `(?<!…)`-appropriate patterns), document that
history/templates never deploy, and note the one-time cleanup for machines that
already stowed the history symlink.

### WR-14: `.gitignore` ignores the plugin lockfile and overmatches elsewhere

**File:** `.gitignore:5,15,18`
**Issue:** (a) Line 5 ignores `nvim/.config/nvim/lazy-lock.json` — the pin record for
~44 plugins that `STACK.md`/`AGENTS.md` cite as the reproducibility mechanism.
Ignoring it guarantees cross-machine plugin drift, the exact failure lockfiles exist
to prevent. If intentional, the rationale is undocumented anywhere in the file.
(b) Line 18 `*.local` matches *any* `*.local` file repo-wide, far broader than the two
intended override paths — it can silently swallow legitimately committable files.
(c) Line 15 `.cache` (no slash, no wildcard) is similarly broad.
**Fix:**
```gitignore
# Neovim — keep the lockfile committed for reproducible installs
# (remove the lazy-lock.json line below)
nvim/.config/nvim/.neoconf.json
...
# Machine-local overrides (Phase 3) — scoped, not global
zsh/.zshrc.local
**/.zshrc.local
nvim/.config/nvim/lua/local.lua
/.cache/
```

### WR-15: README sudoers snippet hardcodes a username; keyd scope understated

**File:** `README.md:116-120`
**Issue:** The least-privilege example hardcodes `shoyeb ALL=(ALL) …`. Second-machine
clones copy-paste it verbatim and it silently does nothing for them (wrong user), while
looking authoritative. Relatedly, the snippet covers only `keyd reload`/`systemctl
reload keyd`, but the installer also runs `sudo stow … -t / keyd` — the privileged
write itself still needs a password/terminal, which the docs never state.
**Fix:**
```
<your-user> ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload keyd, /usr/bin/keyd reload
```
plus one sentence: "the `sudo stow -t / keyd` write itself still prompts for your
password; only the reload is passwordless."

### WR-16: `path=( $path )` word-splits entries containing spaces

**File:** `zsh/.zshrc:440-445`
**Issue:** The final dedupe self-assignment expands `$path` unquoted. Any `PATH` entry
containing spaces (macOS-style dirs, `~/work/my tools/bin` from a local override)
splits into fragments, corrupting `PATH` on the last line of the file — the worst
possible place for it, since nothing after can repair it.
**Fix:**
```zsh
path=( "${path[@]}" )
```

### WR-17: `error()`/`info()` interpolate caller text through prompt expansion

**File:** `zsh/.zshrc:177-183`
**Issue:** `print -P "…$1…"` runs the caller's message through prompt expansion:
any `%` in the message (`100%`, `stow %s`) is interpreted as a prompt escape and
mangled or dropped. Diagnostics that corrupt the values they report are worse than
none when debugging installer/plugin failures.
**Fix:**
```zsh
function error() { print -P "%F{red}[ERROR]%f: %F{yellow}${1//%/%%}%f" && return 1; }
function info()  { print -P "%F{blue}[INFO]%f: %F{cyan}${1//%/%%}%f"; }
```

## Info

### IN-01: Dead commented-out clipboard widget references Wayland-only tool

**File:** `zsh/.zshrc:130-137`
**Issue:** Commented-out `copy-buffer-to-clipboard` pipes through `wl-copy`
unconditionally — dead code that, if revived on X11/headless, fails. Either delete it
or revive it with an availability check (`command -v wl-copy || xclip || …`).
**Fix:** Remove the block or gate it; don't leave half-portable dead code in the hot
path file.

### IN-02: `_fzf_ver` leaks as a global during startup

**File:** `zsh/.zshrc:324-337`
**Issue:** `_fzf_ver` is assigned without `local`/`typeset` at top-level `.zshrc`
scope (cleaned up at line 336 via `unset`, so exposure is brief). Trivial, but
`typeset _fzf_ver` costs nothing and survives future edits that move the `unset`.
**Fix:** `typeset _fzf_ver` before the `if command -v fzf` block.

### IN-03: README template-copy commands assume repo-root CWD

**File:** `README.md:149-154`
**Issue:** `cp zsh/.zshrc.local.example ~/.zshrc.local` only works from the clone
root; run from `$HOME` it fails confusingly right when a new user is following setup
docs. One clause fixes it.
**Fix:** Prefix with "(from the clone root)" or use absolute-ish forms.

### IN-04: Example templates omit the two rules that bite

**File:** `zsh/.zshrc.local.example`, `nvim/.config/nvim/lua/local.lua.example`
**Issue:** Neither template warns that the file is *sourced/required*: `exit` (zsh)
or `os.exit`/`vim.cmd('q!')`-style abort in the local file kills the shell/editor
startup, and anything the nvim template sets around colorschemes is currently
overwritten by the scheduled apply (WR-09). The templates are the natural place to
document both constraints.
**Fix:** Add commented guard lines, e.g. `# never use 'exit' here — this file is sourced`
and `-- NOTE: colorscheme choices here are currently overridden by init.lua's scheduled apply (see WR-09)`.

### IN-05: Fresh local files inherit umask permissions; no ownership check on source

**File:** `setup.sh:779-793`, `zsh/.zshrc:370`
**Issue:** Complements WR-12(b): even after `chmod 600` at creation, `.zshrc`
sources `~/.zshrc.local` with no world-writable/ownership sanity check — standard
dotfiles practice, but a world-writable local file means any local process can inject
code into every shell. Worth a two-line guard or an explicit accepted-risk comment.
**Fix (optional):**
```zsh
if [[ -f "$HOME/.zshrc.local" && ! -w "$HOME/.zshrc.local" ]] || [[ -O "$HOME/.zshrc.local" ]]; then ...; fi
```
or document acceptance.

### IN-06: `vim.loop` is deprecated in favor of `vim.uv`

**File:** `nvim/.config/nvim/init.lua:3`
**Issue:** `vim.loop.fs_stat` is deprecated since Nvim 0.10 (still functional). Will
eventually warn/break on newer Neovim.
**Fix:** `local uv = vim.uv or vim.loop` then `uv.fs_stat(lazypath)` for
forward/backward compatibility.

### IN-07: Uninstall leaves machine-local files with no documented policy

**File:** `setup.sh:835-937`, `README.md:140-157`
**Issue:** `run_uninstall` removes stow symlinks but never mentions
`~/.zshrc.local` / `~/.config/nvim/lua/local.lua`: they persist (arguably correct —
user data), while the nvim one can end up orphaned inside a now-unstowed real
directory or left behind in the repo tree via the WR-12 symlink effect. Neither
README's uninstall bullet nor the code states the intended policy.
**Fix:** One README sentence ("uninstall preserves machine-local files; delete them
manually for a full reset") and, if the WR-12 repo-resident case is fixed, nothing
further.

---
_Reviewed: 2026-09-17T13:25:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
