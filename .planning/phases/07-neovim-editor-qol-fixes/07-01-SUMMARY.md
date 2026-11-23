---
phase: 07-neovim-editor-qol-fixes
plan: 01
subsystem: ui
tags: [neovim, lazy.nvim, keymaps, diagnostics, scrollview, gitsigns, nvim-surround, signcolumn]

requires: []
provides:
  - "On-demand rounded diagnostic float via built-in vim.diagnostic.open_float (<leader>vd)"
  - "Cleaned keymap surface: four uninstalled-plugin binding regions removed, which-key <leader>x group retitled to buffer"
  - "Far-left scrollview git gutter with hidden bar and a blank separator backed by signcolumn=yes:4"
  - "nvim-surround installed and pinned (v4.0.5 @ 2e93e154de9ff326def6480a4358bfc149d5da2c) with default ys/ds/cs/visual-S"
  - "Buffer cycling on <C-,>/<C-.> with terminal-delivery caveat documented"
  - "Cosmetic smoothscroll option removed"
affects: [07-neovim-editor-qol-fixes, future Neovim editor config phases, verify-work Phase 7]

actuals:
  tokens: 1679
  tasks: 3
  commits: 3

tech-stack:
  added: ["kylechui/nvim-surround v4.0.5 (40-hex pin 2e93e154de9ff326def6480a4358bfc149d5da2c)"]
  patterns: ["built-in-first diagnostics", "four-cell signcolumn gutter layout", "headless-lazy-generated lockfile pins"]

key-files:
  created:
    - nvim/.config/nvim/lua/plugins/surround.lua
    - nvim/.config/nvim/lazy-lock.json
  modified:
    - nvim/.config/nvim/lua/base/keymaps.lua
    - nvim/.config/nvim/lua/base/options.lua
    - nvim/.config/nvim/lua/plugins/scrollview.lua
    - nvim/.config/nvim/lua/plugins/which-key.lua
    - nvim/.config/nvim/README.md

key-decisions:
  - "QOL-01: built-in vim.diagnostic.open_float(scope=line, border=rounded, focusable=true) — no Trouble install, no diagnostic wrapping, no new hover binding (K already maps to vim.lsp.buf.hover)"
  - "QOL-03/QOL-06: signcolumn=yes:4 gives scrollview gutter | blank separator | native+gitsigns signs | numbers so the separator survives a shared line; smoothscroll removed as cosmetic cleanup only"
  - "QOL-03: scrollview base=left, column=1, winblend_gui=100 (hidden bar with termguicolors on), signs_on_startup={gitsigns}, signs_scrollbar_overlap=off; gitsigns contrib block untouched"
  - "QOL-04: generate the 40-hex pin from a real headless `Lazy! install nvim-surround` (tag v4.0.5), never hand-written"
  - "QOL-05: rebind only the lhs of the two BufferLine cycle maps to <C-,>/<C-.>; document insert-mode <C-v><C-,> test and Alacritty key_bindings caveat"
  - "QOL-02: delete exactly four dead binding regions by lhs, preserving section banners and neighboring gitsigns/TodoFzfLua/Bdelete maps"

patterns-established:
  - "On-demand diagnostics stay built-in: vim.diagnostic.open_float covers full-line messages without a plugin"
  - "Gutter cell budget: signcolumn=yes:4 reserves a blank separator between the scrollview gutter and combined native/gitsigns signs"
  - "Lockfile pins are generated, never fabricated: run headless lazy install from the repo root, then commit the resulting 40-hex commit"

requirements-completed: [QOL-01, QOL-02, QOL-03, QOL-04, QOL-05, QOL-06]

