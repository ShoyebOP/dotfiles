---
phase: 07-neovim-editor-qol-fixes
plan: 03
subsystem: editor
tags: [neovim, kitty, keybindings, bufferline, terminal-encoding, documentation]

# Dependency graph
requires:
  - phase: 07-neovim-editor-qol-fixes
    provides: Phase-07 diagnostic float, dead-key cleanup, scrollview gutter fix (07-02), nvim-surround, and the original buffer-cycle wiring that headless maparg proved healthy
provides:
  - Buffer next/previous bound to Alt+comma / Alt+period, the only user-offered pair kitty's legacy encoding delivers
  - README caveat explaining kitty Ctrl+punctuation dropping and the insert-mode key-delivery test
affects: [07-neovim-editor-qol-fixes, G-07-2, QOL-05]

# Actuals (#2632) — chars/4 over the realized diff of the two changed files.
actuals:
  tokens: 814
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Neovim normal-mode lhs remap preserving rhs/desc/order exactly
    - ESC-prefixed Alt encoding (<M-,>/<M-.>) as the legacy-terminal-safe key form

key-files:
  created: []
  modified:
    - nvim/.config/nvim/lua/base/keymaps.lua
    - nvim/.config/nvim/README.md

key-decisions:
  - "Chose <M-,>/<M-.> (Alt+comma/Alt+period): kitty legacy Alt encoding prepends ESC so Neovim decodes it regardless of protocol negotiation; Ctrl+;/' drop Ctrl identically, Ctrl+[ is byte-identical to Escape, Ctrl+] is an existing builtin. This supersedes 07-CONTEXT.md scope item 5's original Ctrl+comma/Ctrl+period choice per the user's explicit UAT acceptance of alternative keys."
  - "Kept Tab/Shift+Tab free for completion and preserved the adjacent close-buffer map; changed only the two lhs values."
  - "Documented kitty as the primary terminal in the README with Alacritty retained only as a secondary case, matching the user's actual terminal."

patterns-established:
  - "Key-delivery bugs: prove editor-side maparg headlessly first, then fix at the terminal-encoding layer rather than adding terminal config."

requirements-completed: [QOL-05]

coverage:
  - id: D1
    description: "Next/previous buffer bound to <M-,>/<M-.> with the original BufferLineCycleNext/Prev rhs, desc and order; Tab/Shift+Tab and both old Ctrl+punctuation lhs values unbound"
    requirement: QOL-05
    verification:
      - kind: unit
        ref: "grep source gate -> BUFFER-ALT-SOURCE-OK"
        status: pass
      - kind: unit
        ref: "nvim --headless --clean -u NONE maparg probe -> BUFFER-ALT-OK"
        status: pass
      - kind: unit
        ref: "grep BufferLineCycleNext/Prev -> BUFFER-CMDS-INTACT"
        status: pass
    human_judgment: false
  - id: D2
    description: "Alt+comma / Alt+period actually switch buffers in the user's live kitty terminal"
    requirement: QOL-05
    verification: []
    human_judgment: true
    rationale: "No kitty binary exists in this headless environment, so terminal-to-Neovim delivery cannot be reproduced here; headless maparg proves only the editor side. End-of-phase UAT must confirm the keys in real kitty on >=2 buffers."
  - id: D3
    description: "README buffer-cycling caveat documents kitty's legacy Ctrl+punctuation drop, why the other offered combinations were rejected, and the insert-mode <C-v> delivery test"
    requirement: QOL-05
    verification:
      - kind: unit
        ref: "grep kitty/<M-,>/<M-.>/Alt -> KITTY-DOC-OK"
        status: pass
      - kind: unit
        ref: "grep -Fc '<C-,>'=0 plus <C-v> present -> STALE-CAVEAT-CLEAN"
        status: pass
    human_judgment: false

commits: 2
plan_head_before: 22efd1e58db4f359c5c8e5f6e17cf29667420b44
plan_head_after: f6358659d8d462f7d21e279dd7e8f8c02c162d9d

# Metrics
duration: 2min
completed: 2026-11-23
status: complete
---

# Phase 07 Plan 03: Neovim Editor QoL Fixes Summary

**Buffer next/previous rebound to Alt+comma / Alt+period (ESC-prefixed M-, / M-. keycodes) with a kitty-specific legacy Ctrl+punctuation delivery caveat in the Neovim README**

## Performance

- **Duration:** 2 min
- **Started:** 2026-11-23T14:03:18Z
- **Completed:** 2026-11-23T14:05:04Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Replaced the undeliverable `<C-,>` / `<C-.>` normal-mode buffer-cycle lhs values with `<M-,>` / `<M-.>` in `keymaps.lua`, preserving the `BufferLineCycleNext` / `BufferLineCyclePrev` rhs values, `desc` strings, order, and the adjacent close-buffer mapping.
- Proved the editor side headlessly: real `base.keymaps` loaded with repo rtp returns the correct cycle commands for both Alt keys, while `<Tab>`, `<S-Tab>`, and both old Ctrl+punctuation lhs values map to empty strings.
- Rewrote the README buffer-cycling section with kitty as the primary terminal: legacy Ctrl+punctuation dropping, why Ctrl+semicolon / Ctrl+apostrophe fail identically, why Ctrl+bracket is Escape and Ctrl+close-bracket is a builtin, and the insert-mode `<C-v>` delivery test; Alacritty retained as secondary.
- Left every other Phase-07 deliverable (diagnostic float, 07-02 gutter fix, dead-key cleanup, nvim-surround) untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): Rebind buffer cycling to Alt+comma / Alt+period, proven headlessly** - `8e69071` (fix)
2. **Task 2: Document kitty key delivery in the README caveat** - `f635865` (docs)

**Plan metadata:** final `docs(07-03): complete ... plan` commit (hash reported in completion output).

## Files Created/Modified

- `nvim/.config/nvim/lua/base/keymaps.lua` - two normal-mode buffer-cycle lhs values changed to `<M-,>` / `<M-.>`; rhs/desc/order preserved.
- `nvim/.config/nvim/README.md` - buffer-cycling section rewritten for kitty-inclusive key delivery and Alt bindings.

## Decisions Made

- Chose Alt+comma / Alt+period as the only user-offered pair kitty delivers reliably, superseding the original Ctrl+comma / Ctrl+period choice in 07-CONTEXT.md scope item 5 per the user's UAT acceptance.
- Preserved Tab / Shift+Tab as completion-only bindings and kept the close-buffer map intact.
- Made kitty the primary documented terminal; Alacritty remains a secondary note.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Live kitty delivery cannot be reproduced in this headless environment (no kitty binary); the plan explicitly defers that confirmation to end-of-phase UAT, and the headless maparg gates cover the editor side only.
- Pre-existing uncommitted `.planning/state.json` and untracked `.planning/milestone.lock` were left untouched; they are not part of this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All three Phase-07 plans now have summaries. Ready for end-of-phase UAT: in real kitty with >=2 buffers, press Alt+, / Alt+. and confirm next/previous buffer switching, then run `/gsd-verify-work 07`. No blockers from this plan.

## Self-Check: PASSED

- Both task commits present as ancestors of HEAD: `8e69071`, `f635865`.
- Changed source files exist: `nvim/.config/nvim/lua/base/keymaps.lua`, `nvim/.config/nvim/README.md`.
- All five plan verification markers printed OK: BUFFER-ALT-SOURCE-OK, BUFFER-ALT-OK, BUFFER-CMDS-INTACT, KITTY-DOC-OK, STALE-CAVEAT-CLEAN.

---
*Phase: 07-neovim-editor-qol-fixes*
*Completed: 2026-11-23*
