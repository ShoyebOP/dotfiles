---
phase: 04-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp
plan: 03
subsystem: shell
tags: [zsh, zsh-autocomplete, zasync, menuselect, stow, troubleshooting]

# Dependency graph
requires:
  - phase: 04-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp (04-02)
    provides: [shipped README ladder table, stray eviction, hand-repair runbook, live verdict FAIL carrying SHEL-02 auto-show + Tab forward]
provides:
  - One-shot precmd zasync stale-stub fixup hook in zsh/.zshrc (Gap 1 root-cause fix)
  - menuselect-keymap Tab to menu-complete binding per upstream recipe (Gap 2 fix)
  - README stale-registration troubleshooting paragraph with registration query and retire condition
  - Recorded upstream re-check states with keep-hook decision
  - Verbatim blocking-human live verdict closing the phase (overall PASS)
affects: [phase-04-editor-autonomy, future zsh-autocomplete upstream update]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 739
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns: [one-shot self-removing precmd fixup hook, menuselect-wins Tab layering]

key-files:
  created:
    - .planning/phases/04-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp/04-03-SUMMARY.md
  modified:
    - zsh/.zshrc
    - README.md

key-decisions:
  - "Keep the one-shot precmd hook as the shipped path — both upstream fix proposals still open, so no retire today"
  - "Release-tag pin stays fallback-only on observed live hook failure, never pre-pinned now"
  - "Phase closes on the verbatim overall-PASS live verdict with zero new harness files, zero setup.sh delta, zero nvim tree delta"

patterns-established:
  - "One-shot precmd fixup: stale stub is born at first precmd, so only a self-removing precmd hook converges; a load-time unfunction line is a silent no-op"
  - "Tab layering: atload bind plus post-ladder re-assert plus menuselect in-menu bind, with the fzf ladder clobbering Tab last"

requirements-completed: [SHEL-02, STOW-01]

coverage:
  - id: D1
    description: "One-shot precmd zasync fixup hook converges at first precmd; typing auto-shows the list with ghost coexisting"
    requirement: "SHEL-02"
    verification:
      - kind: other
        ref: "zsh -n zsh/.zshrc => syntax-ok; grep add-zsh-hook precmd _fix_zasync_once => hook-ok"
        status: pass
    human_judgment: true
    rationale: "Async auto-show timing is only observable in a live interactive terminal; static gates prove wiring, the human verdict proves behavior"
  - id: D2
    description: "menuselect Tab to menu-complete binding; Tab never ghost-accepts"
    requirement: "SHEL-02"
    verification:
      - kind: other
        ref: "grep bindkey -M menuselect.*menu-complete => menuselect-ok; tab-owned gate green"
        status: pass
    human_judgment: true
    rationale: "Key-ownership feel (Tab vs ghost, Right-arrow, l, Ctrl keys) requires a live terminal verdict"
  - id: D3
    description: "README stale-registration troubleshooting paragraph; stow end state untouched"
    requirement: "STOW-01"
    verification:
      - kind: other
        ref: "grep whence -v zasync + Retire after => trouble-ok; stow flags >= 7 => docs-ok; setup.sh clean => installer-untouched"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-09-23
status: complete
---

# Phase 04 Plan 03: Gap-Closure Slice Summary

**Upstream-grounded zasync stale-stub fixup hook plus missing menuselect Tab line, closed by an overall-PASS live terminal verdict**

## Performance

- **Duration:** 12 min (continuation: verify + SUMMARY + tracking)
- **Started:** 2026-09-22T17:31:26Z
- **Completed:** 2026-09-23T13:52:02Z
- **Tasks:** 3 (tracer + auto + blocking-human checkpoint)
- **Files modified:** 2 (zsh/.zshrc, README.md)

## Accomplishments

- Shipped the R-3 one-shot precmd fixup hook: clears any stubbed backend registration quietly, registers the cached backend file under the XDG cache path with HOME-cache fallback, then unregisters itself at first precmd
- Shipped the R-7 menuselect-keymap Tab to menu-complete binding with the upstream-recipe comment, after the post-ladder re-assert; atload Tab bind and kcbt line untouched
- Added the README stale-registration troubleshooting paragraph (symptom, `whence -v zasync` registration query, hook location, `Retire after` manager-update condition); key-ownership table and all stow one-liners byte-identical
- Re-checked upstream fix states before close and recorded the keep-hook decision
- Closed the phase on the user's verbatim overall-PASS live verdict with zero new harness files, zero setup.sh delta, zero nvim tree delta

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — end-to-end auto-show via one-shot precmd zasync fixup hook** - `b4d4dd5` (feat)
2. **Task 2: In-menu Tab line plus upstream re-check plus README troubleshooting note** - `eec13ac` (feat)
3. **Task 3: Checkpoint — live terminal verdict on the extended checklist** - overall PASS, no code change, recorded verbatim below

