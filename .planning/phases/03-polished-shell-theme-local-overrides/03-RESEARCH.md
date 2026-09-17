# Phase 3: Polished Shell, Theme & Local Overrides - Research

**Researched:** 2026-09-17
**Domain:** Zsh interactive-shell polish (Zinit plugins, fzf history, PATH hygiene) + Neovim machine-local overrides + Bash installer bootstrap
**Confidence:** MEDIUM

## Summary

Phase 3 makes daily Zsh feel finished under tight user-locked constraints: autocomplete owns `Tab`/`^I` with async auto-show, fzf-history-search owns `Ctrl+R` on a best-effort ladder that must never break autocomplete, `typeset -U path` dedupes every PATH mutation, and machine-local overrides live HOME-only (`~/.zshrc.local`, deployed `local.lua`), gitignored and auto-created empty by `setup.sh`. There is explicitly **zero theme work** — the per-app theme spread is declared intended drift (D-13).

The single most valuable discovery for planning: `zsh/.zshrc:299` reads `zi ice joshskidmore/zsh-fzf-history-search` with **no following `zi light`** [VERIFIED: zsh/.zshrc:299-305], so the fzf-history plugin is very likely never loaded at all — the "fix fzf via zinit" ladder step may be a one-line correction, not a migration. Second: this machine runs fzf `0.44.1` where `fzf --zsh` returns `unknown option` [VERIFIED: tool run 2026-09-17], so the legacy `/usr/share/fzf/key-bindings.zsh` branch (verified present) is the *live* path here and the `≥0.48` branch cannot be smoke-tested on this host. Third: `zsh/.zsh_history` is tracked in git and unignored [VERIFIED: git ls-files 2026-09-17] — the D-12 working-tree untrack has a concrete target.

**Primary recommendation:** Plan one small plan with four independent edit sites (plugin block fix + unconditional `^R` bind, `typeset -U` top-of-file, HOME-only `.local` sourcing + gitignore + `*.example` templates, `pcall(require,"local")` + `setup.sh` empty-file bootstrap), each with reload-smoke verification, and explicitly record the three ROADMAP deltas (keep-BOTH-plugins, HOME-only, theme dropped) so the plan-checker does not flag them as scope misses.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Keep BOTH `joshskidmore/zsh-fzf-history-search` and `marlonrichert/zsh-autocomplete` with split ownership: fzf-history-search owns `Ctrl+R`, autocomplete owns `Tab`/`^I` with explicit load order and bindkeys fixed in `zsh/.zshrc:299-305`.
- **D-02:** Priority ladder is locked: (1) autocomplete must work → (2) fix fzf via zinit plugin in `zshrc` if possible → (3) fall back to system-installed fzf binary → (4) skip fzf entirely. fzf init must never be able to break autocomplete; fzf absence is tolerated.
- **D-03:** Always bind `bindkey '^R' fzf-history-widget` (user explicitly overrode conditional binding). If fzf is missing/not working, emit a warning telling the user to install fzf (no silent dead key, no silent fallback to builtin).
- **D-04:** Fixed autocomplete behavior is auto-show list: the async find-as-you-type completion list appears automatically below the prompt as you type with no keypress; `Tab` only enters menu-select. Today's broken symptom (must press `Tab` to see anything) is the bug to fix.
- **D-05:** Keep all three: `zsh-autosuggestions` (ghost text) + `fast-syntax-highlighting` + `marlonrichert/zsh-autocomplete` must coexist. Dropping autosuggestions to fix the clash is rejected. Planner/researcher must fix load/init order so async auto-show works alongside them.
- **D-06:** Put `typeset -U path` near the top of `zsh/.zshrc` so every later `export PATH` automatically dedupes.
- **D-07:** Scope covers ALL PATH mutations in `zsh/.zshrc`, including the 5 top exports (`~/.local/bin`, `~/.local/sbin`, `~/.bun/bin`, `~/.npm-global/bin`), the late `~/.local/share/zinit/polaris/bin` append (~line 232), bun completions, and uv `fpath` additions — with the constraint "make sure nothing breaks".
- **D-08:** Duplicate semantic is keep-first (zsh `typeset -U` default): existing precedence preserved, later dupes dropped.
- **D-09:** Verification is reload + smoke: repeated `source ~/.zshrc` then `echo $PATH | tr : '\n' | sort | uniq -d` is empty, PLUS `z`/`zi`, zoxide, completions, and p10k prompt still work after reload.
- **D-10:** HOME-only sourcing (user override of the ROADMAP dual-file text): only `~/.zshrc.local` in HOME is auto-sourced at the tail of `zsh/.zshrc` (after `zoxide init`, before p10k apply). No repo-side `zsh/.zshrc.local` is sourced.
- **D-11:** Nvim `lua/local.lua` loads via `pcall(require, "local")` at the very end of `init.lua`, after the `vim.schedule` colorscheme block, so machine tweaks always win.
- **D-12:** Gitignore both local files, and `setup.sh` creates both empty local files in their HOME deployed locations after setup completes, so they never enter the repo at all. Ship `*.example` templates in-repo as documentation.
- **D-13:** Zero theme work in Phase 3. Current per-app mapping (`alacritty catppuccin-mocha` vs `starship catppuccin_latte` vs `nvim tokyodark` vs p10k `catppuccin classic mocha`) is INTENDED drift — no `THEME` token, no `setup.sh apply_theme()`, no warn, no rewrite. Close THEM-01 as intentionally-drifted; planner must not "fix" it and researcher must not flag it as a bug.