coverage:
  - id: D1
    description: "<leader>vd opens a full rounded line diagnostic float with no new plugin and no diagnostic wrapping"
    requirement: QOL-01
    verification:
      - kind: unit
        ref: "nvim --headless --clean -u NONE probe: VD-SOURCE-OK, VD-BEHAVIOR-OK, HOVER-UNCHANGED"
        status: pass
    human_judgment: false
  - id: D2
    description: "Four dead plugin binding regions removed and which-key <leader>x group retitled to buffer"
    requirement: QOL-02
    verification:
      - kind: unit
        ref: "grep/headless probes: DEAD-MAPS-CLEAN, SURVIVORS-OK, WK-LABEL-OK, WK-SPEC-OK"
        status: pass
    human_judgment: false
  - id: D3
    description: "Scrollview git markers in far-left gutter, transparent bar, blank separator via signcolumn=yes:4"
    requirement: QOL-03
    verification:
      - kind: unit
        ref: "headless probes: SCROLLVIEW-OPTS-OK, VD-BEHAVIOR-OK"
        status: pass
    human_judgment: false
  - id: D4
    description: "nvim-surround installed with default keymaps and a committed 40-hex lockfile pin"
    requirement: QOL-04
    verification:
      - kind: unit
        ref: "SURROUND-PIN-OK, SURROUND-SPEC-OK"
        status: pass
    human_judgment: false
  - id: D5
    description: "Buffer cycling on <C-,>/<C-.>, Tab/Shift-Tab freed, terminal caveat documented"
    requirement: QOL-05
    verification:
      - kind: unit
        ref: "BUFFER-MAPS-OK, CAVEAT-DOC-OK"
        status: pass
    human_judgment: false
  - id: D6
    description: "smoothscroll option removed as cosmetic cleanup"
    requirement: QOL-06
    verification:
      - kind: unit
        ref: "SMOOTH-CLEAN"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-11-23
status: complete
---

# Phase 07 Plan 01: Neovim Editor QoL Fixes Summary

**On-demand rounded diagnostic float, dead-key cleanup, far-left scrollview git gutter, pinned nvim-surround, and Tab-free buffer cycling delivered across seven config files with all 13 headless gates green**

## Performance

- **Duration:** 4 min
- **Started:** 2026-11-23T12:40:36Z
- **Completed:** 2026-11-23T12:44:24Z
- **Tasks:** 3 of 3 (1 tracer + 2 auto)
- **Files modified:** 7 (5 modified, 2 newly tracked)

## Accomplishments

- `<leader>vd` opens the full current-line diagnostic in a rounded, focusable float using the built-in API, with no diagnostic wrapping, no new hover binding, and no Trouble plugin.
- Removed all four dead binding regions (`<leader>sr`/grug-far, `<leader>ql`/persistence, `dv`/`<leader>dq`/`dh` Diffview trio, `<leader>xt`/`<leader>xT` Trouble pair) while preserving every banner and neighboring map; retitled the `<leader>x` which-key group to `buffer`.
- Relocated scrollview git markers to the far-left gutter (`base=left`, `column=1`) with a fully transparent bar (`winblend_gui=100`), gitsigns-only startup signs, and no scrollbar overlap; widened `signcolumn` to `yes:4` so a blank separator survives even when a native diagnostic sign and a gitsigns sign share a line.
- Installed `kylechui/nvim-surround` via a real headless lazy install (tag v4.0.5, commit `2e93e154de9ff326def6480a4358bfc149d5da2c`) and committed the generated 40-hex pin; default `ys`/`ds`/`cs`/visual `S` keymaps apply with zero extra mappings.
- Moved next/previous buffer cycling to `<C-,>`/`<C-.>` (Tab/Shift-Tab now free) and documented the insert-mode `<C-v><C-,>` delivery test plus the Alacritty `key_bindings` caveat.
- Removed `opt.smoothscroll = true` as a cosmetic cleanup only — no cursor-jump claims appear in any artifact.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): diagnostic float on demand plus gutter options end-to-end** - `5e4f704` (feat)
2. **Task 2: clean keymap surface and far-left scrollview git gutter** - `68514df` (refactor)
3. **Task 3: nvim-surround pin and buffer cycling on Ctrl-comma/Ctrl-period** - `a986fca` (feat)

**Plan metadata:** `docs(07-01): complete plan` (this SUMMARY commit; no STATE.md/ROADMAP.md edits — orchestrator owns those)

## Files Created/Modified

