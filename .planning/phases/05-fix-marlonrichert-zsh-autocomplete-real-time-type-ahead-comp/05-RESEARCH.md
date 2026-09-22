# Phase 5: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Research

**Researched:** 2026-09-22
**Domain:** Zsh interactive completion (marlonrichert/zsh-autocomplete + zsh-autosuggestions + fzf) + GNU Stow deployment containment
**Confidence:** HIGH (plugin behavior, keybindings, stow semantics); MEDIUM (auto-show root cause — open per D-34, multiple live hypotheses)

## Summary

This phase fixes deferred Phase-3 debt (SHEL-02 half: typing 2–3 chars + pause shows no completion list) plus Stow `.config` containment (STOW-01 latent fold defect), ghost-vs-Tab key ownership, and a documented keybinding priority ladder. Research was conducted per binding directive D-23: Context7 docs first for `marlonrichert/zsh-autocomplete` (2 successful `ctx7` fetches), then the installed plugin sources themselves (zsh-autocomplete @77706d4 2026-09-13, zsh-autosuggestions v0.7.1, fast-syntax-highlighting @4672ad5), then live sandbox verification of every Stow claim with the project's actual `stow 2.4.1`.

The single most important discovery is a **verified Tab-ownership break**: `fzf --zsh` (installed fzf 0.74.4) unconditionally runs `bindkey '^I' fzf-completion` at `zsh/.zshrc:327` — *after* the autocomplete `atload` block binds `^I → menu-select` (line 311–314). So the live Tab key today is fzf's wrapper, not autocomplete's binding. The fix pattern already exists in-repo: line 341 re-asserts `bindkey '^R' fzf-history-widget` after the fzf ladder; Tab needs the identical treatment. The auto-show root cause itself remains OPEN per D-34 — this report gives the planner seven testable hypotheses with live diagnostics instead of a favored theory — but every locked outcome (D-01..D-04, D-20/D-21, D-05..D-07/D-27..D-32) maps to real knobs or verified upstream defaults, so no outcome needs renegotiation. One partial exception: D-21 (prefix-only) needs a live check against the plugin's fuzzy `_complete:-fuzzy` completer entry, with a documented fallback knob.

On the Stow side, all of D-24/D-26/D-33 was verified empirically: default `stow nvim` reproduces the fold bug byte-for-byte (`~/.config -> ../repo/nvim/.config` symlink), `--no-folding` produces leaf-only links, `--no-folding -D` cleanly removes even legacy folded trees, and `--no-folding -S` against a symlinked `~/.config` aborts loudly (`existing target is not owned by stow`) instead of writing through — which is exactly the prevention-only behavior D-26 requires.

**Primary recommendation:** Fix Tab ownership by re-asserting `bindkey '^I' menu-select` after the fzf ladder (plus presetting `fzf_default_completion=menu-select`); drive the auto-show diagnosis live through the hypothesis checklist with `min-input 1` + `delay 0` as the D-01 baseline; apply `--no-folding` + `mkdir -p ~/.config` to all seven stow call sites with a new intermediate-dir non-symlink assertion in `post_verify`; evict the four untracked stray dirs from `nvim/.config/` before re-stowing; repair this machine's `~/.config` symlink by hand in the documented order.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The completion list auto-shows immediately on the first typed character — no keypress, no char-count threshold, no delay.
- **D-02:** Quiet on an empty prompt — nothing pops up until the first character is typed.
- **D-03:** Ghost autosuggestion text and the dropdown list coexist on screen simultaneously, each with its own accept key.
- **D-04:** Auto-show applies in every typing context — command names, arguments, paths, mid-word, after `sudo`.
- **Feasibility caveat (binding on researcher):** D-01..D-04 are recorded as desired outcomes, not verified plugin capabilities. The researcher MUST map each to real knobs/plugin defaults and report back the closest achievable alternative for anything not configurable.
- **D-05:** Enter on a highlighted item selects it into the buffer for further editing; a second Enter runs it. First Enter never executes.
- **D-06:** Esc keeps 100% stock vi behavior (untouched, insert→normal). Ctrl+C is the explicit list-dismiss key.
- **D-07:** Tab cycles forward / Shift-Tab cycles back inside the menu (existing `kcbt` wiring kept); arrow keys also work.
- **D-08 (SUPERSEDED in part by D-27/D-28):** Ctrl+Space/Ctrl+_ retention confirmed; Right-arrow confirmed; the `l`-drop is reversed — see D-27/D-28.
- **D-09:** On any widget clash between fzf and autocomplete, the researcher decides what stays; fzf loses by default per the Phase-3 priority ladder.
- **D-10:** fzf extras (`**` Tab fuzzy file find, Ctrl+T, Alt+C) are expendable — they may be dropped to save autocomplete. Ctrl+R history ownership is not negotiable.
- **D-11:** The Phase-3 fzf init ladder (version branch, Debian rung, warn-if-missing) is NOT frozen — researcher may rework fzf init placement/loading as part of the fix.
- **D-12:** Plugin load order is free to reorder — relaxes the Phase-3 D-01 order lock. Locked from D-01: keep all three plugins, and the Ctrl+R-vs-Tab split ownership.
- **D-13:** The user's live terminal verdict closes the phase, backed by ad-hoc commands run during verification. Zero new harness/probe files.
- **D-14:** Live regression covers shell spine (auto-show + Ctrl+R + ghost + Tab menu-select + clean reload, no errors), extended 2026-09-22: Tab never ghost-accepts (D-29), `l`/Right-arrow ghost-accept still work (D-28), Right-arrow navigates menu when open (D-32), `~/.config` is a real dir with only `nvim/` stow-linked (D-24..D-26).
- **D-15:** All non-decided vi bindings stay stock. Core motions untouchable. D-28's `l` ghost-accept is conditional existing behavior — protect it; researcher documents what provides it.
- **D-16:** Full untruncated list by default, hard cutoff at thousands-scale (researcher picks number; user judges live).
- **D-17:** Truncation always shows a visible hint — never a silent cut.
- **D-18 (EXPANDED by D-33):** Change surface per D-33. Phase-1 atomic-docs rule applies.
- **D-20:** Auto-show list shows everything EXCEPT history. History stays behind Ctrl+R fzf.
- **D-21:** Prefix-only matching — candidates must start with exactly what was typed. No fuzzy-anywhere.
- **D-19:** New plugin allowed if clean fix, but `marlonrichert/zsh-autocomplete` stays the engine. Engine swap only if researcher proves unfixable.
- **D-23:** Researcher consults Context7 first, then GitHub CLI only if needed.
- **D-34:** Auto-show failure is NOT presumed a keybind issue. Researcher explores ALL possibilities with no favored hypothesis. Planner has complete freedom bounded only by locked OUTCOMES.
- **D-24:** Fold prevention = BOTH `--no-folding` on all stows (install AND uninstall) + `mkdir -p "$HOME/.config"` guard. Reversible.
- **D-25:** Evict `opencode/`, `lazygit/`, `context7/` (plus observed `gh/`) from `nvim/.config/` to real `~/.config/` locations; delete from repo tree; never stow them; nvim package keeps ONLY `.config/nvim/`. Reversible.
- **D-26:** Broken `~/.config` symlink repaired BY HAND by executor (break symlink → mkdir → move siblings → re-stow with D-24 guards → verify). Installer NEVER auto-repairs, then or ever. Preview each step per Safety constraint.
- **D-27:** Ghost-accept keys after fix: Right-arrow + `l` in vi-normal + Ctrl+Space (accept) / Ctrl+_ (execute). Tab is never ghost-accept.
- **D-28:** `l` and Right-arrow ghost-accept already work — preserve, do not rebuild; verify in regression; researcher documents WHAT provides them.
- **D-29:** Actively unbind Tab from autosuggest-accept. Researcher traces the Tab-accepts-ghost hijack, removes it, Tab always resolves to `menu-select`. Verified live.
- **D-30:** Ladder, highest first: autocomplete (Tab/menu) > autosuggestions (ghost-accept) > fzf (Ctrl+R + extras) > stock vi/zle. New clashes resolve downward.
- **D-31:** Ladder ships as comment block at top of `zsh/.zshrc` plugin section PLUS key-ownership table in `README.md` Zsh section (atomic-docs).
- **D-32:** With ghost + menu both visible, Right-arrow navigates the menu (menuselect wins, autocomplete-first). Ghost-accept via Right-arrow only when menu closed.
- **D-33:** Full surface: `zsh/.zshrc` (fix + ladder comment) + `setup.sh` (all-stow `--no-folding`, mkdir guard, post_verify link-shape adjustment, uninstall parity, prevention-only rule) + README/docs/comments + nvim tree eviction + executor one-time live `$HOME` repair (hand-executed, never installer code).

