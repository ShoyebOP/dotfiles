---
phase: 05-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp
verified: 2026-09-18T13:05:00Z
status: human_needed
score: 10/19 must-haves verified
behavior_unverified: 9
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 10/19
  gaps_closed:
    - "explicit (D-08): Right-arrow fallback dead key (WR-01) — wrapper widget present, registered before binds, both viins binds repointed, bare-widget binds at zero, branch logic proven headless"
    - "explicit (D-14): reload robustness (WR-02/WR-03/WR-04) — complist load guard plus suppressed menuselect bind, interactive-gated WARN (headless WARN count 1→0), widget-guarded Ctrl+R with stock fallback"
  gaps_remaining: []
  regressions: []
behavior_unverified_items:
  - truth: "explicit (D-01): typing the first character auto-shows the completion list below the prompt with no keypress"
    test: "In a live interactive terminal, type one character (e.g. `e`) and pause ~0.2s"
    expected: "Completion list renders below the prompt with no keypress"
    why_human: "Auto-show is an async line-pre-redraw engine behavior; headless `zle -l` shows nothing and bindkey dumps show stock defaults without the interactive plugin stack — static `min-input 1` + ladder order prove intent, not runtime render"
  - truth: "explicit (D-02): an empty prompt shows no list — nothing pops up until the first character is typed"
    test: "Open a fresh prompt and wait; then type one char"
    expected: "Fresh prompt stays quiet; list appears only after the first character"
    why_human: "Absence-of-render on idle; follows from 0 chars < min-input 1 by construction but needs a live eyeball"
  - truth: "explicit (D-03): ghost autosuggestion text and the dropdown list render simultaneously, each with its own accept key"
    test: "Type a prefix with both a history ghost and multiple completions visible"
    expected: "Ghost POSTDISPLAY text and the dropdown list coexist; Ctrl+Space/Right-arrow accepts ghost, Tab enters the list"
    why_human: "Co-rendering of two async display surfaces; no headless probe can judge visual coexistence"
  - truth: "stock-default (D-04): auto-show fires in every typing context — command name, argument, path, mid-word, after sudo (judged live)"
    test: "Probe one-char auto-show in each context: `e` (command), `ls --<pause>` (argument/flag), `ls /u` (path), mid-word after moving cursor left, `sudo apt i` (after sudo)"
    expected: "List auto-shows in all five contexts with sane stock candidates"
    why_human: "Per-context compsys behavior explicitly designated stock-default live verdict in CONTEXT D-04"
  - truth: "explicit (D-05): first Enter on a highlighted item selects it into the buffer for editing; only a second Enter executes"
    test: "Enter the Tab menu, highlight an item, press Enter once, then again"
    expected: "First Enter inserts into the buffer without executing; second Enter runs"
    why_human: "Menuselect keymap runtime behavior; static proof is only the absence of a menuselect ^M bind (count 0), which rules out the execute-on-first-Enter recipe but cannot demonstrate the two-step feel"
  - truth: "explicit (D-07): Tab cycles forward and Shift-Tab cycles back inside the menu; arrow keys also navigate"
    test: "Type a prefix, press Tab to enter the menu, then Tab / Shift-Tab / Up / Down"
    expected: "Tab moves forward, Shift-Tab moves back, arrows navigate; selection wraps sanely"
    why_human: "Interactive menu cycling feel; static proof is the re-asserted `bindkey '^I' menu-select` plus engine-stock cycling plus terminfo kcbt availability (^[[Z verified here)"
  - truth: "assumption (D-20-scope): Up-arrow opening the history menu on an explicit keypress does not violate the no-history rule"
    test: "Press Up-arrow on a non-empty prefix; compare against typing (auto-show must never contain history) vs Ctrl+R"
    expected: "User judges whether the explicit-keypress history menu is acceptable scope or a D-20 violation"
    why_human: "Scope judgment reserved to the user in RESEARCH A6; no grep can resolve intent"
  - truth: "explicit (D-08) live halves: with a ghost visible Right-arrow accepts the suggestion; with the suggestion cleared Right-arrow advances the cursor one char with no error"
    test: "In a live terminal, type a prefix until ghost text shows, press Right-arrow; then retype a non-matching prefix (or clear the line) and press Right-arrow"
    expected: "First press accepts the ghost text; second press moves the cursor one char right with no error output"
    why_human: "Headless proves the wrapper branch logic (zle stub: POSTDISPLAY-set→accept, empty/unset→forward-char) and the bindkey wiring, but real ZLE keypress dispatch with the live autosuggestions plugin setting POSTDISPLAY needs an interactive session per D-13"
  - truth: "explicit (D-14) live halves: interactive reload prints no errors; Ctrl+R opens fzf history on an fzf host and falls back to stock search plus a single yellow WARN on an fzf-less host"
    test: "Run `source ~/.zshrc` interactively; press Ctrl+R on this host; (if available) repeat on an fzf-less host"
    expected: "Reload prints zero errors; Ctrl+R opens fzf history here; fzf-less host keeps stock history-incremental-search-backward plus exactly one WARN"
    why_human: "Headless proves silent non-interactive reload (exit 0, zero WARN, zero keymap errors) and the guard structure, but interactive ZLE widget resolution and the fzf-less else path need live terminals per D-13"