- `nvim/.config/nvim/lua/plugins/surround.lua` - new lazy spec for `kylechui/nvim-surround` (`version="*"`, `event="VeryLazy"`, `opts={}`)
- `nvim/.config/nvim/lazy-lock.json` - newly tracked lockfile carrying all 39 existing pins plus the generated nvim-surround 40-hex pin
- `nvim/.config/nvim/lua/base/keymaps.lua` - `<leader>vd` float mapping, four dead regions removed, buffer-cycle lhs changed to `<C-,>`/`<C-.>`
- `nvim/.config/nvim/lua/base/options.lua` - `signcolumn = "yes:4"` with four-cell comment; smooth-scroll assignment deleted
- `nvim/.config/nvim/lua/plugins/scrollview.lua` - far-left gutter options, hidden bar, gitsigns-only signs
- `nvim/.config/nvim/lua/plugins/which-key.lua` - `<leader>x` group retitled to `buffer`
- `nvim/.config/nvim/README.md` - Keymaps subsection with buffer-cycle caveat

## Decisions Made

All six locked scope decisions from `07-CONTEXT.md` were executed verbatim; no new product decisions were introduced. Cursor-jump investigation remained untouched and unmentioned except for the cosmetic smooth-scroll removal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Force-added the gitignored lockfile so the required pin is committed**
- **Found during:** Task 3 (nvim-surround pin)
- **Issue:** `.gitignore` lines 5 and 22 both ignore `nvim/.config/nvim/lazy-lock.json`, and the file was untracked in HEAD. The plan explicitly requires "a committed 40-hex lockfile pin" and says to "commit the new spec and updated lockfile together," so a normal `git add` was refused and the deliverable would not have landed in git.
- **Fix:** Ran `git add -f nvim/.config/nvim/lazy-lock.json` and committed it with the Task 3 files. No other tracked file or `.gitignore` rule was changed.
- **Files modified:** `nvim/.config/nvim/lazy-lock.json`
- **Verification:** `git ls-files` now lists the file; `SURROUND-PIN-OK` passes against the committed file; JSON validates and the pin matches the installed plugin HEAD.
- **Committed in:** `a986fca`

---

**Total deviations:** 1 auto-fixed (1 blocking). **Impact on plan:** Necessary to satisfy the plan's explicit committed-pin requirement; no scope creep and no config behavior change.

## Issues Encountered

None beyond the gitignored-lockfile conflict documented above (resolved automatically, no user input needed).

## User Setup Required

None - no external service configuration required. The nvim-surround plugin is installed locally under `~/.local/share/nvim/lazy/nvim-surround`; a fresh clone will install it on first `nvim` launch from the committed spec and lockfile pin.

## Verification Evidence

All 13 plan-level gates re-run after the final commit and passed: `VD-SOURCE-OK`, `VD-BEHAVIOR-OK`, `HOVER-UNCHANGED`, `SMOOTH-CLEAN`, `DEAD-MAPS-CLEAN`, `SURVIVORS-OK`, `WK-LABEL-OK`, `SCROLLVIEW-OPTS-OK`, `WK-SPEC-OK`, `SURROUND-PIN-OK`, `SURROUND-SPEC-OK`, `BUFFER-MAPS-OK`, `CAVEAT-DOC-OK` (13 passed, 0 failed). Self-check confirmed all 7 files exist, all 3 task commits are ancestors of HEAD, and the working tree is clean.

## Next Phase Readiness

Phase 07 Plan 01 is the only plan in Phase 7, so the phase's code work is complete and ready for the orchestrator's `/gsd-verify-work` UAT pass. Per dispatch, this executor did **not** edit `.planning/STATE.md` or `.planning/ROADMAP.md`; the orchestrator owns those updates and should advance Phase 7 to complete, mark QOL-01..QOL-06 requirements complete, and record the three task commits plus this metadata commit. ROADMAP still lists Phases 5 and 6 as unexecuted; that ordering is unchanged by this work. No blockers or carry-forward defects were left open.

---
*Phase: 07-neovim-editor-qol-fixes*
*Completed: 2026-11-23*

## Self-Check: PASSED
