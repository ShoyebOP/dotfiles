---
phase: 05-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp
plan: 01
subsystem: shell
tags: [zsh, zsh-autocomplete, zinit, fzf, compsys, vi-mode]

# Dependency graph
requires:
  - phase: 03-polished-shell-theme-local-overrides
    provides: Zsh spine with Ctrl+R live-passed, PATH dedup, HOME-only local overrides, and the deferred typing auto-show debt this phase fixes
provides:
  - fzf ladder evaluates before the autocomplete engine (last-writer-wins fix)
  - Ownership block after the engine: Tab/Ctrl+R split, prefix-only styles, min-input 1, list-lines 200, Right-arrow ghost-accept, Ctrl+G dismiss
  - Atomic docs (README five facts + local-example cutoff override) and live-judgment flags for the user verdict
affects: [04-editor-autonomy-verified-health, verify-work, ship]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 2459
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns: [ownership re-assertion after last writer, fzf ladder before engine, Why comments with D-IDs]

key-files:
  created: []
  modified: [zsh/.zshrc, README.md, zsh/.zshrc.local.example]

key-decisions:
  - "Keep marlonrichert/zsh-autocomplete as the engine — swap bar not met, bug is ordering/ownership not capability"
  - "Ladder-before-engine plus ownership-after-engine: fzf can never clobber engine widgets (last-writer-wins)"
  - "Prefix-only overrides sit after the engine load with intentional loss of typo-correction documented"
  - "Ctrl+C keeps stock SIGINT; buffer-preserving dismiss is Ctrl+G send-break in menuselect (closest-achievable D-06)"
  - "list-lines 200 with 60/16 fallback ladder; stock result ordering kept; user judges feel live"

patterns-established:
  - "Ownership re-assertion after the last writer: Tab/Ctrl+R binds live in one block after ALL plugin/fzf loads"
  - "Why comments cite D-IDs on every moved/deleted hunk so ordering constraints survive future edits"

requirements-completed: [SHEL-02]

# Coverage metadata (#1602) — one entry per shipped deliverable. Drives DETERMINISTIC UAT routing in verify-work.
coverage:
  - id: D1
    description: "fzf ladder evaluates before the engine; dead staged-modifiers ice and finalize block deleted"
    requirement: "SHEL-02"
    verification:
      - kind: other
        ref: "zsh -n zsh/.zshrc (exit 0)"
        status: pass
      - kind: other
        ref: "ladder header line 312 < engine load line 359"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ownership block after the engine: Tab/Ctrl+R split, prefix-only, min-input 1, list-lines 200, ghost-accept, Ctrl+G dismiss, expendable strips"
    requirement: "SHEL-02"
    verification:
      - kind: other
        ref: "zsh -n zsh/.zshrc (exit 0)"
        status: pass
      - kind: other
        ref: "ownership header line 362 > engine load line 359; both compsys overrides > engine"
        status: pass
      - kind: other
        ref: "comment-filtered absence gates: 0 hits for default-context, widget-style, fzf-completion, find-directories, stty, .accept-line"
        status: pass
    human_judgment: false
  - id: D3
    description: "Atomic docs: README five facts plus local-example cutoff override plus live-judgment flags"
    requirement: "SHEL-02"
    verification:
      - kind: other
        ref: "grep README five facts (auto-shows, Ctrl+R/fzf, prefix-only, MORE, Ctrl+G) — all present"
        status: pass
      - kind: other
        ref: "grep -c list-lines zsh/.zshrc.local.example == 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Live type-ahead feel: first-char auto-show, empty-prompt silence, ghost+list, Tab cycling, Enter select-then-edit, Esc/Ctrl+R, per-context probes"
    requirement: "SHEL-02"
    verification: []
    human_judgment: true
    rationale: "Requires a live interactive terminal per D-13 — headless bindkey/zle probes show stock defaults and cannot judge feel, lag, or ordering"

# Metrics
duration: 4min
completed: 2026-09-17
status: complete
---

# Phase 05 Plan 01: Real-time type-ahead completion Summary

**Marlonrichert engine restored to first-char auto-show via ladder-before-engine reorder plus after-engine ownership (prefix-only, ghost-accept, Ctrl+G dismiss) with atomic docs**

## Performance