### Agent's Discretion

None — every presented option was decided by the user (including two explicit overrides: HOME-only local sourcing, and full theme drop). No "You decide" selections.

### Deferred Ideas (OUT OF SCOPE)

- **History + secret purge across all branches (user-requested, NOT Phase 3 work):** full purge from all previous commits on all branches plus key rotation is SECR-02 (v2-deferred: `filter-repo`/`BFG` + force-push coordination, `sops`/`age`/`pass` + `gitleaks` hook). Do NOT attempt history rewrite in Phase 3. Working-tree untrack + gitignore of `zsh/.zsh_history` may ride with D-12. Never write secret values into planning docs or commits.
- **Debian keyd fully-automated git-build path** — carried from Phase 2.1 deferred.
- **AUTO-01/AUTO-02 backup snapshot + CI matrix** remain v2; not re-raised.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHEL-02 | Fuzzy-search history with `Ctrl+R` via fzf without conflicts (version-branch, plugin order, `^R` normalization) — reshaped autocomplete-first per D-01..D-05 | Plugin-block finding (`zi ice` w/o `light`), fzf `≥0.48` vs legacy branching, split-ownership binding pattern |
| SHEL-03 | PATH deduped and stable (`typeset -U path`, reload-empty) per D-06..D-09 | Tied `path`/`PATH` semantics, top-of-file placement, keep-first, reload+smoke verification |
| SHEL-04 | Machine-local Zsh overrides via gitignored `~/.zshrc.local` auto-sourced at tail — HOME-only per D-10 (ROADMAP dual-file text superseded) | Conditional-source guard idiom, insertion point after `zoxide init` / before p10k apply, gitignore + `*.example` pattern |
| EDIT-04 | Machine-local Neovim overrides via gitignored `lua/local.lua` (`pcall(require,"local")` at end of `init.lua`) per D-11..D-12 | `pcall(require)` no-op-when-absent pattern, post-`vim.schedule` placement, `setup.sh` empty-file bootstrap |
| THEM-01 | **CLOSED as intentionally-drifted per D-13 — no implementation.** Research records only that no `THEME` token / `apply_theme()` / warn must be added | Intended-drift declaration; planner must note delta vs ROADMAP criterion #5, not implement it |

**ROADMAP deltas the planner must note (not blindly implement ROADMAP text):** (1) criterion #1 "one history plugin policy" → superseded by D-01 keep-BOTH with split ownership; (2) criterion #3 dual `*.local` files → superseded by D-10 HOME-only; (3) criterion #5 theme token → dropped by D-13.

## Project Constraints (from AGENTS.md)

