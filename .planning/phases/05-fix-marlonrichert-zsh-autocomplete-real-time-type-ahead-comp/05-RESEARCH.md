# Phase 5: fix marlonrichert/zsh-autocomplete Real-time type-ahead completion - Research

**Researched:** 2026-09-17
**Domain:** Zsh interactive completion (marlonrichert/zsh-autocomplete + zsh-autosuggestions + fzf coexistence under Zinit)
**Confidence:** MEDIUM (knob enumeration HIGH — read from installed plugin source this session; root cause MEDIUM — live shell needed to confirm which suspect fires)

## Summary

The auto-show engine in `marlonrichert/zsh-autocomplete` is an async `line-pre-redraw` hook that lists completions after ~0.05s of idle time with a default `min-input` of 1 character — meaning **first-character auto-show (D-01), quiet empty prompt (D-02), ghost+list coexistence (D-03), Enter select-then-edit (D-05), and no-history auto-show (D-20) are all stock defaults, not new capabilities**. The phase is therefore a_corrrective-config_ phase, not a capability-building phase: move fzf init before the engine, re-assert widget ownership after everything, apply a small set of verified `zstyle`/`bindkey` deltas in `zsh/.zshrc`, delete two dead code blocks, and prove it in a live terminal.

**Primary recommendation:** Keep `marlonrichert/zsh-autocomplete` as the engine (D-19 bar for a swap is not met — nothing is proven unfixable); fix ordering (`fzf ladder → autocomplete LAST → ownership re-assertion`), add Right-arrow ghost-accept, force prefix-only matching via standard compsys overrides, set `list-lines 200`, and verify with ad-hoc live commands only (no new files per D-13).

## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Auto-show trigger sensitivity

- **D-01:** The completion list auto-shows immediately on the first typed character — no keypress, no char-count threshold, no delay.
- **D-02:** Quiet on an empty prompt — nothing pops up until the first character is typed (no wall of commands on every fresh prompt).
- **D-03:** Ghost autosuggestion text and the dropdown list coexist on screen simultaneously, each with its own accept key.
- **D-04:** Auto-show applies in every typing context — command names, arguments, paths, mid-word, after `sudo`.
- **Feasibility caveat (binding on researcher):** D-01..D-04 are recorded as desired outcomes, not verified plugin capabilities. The researcher MUST map each to real knobs/plugin defaults and report back the closest achievable alternative for anything not configurable — the planner must not lock an impossible config.

#### Menu key behavior

- **D-05:** Enter on a highlighted item selects it into the buffer for further editing; a second Enter runs it. First Enter never executes.
- **D-06:** Esc keeps 100% stock vi behavior (untouched, insert→normal). Ctrl+C is the explicit list-dismiss key.
- **D-07:** Tab cycles forward / Shift-Tab cycles back inside the menu (existing `kcbt` wiring kept); arrow keys also work.
- **D-08:** Ghost-text accept keys are the existing Ctrl+Space (accept) / Ctrl+_ (execute), plus Right-arrow accept added in insert mode. Researcher picks the exact widget so plain cursor movement still works when no suggestion is shown. The vi-normal-mode `l`-to-accept idea was proposed and explicitly dropped — no normal-mode ghost-accept rebind.

#### fzf coexistence boundary

- **D-09:** On any widget clash between fzf and autocomplete, the researcher decides what stays; fzf loses by default per the Phase-3 priority ladder (fzf must never break autocomplete).
- **D-10:** fzf extras (`**` Tab fuzzy file find, Ctrl+T, Alt+C) are expendable — they may be dropped to save autocomplete. Ctrl+R history ownership is not negotiable.
- **D-11:** The Phase-3 fzf init ladder (version branch, Debian rung, warn-if-missing) is NOT frozen — researcher may rework fzf init placement/loading as part of the fix.
- **D-12:** Plugin load order is free to reorder — this relaxes the Phase-3 D-01 order lock. What stays locked from D-01: keep all three plugins, and the Ctrl+R-vs-Tab split ownership.

#### Proof and regression

- **D-13:** The user's live terminal verdict closes the phase, backed by ad-hoc commands run during verification. Zero new harness/probe files — Phase 4 owns `--self-test` and hasn't started, so no dependency is taken on it.
- **D-14:** The live regression covers the shell spine: auto-show works + Ctrl+R history + ghost text + Tab menu-select + clean reload with no errors.

#### Vi-mode interplay

- **D-15:** All non-decided vi bindings stay stock. Core motions (`hjkl`, `w`/`b`, `gg`/`G`, etc.) are untouchable and must never be rebound. Non-motion vi keys may be rebound only if the fix needs it.

#### List noise guard

- **D-16:** Show the full untruncated list by default, with a hard cutoff when the candidate count passes a threshold (thousands-scale completions lag). Researcher picks the cutoff number; user judges it live.
- **D-17:** Truncation always shows a visible hint (e.g. "…more — keep typing to narrow") — never a silent cut that looks like missing results.

#### Change boundary

- **D-18:** The fix may touch `zsh/.zshrc` + docs/comments + `setup.sh` installer wiring wherever needed. The Phase-1 atomic-docs rule applies (behavior change ships with its doc updates).
- **D-19:** A new plugin is allowed if it's the clean fix, but `marlonrichert/zsh-autocomplete` stays the engine. Swapping the completion engine entirely is allowed only if the researcher proves it unfixable.