### Agent's Discretion

- D-09 clash resolution (fzf loses by default).
- D-22 result ordering (researcher picks from upstream defaults; user judges live).
- D-16 threshold number (researcher picks; user judges live).
- Exact widgets/keys implementation for D-27..D-29 as long as end-state matches.
- Post-verify adjustments for `--no-folding` under D-33.
- Planner has complete freedom on fix approach per D-34.

### Deferred Ideas (OUT OF SCOPE)

None — stow containment was pulled INTO this phase; ghost/ladder work is keybinding-ownership clarification. Phase-4 `--self-test` harness integration is not this phase's work (D-13).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHEL-02 | Fuzzy history without conflicts; `bindkey '^R'` normalized; plugin-order fix (Ctrl+R half live-passed in Phase 3) | fzf `^I` rebind finding (§Architecture Patterns, Pitfall 1); `^R` ownership intact — fzf binds `^R` in emacs/vicmd/viins and line 341 re-asserts it; Tab re-assert mirrors that pattern; auto-show hypothesis checklist |
| STOW-01 | Stow packages correctly symlinked from repo root with preview + `test -L`/`readlink -f` post-verify | Sandbox-verified `--no-folding` semantics on all 7 call sites; intermediate-dir non-symlink assertion design; uninstall `-D` parity verified incl. legacy folded trees; hand-repair runbook |

## Project Constraints (from AGENTS.md)