human_verification:
  - test: "Type one character (e.g. `e`) and pause ~0.2s in a live terminal"
    expected: "Completion list renders below the prompt with no keypress"
    why_human: "Async line-pre-redraw engine render; headless probes show stock defaults only"
  - test: "Open a fresh prompt and wait; then type one char"
    expected: "Fresh prompt stays quiet; list appears only after the first character"
    why_human: "Absence-of-render on idle needs a live eyeball"
  - test: "Type a prefix with both a history ghost and multiple completions visible"
    expected: "Ghost text and dropdown coexist; Ctrl+Space/Right-arrow accepts ghost, Tab enters the list"
    why_human: "Co-rendering of two async display surfaces"
  - test: "Probe one-char auto-show in each D-04 context (command, argument, path, mid-word, after sudo)"
    expected: "List auto-shows in all five contexts with sane stock candidates"
    why_human: "Per-context compsys behavior designated live verdict in CONTEXT D-04"
  - test: "Enter the Tab menu, highlight an item, press Enter once, then again"
    expected: "First Enter inserts without executing; second Enter runs"
    why_human: "Menuselect runtime feel; static absence-proof cannot demonstrate two-step behavior"
  - test: "Type a prefix, press Tab, then Tab / Shift-Tab / Up / Down"
    expected: "Tab forward, Shift-Tab back, arrows navigate"
    why_human: "Interactive menu cycling feel"
  - test: "Press Up-arrow on a non-empty prefix; compare auto-show contents vs Ctrl+R"
    expected: "User judges whether the explicit-keypress history menu violates D-20"
    why_human: "Scope judgment reserved to the user (RESEARCH A6)"
  - test: "With ghost visible press Right-arrow; with suggestion cleared press Right-arrow"
    expected: "Ghost accepts; cleared suggestion advances cursor one char, no error"
    why_human: "Live ZLE keypress dispatch with the real autosuggestions plugin needs an interactive session (D-13); headless branch logic already proven"
  - test: "`source ~/.zshrc` interactively; press Ctrl+R here (and on an fzf-less host if available)"
    expected: "Zero reload errors; fzf history here; stock search plus one WARN without fzf"
    why_human: "Interactive widget resolution and the fzf-less else path need live terminals (D-13); headless silent reload already proven"
---

# Phase 05: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp Verification Report