#### Completion sources

- **D-20:** The auto-show list shows everything EXCEPT history — commands, files/paths, options/flags, variables. History stays exclusively behind Ctrl+R fzf (consistent with split ownership).
- **D-21:** Prefix-only matching — candidates must start with exactly what was typed. No fuzzy-anywhere matching.

#### Research directive

- **D-23:** The researcher consults Context7 docs first for the plugin's current documentation, then falls back to GitHub CLI (issues/PRs/source) only if needed.

### Agent's Discretion

- D-09 clash resolution (which widget/config survives a conflict, fzf loses by default).
- D-22 result ordering inside the combined completion list (researcher picks from upstream defaults; user judges the feel live).
- D-16 threshold number for the thousands-scale cutoff (researcher picks; user judges live).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. (Phase-4 `--self-test` harness integration is not deferred work for this phase by user directive — Phase 4 may pick up the fixed behavior into its gates when it runs.)

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Type-ahead completion list | Interactive shell (ZLE) | — | `line-pre-redraw` hook + async pty worker, all inside the running `zsh` process |
| Ghost autosuggestion text | Interactive shell (ZLE `POSTDISPLAY`) | — | `zsh-autosuggestions` renders via highlight hook in the same process |
| History search (Ctrl+R) | Interactive shell (fzf child process) | — | fzf binary invoked as a full-screen child; ownership split is by keybinding only |
| Keymap ownership (Tab/Ctrl+R) | Interactive shell (ZLE keymaps) | — | Decided purely by `bindkey` order in `zsh/.zshrc` |

Single-tier phase: every change lives in the interactive-shell tier (`zsh/.zshrc` evaluation order). No backend, no daemon, no installer logic change required (see D-18 finding below).

## Standard Stack

### Core (locked — keep all three plugins + fzf, per D-12)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `marlonrichert/zsh-autocomplete` | Zinit `light` (main branch, self-updating) | Real-time async type-ahead list | Locked engine per D-19; owns its own `compinit`, matcher defaults, and keymaps |
| `zsh-users/zsh-autosuggestions` | Zinit `light` | Ghost `POSTDISPLAY` suggestion + accept/execute widgets | Locked per D-12; existing Ctrl+Space / Ctrl+_ binds stay |
| `zdharma-continuum/fast-syntax-highlighting` | Zinit `light-mode` | Real-time syntax validation | Locked per D-12; plugin already contains a workaround hook for it |
| `joshskidmore/zsh-fzf-history-search` | Zinit `light` | Defines `fzf_history_search` widget (currently shadowed, harmless) | Locked per D-12; keep loaded, no rebind needed |
| `fzf` binary | Arch: ≥0.48 (native `--zsh` rung); Debian-family: 0.44.1 (legacy `doc/examples` rung, verified on this machine) | Ctrl+R history finder (child process) | Already in `setup.sh` `common` toolchain on all families — no installer change |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `zsh-users/zsh-completions` | — | Extra completion definitions | NOT USED — the `zi ice zsh-users/zsh-completions` line in `.zshrc:288` never loads anything (confirmed absent from `~/.local/share/zinit/plugins/`). Delete the dead line; do not "fix" it into a load (scope creep, new completion surface). |
| OMZL `compfix`/`git` snippets + PZT `history` | Zinit snippets | Shell library helpers | Keep. OMZL `completion.zsh` sets only `setopt`/`zstyle`/aliases — it does **not** call `compinit` (verified 78-line file), so it does not fight the engine's own `compinit`. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Keep engine (recommended) | Swap to `zsh-autosuggestions` + bare compsys menu | Loses async find-as-you-type list entirely — the exact capability this phase restores. D-19 swap bar not met. |
| `bindkey '^I' menu-select` (keep) | Plugin default `complete-word` on Tab | `complete-word` inserts the top match immediately; `menu-select` enters the menu. D-07 + Phase-3 Tab-ownership lock require keeping `menu-select`. |
| `bindkey -r` expendables (legacy rung) | `FZF_CTRL_T_COMMAND=` env-disable | Env-disable is the official mechanism [CITED: github.com/junegunn/fzf README "Setting up shell integration"] but only honored by the ≥0.48 `--zsh` script; the 0.44.1 legacy `key-bindings.zsh` binds unconditionally (verified — zero conditionals around its `bindkey` lines), so the legacy rung needs `bindkey -r`. Use each mechanism on its own rung. |

**Installation:** None. Zero new packages, zero version changes. (`fzf` + `zsh` already in `setup.sh` `common` for `arch`/`debian`/`termux` families [VERIFIED: setup.sh:194-202].)

## Package Legitimacy Audit

Not applicable — this phase installs no external packages. No new plugin is recommended (D-19 complement unneeded). No `npm`/`pip`/`cargo` surface exists in this repo (configuration repo, no root manifest).

## D-item → Real-knob Feasibility Map (binding per D-23 / feasibility caveat)

Exhaustive `:autocomplete:` knob enumeration, read from the installed plugin source this session [VERIFIED: ~/.local/share/zinit/plugins/marlonrichert---zsh-autocomplete/Functions + Completions]:

| Real knob | Default | Source line |
|-----------|---------|-------------|
| `:autocomplete:` `delay` (alias `min-delay`) | `0.05` s | `.autocomplete__async:170-172`, verbatim: `builtin zstyle -s :autocomplete: delay seconds \|\| builtin zstyle -s :autocomplete: min-delay seconds \|\| (( seconds = 0.05 ))` |
| `:autocomplete:` `default-context` | unset (normal completion) | `.autocomplete__async:56`, verbatim: `builtin zstyle -s :autocomplete: default-context curcontext` |
| `:autocomplete:<ctx>:` `min-input` | `1` (normal ctx) / `0` (history/recent ctx) | `.autocomplete__async:401-409`, verbatim: `if ! builtin zstyle -s ":autocomplete:${curcontext}:" min-input min_input; then if [[ -n $curcontext ]]; then min_input=0; else min_input=1; fi; fi` |
| `:autocomplete:<ctx>:` `ignored-input` | unset | `.autocomplete__async:412` |
| `:autocomplete:<ctx>:` `list-lines` | `16` | `.autocomplete__async:459-463`, verbatim: `builtin zstyle -s ":autocomplete:${curcontext}:" list-lines max_lines \|\| max_lines=16` |
| `:autocomplete:<ctx>` `timeout` | `1.0` s | `.autocomplete__async:255-256` |
| `:autocomplete:<LASTWIDGET>:` `ignore` | unset | `.autocomplete__async:118-119` |
| `:autocomplete:<ctx>:history-lines` `add-semicolon` | on | `_autocomplete__history_lines:139` |
| `:autocomplete:<WIDGET>:` `add-space` | `executables aliases functions builtins reserved-words commands` | `_autocomplete__should_add_space:12` + README |
| `:autocomplete:<ctx>` `insert-unambiguous` | off | `_autocomplete__should_insert_unambiguous:8-9` |
| `:autocomplete::compinit` `arguments` | none | `.autocomplete__compinit:53` |

**Knobs hypothesized in the brief that DO NOT EXIST — do not plan them:** `widget-style`, `fzf-completion`, `find-directories` (zero hits across the whole plugin tree), and any candidate-*count* cutoff (the only cutoff knob is `list-lines`, i.e. display *lines*, always additionally capped to `LINES - BUFFERLINES - 1` [VERIFIED: .autocomplete__async:463]).