- **Duration:** 4 min (213s)
- **Started:** 2026-09-17T16:55:03Z
- **Completed:** 2026-09-17T16:58:36Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Tracer slice: fzf degradation ladder relocated before the engine, engine atload simplified to single Tab menu-select, dead staged-modifiers ice and commented finalize block deleted, file parses clean
- Ownership block: Tab and Ctrl+R re-asserted last, prefix-only completer/matcher after engine, min-input 1 plus list-lines 200, viins Right-arrow ghost-accept, menuselect Ctrl+G dismiss, fzf expendables stripped per rung with Ctrl+R intact
- Atomic docs plus proof: README five-fact behavior text, local-example cutoff override (200 with 60/16 fallbacks), four live-judgment flags in the ownership region, ad-hoc diagnostic evidence recorded for the user live verdict

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer: fzf ladder before engine plus dead-code deletion, one coherent file end to end** - `13ae8ea` (fix)
2. **Task 2: Ownership block: prefix-only styles plus ghost-accept plus expendable strips** - `81dccb7` (feat)
3. **Task 3: Atomic docs plus ad-hoc proof suite and assumption flags** - `7432a04` (docs)

**Plan metadata:** pending final docs commit (this SUMMARY plus STATE/ROADMAP updates)

## Files Created/Modified

- `zsh/.zshrc` - Ladder-before-engine reorder, ownership block (styles + binds + strips), live-judgment flags; the single behavior edit site
- `README.md` - New `Zsh completion behavior (Phase 5)` five-bullet section (auto-show, split ownership, prefix-only, MORE marker, dismiss keys)
- `zsh/.zshrc.local.example` - Commented `list-lines` override example only (200 default, 60/16 fallbacks, gitignored note)

## Decisions Made

- Kept `marlonrichert/zsh-autocomplete` as the engine (D-19 swap bar not met — research shows stock defaults already cover D-01/D-02/D-03/D-05/D-20; bug is ordering/ownership)
- Ladder-before-engine plus ownership-after-engine as the ordering fix (last-writer-wins; fzf can never regress auto-show)
- Prefix-only overrides placed after the engine with intentional typo-correction loss documented (D-21)
- Ctrl+C keeps stock SIGINT; Ctrl+G send-break in menuselect is the buffer-preserving dismiss (D-06 closest-achievable; never rebind Ctrl+C, never touch Esc)
- list-lines 200 with 200→60→16 fallback ladder; stock result ordering kept (D-16/D-22 discretion; user judges live)
- Up-arrow history-menu kept stock per D-20-scope assumption (explicit keypress menu is not auto-show; user judges live)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Headless executor cannot run the live interactive spine: `zle -l | grep autocomplete` returns nothing headless and `bindkey ^I/^R` dumps show stock defaults (`expand-or-complete`, `redisplay`) because the full plugin stack only loads in an interactive ZLE session. Static proofs (zsh -n, line-order, presence/absence greps, style listings) are authoritative headless; the interactive feel items are deferred to the user live verdict per D-13 (see spine checklist below). Not a plan deviation — the plan anticipates this split.
- Strict fileset gate (`! git status --porcelain | grep -v '^ M (three paths)$'`) reports two extra pre-existing lines: `M .planning/STATE.md` (orchestrator phase-start state, uncommitted before this plan ran) and `?? .planning/phases/05-.../.gitkeep` (phase-dir placeholder). Task-only fileset is exactly the three allowed paths (`git status --porcelain -- zsh/.zshrc README.md zsh/.zshrc.local.example` shows only those three as M before their commits, clean after). Zero new files were created by this plan. Documented here so the verifier does not misread orchestrator state as plan scope creep.

## Diagnostic evidence (ad-hoc suite, read-only)

Headless run 2026-09-17; interactive-only probes noted where ZLE limits apply:

- `zsh -n zsh/.zshrc` → exit 0. **Meaning:** file parses clean after all three edits.
- `zle -l | grep -E 'autocomplete|autosuggest|fzf'` headless → no output, exit 0. **Meaning:** expected headless limit — engine widgets only register in an interactive ZLE session; not a failure. Live terminal should list `autocomplete`, `autosuggest`, and `fzf-history-widget` entries.
- `bindkey '^I'` headless → `"^I" expand-or-complete`; `bindkey '^R'` → `"^R" redisplay`; `bindkey -M viins '^[[C'` → `vi-forward-char`. **Meaning:** stock defaults without the plugin stack loaded; proves nothing about the ownership block headless. Authoritative proof is static: ownership binds are present at lines 368/371/393/394/400 and the ownership header (362) is after the engine load (359).
- `print -r -- "[${terminfo[kcbt]:-EMPTY}]"` → `[^[Z]`. **Meaning:** backtab sequence is available in this environment; the deleted redundant menuselect backtab line is safely covered by the engine's own binding.
- `zstyle -L` equivalent via grep (authoritative headless): `379: completer _expand _complete _ignored`, `380: matcher-list 'm:{[:lower:]-}={[:upper:]_}'`, `384: min-input 1`, `387: list-lines 200`. **Meaning:** all four real styles present and (by line numbers) after the engine load, so last-set-wins holds.
- Engine log tail (`~/.local/state/zsh-autocomplete/log/2026-09-17.log`) → `zshexit: write error: Input/output error` (also on 09-14; 09-10 shows `completion cannot be used recursively (yet)` ×2; other days empty). **Meaning:** no persistent async-worker crash signature; the `zshexit` line is a shell-exit artifact and the 09-10 recursion note predates this phase. If auto-show still fails live after this reorder, the log plus `zle -l` plus `zstyle -L` in the live session isolates pty vs config per RESEARCH suspect 5.
- Comment-filtered absence gates → `default-context: 0`, `widget-style: 0`, `fzf-completion: 0`, `find-directories: 0`, `history-context: 0`, `stty: 0`, `.accept-line: 0`, `reverse-menu-complete: 0`, `zsh-completions: 0`, `zicompinit: 0`, `zicdreplay: 0`. **Meaning:** dead code and all forbidden knobs confirmed absent.
- Line-order proofs → ladder 312 < engine 359 PASS; ownership 362 > engine 359 PASS; both compsys overrides (379/380) > engine PASS.
- `grep -c 'list-lines' zsh/.zshrc.local.example` → `1`. **Meaning:** exactly the one commented override example, no functional line added.
- `grep AGENTS.md` for `autocomplete|autosuggest|list-lines|menu-select` → 0 hits. **Meaning:** confirmed no interactive-completion behavior text lives in the generated AGENTS.md; correctly left unedited.

## D-14 spine checklist (live terminal — user verdict per D-13)

Static items verified headless (PASS); interactive feel items marked LIVE for the user:

- One-char auto-show (type 1 char → list appears): LIVE — user judges in live terminal
- Empty-prompt silence (fresh prompt → no popup): LIVE — user judges (stock default, no config)
- Ghost alongside list (ghost text visible with dropdown): LIVE — user judges (stock default)
- Tab enters menu; Tab / Shift-Tab / arrows cycle: LIVE — user judges (Tab re-asserted last, cycling stock)
- First Enter edits without executing; second Enter runs: LIVE — user judges (stock, no menuselect Enter bind added)
- Esc enters normal mode (stock vi): LIVE — user judges (Esc untouched, menuselect Esc count 0)
- Ctrl+R opens fzf history: LIVE — user judges (Ctrl+R re-asserted last, warn moved)
- Clean reload (`source ~/.zshrc` → no errors other than intended fzf-missing warn): LIVE — user judges (`zsh -n` PASS headless)
- D-04 per-context auto-show probes (each judged as stock-default live verdict): command name — LIVE; argument — LIVE; path — LIVE; mid-word — LIVE; after sudo — LIVE
- Open live-judgment flags for the verdict: (1) Up-arrow history-menu scope — LIVE; (2) final cutoff number 200 (fallbacks 60/16) — LIVE; (3) stock result ordering feel — LIVE; (4) native-rung trigger disable — LIVE

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for the user live terminal verdict that closes the phase per D-13 (spine checklist plus four flags above); on PASS, SHEL-02 carry-forward is fully closed including the deferred Phase-3 auto-show debt.
- Ready for Phase 4 health gates to pick up the fixed behavior when that phase runs (no dependency was taken on `--self-test` per D-13).
- No blockers; no new files to clean up; `~/.zshrc.local` override path documented for per-machine cutoff tuning.

## Self-Check: PASSED

- `zsh/.zshrc` FOUND; `README.md` FOUND; `zsh/.zshrc.local.example` FOUND
- Commits `13ae8ea`, `81dccb7`, `7432a04` all FOUND in `git log --all`
- Zero new files from this plan (task-only fileset exactly the three modified paths; repo-root untracked from plan: none)

---
*Phase: 05-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp*
*Completed: 2026-09-17*
