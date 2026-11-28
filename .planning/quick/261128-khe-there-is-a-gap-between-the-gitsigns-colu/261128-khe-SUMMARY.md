---
phase: "06"
plan: "261128-khe"
subsystem: nvim-editor-ui
tags: [neovim, gitsigns, statuscolumn, signcolumn, gutter, left-gutter]
requires: []
provides:
  - "Explicit native statuscolumn that packs the gitsigns sign slot against a raw line number"
affects: [nvim base options, gitsigns gutter rendering, future left-gutter work]
actuals:
  tokens: 142
  tasks: 2
  commits: 1
  plan_head_before: b426b9cd57ec30ce1e3ccc38630f172edacf6b1e
  plan_head_after: 139fd8b8799bf818f90cd6d585c48f9d55cfa44f
tech-stack:
  added: []
  patterns:
    - "Native per-line signs plus explicit statuscolumn using %s + raw v:lnum with a virtnum guard"
key-files:
  created: []
  modified:
    - nvim/.config/nvim/lua/base/options.lua
key-decisions:
  - "No textual revert exists: 887b97c and HEAD both carry signcolumn=yes / numberwidth=2 and gitsigns.lua is unchanged; the gap is Neovim's default status column layout"
  - "Use one explicit left-gutter statuscolumn string (%s%{v:virtnum>0 ? '' : v:lnum}) rather than a plugin, widened sign column, divider glyph, or right-side setting"
  - "Accept that an explicit statuscolumn drops default sign-column click callbacks as out of scope for this left-gutter-only fix"
patterns-established:
  - "Headless screenstring probe measures gutter blank-cell count before/after a display-only option change"
requirements-completed: [QOL-03]
duration: 5min
completed: 2026-11-28
status: complete
---

# Phase 06 Quick Task 261128-khe: Gitsigns Gutter Gap Summary

**Explicit native statuscolumn packs the gitsigns sign against the line number, cutting the measured left-gutter gap from three blank cells to one**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-28T08:53:30Z
- **Completed:** 2026-11-28T08:58:43Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added one explicit `opt.statuscolumn` line directly after `opt.signcolumn = "yes"` in `nvim/.config/nvim/lua/base/options.lua`, with a one-line rationale comment.
- Verified via headless `screenstring` probe on a 100-line buffer with a sign on line 2: `DEFAULT_GAP=3`, `SHIPPED_GAP=1` (sign glyph immediately followed by one blank cell then the number digit).
- Confirmed no surviving Phase-7 left-gutter delta: `signcolumn`, `numberwidth`, `gitsigns.lua`, dependency manifests, and right-side settings are untouched.
- Confirmed headless Neovim starts cleanly with the new config (`config-ok`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add an explicit tight left-gutter status column** - `139fd8b` (fix)
2. **Task 2: Confirm left-only scope and native-sign regression safety** - verification only, no edits (no commit)

**Plan metadata:** not applicable (standalone quick task; docs commit handled by orchestrator)

_Probe at `/tmp/opencode/gutter_gap_probe.lua` is temporary and was never committed._

## Files Created/Modified

- `nvim/.config/nvim/lua/base/options.lua` - one added comment line and one added `opt.statuscolumn` assignment; `signcolumn`/`numberwidth` values unchanged

## Decisions Made

- Treat the residual gap as a default-status-column layout artifact, not a surviving source edit, so no textual revert was attempted.
- Use the exact plan string `%s%{v:virtnum>0 ? '' : v:lnum}` so the native sign slot is retained, the number is raw (no right-aligned reserved padding), and wrapped virtual rows do not repeat the number.
- Keep scope strictly left-gutter: no gutter plugin, no widened sign column, no divider glyph, no right-side setting, no manifest change.

## Deviations from Plan

None - the source change, probe, and gates matched the plan exactly. Task 2's scope gate was evaluated against the committed diff (`git diff $PLAN_HEAD_BEFORE..HEAD`) rather than the uncommitted working-tree diff, because Task 1 was committed atomically per the executor protocol; all gate assertions otherwise matched the plan's `<automated>` block.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- QOL-03 delivered; left gutter now shows the native gitsigns sign followed by at most one blank cell before the number.
- No blockers. Live on-screen confirmation by the user remains optional; the authoritative headless probe passed both thresholds.

---
*Quick task: 261128-khe*
*Completed: 2026-11-28*

## Self-Check: PASSED

- Verified `nvim/.config/nvim/lua/base/options.lua` contains the exact `opt.statuscolumn` assignment.
- Verified commit `139fd8b` is an ancestor of HEAD and touches only `nvim/.config/nvim/lua/base/options.lua`.
- Verified temporary probe is outside the repo and untracked files are limited to `.planning/quick/`.