- **Shell default:** Zsh everywhere; Nushell backup only — no Nushell-side changes in this phase.
- **Installer language:** Unified installer is Bash — all `setup.sh` edits follow `set -Eeuo pipefail`, `${1-}` guards, `--help`-wins pre-scan.
- **Scope filter:** No Nushell-only fixes.
- **OS support:** `ID_LIKE` + manager probing (this machine: `ID=archarm`, `ID_LIKE=arch` [VERIFIED: /etc/os-release]) — plus upstream `skip_global_compinit=1` needed for Ubuntu-family (new finding, §Pitfalls).
- **Machine-local:** Gitignored overrides; repair moves preserve data, never delete.
- **Reversibility:** Every surface independently revertable (bindkey lines, stow flags, sibling moves of untracked dirs).
- **Safety:** No destructive writes without preview/confirmation — binds the D-26 hand-repair (each step has a preview command) and all `setup.sh` edits (DRY_RUN echo strings must be updated to show `--no-folding`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Async completion list render | Zsh line editor (ZLE hooks) | — | `line-pre-redraw` hook → zasync pty worker → `zle -R`; all inside the interactive shell process |
| Ghost autosuggestion text | ZLE (`POSTDISPLAY`) | — | zsh-autosuggestions renders via `POSTDISPLAY` highlight; coexists with list by design |
| Tab/menu key ownership | ZLE keymaps (`viins`/`menuselect`) | — | `bindkey` layering order is the entire D-29/D-30 problem |
| fzf history search (Ctrl+R) | External binary + ZLE widgets | — | fzf 0.74.4 owns `^R` in all three keymaps; must not own `^I` |
| Stow symlink deployment | Installer (Bash) + GNU Stow | Filesystem | Link shapes decided by stow flags; verified in sandbox, not by reading docs |
| Live `~/.config` repair | Executor hands (one-time) | — | Installer is explicitly forbidden from repairing (D-26) |

## Standard Stack

### Core (no new packages — all changes are config)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `marlonrichert/zsh-autocomplete` | main @77706d4 (2026-09-13) [VERIFIED: plugin git log] | Real-time type-ahead list engine (locked per D-19) | Upstream plugin; async pty architecture; zstyle-configurable |
| `zsh-users/zsh-autosuggestions` | v0.7.1 [VERIFIED: VERSION file] | Ghost `POSTDISPLAY` text + accept keys | Fish-like suggestions; defaults already provide Right-arrow/`l` accept (D-28) |
| `zdharma-continuum/fast-syntax-highlighting` | @4672ad5 (2026-08-31) [VERIFIED: plugin git log] | Real-time syntax validation | Plugin ships an explicit `#549` workaround inside autocomplete's async path — known coexistence point |
| GNU Stow | 2.4.1 [VERIFIED: `stow --version`] | Symlink deployment | `--no-folding` verified working despite absence from `--help` text |
| fzf (system binary) | 0.74.4 [VERIFIED: `fzf --version`] | Ctrl+R history + `**` extras | ≥0.48 → native `fzf --zsh` rung; the same integration rebinds Tab (must be contained) |
| zsh | 5.9.2 [VERIFIED: `zsh --version`] | Interactive shell | Within plugin's tested range (5.8+); 5.9-family `max()` workaround code paths apply |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `marlonrichert/zasync` | auto-cloned to `~/.cache/zsh/zasync` [VERIFIED: dir exists] | Async worker backend for autocomplete | Already present; first-run clone needs network+git (fresh-clone failure mode, §Pitfalls) |
| `joshskidmore/zsh-fzf-history-search` | installed | Owns Ctrl+R widget | Keep; `^R` re-assert at zshrc:341 already contains it |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Re-assert `^I menu-select` after fzf ladder | Move fzf ladder before plugin block | Moving changes what fzf captures as `fzf_default_completion` (would capture pre-autocomplete binding — worse fallback). Keep position, re-assert after. |
| `--no-folding` on every stow | Per-package flag only on nvim | D-24 mandates all stows; flag is harmless on already-unfoldable packages and uniform flags prevent regression. |
| New completion engine (per D-19 allowance) | — | NOT justified: every locked outcome maps to knobs/defaults; engine stays. |

**Installation:** none — zero new packages. (`zasync` self-provisions at first prompt via `git clone --depth 1 https://github.com/marlonrichert/zasync.git` [VERIFIED: Functions/Init/.autocomplete__async:18-25] — supply-chain note, not an install step.)

**Version verification:** `zsh 5.9.2`, `fzf 0.74.4`, `stow 2.4.1` all confirmed live on this machine (commands run 2026-09-22). `ctx7` library resolution confirmed `/marlonrichert/zsh-autocomplete` (77.53 benchmark, High reputation) and `/zsh-users/zsh-autosuggestions` (85.76, High).

## Package Legitimacy Audit

No external packages are installed by this phase — all edits are to `zsh/.zshrc`, `setup.sh`, `README.md`, and untracked-dir moves. Audit table N/A by design.

**Supply-chain note for planner:** autocomplete auto-clones `marlonrichert/zasync` from GitHub on first prompt if `zasync` is not already autoloadable (pinned to no commit — `--depth 1` of default branch, with `pull --ff-only` refresh). Present on this machine, so no action here; on fresh clones the first prompt requires network+git or the async list silently never starts (Hypothesis H-2). No `postinstall`-style risk (zsh plugin, no npm). No action beyond documenting the offline first-run behavior.

## Architecture Patterns

### System Architecture Diagram

```text
Every keystroke (viins)
        │
        ▼
zle line-pre-redraw hook chain
  (.autocomplete:async:complete  ← registered at first precmd)
        │
        ├── KEYS_QUEUED_COUNT/PENDING? ──yes──▶ return (still typing)
        ├── LASTWIDGET in ignore set? ──yes──▶ return
        └── otherwise ──▶ zasync wait (delay, default 0.05s)
                                │
                                ▼
                    zasync complete (pty worker:
                    LBUFFER/RBUFFER → _main_complete
                    in isolated pty, timeout default 1s)
                                │
                                ▼
              .autocomplete:async:complete:callback
               computes list_lines → zle ._list_choices
               → zle -R (redraw w/ list below prompt)
               + autosuggest POSTDISPLAY ghost (independent path)

Tab key ownership chain (load order = layering):
  zshrc:65  bindkey -v            (main aliases viins)
  plugin load  main[^I]=complete-word, menuselect populated
  zshrc:311  atload: ^I→menu-select (viins), kcbt→reverse-menu-complete
  zshrc:327  source <(fzf --zsh): ^I→fzf-completion  ← CLOBBERS atload
  FIX:       re-assert ^I→menu-select AFTER ladder (+ preset
             fzf_default_completion=menu-select BEFORE source)

Stow shapes (target $HOME, package nvim):
  folded (bug):    ~/.config ──symlink──▶ repo/nvim/.config
  unfolded (fix):  ~/.config/ (real) ──▶ nvim/ (real) ──▶ *.lua symlinks
```

### Recommended Project Structure

No new files except one: `zsh/.zshenv` (Ubuntu `skip_global_compinit=1` per upstream README — §Pitfalls). All other changes are in-place edits:

```text
zsh/.zshrc            # ladder comment (~line 283) + zstyle knobs + Tab re-assert
zsh/.zshenv           # NEW: skip_global_compinit=1 (Ubuntu-family correctness)
setup.sh              # --no-folding ×7 call sites + mkdir guard + post_verify assert
README.md             # key-ownership table (Zsh section) + stow command updates
nvim/.config/         # evict opencode/ lazygit/ context7/ gh/ (mv to ~/.config/)
$HOME                 # hand repair (executor, never installer)
```

### Pattern 1: fzf-ladder re-assert (the line-341 precedent)

**What:** Any key fzf's integration binds must be explicitly re-bound after `source <(fzf --zsh)` if the phase owns it. `^R` already follows this pattern (zshrc:341–342); `^I` must join it.
**When to use:** For every owned key (Tab now; any future fzf-bound key later).
**Example:**

```zsh
# fzf captures the prior ^I binding into $fzf_default_completion and falls back
# to it; presetting keeps the **-fallback on menu-select even if order shifts.
# [VERIFIED: /tmp/fzf-zsh-integration.zsh:667-675 from fzf 0.74.4]
fzf_default_completion=menu-select
source <(fzf --zsh) 2>/dev/null || true
# ...existing version-branched ladder unchanged...
# Autocomplete-first (D-30): re-assert AFTER fzf — fzf unconditionally binds ^I.
bindkey '^I' menu-select            # Tab enters menu, never ghost-accepts (D-29)
bindkey '^R' fzf-history-widget     # existing line 341, unchanged owner
```

### Pattern 2: zstyle knobs are read dynamically — keybindings are load-ordered

**What:** `:autocomplete:*` styles (`min-input`, `delay`, `list-lines`, `ignored-input`) are read with `zstyle -s` at event time (each keystroke worker), so they can live anywhere before first use; `bindkey` lines must come after plugin load (atload or later) AND after the fzf ladder for clobbered keys. Upstream: keybindings customized "after loading Autocomplete" [CITED: CONFIGURATION.md#keybindings].
**When to use:** Place the D-01/D-16 zstyle block just above the plugin section (visible, grouped); place owned `bindkey`s after the fzf ladder.

### Pattern 3: Stow prevention = flag on every invocation + guard + loud verify

**What:** `mkdir -p "$HOME/.config"` before any stow run; `--no-folding` on every `stow` invocation (install, preview-parity echoes, uninstall `-D`, privileged keyd `-t /`); `post_verify` gains an intermediate-dir non-symlink assertion so a fold fails loudly instead of passing silently (today's `assert_linked` passes folded trees because `readlink -f` resolves through the dir symlink).
**When to use:** All `setup.sh` stow paths; uninstall uses `--no-folding -D` which also cleanly removes legacy folded links [VERIFIED: sandbox lab2].

### Anti-Patterns to Avoid

- **Uncommenting the `zicompinit`/`zicdreplay` finalize block (zshrc:353–359) "to fix" completion:** upstream requires *removing* compinit calls — autocomplete runs compinit itself at first precmd (`compinit() { : }` no-op guard after) [VERIFIED: Functions/Init/.autocomplete__compinit:42-63]. An eager `zicompinit` double-initializes against the plugin's dump handling. Replace the commented block with a short comment explaining why it stays out.
- **Adding the CONFIGURATION.md "arrows always move cursor" override:** would break D-32 (Right-arrow must navigate the open menu — already the upstream default).
- **Adding the "Enter always submits" override:** would break D-05 (first Enter must select-into-buffer, never execute).
- **Setting `ZSH_AUTOSUGGEST_STRATEGY` to include `completion`:** its setup runs `bindkey '^I' autosuggest-capture-completion` [VERIFIED: src/strategies/completion.zsh:69] — the one in-repo-adjacent Tab-hijack vector. Strategy stays default `(history)`.
- **Overriding `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS`:** would clobber the D-28 `forward-char`/`vi-forward-char` defaults. Never set it.
- **Installer detecting/repairing a symlinked `~/.config`:** explicitly forbidden (D-26). Detection (loud abort via stow's own conflict error + post_verify assert) is allowed; repair is executor-only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async list timing/dedup | Custom debounce widget or `zle -R` loop | `zstyle ':autocomplete:*' delay/min-input/timeout/cooldown` | pty worker, timeout accounting, retry-cooldown, and same-state dedup already implemented (679-line async module) |
| Truncation hint | Custom "(more)" marker widget | Upstream `(MORE)` marker (automatic on partial lists) [VERIFIED: .autocomplete__async:426-429] | Rendered via `compadd -J -last- -x '%F{0}%K{12}(MORE)%f%k'`; satisfies D-17 with zero code |
| History exclusion | Custom completer filter | Default context (no `default-context` style set) | History enters the list only via toggle contexts (`^R`/`/`) or opt-in `default-context history-incremental-search-backward` [VERIFIED: .autocomplete__async:449-481 + CONFIGURATION.md:14-19] |
| Menu navigation keys | Custom menuselect binds | Upstream menuselect defaults (Tab/Shift-Tab cycle, arrows move) [VERIFIED: key-bindings:41-50, README table] | Any override risks D-07/D-32 regressions |
| Fold-safe symlinking | Custom `ln -sf` loop | `stow --no-folding` + `mkdir -p` guard | Stow 2.4.1 handles leaf linking, conflict detection, and `-D` parity; custom loops mishandle `-t /` and adopt paths (REQUIREMENTS Out-of-Scope row) |
| Completion-system init | Eager `compinit`/`zicompinit` calls | Autocomplete's first-precmd compinit (with `':autocomplete::compinit' arguments` passthrough if ever needed) | Upstream README: "Remove any calls to compinit" [CITED] |

**Key insight:** Every locked outcome except the open root cause is already a default or a one-line zstyle/bindkey. The phase is burn-down of layering mistakes (fzf Tab clobber), not new machinery — the planner should frame tasks as "re-assert + verify live," with the hypothesis checklist as the only investigative work.

## D-01..D-04 Feasibility Map (binding caveat answered)

| Decision | Verdict | Real knob / default |
|----------|---------|---------------------|
| D-01 auto-show on first char, no delay | ACHIEVABLE | `zstyle ':autocomplete:*' min-input 1` (= current default: worker uses `min_input=1` when no toggle context [VERIFIED: .autocomplete__async:382-390]) + `zstyle ':autocomplete:*' delay 0` (default 0.05 [CITED: CONFIGURATION.md:80-85]). Baseline for live test. |
| D-02 quiet on empty prompt | DEFAULT, no config needed | Empty word (length 0 < min-input 1) suppresses the list in `.autocomplete:async:sufficient-input` [VERIFIED]. Note: this covers auto-show; pressing Tab on an empty prompt hits fzf's `expand-or-complete` branch (fzf line 603–607) — out of D-02 scope but planner should know. |
| D-03 ghost + list coexist | DEFAULT, no config needed | Independent render paths (POSTDISPLAY vs `zle -R` list); plugin's main:precmd explicitly orders itself before Autosuggest ("so we don't overwrite its default ignore list") [VERIFIED: .autocomplete__main:38-39]. |
| D-04 every context (commands, args, paths, mid-word, sudo) | EXPECTED from defaults, VERIFY LIVE | Normal `_complete` covers commands/args/paths; `sudo` via stock `_sudo`; mid-word relies on `_complete` internals. Fallback if any context fails live: `setopt completeinword` (global, cheap) — flag as behavior-changing for Tab too, so prefer per-failure diagnosis over preemptive setopt. |
| D-20 no history in list | DEFAULT, no config needed | History completions only under `*history-*`/`recent-paths` toggle contexts; default `curcontext` is empty → plain completion path [VERIFIED: .autocomplete__async:449-481]. Do NOT set `default-context`. |
| D-21 prefix-only | LIKELY default, MUST VERIFY LIVE (open question) | Upstream default `matcher-list 'm:{[:lower:]-}={[:upper:]_} r:|[.]=**'` is prefix + case-fold [VERIFIED: .autocomplete__config:30-31], BUT the default `completer` chain includes `_complete:-fuzzy` whose matcher adds `l:|=*` substring matching [VERIFIED: .autocomplete__config:13-14, 32-35]. Whether the auto-show path surfaces fuzzy matches needs a live probe (`git ch` → only prefix hits?). Fallback knob (only if live fails): narrow the completer chain or matcher-list back to prefix-only. |
| D-16 thousands-scale cutoff | ACHIEVABLE via `list-lines` | Upstream caps real-time listings at `list-lines` (default 16) AND screen-fit `min(list-lines, LINES-BUFFERLINES-1)`, with automatic `(MORE)` partial marker [VERIFIED: CONFIGURATION.md:141-160; .autocomplete__async:442-447]. **Researcher pick: `zstyle -e ':autocomplete:*:*' list-lines 'reply=( 300 )'`** — rationale: "full list" is physically bounded by screen-fit anyway (~20–40 visible lines + `(MORE)`), so the number only matters on tall terminals; 300 is safely above any screen while bounding render cost three orders below the thousands-scale lag regime; generation cost stays capped by `timeout 1` + `cooldown 10` defaults. User judges live per discretion. |
| D-17 truncation hint | DEFAULT, no config needed | `(MORE)` marker automatic on partial lists [VERIFIED]. Planner may restyle text only. |
| D-22 result ordering | KEEP UPSTREAM DEFAULT | Upstream `group-order`: `expansions all-expansions options remotes hosts recent-branches heads-local commits commit-tags executables suffix-aliases reserved-words aliases functions builtins commands local-directories directories` [VERIFIED: .autocomplete__config:128-133]. Only override is the documented `group-order` zstyle if the user dislikes the feel live. |

## D-28 Provider Trace (what supplies `l` / Right-arrow ghost-accept today)

Upstream plugin defaults — **zero local config involved**. Verbatim defaults from `src/config.zsh:45-54` [VERIFIED]:

```zsh
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
    forward-char
    end-of-line
    vi-forward-char
    vi-end-of-line
    vi-add-eol
)
```

- **Right-arrow** in insert mode = stock `forward-char` → full ghost-accept by default.
- **`l`** in vi-normal mode = stock `vi-forward-char` → full ghost-accept by default.
- Our `zsh/.zshrc` binds only `^_` (execute) and `^ ` (accept) for autosuggest (lines 293–295) and never touches `forward-char`/`vi-forward-char` or `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS` (grep-verified this session). Fix must not rebind those two widgets and must never set `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS`.

## D-29 Hijack Trace (why Tab misbehaves with ghost visible)

Verified chain (strongest evidence first):

1. **fzf rebind (VERIFIED, primary):** `fzf --zsh` from installed fzf 0.74.4 ends with `binding=$(bindkey '^I')` capture + unconditional `bindkey '^I' fzf-completion` [VERIFIED: generated integration lines 667–675]. Sourced at zshrc:327, after the atload `^I → menu-select`. Fallback without `**` trigger runs `zle ${fzf_default_completion:-expand-or-complete}` (the captured `menu-select`), EXCEPT on empty buffers where it hardcodes `expand-or-complete` (lines 603–607). Net: live Tab is fzf's wrapper, and the empty-prompt Tab path genuinely diverges from menu-select.
2. **Autosuggest self-bind (VERIFIED absent):** the only autosuggest code that binds Tab is `_zsh_autosuggest_capture_setup` (`bindkey '^I' autosuggest-capture-completion`) [VERIFIED: src/strategies/completion.zsh:69], reachable only when `ZSH_AUTOSUGGEST_STRATEGY` includes `completion`. Default strategy is `(history)` [VERIFIED: src/config.zsh:18-21] and `zsh/.zshrc` never overrides it (grep-verified). So autosuggestions is NOT the hijacker under current config — the "remove Tab from ghost-accept" prescription is still correct as hardening (plus it guards future strategy changes), implemented as: keep strategy at default AND ensure final `^I` ownership is menu-select (which structurally cannot ghost-accept).
3. **Perception hypothesis [ASSUMED]:** with the list failing to auto-show, Tab → (fzf wrapper →) `menu-select` inserts the top completion, which usually coincides with the ghost text — indistinguishable from ghost-accept by feel. The D-29 live check (Tab with ghost visible must open/navigate the menu, never insert) adjudicates this.

**Prescription:** preset `fzf_default_completion=menu-select` before the fzf source + explicit `bindkey '^I' menu-select` after the ladder (Pattern 1). No autosuggest-side unbind is needed beyond never adopting the `completion` strategy.

## Key-Binding State Reference (planner's ground truth)

Upstream autocomplete defaults that satisfy locked outcomes with no local code (all [VERIFIED] this session):

| Key | Context | Default behavior | Locked decision |
|-----|---------|------------------|-----------------|
| Tab / Shift-Tab | menu open | next/previous item (`menuselect`: `\t→menu-complete`, `kcbt→reverse-menu-complete`) | D-07 ✓ (zshrc menuselect kcbt line is redundant-but-harmless; recommend dropping) |
| ← → ↑ ↓ | menu open | move selection (menuselect) | D-07/D-32 ✓ — never add the "arrows move cursor" override |
| Enter | menu open | exit menu / select into buffer ("Stop text search or exit menu") | D-05 ✓ by default; verify second-Enter runs |
| Ctrl+C / Ctrl+G | menu open | exit menu, undo added items | D-06 ✓ by default |
| Esc | anywhere | untouched by plugin | D-06 ✓ (nothing binds it) |
| Ctrl+Space (`^@`) | menu open | `accept-and-hold` (add another item) | D-30 (autocomplete-first in menu) — document, not a clash |
| Ctrl+Space (`^ `) | menu closed | `autosuggest-accept` (local atinit) | D-27 ✓ keep |
| Ctrl+_ | menu closed | `autosuggest-execute` (local atinit) | D-27 ✓ keep; in-menu `^_` = undo (autocomplete-first, document) |
| Ctrl+R | anywhere | plugin default `history-incremental-search-backward`, overridden by fzf per split ownership | Phase-3 lock; line 341 re-assert stands |

Ordering invariants the planner must preserve: p10k instant prompt stays at top; `bindkey -v` stays before plugin loads (else `main`-keymap binds land in emacs, per README §keyboard-shortcuts); tail `path=( $path )` stays last; `.zshrc.local` sourcing stays after tool inits / before p10k apply.

## Auto-Show Hypotheses (D-34 — no favored theory; diagnose live)

All consistent with "Tab works, typing shows nothing" (Tab path is synchronous `_main_complete`; auto-show path is the async `line-pre-redraw → zasync` pipeline):

- **H-1 fzf/ladder interference:** `source <(fzf --zsh)` redefines completion-adjacent widgets after autocomplete loads. Diagnostic: `bindkey '^I'` before/after; temporarily comment the fzf ladder, `exec zsh`, type 2 chars + pause.
- **H-2 zasync backend failure:** first prompt clones `marlonrichert/zasync` (network+git). Present here (`~/.cache/zsh/zasync` ✓) but fresh clones / offline shells lose the entire async path silently while Tab keeps working. Diagnostic: `ls ~/.cache/zsh/zasync`; watch first-prompt errors; check `~/.local/state/zsh-autocomplete/log/$(date +%F).log`.
- **H-3 fast-syntax-highlighting widget conflict:** plugin carries an explicit `#549` FSH workaround in the async path [VERIFIED: .autocomplete__async:133-135] and a hook-rebind workaround at first precmd [VERIFIED: .autocomplete__main:53-64]. Diagnostic: unload FSH temporarily, retest; note FSH @4672ad5 is newer than the workaround — version skew cuts both ways.
- **H-4 OMZ snippet / compinit ordering:** no eager `compinit` exists today (OMZL::completion.zsh has none — grep-verified; only `bashcompinit`), so autocomplete's first-precmd compinit owns init, matching upstream's "remove any calls to compinit" [CITED: README]. Diagnostic: `exec zsh` watching for `compdef: command not found` (OMZP pip/terraform snippets load before autocomplete); confirm `_comp_setup` is set after first prompt.
- **H-5 `line-pre-redraw` hook chain broken:** the async trigger is `add-zle-hook-widget line-pre-redraw .autocomplete:async:complete` [VERIFIED: .autocomplete__async:49]. p10k instant prompt, FSH, or autosuggest wrapping could swallow it. Diagnostic: after first prompt, `zle -l | grep -i autocomplete`; `print $line_pre_redraw_functions` (or azhw equivalents); check `_autocomplete__log`.
- **H-6 still-typing gate misfiring:** worker is skipped while `KEYS_QUEUED_COUNT || PENDING` [VERIFIED: .autocomplete__async:94-95] and after `delay` (0.05) + `timeout` (1.0, `cooldown` 10 after timeouts). On slow/loaded machines every keystroke re-arms the gate and the list never renders; repeated timeouts then suppress retries for 10s. Diagnostic: raise `timeout`, lower `delay 0`, watch the log during the pause.
- **H-7 Ubuntu global compinit (non-Arch only):** Ubuntu's `/etc/zsh/zshrc` runs system compinit unless `skip_global_compinit=1` is set in `.zshenv` [CITED: upstream README]. This repo has no `.zshenv`. Harmless on Arch (no global compinit — `/etc/zsh/` holds only `zprofile`, verified), but Ubuntu-family machines get double init. Prescription: add `zsh/.zshenv` with `skip_global_compinit=1` + comment (new stow file, auto-deploys as `~/.zshenv`).

Ad-hoc live probes for the D-14 regression (no files, per D-13): `bindkey '^I' '^R'` state dump; `zstyle -L ':autocomplete:*'`; type-pause-observe in command/arg/path/`sudo`/mid-word contexts; Tab-with-ghost-must-open-menu; `l`/Right-arrow accept; Right-arrow-in-menu navigates; Ctrl+C dismisses; Enter-selects-then-runs; `source ~/.zshrc` twice + `echo $PATH | tr : '\n' | sort | uniq -d` empty; `ls -la ~/.config` (real dir) + `readlink ~/.config/nvim`.

## Stow Findings (all sandbox-verified on stow 2.4.1, 2026-09-22)

1. **Bug reproduced:** empty target + `stow nvim` → folded `~/.config -> ../repo/nvim/.config` symlink (lab2). This is the exact live breakage (`/home/shoyeb/.config -> dotfiles/nvim/.config`, created same instant as the `~/.zshrc` link per CONTEXT).
2. **`--no-folding` accepted** despite missing from `stow --help` text; produces real dirs + leaf symlinks only (lab1).
3. **Uninstall parity:** `stow --no-folding -D nvim` on a legacy FOLDED tree removes the folded link cleanly (lab2) — so `-R --no-folding` migrates folded→unfolded in one step. Unstow leaves now-empty dirs behind (cosmetic; no `rmdir` needed).
4. **Prevention-only proven:** `--no-folding -S` with symlinked `~/.config` aborts with `existing target is not owned by stow: .config`, rc=1, zero writes (lab3). `mkdir -p` passes through harmlessly (dir exists via link) but stow still refuses — detection without repair, exactly D-26.
5. **Post-repair shape:** real `~/.config` with sibling dirs + `--no-folding -S nvim` links only `nvim/*.lua` leaves, siblings untouched (lab4).

### All stow call sites needing `--no-folding` (grep-verified in `setup.sh`)

| Site | Lines | Change |
|------|-------|--------|
| keyd privileged preview (`--no --verbose`) | 420–422 | add `--no-folding` for honest preview |
| keyd DRY_RUN echo | 433 | echo string gains `--no-folding` |
| per-pkg DRY_RUN echo + preview | 437–438 | echo + live preview command gain flag |
| keyd install preview | 564–566 | add flag |
| keyd install DRY_RUN echo | 580 | echo string gains flag |
| keyd live `sudo stow [--adopt] -t /` | 635, 637 | add flag (harmless under `-t /`, uniform per D-24) |
| `run_stow` live `--restow` | 949–950 | add flag + `mkdir -p "$HOME/.config"` guard before loop |
| uninstall DRY_RUN echoes + previews | 842–844, 855 | echo strings + preview gain flag |
| uninstall live `-D` (+ keyd `-D -t /`) | 904, 911 | add flag |
| README manual stow one-liners | 89–101, 110–113 | append `--no-folding` (atomic-docs) |

### post_verify adjustment (D-33 researcher pick)

Per-file `readlink -f` prefix checks pass UNCHANGED under `--no-folding` (same file set, different link shapes — verified by reasoning over `assert_linked`, setup.sh:493-504). The required addition is a **fold detector**: for each verified `rel`, walk its intermediate dir components; require `$HOME/<prefix>` to be a real directory and NOT a symlink. Minimal targeted form: when any selected package contains `.config/...` paths, assert `[[ ! -L $HOME/.config ]]` with a D-26 pointer message ("hand-repair required — installer will not fix this automatically"). Without this, post_verify keeps passing folded trees silently — the exact latent STOW-01 defect.

`quarantine_scan` needs no logic change (ownership test is shape-agnostic; verified safe against the folded state — stow-owned paths skip, strays aren't in any package after D-25). `ensure_local_files` ordering: mkdir guard must precede `run_stow`, and DRY_RUN must echo it.

### D-25 eviction facts

`git status --short` shows all four as untracked (`?? nvim/.config/{context7,gh,lazygit,opencode}/`) [VERIFIED] and `git ls-files nvim/.config/` lists only `nvim/...` paths — so eviction is plain `mv` (no `git rm`), zero git-history impact. Order matters: move strays OUT of the package BEFORE re-stowing (else `--no-folding` leaf-links every stray file into `~/.config/` as stow-owned links). `opencode/` is ~80MB per CONTEXT — preview with `du -sh` first. Destinations are the same `~/.config/<name>` paths users already see through the fold (move, never copy-delete, never delete).

### D-26 hand-repair runbook (executor, preview-each-step)

1. Preview: `ls -la ~/ | grep -E 'config|zshrc'; readlink ~/.config ~/.zshrc; ls ~/.config/` (expect `nvim opencode lazygit context7 gh` through the link).
2. Size preview: `du -sh ~/dotfiles/nvim/.config/*/`.
3. Break symlink ONLY: `rm ~/.config` (removes the link; content lives in repo — re-verify with `ls ~/dotfiles/nvim/.config/` after).
4. `mkdir -p ~/.config`.
5. Move strays: `mv ~/dotfiles/nvim/.config/{opencode,lazygit,context7,gh} ~/.config/` (one per line, verify each landing).
6. `git -C ~/dotfiles status --short` — strays gone, tree clean.
7. Re-stow: `stow --dir=~/dotfiles --target="$HOME" --no-folding --restow nvim` (extend to full selection per installer later).
8. Verify: `[[ ! -L ~/.config ]] && readlink ~/.config/nvim && ls ~/.config/` — real dir, `nvim` link → `.../nvim/.config/nvim`, siblings real dirs. `~/.zshrc -> dotfiles/zsh/.zshrc` file link is unaffected (top-level file, no folding involved).

## Common Pitfalls

### Pitfall 1: fzf --zsh steals Tab AFTER autocomplete binds it (VERIFIED present)

**What goes wrong:** Live `^I` = `fzf-completion`, not `menu-select`; empty-prompt Tab runs `expand-or-complete` instead of menu behavior.
**Why it happens:** Load order — fzf sourced at zshrc:327, after atload binds at 311–313; fzf 0.74.4 unconditionally binds `^I` (integration lines 667–675).
**How to avoid:** Preset `fzf_default_completion=menu-select` + re-assert `bindkey '^I' menu-select` after the ladder (Pattern 1). Never "fix" by deleting the fzf ladder — Ctrl+R ownership depends on it.
**Warning signs:** `bindkey '^I'` reports `fzf-completion` after reload.

### Pitfall 2: "Fixing" completion by uncommenting zicompinit block

**What goes wrong:** Eager double compinit fights autocomplete's first-precmd init and dump handling.
**Why it happens:** Zinit docs recommend the finalize idiom generally, but upstream autocomplete explicitly requires removing compinit calls.
**How to avoid:** Replace the commented block with a why-it-stays-out comment. Diagnose via H-4/H-5 instead.
**Warning signs:** Duplicate dump files (`~/.cache/zsh/compdump` vs zinit path), `compdef: command not found` on startup.

### Pitfall 3: Assuming the bug is keybinds (D-34 violation)

**What goes wrong:** Planner locks a rebind-only plan; auto-show still dead.
**Why it happens:** Tab works synchronously, so binds *look* like the whole story — but auto-show is the independent async pipeline.
**How to avoid:** Work the H-1..H-7 checklist live; baseline `min-input 1` + `delay 0` first to isolate config from mechanism.

### Pitfall 4: Re-stowing before evicting strays

**What goes wrong:** `--no-folding` leaf-links every stray file (`opencode/*`, …) as stow-owned links into `~/.config/`, which then must be unstowed file-by-file.
**Why it happens:** Strays still sit inside the `nvim/.config/` package tree at stow time.
**How to avoid:** D-25 `mv` first, `git status` clean, then stow. Order is part of both the installer flow and the D-26 runbook.

### Pitfall 5: post_verify passing a folded tree

**What goes wrong:** Green verify on broken deployment (today's behavior — `readlink -f` resolves through dir symlinks).
**Why it happens:** `assert_linked` checks leaf resolution only.
**How to avoid:** Add the intermediate-dir non-symlink assertion; treat its failure message as a hand-repair pointer, never an auto-fix trigger.

### Pitfall 6: Ubuntu global compinit double-init

**What goes wrong:** On Ubuntu-family, system `/etc/zsh/zshrc` compinit + autocomplete's precmd compinit.
**Why it happens:** No `.zshenv` with `skip_global_compinit=1` (upstream requirement; absent repo-wide, verified).
**How to avoid:** Ship `zsh/.zshenv` with the var + comment. Harmless on Arch (no global compinit present).

### Pitfall 7: Offline first prompt kills async silently

**What goes wrong:** Fresh clone without network/git at first prompt → zasync clone fails → no auto-show ever, Tab fine, no error surfaced later.
**Why it happens:** Clone attempted once at first precmd; failure is silent-ish.
**How to avoid:** Document in README troubleshooting; D-14 regression implicitly covers it (auto-show check fails). Installer could pre-warm the clone — discretionary, out of locked scope; flag as planner option.

## Code Examples

### D-01 baseline zstyle block (place above plugin section)

```zsh
# Find-as-you-type auto-show (D-01..D-04): first char triggers, no added delay.
# min-input 1 == upstream default; stated explicitly so intent is locked.
# Source: CONFIGURATION.md (Response timing) via ctx7 docs fetch.
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' delay 0
# Thousands-scale cutoff (D-16, researcher pick): screen-fit binds anyway;
# (MORE) marker is automatic on partial lists.
zstyle -e ':autocomplete:*:*' list-lines 'reply=( 300 )'
```

### Ladder comment block (D-31, top of plugin section ~zshrc:283)

```zsh
# Key-ownership ladder (highest first — new clashes resolve downward):
#   1. autocomplete: Tab/menu (Tab ALWAYS menu-select, never ghost-accept)
#   2. autosuggestions: ghost-accept (Right-arrow, vicmd-l, Ctrl+Space, Ctrl+_)
#   3. fzf: Ctrl+R (+ expendable **/Ctrl+T/Alt+C extras — droppable per D-10)
#   4. stock vi/zle: everything undecided (core motions hjkl/wb/ggG untouchable)
# Load-order rule: plugin binds, then atload overrides, then fzf ladder, then
# owned keys are RE-ASSERTED (^I like ^R) because fzf --zsh rebinds ^I last.
```

### post_verify fold-detector addition (setup.sh, inside post_verify loop)

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

### mkdir guard placement (setup.sh, start of run_stow)

```bash
# D-24: parent-dir guard — plain mkdir (never inspects/repairs symlinks, D-26).
mkdir -p "$HOME/.config"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Folded stow trees accepted silently | `--no-folding` + mkdir guard + fold-detector verify | This phase (stow 2.4.1 supports the flag) | `~/.config` can never be swallowed again; legacy folds removed via `-R --no-folding` |
| Tab ownership assumed from atload order | Re-assert owned keys after fzf ladder | This phase (fzf ≥0.48 native integration rebinds `^I`) | Tab deterministically `menu-select` regardless of fzf version behavior |
| Commented zicompinit kept "just in case" | Delete + why-it-stays-out comment | This phase | Removes the highest-risk well-meaning regression |
| Autosuggest strategy assumed default | Verified default `(history)` + never adopt `completion` strategy | This phase | Eliminates the only autosuggest-side Tab-bind vector by policy |

**Deprecated/outdated:**
- The commented `zicompinit; zicdreplay` + `_zsh_highlight_bind_widgets` / `_zsh_autosuggest_bind_widgets` finalize block: remove. Autocomplete owns compinit; all three plugins bind independently at load/precmd by design.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Tab-accepts-ghost is fzf-wrapper fallback + top-completion/ghost coincidence, not an autosuggest Tab bind | D-29 trace | LOW — prescription (final `^I` = menu-select) fixes all three candidate mechanisms identically; live D-29 check adjudicates |
| A2 | Upstream Enter-in-menu selects-into-buffer without executing (README wording "Stop text search or exit menu") | D-05 | MEDIUM — must be confirmed in live regression (Enter, then Enter); if it executes, planner needs a menuselect `^M` rebind, which upstream documents as the inverse (`bindkey -M menuselect '^M' .accept-line` is the *submit* override — absence of that line is the evidence) |
| A3 | D-04 mid-word/`sudo` contexts work from defaults | Feasibility map | LOW — fallback `setopt completeinword` documented; each context is individually live-tested |
| A4 | `list-lines 300` is a good thousands-scale cutoff | D-16 | LOW — agent's discretion + user judges live; screen-fit binds anyway so blast radius is small |
| A5 | Unset `$terminfo[kcbt]` won't break atload (bindkey error non-fatal, prior line already applied) | Keybindings | LOW — alacritty + linux consoles define kcbt; failure mode is Shift-Tab only |
| A6 | Installer-side zasync pre-warm stays out of scope | Pitfall 7 | LOW — flagged as planner option, not locked scope |

## Open Questions

1. **Does the auto-show list surface fuzzy (`_complete:-fuzzy`) matches? (D-21)**
   - What we know: default completer chain includes `_complete:-fuzzy` with substring matchers [VERIFIED: .autocomplete__config:13-14, 32-35]; default top-level matcher is prefix+case-fold.
   - What's unclear: whether the real-time path (vs Tab path) exposes fuzzy hits for short inputs.
   - Recommendation: live probe first (`git ch`, `cd /u/l` style); apply completer/matcher narrowing only on observed failure.

2. **Which of H-1..H-7 is the actual auto-show blocker on this machine?**
   - What we know: all static config consistent with working auto-show except the fzf Tab clobber (which affects Tab, not the async path).
   - What's unclear: runtime-only state (hook chain, zpty health, FSH interplay).
   - Recommendation: planner works the checklist in order H-1 → H-7 with the log file (`~/.local/state/zsh-autocomplete/log/`) open; D-34 grants full freedom on the fix shape.

3. **Exact Enter semantics in-menu (one vs two Enter to run)?**
   - Covered in A2; resolved by the D-14 live regression, not by further research.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| zsh | interactive shell | ✓ | 5.9.2 | — |
| GNU Stow | installer + repair | ✓ | 2.4.1 | — |
| fzf | Ctrl+R + extras | ✓ | 0.74.4 (native `--zsh` rung) | ladder degrades to warn-and-continue |
| git | zinit plugins, zasync, snippet updates | ✓ | (present) | — |
| `~/.cache/zsh/zasync` | async list backend | ✓ present | — | auto-clone at first prompt (needs network) |
| alacritty/linux terminfo `kcbt` | Shift-Tab | ✓ (assumed present) | — | Tab-only cycling still works |
| Ubuntu `/etc/zsh/zshrc` global compinit | N/A on this machine | N/A (Arch ARM) | — | new `zsh/.zshenv` covers Ubuntu-family |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none on this machine (fzf-absent path already handled by ladder).

## Security Domain

Applicable: installer runs privileged `stow -t /` for keyd (unchanged paths, flag-only edits) and the executor performs destructive-adjacent `rm ~/.config` (symlink) + `mv` of ~80MB+ app data.

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | Yes (privileged keyd path) | No change to confirmation/diff/adopt gates; `--no-folding` under `-t /` is link-shape-only, no privilege change |
| V5 Input Validation | Yes | `SELECTED_PACKAGES` values are internally generated (checklist), never raw user strings; new `mkdir -p "$HOME/.config"` uses no external input |
| V6 Cryptography | No | — |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Symlink-through-write during repair (`mv`/`stow` following `~/.config` link) | Tampering | Ordered runbook: break link → mkdir → move → stow; preview (`ls`, `readlink`, `du`) before each mutation; moves are `mv` (no delete) |
| `--adopt` swallowing user `/etc/keyd` content | Tampering / Repudiation | Existing explicit-confirm adopt gate untouched; flag addition doesn't alter adopt semantics |
| zasync auto-clone executing remote code at first prompt | Supply-chain | Pre-existing upstream behavior, unchanged by this phase; noted, not expanded |

## Sources

### Primary (HIGH confidence — tool-verified this session)

- `ctx7 docs /marlonrichert/zsh-autocomplete` — delay/timeout/min-input knobs, Tab rebinding recipes, compinit-removal + `skip_global_compinit` requirements (2 fetches, 2026-09-22)
- Installed plugin source `~/.local/share/zinit/plugins/marlonrichert---zsh-autocomplete/` @77706d4: `Functions/Init/.autocomplete__{main,async,compinit,config,key-bindings,widgets}`, `Functions/Util/.autocomplete__zle-flags`, `CONFIGURATION.md`, `README.md` — read with line citations above
- Installed `zsh-users---zsh-autosuggestions` v0.7.1: `src/config.zsh` (ACCEPT/PARTIAL defaults, strategy default), `src/strategies/completion.zsh` (Tab bind vector), `src/bind.zsh`
- Live `fzf 0.74.4 --zsh` output (`/tmp/fzf-zsh-integration.zsh:597-675`) — Tab capture/rebind/fallback semantics
- Live `stow 2.4.1` sandbox labs 1–4 (/tmp/stowlab*) — fold reproduce, unfold, legacy-unstow, symlink-abort, sibling coexistence
- `zsh/.zshrc` (445 lines), `setup.sh` call-site grep, `git status`/`ls-files` (stray untracked proof), `/etc/os-release` (archarm), `~/.config` + `~/.zshrc` symlinks, OMZL snippet (no compinit)

### Secondary (MEDIUM — official docs via ctx7, consistent with source)

- Upstream README keyboard-shortcut tables and CONFIGURATION.md keybinding recipes (corroborated by the installed key-bindings module — no divergence observed)

### Tertiary (LOW — marked [ASSUMED], for live adjudication)

- A1–A6 assumptions log; H-1..H-7 root-cause ranking is deliberately flat per D-34

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified live; plugin internals read, not recalled
- Architecture (hook/async pipeline, Tab layering, stow shapes): HIGH — source-read + sandbox-executed
- Pitfalls: HIGH for fzf-Tab/stow-fold/finalize-block; MEDIUM for auto-show root cause (runtime-only, open per D-34)
- Feasibility map D-01..D-04/D-16/D-20/D-22: HIGH except D-21 (MEDIUM — live probe required)

**Research date:** 2026-09-22
**Valid until:** ~30 days (stable domain; plugin @77706d4 is 9 days old — re-check upstream only if auto-show hypotheses implicate a plugin bug requiring an update)
