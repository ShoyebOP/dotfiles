---
phase: 07-neovim-editor-qol-fixes
plan: 04
subsystem: ui
tags: [neovim, scrollview, gitsigns, signcolumn, gutter, gap-closure, supersession]

# Dependency graph
requires:
  - phase: 07-neovim-editor-qol-fixes
    provides: "The far-left marker + divider gutter built by 07-01/07-02 (G-07-1), which the user rejected in UAT gap G-07-4"
provides:
  - "Native per-line gitsigns as the only git indicator in the gutter — no plugin spec, no pin, no marker column, no divider float, no widened signcolumn"
  - "G-07-4 supersession recorded in research, requirements, roadmap, state and verification artifacts so future verification does not re-assert the abandoned layout"
affects: [07-neovim-editor-qol-fixes, G-07-4, QOL-03, verify-work Phase 7]

# Actuals (#2632) — chars/4 over the realized diff of the files changed by this plan.
actuals:
  tokens: 13362
  tasks: 3
  commits: 3
  plan_head_before: 5ca15964334f05fa730773572c835df34786c4db
  plan_head_after: 854f005e4da7fb0eaecd20d06aea4384ef1e4182

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Abandoned-layout gap closure by deletion, not iteration: spec + pin + option removed together"
    - "Decision supersession recorded in every artifact that would otherwise drive a stale re-verification"
    - "Supersession report without a new PASS — behavioral verdict deferred to end-of-phase UAT"

key-files:
  created: []
  modified:
    - nvim/.config/nvim/lua/plugins/scrollview.lua (deleted)
    - nvim/.config/nvim/lua/base/options.lua
    - nvim/.config/nvim/lazy-lock.json
    - .planning/phases/07-neovim-editor-qol-fixes/07-RESEARCH.md
    - .planning/phases/07-neovim-editor-qol-fixes/07-VERIFICATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "G-07-4: the far-left git-marker column plus one-pixel divider gutter was abandoned entirely as unachievable with the pinned nvim-scrollview and Neovim signcolumn model; the plugin was deleted rather than iterated on"
  - "G-07-4: signcolumn reverted from the reserved-cell width to the plain default `yes`, with no gutter-layout comment, so native signs and gitsigns use stock sign slots"
  - "G-07-4: the scrollview lazy-lock pin was removed while the nvim-surround pin and all other pins stayed byte-identical; no lazy sync was run"
  - "G-07-4 supersedes both G-07-1 gutter decisions in STATE.md and the ROADMAP goal/gutter success criterion; research, requirements and verification now describe native per-line gitsigns only"
  - "07-VERIFICATION.md was rewritten as a supersession record, not a new PASS: gutter-layout rows, artifacts and key links are retired and the orchestrator must re-verify the new end state"

requirements-completed: [QOL-03]

coverage:
  - id: D1
    description: "The gutter plugin is fully absent from the shipped configuration: no spec file, no lockfile pin, no module reference"
    requirement: QOL-03
    verification:
      - kind: unit
        ref: "SCROLLVIEW-SPEC-GONE; LOCKFILE-CLEAN (nvim-scrollview count 0, nvim-surround count 1, JSON.parse passes); no scrollview reference anywhere in shipped nvim config"
        status: pass
    human_judgment: false
  - id: D2
    description: "signcolumn is the plain default with no reserved-cell count and no gutter-layout comment; headless Neovim loads cleanly"
    requirement: QOL-03
    verification:
      - kind: unit
        ref: "SIGNCOLUMN-DEFAULT; GUTTER-NATIVE-ONLY-OK (headless assert vim.o.signcolumn == 'yes'); CONFIG-LOAD-OK"
        status: pass
    human_judgment: false
  - id: D3
    description: "In kitty, a changed file shows only native per-line gitsigns — no far-left marker column, divider glyph or wide empty gap — and native diagnostic signs still render with gitsigns on a shared line"
    requirement: QOL-03
    verification: []
    human_judgment: true
    rationale: "No kitty binary exists in this headless environment. Per human_verify_mode = end-of-phase, the gutter visual check is harvested by the orchestrator's end-of-phase UAT, not asserted here."
  - id: D4
    description: "Research, requirements, roadmap and state record the G-07-4 decision and no stale gutter-layout claim is presented as current"
    requirement: QOL-03
    verification:
      - kind: unit
        ref: "RESEARCH-SUPERSEDED; REQUIREMENTS-REFRAMED; ROADMAP-REFRAMED; STATE-SUPERSEDED (G-07-4 citation present, stale-option/layout-phrase counts 0)"
        status: pass
    human_judgment: false
  - id: D5
    description: "07-VERIFICATION.md retires the abandoned layout verdicts without claiming a premature PASS for the removal"
    requirement: QOL-03
    verification:
      - kind: unit
        ref: "VERIFICATION-REFRAMED (G-07-4 cited, retired gate-label count 0); supersession note and RETIRED rows present"
        status: pass
    human_judgment: false
  - id: D6
    description: "The passing Phase-07 deliverables remain byte-intact against HEAD"
    requirement: QOL-03
    verification:
      - kind: unit
        ref: "PRESERVED-BYTE-INTACT (git diff --quiet HEAD -- keymaps.lua, which-key.lua, surround.lua, README.md)"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-11-23