- **Shell default:** Zsh is default everywhere; Nushell is backup only — do not touch Nushell files in this phase.
- **Installer language:** Any installer change must be **Bash** in canonical `setup.sh` (`set -Eeuo pipefail`, `${1-}` guards, `--help`-wins pre-scan).
- **Machine-local:** Overrides must be gitignored and auto-sourced if present — exactly what D-10..D-12 implement.
- **Reversibility:** Removal parity expected; local-file creation must be preview-safe (no writes under `--dry-run`).
- **Safety:** No destructive writes without preview/confirmation. `git rm --cached zsh/.zsh_history` is non-destructive to working files but changes tracking — preview via `git status` and keep the working-tree history file itself untouched.
- **Atomic-docs rule (Phase 1 D-04):** Every behavior change ships with its README/AGENTS.md/in-code comment update in the same commit.
- **Locked from Phases 1/2/2.1:** Installer spine, unified single-page checklist, uninstall `yes`-guard, keyd gate, Zinit self-clone, Hyprland removal, `zsh/.zprofile` stays empty — do not re-ask or regress.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Zsh history search + autocomplete (`^R`, `^I`, auto-show) | Interactive shell (Zsh init) | — | Keybindings, widgets, and plugin load order live entirely in `zsh/.zshrc`; no backend involved |
| PATH stability across reloads | Interactive shell (Zsh init) | Installer (declares toolchain) | Dedup mechanism is shell-side (`typeset -U`); installer only guarantees the binaries exist |
| Machine-local shell overrides | Interactive shell (Zsh init) | Installer bootstrap | Sourcing guard lives in `.zshrc` tail; `setup.sh` only creates the empty HOME file once |
| Machine-local Neovim overrides | Editor (Neovim init) | Installer bootstrap | `pcall(require,"local")` lives in `init.lua`; `setup.sh` only creates the empty deployed file once |
| Theme mapping | — (no work, D-13) | — | Explicitly out of scope; no tier owns new behavior |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| zsh | 5.9 [VERIFIED: `zsh --version` 2026-09-17] | Interactive shell runtime | System shell; `typeset -U`, `bindkey`, `zle` are builtins — no dependency to add |
| Zinit (`zdharma-continuum/zinit`) | self-clone on first launch, no pin (locked Phase 2 D-12) | Zsh plugin manager | Already the repo standard; all Phase 3 plugin changes go through `zi light` |
| `marlonrichert/zsh-autocomplete` | via `zi light` (unpinned, rolling) | Async find-as-you-type auto-show list, owns `^I` | User-locked (D-01/D-04); upstream documents out-of-box auto-show + coexistence with autosuggestions/fast-syntax-highlighting [CITED: https://github.com/marlonrichert/zsh-autocomplete/blob/main/README.md] |
| `joshskidmore/zsh-fzf-history-search` | via `zi light` (unpinned, rolling) | `Ctrl+R` fuzzy history widget (`fzf-history-widget`) | User-locked (D-01); provides the exact widget D-03 binds |
| fzf (system binary) | 0.44.1 on this host [VERIFIED: `fzf --version` 2026-09-17]; already in `ALL_TOOLCHAIN` [VERIFIED: setup.sh:24] | Fuzzy finder backend for `^R` | Already a required toolchain dep; version-branch handles old/new distros |
| Neovim | 0.12.2 [VERIFIED: `nvim --version` 2026-09-17] | Editor runtime for `local.lua` override | `pcall(require, ...)` is stock Lua/Neovim — no plugin needed [CITED: https://neovim.io/doc/user/lua-guide/] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `zsh-users/zsh-autosuggestions` | via `zi light` (existing) | Ghost-text suggestion, owns `^_`/`^ ` bindings | Already loaded; keep, do not drop per D-05 |
| `zdharma-continuum/fast-syntax-highlighting` | via `zi light-mode` (existing) | Real-time syntax validation | Already loaded; keep per D-05 |
| `romkatv/powerlevel10k` + `tolkonepiu/catppuccin-powerlevel10k-themes` | existing | Prompt | Read-only context; `.local` sourcing must precede p10k apply (D-10) |
| `zoxide` | existing | `z`/`zi` navigation (D-09 smoke) | Verification target only |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `zsh-fzf-history-search` plugin | fzf's own `key-bindings.zsh` `^R` widget | Native fzf widget also binds `^R`; but user locked the zinit plugin (D-01) — do not substitute |
| `typeset -U path` | Manual `export PATH=$(dedup)` function | Hand-rolled dedup breaks on every new mutation site; `typeset -U` is a one-line shell builtin covering all sites |
| `pcall(require,"local")` | `dofile()` / `source` of absolute path | `dofile` errors when absent (breaks fresh clones); `require` resolves via `runtimepath` so stowed path just works |
| HOME-only `.local` | Repo-side `zsh/.zshrc.local` stowed + sourced | User explicitly overrode to HOME-only (D-10); repo-side file risks accidental commit of machine secrets |

**Installation:** No new packages. `fzf` is already in `ALL_TOOLCHAIN` [VERIFIED: setup.sh:24]; Zsh plugins arrive via existing Zinit self-clone. Nothing to `npm install` / `apt install` beyond what the installer already declares.

## Package Legitimacy Audit

No registry packages are installed by this phase — all artifacts are Zsh plugin git repos consumed through the existing Zinit manager (`marlonrichert/zsh-autocomplete`, `joshskidmore/zsh-fzf-history-search`, both already referenced in `zsh/.zshrc:299-305` [VERIFIED: zsh/.zshrc:299-305]) and the distro-packaged `fzf` binary already in `ALL_TOOLCHAIN`. Per the Package Legitimacy Gate, there is nothing to check: no `npm`/`pip`/`cargo` names appear in any recommendation, so no `package-legitimacy check` run is required.

**Packages removed due to SLOP verdict:** none. **Packages flagged SUS:** none.

## Architecture Patterns

### System Architecture Diagram

```text
fresh clone
    │
    ▼
bash setup.sh ──► installs toolchain (incl. fzf) ──► stow zsh/nvim ──► creates EMPTY ~/.zshrc.local
    │                                                              and deployed local.lua (DRY_RUN previews only)
    ▼
interactive zsh launch
    │
    ├─► top: typeset -U path ──► all later PATH exports auto-dedupe (keep-first)
    │
    ├─► Zinit block ──► autosuggestions ──► fast-syntax-highlighting ──► zsh-fzf-history-search ──► zsh-autocomplete (LAST)
    │        │                                                                              │
    │        │                                                        fzf version probe: ────┤
    │        │                                                        ≥0.48 → source <(fzf --zsh) / <0.48 → legacy key-bindings.zsh / absent → warn
    │        ▼
    ├─► bindkey '^R' fzf-history-widget (unconditional + warn-if-missing) ; ^I stays menu-select (autocomplete)
    │
    ├─► eval "$(zoxide init zsh)" ──► source ~/.zshrc.local (if present) ──► source ~/.p10k.zsh + apply_catppuccin
    │
    ▼
  prompt ready: auto-show completions while typing, ^R fuzzy history, clean git status
```

File-to-implementation mapping belongs in the Component Responsibilities table below, not the diagram.

### Recommended Project Structure

No new directories. Files touched or added:

```text
zsh/
├── .zshrc                 # typeset -U top; plugin-block fix; ^R bind; .local tail sourcing
└── .zshrc.local.example   # NEW template (docs only, never sourced)
nvim/.config/nvim/
├── init.lua               # append pcall(require,"local") after vim.schedule block
└── lua/
    └── local.lua.example  # NEW template (docs only, never required)
.gitignore                 # *.local + deployed local.lua + zsh/.zsh_history
setup.sh                   # post-stow: create empty HOME local files (DRY_RUN-safe)
```

### Component Responsibilities

| Edit site | Responsibility | Exact location |
|-----------|----------------|----------------|
| PATH guard | `typeset -U path` before any mutation | `zsh/.zshrc` near top, before line 36 `export PATH="$HOME/.local/bin:$PATH"` [VERIFIED: zsh/.zshrc:36-40] |
| Plugin repair | Load fzf-history-search, keep autocomplete last, fzf version-branch, `^R`/`^I` binds | `zsh/.zshrc:298-305` [VERIFIED: zsh/.zshrc:298-305] |
| Shell local override | Conditional source of HOME-only file | `zsh/.zshrc` tail after `zoxide init` (~line 54) and before `source ~/.p10k.zsh` (line 327) [VERIFIED: zsh/.zshrc:54,327] |
| Nvim local override | Best-effort load of machine tweaks | `nvim/.config/nvim/init.lua` after the `vim.schedule` colorscheme block (lines 84-87) [VERIFIED: nvim/.config/nvim/init.lua:84-87] |
| Bootstrap | Create empty HOME local files post-stow | `setup.sh` post-stow success path, after `run_stow()` (line 920+) [VERIFIED: setup.sh `run_stow()` at line 920] |

### Pattern 1: Split-ownership keybindings (D-01/D-03)

**What:** Two history/completion plugins coexist by owning disjoint keys — fzf-history-search owns `^R`, autocomplete owns `^I` — with an unconditional `bindkey '^R' fzf-history-widget` plus a warn-if-missing guard so a dead key is never silent.
**When to use:** Whenever two Zsh plugins register overlapping widgets; partition by key instead of disabling one plugin.

### Pattern 2: Degrade-ladder init (D-02)

**What:** Capability probing in strict priority order — zinit plugin → system binary → skip-with-warning — where each lower rung is strictly weaker and can never break higher rungs (fzf init guarded so failure cannot touch autocomplete widgets).
**When to use:** Optional shell enhancements (fzf, completions) that must survive minimal hosts (server mode, Termux, old distro fzf).

### Pattern 3: Silent-absent / loud-broken local overrides (D-10/D-11)

**What:** `[[ -f ~/.zshrc.local ]] && source ...` and `pcall(require, "local")` — absent file is a silent no-op (fresh clones just work); present-but-erroring file surfaces a warning. Mirrors the existing `pcall(require, ...)` + `vim.notify WARN` idiom in `lua/lang/init.lua:25` and the `[[ -f ... ]] && source ...` idiom for `.shell_aliases` at `zsh/.zshrc:24-25` [VERIFIED: zsh/.zshrc:24-25].
**When to use:** All machine-local extension points.

### Anti-Patterns to Avoid

- **"Fixing" theme drift:** Normalizing `catppuccin_latte`/`catppuccin-mocha`/`tokyodark` across apps violates D-13. If a diff shows theme files touched, the plan is wrong.
- **Repo-side `.local` files that get sourced:** Sourcing anything under the repo risks committing machine secrets; D-10 mandates HOME-only. `*.example` templates are docs, never sourced/required.
- **Conditional `^R` binding:** `if zle -l | grep -q fzf-history-widget` fallback-to-builtin hides breakage; D-03 mandates unconditional bind + warning.
- **PATH rewrite functions:** Custom dedup loops fight every future `export PATH`; `typeset -U path` is declarative and covers all sites including future ones.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| fzf shell keybindings | Custom `^R` widget reading `fc -l` through `fzf` | fzf's own integration (`source <(fzf --zsh)` ≥0.48, legacy `key-bindings.zsh` below) [CITED: https://github.com/junegunn/fzf/blob/master/README.md] | Upstream handles multi-line commands, dedup, preview, and version differences; hand-rolled widgets corrupt history entries with newlines and drop `fzf-history-widget-accept` semantics |
| PATH dedup | `dedup_path()` shell function / `awk`-filter `export` | `typeset -U path` builtin | One line, keep-first, applies retroactively to current value and automatically to every later mutation; zero maintenance |
| Optional module load (nvim) | `dofile(vim.fn.expand(...))` with existence checks | `pcall(require, "local")` | `require` uses `runtimepath` (stow-safe), `pcall` converts absent-module error into a boolean; matches the established `lang/init.lua` pattern. Absent file must be no-op, erroring file must warn — `pcall` gives both [CITED: https://neovim.io/doc/user/lua-guide/] |
| Optional file source (zsh) | Sourcing unconditionally + `|| true` | `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` | Matches existing `.shell_aliases`/`.shell_functions` guard idiom in the same file; `|| true` would still print "no such file" noise under some options |

**Key insight:** Every mechanism this phase needs already exists as a shell builtin, an upstream integration script, or an in-repo idiom — the work is wiring and ordering, not invention. Any plan task that writes a new widget, dedup function, or loader from scratch should be rewritten to use the standard piece.

## Common Pitfalls

### Pitfall 1: `zi ice` without a load command silently loads nothing

**What goes wrong:** `zsh/.zshrc:299` is a bare `zi ice joshskidmore/zsh-fzf-history-search` with no following `zi light` — the next load command (line 305, `zi light marlonrichert/zsh-autocomplete`) consumes the *autocomplete* atload ice instead, so the fzf-history plugin is most likely never installed or loaded and `fzf-history-widget` never exists [VERIFIED: zsh/.zshrc:299-305 — file read this session; zinit `ice`-attaches-to-next-load semantics tagged [ASSUMED] pending executor verification via `zle -l | grep fzf`].
**Why it happens:** In Zinit, `ice` only stages modifiers for the *next* `light`/`load`; a repo string on the `ice` line is parsed as modifiers, not as a plugin spec. It looks correct at a glance.
**How to avoid:** Give fzf-history-search its own `zi light` (with its own ice line if modifiers are needed), keep `marlonrichert/zsh-autocomplete` as the final plugin load, and verify with `zle -l | grep -c fzf-history-widget` (=1) after reload.
**Warning signs:** `bindkey '^R'` reports "no such widget"; `ls ~/.local/share/zinit/plugins | grep fzf-history` empty.

### Pitfall 2: The `≥0.48` fzf branch is untestable on old-distro hosts

**What goes wrong:** Plan verification passes locally on the legacy branch but the `source <(fzf --zsh)` branch ships untested (or vice versa on a newer machine). This host has fzf `0.44.1` where `fzf --zsh` prints `unknown option` [VERIFIED: tool run 2026-09-17], so the modern branch is dead code here.
**Why it happens:** Version-branched code doubles the test surface; the developer's machine only exercises one side.
**How to avoid:** Gate on a probe (`command -v fzf` + `fzf --version` parsed with `sort -V` against `0.48`), and verify the *probe logic* directly (e.g., feed it fake version strings) plus smoke the live branch end-to-end. Never let the probe error abort the shell — a failed probe must fall through to warn-and-continue per D-02 rung 4.
**Warning signs:** `source <(fzf --zsh)` under `setopt` errors killing interactive startup on old fzf; `sort -V` unavailable (it is coreutils — fine on Arch/Debian/Termux).

### Pitfall 3: `typeset -U path` placed too late (or expected to reorder)

**What goes wrong:** Putting `typeset -U path` at the tail dedupes only what remains (works, but reload-smoke may still show dupes introduced *before* it on first source), or expecting it to reorder entries — it never reorders, it keeps first occurrence and drops later dupes [CITED: https://zsh.sourceforge.io/Doc/Release/Parameters.html — tied `path`/`PATH` pair; keep-first from `typeset -U` unique-attribute semantics, LOW confidence, treat as verify-at-executor].
**Why it happens:** Misunderstanding that `-U` is a forward-looking array attribute, not a filter function.
**How to avoid:** Place it near the top before line 36 (D-06), then verify with *repeated* `source ~/.zshrc` + the `tr : '\n' | sort | uniq -d` empty check (D-09) — repetition is what catches ordering bugs.
**Warning signs:** First `source` clean, third `source` shows dupes (means a mutation site sits above the guard).

### Pitfall 4: `.local` sourced in the wrong position breaks prompt or overrides

**What goes wrong:** Sourcing `~/.zshrc.local` before `zoxide init` lets user overrides get clobbered by init output; sourcing after p10k apply means prompt/alias overrides never render.
**Why it happens:** `.zshrc` tail has implicit ordering constraints (zoxide position fixed, p10k instant-prompt at top + apply at tail).
**How to avoid:** Insert exactly between `eval "$(zoxide init zsh)"` (~line 54) region's tail section and `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh` (line 327) per D-10 [VERIFIED: zsh/.zshrc:54,327]. Document the ordering with a rationale comment (atomic-docs rule).
**Warning signs:** User-set `POWERLEVEL9K_*` in `.local` has no effect; `z`/`zi` aliases overridden unexpectedly.

### Pitfall 5: setup.sh writes files during `--dry-run`

**What goes wrong:** D-12 file creation (`touch ~/.zshrc.local`, deployed `local.lua`) violates the Phase 1/2 invariant that `--dry-run` never mutates the filesystem.
**Why it happens:** New code appended to the post-stow success path misses the `DRY_RUN` early-return + `[DRY RUN] Would run:` preview convention.
**How to avoid:** Follow the established `run_stow`/`install_keyd_privileged` pattern: `if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: touch ..."; return 0; fi` before any write; create files only if absent (never truncate an existing user file — use `test -f || touch`, and for `local.lua` write via the deployed `$HOME` path, never into the repo).
**Warning signs:** `bash setup.sh --dry-run` leaves new files behind; existing user `.local` content clobbered.

### Pitfall 6: Bun absolute path breaks `.local` portability story

**What goes wrong:** `zsh/.zshrc:393` sources `/home/shoyeb/.bun/_bun` — a hard-coded home directory that breaks on the "second machine" scenario SHEL-04 exists to serve [VERIFIED: zsh/.zshrc:393].
**Why it happens:** Tool installer wrote an absolute path; nobody parameterized it.
**How to avoid:** Rewrite as `$HOME/.bun/_bun` with existence guard (`[[ -s "$HOME/.bun/_bun" ]] && source ...`). Small, in-scope for "PATH is stable / second machine clean" — flag to planner as a rider on the PATH task.
**Warning signs:** Fresh user sources `.zshrc` and gets "no such file" for another username.

## Code Examples

### fzf version-branched init with warn-if-missing (SHEL-02, D-02/D-03)

```zsh
# Ladder: zinit plugin (loaded above via `zi light`) -> system binary -> warn-and-continue.
# Must never break autocomplete: probe failures fall through, never `return 1` at top level.
if command -v fzf >/dev/null 2>&1; then
  _fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
  if [[ -n "$_fzf_ver" ]] && [[ "$(printf '%s\n%s\n' "$_fzf_ver" "0.48" | sort -V | head -n1)" == "0.48" ]]; then
    source <(fzf --zsh)   # fzf >= 0.48 native integration [CITED: https://github.com/junegunn/fzf/blob/master/README.md]
  elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh   # legacy path — live branch on fzf 0.44.1 hosts [VERIFIED: ls /usr/share/fzf/ 2026-09-17]
  fi
fi
# Unconditional bind per D-03; warn (don't silently rebind) when the widget is absent.
bindkey '^R' fzf-history-widget
if ! zle -l | grep -q fzf-history-widget; then
  print -P "%F{yellow}[WARN]%f fzf history widget missing — install fzf (or check the zinit plugin) to enable Ctrl+R."
fi
```

### PATH dedup guard (SHEL-03, D-06)

```zsh
# Dedupe every PATH mutation below (keep-first): must precede the first `export PATH`.
# `path`/`PATH` are a tied array/scalar pair, so `typeset -U` on the array covers `export PATH=...` too.
typeset -U path   # [CITED: https://zsh.sourceforge.io/Doc/Release/Parameters.html]
export PATH="$HOME/.local/bin:$PATH"
# ... all existing exports unchanged, including the polaris/bin append (~line 232)
```

Verify (D-09): `for i in 1 2 3; do source ~/.zshrc; done; echo $PATH | tr : '\n' | sort | uniq -d` must print nothing; then `z --help && zi --help`, tab-completion, and p10k prompt render.

### HOME-only local sourcing (SHEL-04, D-10)

```zsh
# Machine-local overrides (HOME-only, gitignored): sourced after tool inits, before prompt apply,
# so user tweaks win without dirtying the repo. Template: zsh/.zshrc.local.example (docs only).
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```

### Neovim local override (EDIT-04, D-11)

```lua
-- Machine-local overrides (deployed local.lua, gitignored): loaded last so machine tweaks win.
-- Absent file is a silent no-op; a present-but-erroring file warns instead of breaking startup.
local ok, err = pcall(require, "local")
if not ok and not tostring(err):match("module 'local' not found") then
  vim.notify("local.lua error: " .. tostring(err), vim.log.levels.WARN)
end
```

Placed after the `vim.schedule` colorscheme block at the end of `init.lua` [VERIFIED: nvim/.config/nvim/init.lua:84-87].

### setup.sh empty-file bootstrap (D-12, DRY_RUN-safe)

```bash
# Post-stow success path only. Never truncate existing user files; never write under --dry-run.
if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: touch $HOME/.zshrc.local + deployed local.lua (if absent)"; return 0; fi
[[ -f "$HOME/.zshrc.local" ]] || touch "$HOME/.zshrc.local"
_local_lua="$HOME/.config/nvim/lua/local.lua"
[[ -f "$_local_lua" ]] || { mkdir -p "$(dirname "$_local_lua")" && touch "$_local_lua"; }
```

Note: the deployed `local.lua` path must be derived from the stow target (`$HOME`), never written into `$SCRIPT_DIR` (that would dirty the repo).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| fzf per-shell scripts (`/usr/share/fzf/key-bindings.zsh`, `completion.zsh`) | `source <(fzf --zsh)` unified integration | fzf 0.48 (2024) [CITED: https://github.com/junegunn/fzf/blob/master/README.md] | One-liner replaces two sourced files; old distros (Debian apt = 0.44.1 here) still need the legacy path — hence mandatory version-branching |
| One-history-plugin policy (disable autocomplete *or* fzf) | Split ownership (`^R` vs `^I`) with load-order fix | Locked by user D-01 (this phase) | Both capabilities survive; planner must not regress to either/or |
| Repo-side `*.local` stowed files | HOME-only `~/.zshrc.local` + deployed `local.lua`, never in repo | Locked by user D-10/D-12 (this phase) | Zero accidental-secret-commit surface; `*.example` templates carry the docs |
| `THEME` token + `apply_theme()` warn | Intended drift, no token | Locked by user D-13 (this phase) | THEM-01 closes without code; any theme normalization is a scope violation |

**Deprecated/outdated:**
- fzf `<0.48` without `key-bindings.zsh` present and without the zinit plugin: `^R` falls to warn-and-continue (rung 4) — tolerated, not an error.
- The commented-out `zicompinit; zicdreplay` finalization block (`zsh/.zshrc:314-320` [VERIFIED]) predates current Zinit behavior; executor must determine whether re-enabling is needed for auto-show or whether `zsh-autocomplete`'s own init suffices — do not blindly uncomment.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Zinit `ice` modifiers attach to the *next* `light`/`load`, so bare `zi ice <repo>` loads nothing (root cause of missing widget) | Pitfall 1 | LOW — executor verifies in one command (`zle -l \| grep fzf`); fix is identical (own `zi light`) either way |
| A2 | `typeset -U` keep-first + tied `path`/`PATH` semantics as documented upstream | Pitfall 3, Examples | LOW — D-09 reload-smoke test proves the behavior empirically regardless of docs |
| A3 | `joshskidmore/zsh-fzf-history-search` defines widget `fzf-history-widget` and binds `^R` by default (explicit re-bind is idempotent) | Standard Stack, Examples | LOW — explicit `bindkey` after load is correct whether or not the plugin pre-binds |
| A4 | `marlonrichert/zsh-autocomplete` auto-shows out-of-the-box and is compatible with autosuggestions + fast-syntax-highlighting when ordered correctly | Standard Stack | MEDIUM — if auto-show needs `zstyle` tuning, executor discovers it during smoke test; upstream README + 121-snippet Context7 doc set back the claim [CITED] |
| A5 | Debian/Ubuntu `key-bindings.zsh` path `/usr/share/fzf/key-bindings.zsh`; Arch path differs (`/usr/share/fzf/key-bindings.zsh` also on Arch; guard with `[[ -f ]]` + `find` fallback) | Examples | LOW — existence guard + zinit-plugin rung above it absorb path variance |
| A6 | `zsh/.zprofile` must stay untouched (intentionally empty, Phase 2 lock) | Constraints | LOW — no Phase 3 requirement touches login-shell behavior |

## Open Questions

1. **Should the `zsh/.zsh_history` working-tree untrack (`git rm --cached` + gitignore) ride with D-12?**
   - What we know: CONTEXT.md explicitly permits it ("may ride with D-12 since it is the same git-stays-clean theme"); file confirmed tracked and unignored [VERIFIED: git ls-files 2026-09-17]. Full history purge is deferred (SECR-02).
   - What's unclear: Whether the user wants even the working-tree step now or prefers zero history handling until the dedicated hygiene phase.
   - Recommendation: Include as a separately-verifiable task the user can veto at plan review; it is one `git rm --cached` + gitignore line + `git status` proof, fully reversible.

2. **Does auto-show need `zicompinit; zicdreplay` re-enabled or `zstyle ':autocomplete:*'` tuning?**
   - What we know: Finalization block is commented out [VERIFIED: zsh/.zshrc:314-320]; upstream sources the plugin before `compdef` with no own `compinit` [CITED].
   - What's unclear: Which of the three candidate causes (missing load, init order, missing compinit replay) produces the "must press Tab" symptom — likely observable only in an interactive shell.
   - Recommendation: Executor diagnoses live (`zle -l`, `bindkey '^I'`, reload smoke) before choosing the fix; plan the diagnosis as an explicit first task, not a presumed edit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| zsh | SHEL-02/03/04 shell changes + reload smoke | ✓ | 5.9 [VERIFIED] | — (already default shell path) |
| fzf | SHEL-02 `^R` backend | ✓ | 0.44.1 (< 0.48) [VERIFIED] | Legacy `key-bindings.zsh` [VERIFIED present] → warn-and-skip rung |
| nvim | EDIT-04 `local.lua` load | ✓ | 0.12.2 [VERIFIED] | — |
| stow | Symlink verification of new `*.example` files | ✓ | 2.3.1 (< 2.4.1) [VERIFIED] | Phase 1 auto-upgrade path already handles; note only |
| git | Untrack + gitignore verification | ✓ | (repo functional) | — |
| `sort -V` (coreutils) | fzf version probe | ✓ [ASSUMED — verify at execution] | — | String compare is wrong (`2.10` vs `0.48`); must use `sort -V` |

**Missing dependencies with no fallback:** none — all Phase 3 work is config-file edits verifiable with tools already on this host.

**Missing dependencies with fallback:** fzf `≥0.48` (modern integration branch untestable here — verify probe logic with fake versions per Pitfall 2).

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (dotfiles, no auth surface) |
| V3 Session Management | no | — |
| V4 Access Control | partial | HOME-only local files inherit `$HOME` ownership; never `sudo` for Phase 3 edits (all targets are `$HOME`/repo — no `/etc/keyd` involvement) |
| V5 Input Validation | yes (light) | Quote all paths in new shell code (`"$HOME/.zshrc.local"`); guard `setup.sh` additions with `${1-}`/`set -Eeuo pipefail` conventions; fzf version string parsed defensively (`awk '{print $1}'`, empty-check) |
| V6 Cryptography | no | — (secret-management is deferred SECR-01/02) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Machine secrets committed via sourced repo-side file | Information disclosure | HOME-only sourcing + `*.local` gitignore + `*.example` templates (D-10/D-12); never `git add -f` a `.local` file |
| Shell history (`zsh/.zsh_history`) leaking commands/tokens via git | Information disclosure | Working-tree untrack + gitignore now (rides D-12); full purge deferred to SECR-02 hygiene phase — do NOT attempt `filter-repo` here |
| Sourcing untrusted `.local` content (arbitrary code exec at shell start) | Elevation of privilege | `~/.zshrc.local` is user-owned in `$HOME` (same trust as `.zshrc` itself); document "only put your own content here" in the `*.example` template; never source repo-side or world-writable paths |

Never log or reproduce secret values (filenames only) in plans, commits, or verification output — per CONTEXT.md deferred-ideas note.

## Sources

### Primary (HIGH confidence — tool-verified this session)

- `zsh/.zshrc` lines 24-25, 36-40, 54, 232, 298-305, 314-320, 327, 330, 393 — read this session; all line-numbered claims cite these ranges
- `nvim/.config/nvim/init.lua:84-87` (`vim.schedule` colorscheme tail) and `lua/settings.lua:13` (`colorscheme = "tokyodark"`, read-only) — read this session
- `setup.sh:24` (`ALL_TOOLCHAIN` incl. `fzf`), `run_stow()` line 920 — grepped this session
- `.gitignore` (no `*.local`, no `zsh_history`) + `git ls-files` showing `zsh/.zsh_history` tracked — run this session
- `zsh 5.9`, `fzf 0.44.1` + `fzf --zsh` → `unknown option`, `/usr/share/fzf/` contents, `nvim 0.12.2`, `stow 2.3.1` — version probes run this session

### Secondary (MEDIUM confidence — Context7 curated docs)

- `/marlonrichert/zsh-autocomplete` — source-before-`compdef`, no own `compinit`, out-of-box async auto-show, coexistence with autosuggestions/fast-syntax-highlighting [CITED: https://github.com/marlonrichert/zsh-autocomplete/blob/main/README.md]
- `/junegunn/fzf` — `source <(fzf --zsh)` current integration; legacy `/shell` scripts for older versions [CITED: https://github.com/junegunn/fzf/blob/master/README.md]
- `zshparam`/`zshparam(1)` — tied `path`/`PATH` pair semantics (LOW-MEDIUM; cross-checked across zsh mailing list, Arch man pages, StackOverflow — consistent)
- Neovim `lua-guide` — `pcall(require, ...)` for fallible module load [CITED: https://neovim.io/doc/user/lua-guide/]; public-dotfiles `lua/local.lua` override pattern corroborated by multiple independent repos (LOW, web-only)

### Tertiary (LOW confidence — training knowledge, verify at execution)

- Zinit `ice`-without-`light` no-op semantics (A1); `sort -V` availability; Arch fzf legacy path; exact `zstyle` knobs if auto-show needs tuning (A4)

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — core mechanisms tool-verified locally; upstream coexistence/auto-show claims are Context7-backed, not executed here
- Architecture: HIGH — all edit sites line-verified against the actual files; nothing proposed that isn't anchored to a read line range
- Pitfalls: MEDIUM — Pitfall 1 cause is file-verified with one [ASSUMED] semantic link; Pitfalls 2/5/6 are fully verified; Pitfall 3 leans on LOW-confidence docs but D-09 smoke makes it self-proving

**Research date:** 2026-09-17
**Valid until:** ~30 days (stable domain: shell builtins, established plugins; only fzf-version drift could age the version-branch threshold — re-check if distro fzf jumps past 0.48+ behavior changes)