**Phase Goal:** Typing the first character auto-shows the completion list with no keypress, while ghost text, Ctrl+R fzf history, Tab menu-select, and stock vi behavior stay intact (ROADMAP.md Phase 5)
**Verified:** 2026-09-18T13:05:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plan 05-02, commit 535a3ed)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | explicit (D-01): typing the first character auto-shows the completion list below the prompt with no keypress | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `zstyle ':autocomplete:*' min-input 1` :388 (after engine :359, last-wins holds); ladder-before-engine order proven (:312 < :359). Runtime render needs live terminal — see behavior items |
| 2 | explicit (D-02): an empty prompt shows no list | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Follows from 0 chars < min-input 1 by construction, zero config; needs live eyeball |
| 3 | explicit (D-03): ghost autosuggestion text and the dropdown list render simultaneously, each with its own accept key | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Engine stock default; co-render needs live eyeball |
| 4 | stock-default (D-04): auto-show fires in every typing context — command name, argument, path, mid-word, after sudo (judged live) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Stock default per RESEARCH; all five contexts need live probes |
| 5 | explicit (D-05): first Enter on a highlighted item selects it into the buffer for editing; only a second Enter executes | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Menuselect `^M`/`.accept-line` absence count 0 — execute-on-first-Enter recipe provably absent; two-step feel needs live press |
| 6 | explicit (D-06-Esc): Esc keeps 100% stock vi behavior (insert-to-normal) and is never rebound | ✓ VERIFIED | Comment-filtered menuselect `^[` count 0; zero `^C` binds; zero `stty`. No code path can alter Esc — absence fully proven (regression re-checked) |
| 7 | backstop (D-06-CtrlC): Ctrl+C keeps stock SIGINT semantics; the buffer-preserving menu dismiss is Ctrl+G (send-break) | ✓ VERIFIED | `bindkey -M menuselect '^G' send-break 2>/dev/null \|\| true` :417 confined to menuselect with load guard; `^C` binds 0, `stty` 0 (regression re-checked) |
| 8 | explicit (D-07): Tab cycles forward and Shift-Tab cycles back inside the menu; arrow keys also navigate | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `bindkey '^I' menu-select` re-asserted last :368; kcbt `^[[Z` available; cycling feel needs live press |
| 9 | explicit (D-08): Right-arrow in insert mode accepts ghost text when a suggestion is shown, else moves the cursor | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED (gap CLOSED headless) | Wrapper `autosuggest-accept-or-forward` :399-405 branches on `${POSTDISPLAY:-}` → `zle autosuggest-accept` / `zle vi-forward-char`; `zle -N` :406 precedes both viins binds :407-408; bare-widget viins binds 0; Why comment corrected. Branch proven live-logic headless via zle stub (set→accept, empty/unset→forward-char). Real keypress halves need live terminal — see behavior items |
| 10 | explicit (D-09/D-10): fzf never breaks autocomplete; expendable fzf extras are stripped, Ctrl+R history is intact | ✓ VERIFIED | Ladder :312 < engine :359; both legacy rungs strip `^T`/`\ec` across emacs/viins/vicmd; no strip touches `^R`; native-rung env-disable :328 (A1 live flag carried). Regression re-checked |
| 11 | explicit (D-12): all three plugins stay loaded with Ctrl+R owned by fzf and Tab owned by autocomplete | ✓ VERIFIED | `zsh-autosuggestions` + `fast-syntax-highlighting` + `marlonrichert` + `fzf-history-search` all present; ownership :362 > engine :359; `^I`→menu-select :368, `^R` inside widget-exists guard :374-375. Regression re-checked |
| 12 | explicit (D-14): shell spine regresses clean — auto-show, Ctrl+R, ghost, Tab menu-select, error-free reload | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED (gap CLOSED headless) | `zsh -n` exit 0; `zsh -c 'source ./zsh/.zshrc'` exit 0 with zero WARN (was 1 pre-fix) and zero `no such keymap` errors — silent headless reload behaviorally proven. `zmodload -i zsh/complist` :416 precedes suppressed menuselect bind :417; WARN gated on `[[ -o interactive ]]` :377; Ctrl+R bound only inside widget-exists guard (bind count 1, else path binds nothing). Interactive halves need live terminal — see behavior items |
| 13 | explicit (D-15): no vi motion key (hjkl, w/b, gg/G) is rebound | ✓ VERIFIED | Diff adds exactly `^I`, `^R`, two Right-arrow, `^G`-in-menuselect plus `^T`/`\ec` removals — zero motion keys. Regression re-checked |
| 14 | explicit (D-16/D-17): full untruncated list by default with a visible (MORE) hint when the line cutoff engages | ✓ VERIFIED | `list-lines 200` :391 after engine; `(MORE)` marker engine stock. Cutoff-number feel stays a live flag. Regression re-checked |
| 15 | explicit (D-20): the auto-show list never contains history; history stays behind Ctrl+R | ✓ VERIFIED | `default-context` 0, `history-context` 0 — history injection provably absent. Up-arrow scope stays a user judgment. Regression re-checked |
| 16 | explicit (D-21): candidates match by prefix only — no fuzzy-anywhere matching | ✓ VERIFIED | `completer _expand _complete _ignored` :383 and prefix-only `matcher-list` :384, both > engine :359. Regression re-checked |
| 17 | assumption (D-16-number): list-lines 200 feels lag-free; fallback ladder 200 to 60 to 16 if the live verdict reports lag | ✓ VERIFIED | 200 set :391; local-example carries commented override (`grep -c list-lines` == 1). Feel is a live flag. Regression re-checked |
| 18 | assumption (D-22): upstream stock result ordering is acceptable; user judges feel live | ✓ VERIFIED | `group-order`/`tag-order` absent — stock ordering kept. Regression re-checked |
| 19 | assumption (D-20-scope): Up-arrow opening the history menu on an explicit keypress does not violate the no-history rule | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Assumption A6 by design; routed to user judgment |