| D-item | Verdict | Real knob / default |
|--------|---------|---------------------|
| D-01 first-char auto-show | ACHIEVABLE = stock default | `min-input` defaults to `1`; add explicit `zstyle ':autocomplete:*' min-input 1` to document intent. **Note:** "no delay" is not literally achievable — the engine always waits `delay` (default 0.05 s idle). Closest alternative: `zstyle ':autocomplete:*' delay 0.01`. Recommend keeping stock 0.05 (0.01 re-fires the worker on every keystroke of fast typing; the `KEYS_QUEUED_COUNT` guard drops most of them anyway, but log churn grows). |
| D-02 quiet empty prompt | ACHIEVABLE = stock default | 0 chars < `min-input` 1 → no list. No config. |
| D-03 ghost + list coexist | ACHIEVABLE = stock default | Engine sets `ZSH_AUTOSUGGEST_USE_ASYNC=yes`, appends its widgets to `ZSH_AUTOSUGGEST_IGNORE_WIDGETS`, and re-applies ghost highlight after each async render [VERIFIED: .autocomplete__async:12,16-21,389-390]. No config. |
| D-04 every context | ACHIEVABLE = stock default | Engine forces `completealiases completeinword` per completion [VERIFIED: .autocomplete__main:10]; `sudo` prefix completes via stock compsys `_sudo`. Live-verify each context (table below). |
| D-05 Enter select-then-edit | ACHIEVABLE = stock default — **zero config, and affirmatively do NOT add the `bindkey -M menuselect '^M' .accept-line` recipe** (that recipe makes first Enter *execute*, violating D-05). Stock menuselect map contains no `^M`/`^J` override [VERIFIED: `bindkey -M menuselect` probe + `.autocomplete__key-bindings:41-50` — only Tab/backtab/`^@`/`^[v`/`^_`/`^[u`/PgUp/PgDn bound]; README keyboard table: "Enter … Exit menu text search or exit menu" [CITED: plugin README "Keyboard shortcuts"]. |
| D-06 Esc stock / Ctrl+C dismiss | SPLIT — Esc achievable stock; Ctrl+C-as-pure-dismiss NOT safely achievable | Esc: stock menuselect map has no `^[` binding (verified probe), so Esc aborts the menu and is re-processed in `viins` → enters normal mode. Untouched. Ctrl+C: with default `stty isig`, `^C` never reaches ZLE as input (terminal sends SIGINT) so **no menuselect `^C` binding can ever fire**; stock SIGINT aborts the whole line (list gone *and* buffer gone — plugin's own `TRAPINT` handler confirms `^C`-during-completion aborts [VERIFIED: .autocomplete__compinit:117-121]). A pure "dismiss list, keep buffer" `^C` requires `stty -isig`, which would also break `^C`-cancels-foreground-jobs — REJECTED as unsafe. Closest achievable alternative: document stock behavior + `^G` (`send-break`, already bound in emacs, unbound in menuselect — recommend `bindkey -M menuselect '^G' send-break`) as the buffer-preserving dismiss. Planner: present this alternative at build time; do not lock a `^C` rebind. |
| D-07 Tab/Shift-Tab/arrows | ACHIEVABLE = stock + one kept override | Plugin binds menuselect Tab→`menu-complete`, Backtab→`reverse-menu-complete` itself [VERIFIED: .autocomplete__key-bindings:41-43] — **the `.zshrc` atload `bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete` line is redundant: delete it.** Keep main-map `bindkey '^I' menu-select` (differs from plugin default `complete-word`, required for menu-enter feel). Arrows: stock (command-line ↑/↓ enter menu/history via plugin widgets; in-menu arrows navigate). Do NOT add the "arrows always move cursor" recipe (would violate D-07). Guard `$terminfo[kcbt]` usage generally (`[[ -n ${terminfo[kcbt]:-} ]]`) — verified non-empty (`^[[Z`) in this environment but not guaranteed on all terminals. |
| D-08 Right-arrow ghost accept | ACHIEVABLE — `bindkey -M viins '^[[C' '^[OC' autosuggest-accept` | `autosuggest-accept` "invokes the original widget instead" when conditions are unmet [CITED: zsh-autosuggestions API docs via Context7] and `_zsh_autosuggest_accept` bails to `_zsh_autosuggest_invoke_original_widget` when cursor is not at EOL or `POSTDISPLAY` is empty [VERIFIED: src/widgets.zsh:110-130] — plain cursor movement is preserved by construction. Bind *after* all plugins load so the captured original is `vi-forward-char`. Note: `vi-forward-char` is already in default `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS` [VERIFIED: src/config.zsh:47-53], so → may already accept at EOL — the explicit bind makes it deterministic regardless of wrap state (`ZSH_AUTOSUGGEST_MANUAL_REBIND=1` is set by the engine [VERIFIED: .autocomplete__widgets:4]). |
| D-09/D-10 fzf loses | Decided (researcher discretion): fzf ladder moves BEFORE the engine; expendables stripped per-rung; `^R` kept; ownership re-asserted after everything | Legacy rung (0.44.1, live on Debian-family): binds `^T`/`^[c`/`^R` in emacs+vicmd+viins unconditionally and binds **zero** Tab keys [VERIFIED: `grep -c '\^I'` = 0; bindkey lines 70-72, 93-95, 114-116] → strip with `bindkey -r` in all three keymaps. New rung (≥0.48, Arch): official env-disable `FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND= source <(fzf --zsh)` [CITED: junegunn/fzf README]; new script binds only Ctrl-T/Ctrl-R/Alt-C + `**`-triggered completion, never plain Tab. `**` trigger: already dead on legacy rung (`completion.zsh` never sourced); on the new rung set `FZF_COMPLETION_TRIGGER=''` [ASSUMED — verify live, fallback: leave default since it needs an explicit `**` prefix and cannot clash with plain Tab]. |
| D-13/D-14 proof | Ad-hoc commands only — diagnostic + regression tables below | No files. |
| D-15 vi motions | Compatible — plugin's own binds avoid command-line motions | Engine binds `k`/`j`/`^P`/`^N`/`/` **in menus only** (`menukeys`) or as Alt-chords; command-line `vicmd` motions untouched [VERIFIED: .autocomplete__key-bindings:30-37]. Plan must add no motion rebinds. |
| D-16 cutoff | Closest achievable: `list-lines` (display lines, not candidate count) — researcher picks **200** | Truncation short-circuits per-tag computation (`_autocomplete__partial_list` → `comptags() { false }` stops further tags [VERIFIED: .autocomplete__async:549-553,691-694]) and render is screen-capped, so 200 ≈ "everything that fits, packed multi-column ≈ 800–1200 candidates" with compute bounded by `timeout` 1.0 s. Fallback ladder if laggy live: 200 → 60 → stock 16. User judges live per discretion. |
| D-17 visible MORE hint | ACHIEVABLE = stock, zero config | Engine appends `compadd -J -last- -x '%F{0}%K{12}(MORE)%f%k'` automatically on partial lists [VERIFIED: .autocomplete__async:444-447]. |
| D-18 scope | `zsh/.zshrc` + comments only; **no `setup.sh` change needed** | `fzf`+`zsh` already in `common` toolchain on all three families [VERIFIED: setup.sh:194-202]. Atomic-docs rule still applies to README/AGENTS touch-ups if behavior text changes. |
| D-19 engine stays | YES — swap bar not met | Nothing is proven unfixable (see suspects ranking). No complement plugin needed either. |
| D-20 no history in auto-show | ACHIEVABLE = stock default — **never set `default-context`** | Auto-show (`*` branch) runs normal completion (commands/files/options, no history tag); history lines render only in `*history-*` curcontext, entered via explicit `^R`/`/`/`↑` toggles [VERIFIED: .autocomplete__async:466-503]. Open question: `↑` entering the history *menu* is stock engine behavior on an explicit keypress — confirm live whether the user counts that as "history behind Ctrl+R" (recommend keeping: it is not auto-show). |
| D-21 prefix-only | NOT stock (stock is fuzzy) — achievable via standard compsys overrides placed AFTER the engine load | Engine sets `completer _expand _complete _complete:-fuzzy _correct _approximate _ignored` and fuzzy `matcher-list` (`r:|[.]=**`, `l:|=*`, …) [VERIFIED: .autocomplete__config:13-34, verbatim quotes above]. Override after load: `zstyle ':completion:*' completer _expand _complete _ignored` + `zstyle ':completion:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}'` (case-insensitive prefix only). Tradeoff to document: loses typo-correction (`_correct`/`_approximate`) — intended per D-21. Values are researcher-chosen [ASSUMED] — live-judge feel. |
| D-22 ordering | Researcher picks stock | No `group-order`/`tag-order` overrides — keep upstream defaults. |

## Architecture Patterns

### Init-order diagram (the whole phase is evaluation order in one file)

```text
p10k instant prompt (TOP — frozen)
  │
~/.shell_aliases / ~/.shell_functions
  │
typeset -U path + PATH exports (dedupe guard — frozen)
  │
zoxide init / vi mode / setopts / edit-command-line / undo / magic-space / zmv
  │
Zinit self-clone + OMZL snippets (compfix, git [+completion — keep, harmless])
  │     ▲ engine scrubs hostile `menu` styles itself at first precmd
  │       (deletes all `menu` zstyles, forces `menu no no-select`)
  │       [VERIFIED: .autocomplete__config:146-158]
  │
p10k theme + annexes + zsh-autosuggestions (+ future Right-arrow bind site)
  │
fast-syntax-highlighting → joshskidmore fzf-history-search (binds ^r, shadowed later — harmless)
  │
─── fzf ladder MOVED HERE (was after engine) ───
  │     legacy rung: source key-bindings.zsh, then `bindkey -r ^T/^[c` × {emacs,viins,vicmd}
  │     new rung:    FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND= source <(fzf --zsh)
  │
marlonrichert/zsh-autocomplete (LAST plugin load — frozen position)
  │     atload: keep `bindkey ^I menu-select`; DELETE redundant menuselect kcbt line
  │     owns compinit (deferred to first precmd; OMZL never calls compinit — verified)
  │
─── Phase-5 ownership block (AFTER everything) ───
        bindkey ^I menu-select · bindkey ^R fzf-history-widget + missing-widget warn
        :completion: prefix-only overrides · :autocomplete: min-input/list-lines
        viins Right-arrow autosuggest-accept · menuselect ^G send-break
  │
.local sourcing → p10k apply → bun → tail `path=( $path )` (LAST PATH line — frozen)
```

### Recommended project structure

No new files (D-13). Single edit site `zsh/.zshrc` regions: plugin block (~290–314), fzf ladder (~324–344, moved), finalize block (~353–359, deleted), one new ownership block after the ladder.

### Pattern 1: Ownership re-assertion after the last writer wins

**What:** Any `bindkey`/widget assignment lives in a single block placed after the final plugin load and after the fzf ladder, with a comment citing the split (Ctrl+R = fzf, Tab = autocomplete).
**When to use:** Always in this file — both the engine README ("plugins loaded after Autocomplete may override these bindings" [CITED]) and the observed `^r`/`^R` double-bind prove last-writer-wins is the failure mode.
**Example:**

```zsh
# Ownership (Phase 5): Tab belongs to autocomplete, Ctrl+R to fzf. Last writer
# wins in ZLE, so this block stays after ALL plugin/fzf loads.
bindkey '^I' menu-select
bindkey '^R' fzf-history-widget
```

### Anti-Patterns to Avoid

- **Restoring the commented `zicompinit`/`zicdreplay` finalize block:** unneeded — nothing is turbo-loaded (no `wait` ices), the engine runs its own deferred `compinit` at first precmd and no-ops later `compinit` calls [VERIFIED: .autocomplete__compinit:47-68]; both `_zsh_autosuggest_bind_widgets` and `_zsh_highlight_bind_widgets` exist but initial wrapping already happens via `atload _zsh_autosuggest_start` + the engine's own precmd re-wrap. Delete the block instead.
- **Binding `^M .accept-line` in menuselect:** makes first Enter execute — the opposite of D-05.
- **Setting `default-context history-incremental-search-backward`:** injects history into every new prompt — the opposite of D-20.
- **Setting `min-input 3+`:** re-creates the reported bug (nothing until 3 chars). D-01 wants 1.
- **`stty -isig` to make `^C` a menu-dismiss key:** breaks job control for the whole terminal. Rejected (see D-06).
- **"Fixing" the dead `zi ice zsh-users/zsh-completions` line into a real load:** adds an unrequested completion surface. Delete it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async type-ahead listing | Custom `line-pre-redraw` worker / pty harness | The engine's built-in async module (`zpty` + `zselect` + fd-widgets) | Race handling (`same-state` checks, `KEYS_QUEUED_COUNT` guards), timeout kill, and highlight re-application are subtle; reimplementation will flicker or crash ZLE |
| Prefix-only filtering | Custom `compadd` wrapper / `matcher` function | `zstyle ':completion:*' completer/matcher-list` overrides | The engine already patches `_main_complete`/`_complete`/`_approximate` around stock compsys; fighting it with a second wrapper layer breaks the `(MORE)` short-circuit |
| Ghost-text accept | Custom `POSTDISPLAY`-checking widget | `autosuggest-accept` (falls back to original widget by construction) | Upstream-tested fallback; custom widget must replicate EOL + empty-`POSTDISPLAY` + wrap bookkeeping |
| Menu-dismiss key | `stty` surgery or TRAPINT games | Stock SIGINT semantics + `send-break` (`^G`) in menuselect | Terminal driver owns `^C` delivery; working around it breaks job control |

**Key insight:** every D-item except D-21 maps to a stock default or a one-line standard `zstyle`/`bindkey`; the bug is ordering/ownership, not missing capability.

## Prime-suspect ranking (from CONTEXT Existing Code Insights)

| # | Suspect | Verdict after research |
|---|---------|------------------------|
| 1 | Commented `zicompinit`/`zicdreplay` block (353–359) | CLEARED as cause, DELETE as dead code. Nothing turbo-loads; engine owns `compinit`. The block's absence cannot suppress auto-show (async hook registers at first precmd regardless). |
| 2 | `bindkey -M menuselect` timing (311–314) | CLEARED as cause (plugin loads `zsh/complist` itself at source time [VERIFIED: .autocomplete__key-bindings:2]; `kcbt` non-empty here). Line REDUNDANT (plugin binds menuselect Tab/backtab itself) — delete, keep main-map `^I`. |
| 3 | `source <(fzf --zsh)` AFTER engine clobbers widgets/keymaps | CLEARED for Tab (both rungs bind zero Tab keys — legacy verified by `grep -c '\^I'` = 0; new rung per official docs binds Ctrl-T/Ctrl-R/Alt-C + `**` completion only [CITED]). CONFIRMED for `^R` (same-key double-bind: joshskidmore `bindkey ^r fzf_history_search` [VERIFIED: zsh-fzf-history-search.zsh:91] shadowed by later `bindkey ^R fzf-history-widget`) — but that resolves *in favor of* working Ctrl+R, so keep. **Move the ladder before the engine anyway** (engine README last-writer-wins rule + D-11 license) so no future fzf change can regress auto-show. |
| 4 | Zero `zstyle` tuning | CONFIRMED gap — but only D-16 (cutoff) and D-21 (prefix-only) need new styles; D-01/D-02/D-05/D-17/D-20 are already defaults. Do not add styles for already-default behaviors except documentary `min-input 1`. |
| 5 | Ghost-accept wiring | Needs the Right-arrow bind (safe widget picked — see D-08). Existing Ctrl+Space / Ctrl+_ untouched. |
| — | Unlisted: async worker silently dead | LIVE-DIAGNOSIS item. Engine logs to `${XDG_STATE_HOME:-~/.local/state}/zsh-autocomplete/log/` [VERIFIED: .autocomplete__main:26-41]. If the list still fails after reorder, the log + `zle -l \| grep autocomplete` + `zstyle -L ':autocomplete:*'` table below isolates pty/zselect failure vs config. Stock config *should* auto-show, so a persistent failure after the fix is environmental, not a knob problem — and still not engine-swap-grade (D-19). |

## Live diagnostic + regression commands (ad-hoc, D-13/D-14)

Diagnosis wave (proves which suspect fires; all read-only):

```zsh
zle -l | grep -E 'autocomplete|autosuggest|fzf'   # engine widgets registered?
bindkey '^I'; bindkey '^R'; bindkey -M viins '^[[C'  # ownership after reload
print -r -- "[${terminfo[kcbt]:-EMPTY}]"              # backtab availability
zstyle -L ':autocomplete:*'; zstyle -L ':completion:*' completer
ls -la ${XDG_STATE_HOME:-$HOME/.local/state}/zsh-autocomplete/log/ 2>/dev/null && tail -5 ${XDG_STATE_HOME:-$HOME/.local/state}/zsh-autocomplete/log/*.log
```

Regression wave (D-14 spine, all in a live terminal): type 1 char → list auto-shows; empty prompt → silent; ghost text visible alongside list; Tab enters menu, Tab/Shift-Tab/arrows cycle; Enter on item edits (no exec), second Enter runs; Esc → normal mode; Ctrl+R → fzf history; `source ~/.zshrc` → zero errors/warnings (other than the intended fzf-missing warn on fzf-less hosts).

## Common Pitfalls

### Pitfall 1: `:completion:` overrides placed before the engine load

**What goes wrong:** D-21 prefix-only styles silently vanish.
**Why it happens:** The engine sets same-pattern `:completion:*` defaults at load; identical patterns resolve last-set-wins.
**How to avoid:** All Phase-5 `:completion:` styles go in the ownership block AFTER `zi light marlonrichert/zsh-autocomplete`.
**Warning signs:** `zstyle -L ':completion:*' matcher-list` shows the fuzzy `r:|[.]=**` line after reload.

### Pitfall 2: Testing auto-show with `min-input` raised "temporarily"

**What goes wrong:** Researcher/verifier sets `min-input 3` to "reduce noise" and re-reports the original bug.
**Why it happens:** Single-word inputs shorter than `min-input` are suppressed by design [VERIFIED: .autocomplete__sufficient-input:414].
**How to avoid:** Keep `min-input 1`; use `ignored-input` patterns for specific noise, never a global threshold.

### Pitfall 3: Expecting Esc to reach `vicmd` while the menu is open

**What goes wrong:** "Esc doesn't enter normal mode" reported as a bug.
**Why it happens:** While the menu is active the keymap is `menuselect`, where Esc is unbound — it aborts the menu first, *then* `viins` sees Esc. One Esc press does both, which is correct stock behavior, but a *held* Esc or paste containing Esc can behave unexpectedly.
**How to avoid:** Document; do not bind `^[` in menuselect (would violate D-06/D-15).

### Pitfall 4: Judging prefix-only matching with `cd -` / `~-` / option-prefix inputs

**What goes wrong:** `b:-=+` option-prefix matcher and `~-` directory-stack tag-order are engine-set `:completion:` styles the D-21 override does not touch; behavior there differs from command position.
**Why it happens:** Override scope is `:completion:*` completer/matcher-list only.
**How to avoid:** Judge D-21 on command + path + flag-stem inputs; note anomalies as follow-ups, not blockers.

### Pitfall 5: Huge `list-lines` render lag misread as "engine hang"

**What goes wrong:** `list-lines 200` on a 5000-file directory feels sticky; blamed on async worker.
**Why it happens:** Render cost, not compute — compute is `timeout`-bounded (1 s) and per-tag short-circuited.
**How to avoid:** Fallback ladder 200 → 60 → 16 is pre-agreed; the `(MORE)` marker is automatic so lowering the number never looks like missing results.

## Code Examples

Verified patterns from official sources:

### Ownership + prefix-only + ghost-accept block (sketch for planner)

```zsh
# Source: marlonrichert/zsh-autocomplete README (keybinding recipes) +
#         junegunn/fzf README (FZF_*_COMMAND disable mechanism)
# Ordering: AFTER `zi light marlonrichert/zsh-autocomplete` AND after fzf ladder.

# D-07: Tab enters menu (plugin default is complete-word); menu cycling is stock.
bindkey '^I' menu-select

# D-21: prefix-only matching — overrides engine fuzzy defaults (same pattern,
# later set wins; MUST stay after engine load).
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' matcher-list 'm:{[:lower:]-}={[:upper:]_}'

# D-01/D-16: document first-char trigger; thousands-scale line cutoff.
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' list-lines 200

# D-08: Right-arrow accepts ghost, else moves cursor (fallback is built into
# the widget — safe by construction).
bindkey -M viins '^[[C' autosuggest-accept
bindkey -M viins '^[OC' autosuggest-accept

# D-06 alternative: buffer-preserving menu dismiss (Ctrl+C stays stock SIGINT).
bindkey -M menuselect '^G' send-break
```

### Legacy-rung expendable strip (0.44.1 path)

```zsh
# Source: /usr/share/doc/fzf/examples/key-bindings.zsh (binds ^T/^[c/^R in
# emacs+vicmd+viins unconditionally; zero Tab bindings — verified).
for _k in emacs viins vicmd; do
  bindkey -M "$_k" -r '^T'
  bindkey -M "$_k" -r '\ec'
done; unset _k
# ^R intentionally kept (D-10 non-negotiable).
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `zicompinit`/`zicdreplay` finalize block for Zinit | Engine-owned deferred `compinit` at first precmd; no finalize needed for non-turbo loads | Upstream engine design (current) | Dead block is deletable; restoring it adds nothing |
| `source /usr/share/fzf/key-bindings.zsh` everywhere | Version-branched: `fzf --zsh` (≥0.48) vs legacy path | fzf 0.48 (2024) | Keep the existing branch; apply per-rung disable mechanisms |
| Fuzzy-by-default matching accepted as-is | Explicit prefix-only override | This phase (D-21) | Intentional loss of typo-tolerance; document |

**Deprecated/outdated:**
- `min-delay` style: still honored as a `delay` alias in installed source, but README documents `delay` — use `delay`.
- Debian `doc/examples` rung: still the live path on apt fzf 0.44.1; not deprecated, just old.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `FZF_COMPLETION_TRIGGER=''` disables `**` Tab completion on the ≥0.48 rung | D-09/D-10 | Low — fallback is leaving the default trigger (needs explicit `**`, cannot clash with plain Tab); live-check on an Arch host decides |
| A2 | Stock `^C`/SIGINT aborts the ZLE line (buffer lost); no user-facing test of buffer loss performed this session | D-06 | Low — behavior is standard ZLE; live regression will show it; alternative (`^G`) documented regardless |
| A3 | D-21 override values (`completer _expand _complete _ignored`, case-insensitive-prefix `matcher-list`) preserve sane behavior for `sudo`/subscript/tilde contexts | D-21 | Medium — mitigated by Pitfall 4 + live judgment; fallback is re-adding `_correct` or narrowing pattern scope |
| A4 | `list-lines 200` renders without sticky lag on the user's terminal | D-16 | Low — fallback ladder 200→60→16 pre-agreed; `(MORE)` marker automatic |
| A5 | Right-arrow currently does NOT reliably accept (justifying the explicit bind) vs already-accepting via default `ACCEPT_WIDGETS` | D-08 | Negligible — bind is safe in both cases (fallback preserves movement); live test decides the comment wording |
| A6 | `↑` history-menu-on-keypress does not violate D-20 ("history behind Ctrl+R") | D-20 | Low — flagged as Open Question 1 for the live verdict |

## Open Questions

1. **Does `↑`-opened history menu violate D-20?**
   - What we know: engine stock binds ↑ to history-menu entry on explicit keypress; auto-show never includes history.
   - What's unclear: whether the user reads D-20 as "auto-show only" (recommendation) or "no history UI outside Ctrl+R" (would need `up-line-or-search` rebinds — touches stock arrows, conflicts with D-07).
   - Recommendation: keep stock; ask during live verdict; a `zstyle ':autocomplete:up-line-or-search:' ignore`-class kill-switch exists per-widget (`:autocomplete:<LASTWIDGET>: ignore`) if the user insists.

2. **Final `list-lines` number?**
   - Researcher pick: 200 with fallback ladder. User judges live (D-16 discretion).

3. **Result ordering (D-22)?**
   - Researcher pick: upstream stock `group-order`/`tag-order`. User judges feel live.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `zsh` | Engine (needs ≥5.8 recommended) | ✓ | 5.9 | — |
| `fzf` | Ctrl+R rung (legacy path live) | ✓ | 0.44.1 (Debian) | Warn-and-continue already in ladder |
| `git` | Zinit self-clone/update | ✓ | present | — |
| Live interactive terminal | D-13/D-14 verdict | pending | — | No fallback — user verdict closes phase |
| `gh` CLI | D-23 fallback research path | ✓ (2.45.0) | — | Not needed — Context7 + installed source sufficed; no GitHub queries issued |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none (fzf absence already handled by warn rung).

## Security Domain

`security_enforcement` is enabled; ASVS L1 applied to a shell-config phase (no new trust boundary, no network, no secrets):

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — (no auth surface; `stty` change rejected, preserving terminal job-control semantics) |
| V3 Session Management | No | — |
| V4 Access Control | No | — (`/etc/keyd` untouched; no privilege path in this phase) |
| V5 Input Validation | Partial | Prefix-only matcher *reduces* match surface; no new input parsing added; `bindkey -r` removals only shrink attack-adjacent key surface |
| V6 Cryptography | No | — (never hand-roll; nothing cryptographic here) |

### Known Threat Patterns for zsh-config changes

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious `precmd`/`chpwd` hook via pasted config | Tampering | Changes are reviewable single-file diffs in git; atomic-docs rule keeps them visible |
| `stty -isig`-style terminal hardening removal | Denial of service (loss of job control) | Explicitly rejected in this research (D-06) |

## Sources

### Primary (HIGH confidence — read this session)

- Installed engine source `~/.local/share/zinit/plugins/marlonrichert---zsh-autocomplete/Functions/Init/.autocomplete__{main,config,compinit,key-bindings,widgets,async}` + `Completions/_autocomplete__{history_lines,should_add_space,should_insert_unambiguous}` — knob enumeration, defaults, compinit ownership, key tables, `(MORE)` marker, accept-widget interplay
- Installed `zsh-users/zsh-autosuggestions` `src/{config,widgets,bind}.zsh` — `ACCEPT_WIDGETS` defaults, `_zsh_autosuggest_accept` fallback, wrap mechanism
- Installed `joshskidmore/zsh-fzf-history-search` `zsh-fzf-history-search.zsh:88-91` — `fzf_history_search` widget + `^r` bind (shadowed)
- On-disk `/usr/share/doc/fzf/examples/key-bindings.zsh` (fzf 0.44.1) — unconditional `^T`/`^[c`/`^R` binds, zero `^I` binds
- On-disk OMZL `completion.zsh` (78 lines) — no `compinit` call
- `zsh/.zshrc` (445 lines, this repo) — edit-site regions; `setup.sh:194-202` — installer already ships `fzf`+`zsh` on all families
- Local `zsh` probes: `terminfo[kcbt]=^[[Z]`, stock menuselect map (no `^[`/`^C`), `send-break` exists (zshzle man)

### Secondary (MEDIUM confidence — Context7 docs, cross-checked with source)

- Context7 `/marlonrichert/zsh-autocomplete` — delay/min-input/list-lines/add-space recipes (all confirmed in installed source)
- Context7 `/zsh-users/zsh-autosuggestions` API docs — `autosuggest-accept` original-widget fallback (confirmed in installed source)
- `github.com/junegunn/fzf` README via webfetch — `--zsh` key list (Ctrl-T/Ctrl-R/Alt-C), `FZF_*_COMMAND=` disable mechanism, `**` trigger system

### Tertiary (LOW confidence)

- None relied upon. GitHub-CLI fallback (D-23) not needed — no upstream issues/PRs consulted.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked by CONTEXT; install state verified on disk
- Knob enumeration + defaults: HIGH — read from installed source this session with verbatim quotes
- Keybinding/ownership analysis: HIGH — source + live `zsh` probes
- Docs cross-checks: MEDIUM — Context7 per `classify-confidence --provider context7` (MEDIUM, including `--verified`)
- Root-cause attribution: MEDIUM — stock config should auto-show; final confirmation needs the live terminal
- D-06 Ctrl+C / D-21 values / D-16 number / `**`-disable: LOW ([ASSUMED], flagged for live judgment)

**Research date:** 2026-09-17
**Valid until:** 30 days (stable domain — shell plugin config; re-check if engine updates via Zinit change installed source)