**Plan metadata:** SUMMARY + tracking commits follow (see Self-Check).

## Upstream Re-check (recorded per Task 2 acceptance criteria)

- **PR #903:** open
- **PR #905:** open
- **Issue #907:** open
- **Decision: keep-hook.** Both fix proposals are still open, so the Task 1 hook stays as the shipped path. The release-tag pin is fallback-only on observed live hook failure (exact pin ice syntax to be resolved from plugin-manager help at that time, never pre-pinned now). If either proposal shows merged in a future check, remove the hook block and retire via the manager update path instead. Retire sentence in README starts with the literal words `Retire after` per the plan contract.

## Live Verdict (verbatim, blocking-human checkpoint Task 3)

User response:

> perfect fully fixed and everything is working as intended

Overall verdict: **PASS** — no failed items named. Per the checkpoint contract (overall PASS with no failures named), every extended checklist item is recorded PASS:

1. Backend registration query + two Tab binds + helper presence probe — PASS
2. Double reload with no errors and no PATH duplicates — PASS
3. Type-pause-observe auto-show (command, argument, path, sudo, mid-word; empty prompt quiet; ghost plus list coexisting) — PASS
4. Tab with ghost visible opens/navigates the menu without inserting ghost text (D-29) — PASS
5. Right-arrow navigates with menu open / accepts ghost only when closed (D-32); vi-normal `l` accepts ghost (D-27/D-28); Ctrl+Space accepts; Ctrl+underscore executes — PASS
6. Ctrl+R opens fzf history; Ctrl+C dismisses; Enter selects-into-buffer first / runs second; Esc returns to normal mode — PASS
7. Config path is a real dir with only nvim linked; no new harness or probe file in git status beyond plan plus rc and README edits — PASS

Static gates re-confirmed green at SUMMARY time: syntax-ok, hook-ok, menuselect-ok, trouble-ok, installer-untouched.

## Files Created/Modified

- `zsh/.zshrc` - One-shot precmd `_fix_zasync_once` fixup block (upstream-issue retire comment, hook-helper load, stub clear + cached-file registration, self-unregister, precmd registration) inserted after the marlonrichert/zsh-autocomplete load and before the FZF ladder header; menuselect Tab to menu-complete line appended after the post-ladder Tab re-assert
- `README.md` - Stale-registration troubleshooting paragraph in the first-prompt blockquote (symptom, `whence -v zasync` query, hook location, `Retire after` condition)
- `.planning/phases/04-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp/04-03-SUMMARY.md` - This file (upstream states + verbatim verdict)

## Decisions Made

- Keep the local hook as the shipped path while both upstream proposals stay open; pin is fallback-only, never pre-pinned (see Upstream Re-check above)
- No plugin update, no eager init, no autosuggest-strategy or accept-widgets assignment, no core vi-motion rebinds this round — baseline preserved byte-identical per D-15/D-34 bounds
- STOW-01 stays closed with zero mutations: setup.sh and the nvim tree provably untouched

## Deviations from Plan

None - plan executed exactly as written. Tasks 1-2 commits (b4d4dd5, eec13ac) were verified present on disk and NOT redone by the continuation.

## Issues Encountered

None. The continuation resumed after the blocking-human PASS with no failed items to fix forward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 04 gap-closure slice complete: SHEL-02 auto-show half + D-29 Tab ownership verified live PASS; STOW-01 containment intact
- Watch item: a future upstream merge of PR #903/#905 retires the precmd hook via the manager update path (README `Retire after` condition states this)
- Ready for Phase 05 (Editor Autonomy & fzf-lua Migration) and Phase 06 (Verified Health) per ROADMAP (renumbered 2026-10-01: old Phase 05 → Phase 04)

## Self-Check

- [x] SUMMARY file exists at `.planning/phases/04-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp/04-03-SUMMARY.md`
- [x] Task commits exist: `b4d4dd5` FOUND, `eec13ac` FOUND
- [x] Scope check: working tree holds no setup.sh delta and no nvim tree delta from this plan
- [x] Static gates re-run green at SUMMARY time

**Self-Check: PASSED**

---
*Phase: 04-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp*
*Completed: 2026-09-23*