**Score:** 10/19 truths verified (9 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `zsh/.zshrc` | Ladder-before-engine reorder, dead-code deletions, after-engine ownership block (styles + binds + strips + wrapper + guards), live-judgment flags | ✓ VERIFIED | Exists (516 lines), substantive, wired. Ordering proofs PASS (:312 < :359 < :362; compsys :383/:384 > :359; `zle -N` :406 < binds :407/:408; `zmodload` :416 < menuselect :417; probe :374 < Ctrl+R :375). All presence gates PASS (4 styles, 3 plugins + history-search, `.local` guard, POSTDISPLAY branch, both `zle` call targets, `[[ -o interactive ]]`). All absence gates PASS (11/11 zero). `zsh -n` exit 0; headless source exit 0 silent. Both prior defects resolved — see Gaps Summary |
| `README.md` | Five-fact behavior text (auto-show, split ownership, prefix-only, MORE marker, dismiss keys) | ✓ VERIFIED | `#### Zsh completion behavior (Phase 5)` with all five bullets :140-144 (regression re-checked, untouched by 05-02) |
| `zsh/.zshrc.local.example` | Commented list-lines override example only | ✓ VERIFIED | `grep -c list-lines` == 1; zero functional lines (regression re-checked, untouched by 05-02) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| fzf ladder | autocomplete engine load | Evaluation order — ladder must run first (last-writer-wins) | ✓ WIRED | Ladder header :312 < engine `zi light marlonrichert` :359 |
| Prefix-only compsys overrides | engine fuzzy defaults | Same-pattern zstyle — later set wins, must sit after engine | ✓ WIRED | Both overrides :383/:384 > :359 |
| Right-arrow ghost-accept binds | vi-forward-char fallback | Wrapper registered with `zle -N` before both viins binds point at it | ✓ WIRED (headless; live keypress → human) | `zle -N` :406 < binds :407/:408; bare-widget viins binds 0; branch stub-test proves accept-vs-forward routing. Prior HOLLOW resolved |
| `zmodload` complist guard | menuselect Ctrl+G bind | Guard evaluated before the menuselect bind | ✓ WIRED | :416 < :417; isolated bare-shell snippet prints GUARD-OK exit 0 |
| Ctrl+R bind | fzf-history-widget existence | Bind lives inside the widget-exists guard, else stock preserved | ✓ WIRED | Probe :374 < bind :375; bind count 1; else path binds nothing |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| zsh/.zshrc ladder branch | `_fzf_ver` → version branch | System `fzf --version` | ✓ FLOWING | ✓ FLOWING — unchanged from prior verification |
| Ownership `^R` re-bind | `fzf-history-widget` at press time | Ladder-sourced widget, guarded by `zle -l` probe | ✓ WIRED | ✓ WIRED — main-map bind inside guard; else preserves stock |
| Ghost-accept fallback | `POSTDISPLAY` → accept-or-forward branch | In-memory suggestion variable set by zsh-autosuggestions | ✓ FLOWING | ✓ FLOWING — stub test: set→`zle autosuggest-accept`, empty/unset→`zle vi-forward-char`. Prior DISCONNECTED resolved |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| zsh syntax | `zsh -n zsh/.zshrc` | exit 0 | ✓ PASS |
| Wrapper branch: ghost shown | source rc, stub `zle`, `POSTDISPLAY=suggestion-text`, call wrapper | `ZLE-CALLED:autosuggest-accept` | ✓ PASS |
| Wrapper branch: ghost empty | `POSTDISPLAY=""`, call wrapper | `ZLE-CALLED:vi-forward-char` | ✓ PASS |
| Wrapper branch: ghost unset | `unset POSTDISPLAY`, call wrapper | `ZLE-CALLED:vi-forward-char` | ✓ PASS |
| Silent headless reload | `zsh -c 'source ./zsh/.zshrc'` | exit 0, zero WARN (pre-fix baseline was 1), zero `no such keymap` | ✓ PASS |
| Guarded menuselect snippet | `zsh -f -c "bindkey -M menuselect '^G' send-break 2>/dev/null \|\| true; echo GUARD-OK"` | GUARD-OK, exit 0 | ✓ PASS |
| Wrapper/bare-bind counts | wrapper name 4, `zle -N` 1, viins-wrapper binds 2, bare-widget viins binds 0 | all match | ✓ PASS |
| Ctrl+R guard counts | probe-before-bind order holds, fzf bind count 1 | match | ✓ PASS |
| Ladder/ownership order | 312 < 359 < 362; compsys 383/384 > 359 | PASS | ✓ PASS |
| Forbidden knobs absent | 11-token absence sweep + `^C`/`stty`/menuselect-`^[` | all 0 | ✓ PASS |
| README + local-example | five facts present; `grep -c list-lines` == 1 | PASS | ✓ PASS |
| Commits present | `git log --oneline` | `13ae8ea`, `81dccb7`, `7432a04`, `535a3ed` all present | ✓ PASS |
| Anti-patterns | `TBD/FIXME/XXX`, `TODO/HACK/PLACEHOLDER` in phase files | clean | ✓ PASS |

### Probe Execution

SKIPPED — no probes declared or implied for this phase (D-13 mandates ad-hoc commands only, zero harness/probe files; no `scripts/*/tests/probe-*.sh` exist).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SHEL-02 | 05-01, 05-02 | Ctrl+R fzf history without conflicts (carry-forward, no-regression) + typing auto-show fix | ⚠️ PARTIAL | Ctrl+R half intact and hardened (widget-exists guard, interactive-gated WARN, expendables stripped, `^R` kept). Right-arrow fallback and reload robustness gaps closed headless with behavioral spot-checks. Auto-show feel + all live halves pending user verdict per D-13 (9 behavior items). Prior Phase-3 Ctrl+R human PASS not regressed (no `^R` removal; warn moved and gated, not dropped) |

Orphaned requirements check: REQUIREMENTS.md maps SHEL-02 to Phase 3 (Complete); ROADMAP Phase 5 declares `Requirements: SHEL-02 (carry-forward, no-regression)`; both 05-01 and 05-02 PLAN frontmatter `requirements:` carry exactly `[SHEL-02]`; both SUMMARYs report `requirements-completed: [SHEL-02]`. Zero orphaned — every phase requirement ID is accounted for.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No `TBD`/`FIXME`/`XXX` in any phase-touched file | — | None — clean |
| — | — | No `TODO`/`HACK`/`PLACEHOLDER` in phase files | — | None — clean |
| — | — | No stub returns, empty handlers, or hardcoded-empty renders | — | None — config-only phase |

### Human Verification Required

9 items need live-terminal testing (7 carried from prior verification + 2 live halves of the closed gaps):

### 1. One-char auto-show

**Test:** Type one character (e.g. `e`) and pause ~0.2s in a live terminal
**Expected:** Completion list renders below the prompt with no keypress
**Why human:** Async line-pre-redraw engine render; headless probes show stock defaults only

### 2. Empty-prompt silence

**Test:** Open a fresh prompt and wait; then type one char
**Expected:** Fresh prompt stays quiet; list appears only after the first character
**Why human:** Absence-of-render on idle needs a live eyeball

### 3. Ghost-plus-list coexistence

**Test:** Type a prefix with both a history ghost and multiple completions visible
**Expected:** Ghost text and dropdown coexist; Ctrl+Space/Right-arrow accepts ghost, Tab enters the list
**Why human:** Co-rendering of two async display surfaces

### 4. Per-context auto-show (D-04)

**Test:** Probe one-char auto-show in each D-04 context (command, argument, path, mid-word, after sudo)
**Expected:** List auto-shows in all five contexts with sane stock candidates
**Why human:** Per-context compsys behavior designated live verdict in CONTEXT D-04

### 5. Enter select-then-edit (D-05)

**Test:** Enter the Tab menu, highlight an item, press Enter once, then again
**Expected:** First Enter inserts without executing; second Enter runs
**Why human:** Menuselect runtime feel; static absence-proof cannot demonstrate two-step behavior

### 6. Tab cycling (D-07)

**Test:** Type a prefix, press Tab, then Tab / Shift-Tab / Up / Down
**Expected:** Tab forward, Shift-Tab back, arrows navigate
**Why human:** Interactive menu cycling feel

### 7. Up-arrow history scope (D-20-scope)

**Test:** Press Up-arrow on a non-empty prefix; compare auto-show contents vs Ctrl+R
**Expected:** User judges whether the explicit-keypress history menu violates D-20
**Why human:** Scope judgment reserved to the user (RESEARCH A6)

### 8. Right-arrow live halves (D-08 gap closure)

**Test:** With ghost visible press Right-arrow; with suggestion cleared press Right-arrow
**Expected:** Ghost accepts; cleared suggestion advances cursor one char, no error
**Why human:** Live ZLE keypress dispatch with the real autosuggestions plugin needs an interactive session (D-13); headless branch logic already proven

### 9. Interactive reload + Ctrl+R halves (D-14 gap closure)

**Test:** `source ~/.zshrc` interactively; press Ctrl+R here (and on an fzf-less host if available)
**Expected:** Zero reload errors; fzf history here; stock search plus one WARN without fzf
**Why human:** Interactive widget resolution and the fzf-less else path need live terminals (D-13); headless silent reload already proven

Open live-judgment flags carried for the verdict: cutoff 200 vs 60/16 feel, stock ordering feel, native-rung `**` trigger on the Arch host (A1, untestable here on fzf 0.44.1), Up-arrow scope (item 7).

### Gaps Summary

Both prior gaps are CLOSED — no gaps remain. What changed (commit `535a3ed`, single-file `zsh/.zshrc` edit, verified headless above, not on trust):

1. **D-08 Right-arrow fallback (was FAILED, from WR-01) — CLOSED headless.** The wrapper `autosuggest-accept-or-forward` branches on `${POSTDISPLAY:-}`, is registered with `zle -N` before use, and both viins Right-arrow sequences point at it; bare-widget viins binds are at zero and the stale fallback claim in the Why comment is corrected. Beyond static counts, the branch invariant was executed headless via a `zle` stub: POSTDISPLAY-set routes to `autosuggest-accept`, empty/unset routes to `vi-forward-char`. The dead-key mechanism is gone; only the live keypress halves (real ZLE dispatch) stay with the user verdict per D-13.
2. **D-14 clean-reload robustness (was PARTIAL, from WR-02/WR-03/WR-04) — CLOSED headless.** `zmodload -i zsh/complist 2>/dev/null` plus a suppressed menuselect bind with `|| true` (isolated bare-shell snippet prints GUARD-OK, exit 0); the WARN probe is gated on `[[ -o interactive ]]` so a non-interactive source prints zero WARN (down from the pre-fix baseline of 1); Ctrl+R binds only inside the `zle -l … fzf-history-widget` guard with the else path binding nothing, preserving stock search on fzf-less hosts. A full headless `source` run exits 0 with zero WARN and zero keymap errors.

Not deferred: no later milestone phase covers zsh-autocomplete interactive feel (Phase 4 is EDIT-01/02/03 + HLTH-01), so closure had to happen here — and did, to the full extent headless execution allows.

The phase now closes per D-13 with the user live terminal verdict: the 9 behavior items above plus the 4 open live-judgment flags. SHEL-02 carry-forward (including the deferred Phase-3 auto-show debt) closes on that PASS. Status is `human_needed`, not `passed`, solely because interactive feel cannot be proven without a terminal — every automatable check passes.

---

_Verified: 2026-09-18T13:05:00Z_
_Verifier: the agent (gsd-verifier)_