status: complete
---

# Phase 07 Plan 04: Neovim Editor QoL Fixes — G-07-4 Gutter Layout Abandonment Summary

**The far-left scrollview marker and one-pixel divider gutter were deleted end-to-end — spec, pin and widened signcolumn — leaving only native per-line gitsigns, with every artifact that claimed the rejected layout rewritten as a G-07-4 supersession record**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-23T15:50:50Z
- **Completed:** 2026-11-23T15:56:31Z
- **Tasks:** 3 of 3 (1 tracer + 2 auto)
- **Files changed:** 8 (1 deleted, 7 modified)

## Accomplishments

- Deleted `nvim/.config/nvim/lua/plugins/scrollview.lua` in full (105 lines): lazy spec, setup options, highlight re-assertion autocmds, gitsigns contrib registration and the divider float with all its autocmds. No reduced or commented-out spec remains, so lazy.nvim never provisions the plugin on a fresh clone.
- Reverted `options.lua` line 12 from the reserved-cell signcolumn and its gutter-layout comment to the plain stock default `opt.signcolumn = "yes"`. All other editor options (number, numberwidth, fillchars, smoothscroll's absence, editor behavior) are untouched.
- Removed only the `nvim-scrollview` pin from `lazy-lock.json`; the file still parses as JSON, the `nvim-surround` pin and every other pin are byte-identical, and no lazy sync was run.
- Reframed `07-RESEARCH.md`, `REQUIREMENTS.md` (QOL-03), `ROADMAP.md` (Phase 7 goal, gutter success criterion and historical plan descriptions) and `STATE.md` (new G-07-4 decision, both G-07-1 gutter decisions marked superseded, roadmap-evolution note) around the native-gitsigns-only outcome.
- Rewrote `07-VERIFICATION.md` as a supersession record: retired the opaque-marker and divider-layout verdicts, removed the plugin from the required-artifact and key-link tables, replaced the gutter human-check with a native-gitsigns-only check, and made no new PASS claim for the removal.
- Kept the four byte-intact Phase-07 deliverables untouched: the diagnostic float and dead-key cleanup in `keymaps.lua`, the which-key group label, the kitty README caveat, and the nvim-surround spec and pin.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): remove the gutter plugin and restore native-only gutter end-to-end** — `a112470` (fix)
2. **Task 2: reframe phase research, requirements, roadmap, and state around the user's decision** — `0244dcd` (docs)
3. **Task 3: retire stale layout verdicts from the phase verification report** — `854f005` (docs)

**Plan metadata:** final `docs(07-04): complete ... plan` commit (this SUMMARY plus STATE/ROADMAP/REQUIREMENTS position updates).

## Files Created/Modified

- `nvim/.config/nvim/lua/plugins/scrollview.lua` — deleted in full; no plugin spec, marker config or separator float remains
- `nvim/.config/nvim/lua/base/options.lua` — signcolumn reverted to the plain default `yes`; gutter-layout comment deleted
- `nvim/.config/nvim/lazy-lock.json` — `nvim-scrollview` pin removed; `nvim-surround` pin and all others retained; valid JSON
- `.planning/phases/07-neovim-editor-qol-fixes/07-RESEARCH.md` — obsolete Scrollview relocation findings replaced with the G-07-4 abandonment note
- `.planning/REQUIREMENTS.md` — QOL-03 rewritten to the native-per-line-gitsigns-only assertion, citing G-07-4
- `.planning/ROADMAP.md` — Phase 7 goal and gutter success criterion reframed; 07-02/07-03 plan descriptions marked superseded/current as appropriate
- `.planning/STATE.md` — G-07-4 decision added; two G-07-1 gutter decisions marked superseded; roadmap-evolution note updated
- `.planning/phases/07-neovim-editor-qol-fixes/07-VERIFICATION.md` — stale layout verdicts retired as a supersession record, not a new PASS

## Decisions Made

- Recorded the user's G-07-4 decision: the far-left marker + divider gutter is impossible with the pinned plugin and Neovim signcolumn model, so the layout was abandoned rather than iterated on. This supersedes both G-07-1 decisions previously logged in STATE.md.
- Chose deletion over a reduced/disabled spec so a fresh clone cannot provision the plugin, and reverted signcolumn to the stock default so no layout-only option survives.
- Wrote the verification update as a supersession record deliberately: the orchestrator regenerates 07-VERIFICATION.md after this plan, so claiming a new PASS here would be premature.
- No new product decisions beyond faithfully executing the user's reversal; cursor-jump investigation remained untouched and unmentioned.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The tracer task's `<verify>` carries a `<human-check>` for the kitty gutter. Per the plan's own `<verification>` section and `human_verify_mode = end-of-phase`, that visual check is harvested at end-of-phase UAT rather than halting this autonomous gap-closure plan mid-flight; no kitty binary exists in this environment. The check was rewritten to the native-gitsigns-only expectation in both `07-VERIFICATION.md` and this SUMMARY's coverage block (D3).
- `gsd_run` was not on this shell's PATH; GSD CLI verbs were invoked via the shipped launcher at `/home/shoyeb/.config/opencode/gsd-core/bin/gsd_run`. No behavior or artifact was affected.
- Pre-existing working-tree changes (`.planning/config.json`, `.planning/state.json`, untracked `.planning/milestone.lock`) were left untouched; they are orchestrator dispatch state, not part of this plan.

## User Setup Required

None - no external service configuration required. The plugin removal is a local config change; a fresh clone will no longer install nvim-scrollview because its spec and pin are gone.

## Known Stubs

None.

## Threat Flags

None. All registered mitigations were applied: T-07-07 (file-absence + lockfile gates), T-07-08 (headless signcolumn assertion), T-07-09 (per-artifact G-07-4 citations and no premature PASS), T-07-SC (no package install occurred). No new network endpoint, auth path, file-access pattern or trust-boundary schema was introduced; the change removes a plugin.

## Verification Evidence

All 11 plan-level gates re-run after the final task commit and passed: `SCROLLVIEW-SPEC-GONE`, `LOCKFILE-CLEAN`, `SIGNCOLUMN-DEFAULT`, `GUTTER-NATIVE-ONLY-OK`, `RESEARCH-SUPERSEDED`, `REQUIREMENTS-REFRAMED`, `ROADMAP-REFRAMED`, `STATE-SUPERSEDED`, `VERIFICATION-REFRAMED`, `PRESERVED-BYTE-INTACT`, `G-07-4-CLOSED`. Additional checks: headless `CONFIG-LOAD-OK`; no scrollview reference remains in the shipped nvim config; all four preserved Phase-07 files are byte-identical to HEAD. G-07-4 is closed at the automated/config level; the user-visible gutter result remains an end-of-phase human check.

## Next Phase Readiness

Gap G-07-4 is closed at the configuration and artifact level. The orchestrator should regenerate 07-VERIFICATION.md against the native-gitsigns-only end state and run `/gsd-verify-work 07` to harvest the rewritten gutter human check (and the unchanged kitty Alt-buffer-cycle check). No blockers or carry-forward defects were left by this plan.

---
*Phase: 07-neovim-editor-qol-fixes*
*Completed: 2026-11-23*

## Self-Check: PASSED

- All 7 expected files exist on disk; the deleted `scrollview.lua` is confirmed absent.
- All 3 task commits (`a112470`, `0244dcd`, `854f005`) are ancestors of HEAD.
- All 11 plan-level gates and the self-check file/commit checks passed.
- No stubs introduced; no new threat surface; the four byte-intact Phase-07 deliverables are unchanged against HEAD.
