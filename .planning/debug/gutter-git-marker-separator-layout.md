---
status: diagnosed
trigger: "Investigate issue: gutter-git-marker-separator-layout — scrollview git markers do not render; gutter column order is wrong. Expected far-left git markers (col 1), a very thin 1-pixel solid line separator, then per-line gitsigns. Actual: no git markers at all; per-line gitsigns at far left, then a big empty space, then line numbers, then text."
created: 2026-11-23T13:11:12Z
updated: 2026-11-23T13:18:43Z
mode: find_root_cause_only
---

## Current Focus

status: ROOT CAUSE CONFIRMED — diagnosis-only mode, no fix applied
bug_class: Bohrbug (deterministic; reproduced headlessly with the exact deployed config and pinned plugin)
known_pattern_candidate: none (no `.planning/debug/knowledge-base.md` exists; no prior resolved session matched)
root_cause_summary: >
  Three interacting config/assumption defects in the Phase-07 gutter implementation:
  (1) scrollview gitsign marker sign windows are never created because `base='left', column=1`
  combined with the plugin's default `signs_overflow='left'` and `signs_scrollbar_overlap='off'`
  computes a negative/zero screen column that `is_valid_column()` rejects;
  (2) `winblend_gui=100` is applied by this pinned nvim-scrollview to BOTH the scrollbar AND the
  sign windows (there is no separate signs-winblend option), so even created signs would be fully
  transparent on Neovim 0.12 (the old v<0.12 workaround that forced winblend=0 for non-blank glyphs is skipped);
  (3) `signcolumn='yes:4'` was chosen on the false assumption that Neovim right-aligns signs and leaves
  a blank separator cell on the LEFT — Neovim actually LEFT-aligns signs, so the 3 extra reserved cells
  appear as a large blank gap to the RIGHT of the native gitsigns sign, before the line numbers.
  Additionally, a true 1-pixel solid-line separator is impossible via signcolumn cells (character cells, not pixels),
  and the contrib.gitsigns.setup() call passes three option names the module does not recognize.
test: differential headless probes (A/B/C/D/E) isolating each variable; clean signcolumn probes
expecting: confirmed root cause (achieved)
next_action: return ROOT CAUSE FOUND to orchestrator; do NOT apply fix (find_root_cause_only mode)

## Symptoms

expected: scrollview git markers render in far-left gutter (column 1), scrollbar invisible (winblend_gui=100), blank separator cell before gitsigns native per-line signs, separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4). User's desired layout: git markers at far left, a very thin ONE-PIXEL SOLID LINE separator, then per-line gitsigns.
actual: "no the whole thing is wrong, first i don't see any git markers, the perline gitsigns is in the far left currently, after that there is a big empty space then line numbers and then text. what i wanted was git markers to the far left a very thin one pixel solid line separator, then perline gitsigns"
errors: None reported
reproduction: Test 1 in UAT — open a git-tracked file with uncommitted changes in a terminal with nvim (user actually uses kitty, not Alacritty) and inspect the left gutter.
started: Discovered during UAT for Phase 07 (neovim-editor-qol-fixes), 2026-11-23.
ambiguity_note: The quote "btw i was talking about only the keys not the text itself" appears in UAT Test 2 (buffer-cycling keys <C-,>/<C-.>), NOT Test 1 (gutter). It was included in the objective's symptoms summary, likely by conflation. It does not bear on the gutter layout root cause. Also "text itself" vs "kitty terminal" indicates the user corrected the terminal assumption (kitty, not Alacritty) — environment note, not a gutter-layout cause. The gutter fault reproduced headlessly and is terminal-independent.

## Eliminated

- hypothesis: gitsigns plugin not attaching / no hunks computed, so there is nothing for scrollview to draw
  evidence: Headless probe with the deployed config reported `gitsigns_loaded=true`, `hunks_count=2` on the 200-line fixture with two modified lines. Hunks exist; the fault is downstream.
  timestamp: 2026-11-23T13:14:00Z
- hypothesis: sign group 'gitsigns' disabled at startup / signs_on_startup misconfigured
  evidence: Probe read `scrollview_enabled=true`, `scrollview_signs_on_startup={"gitsigns"}`, `scrollview_signs_scrollbar_overlap="off"`; contrib calls `scrollview.register_sign_group('gitsigns')` + `set_sign_group_state(group, enabled=true)`. Group is active.
  timestamp: 2026-11-23T13:14:00Z
- hypothesis: terminal difference (kitty vs Alacritty / TERM value) causes the missing markers
  evidence: Reproduced deterministically in headless nvim with no real terminal involved; it is a geometry/opacity config fault, not terminal delivery. (Terminal caveat applies only to UAT Test 2 buffer keys.)
  timestamp: 2026-11-23T13:16:00Z
- hypothesis: the invisible markers are caused solely by winblend_gui=100 (single cause)
  evidence: With the shipped `signs_overflow='left'`, `column=1`, **zero** sign windows are created at all, so opacity is not even reached. Flipping only `signs_overflow` to 'right' creates a sign window whose winblend is 100 — showing opacity is a second, independent defect. Both must be addressed.
  timestamp: 2026-11-23T13:17:00Z

## Evidence

- timestamp: 2026-11-23T13:12:00Z
  checked: Phase 07 planning artifacts (07-CONTEXT.md, 07-RESEARCH.md, 07-01-SUMMARY.md) and config files (scrollview.lua, gitsigns.lua, base/options.lua)
  found: Intended layout is `[scrollview git markers col1][blank separator col2][native diag/gitsigns cols3-4][numbers][text]` via `signcolumn='yes:4'`; RESEARCH explicitly claims "Neovim right-aligns signs in a widened signcolumn" and that yes:4 guarantees a blank cell left of the signs. Config ships `base='left', column=1, winblend_gui=100, signs_on_startup={'gitsigns'}, signs_scrollbar_overlap='off'` and `contrib.gitsigns.setup({show_in_folds=true, current_only=true, priority=10})`.
  implication: The entire design rests on an unverified assumption about Neovim sign alignment and on plugin defaults that were never inspected.
- timestamp: 2026-11-23T13:13:00Z
  checked: nvim-scrollview source at pinned commit b9e6ee00 (matches lazy-lock.json), `autoload/scrollview.vim` defaults and `lua/scrollview.lua` draw code
  found: Defaults are `signs_overflow='left'`, `signs_scrollbar_overlap='off'`, `winblend_gui=0`, `column=1`, `base='right'`. In `draw_signs()` (lua/scrollview.lua:1951-1978): `base_col=calculate_scrollbar_column(winid)`; with `base='left', column=1` this is 1; with bar on row, `total_width=1`; with `signs_overflow='left'` the sign col becomes `base_col - total_width - sign_width + 1 = 1 - 1 - 1 + 1 = 0`. `is_valid_column()` (line 1318) rejects `col < min_valid_col(1)` → sign never drawn.
  implication: This is the direct mechanism for "no git markers at all" — the markers are computed off-screen and filtered out.
- timestamp: 2026-11-23T13:13:30Z
  checked: nvim-scrollview sign/bar window winblend code (lua/scrollview.lua:1662-1682 and 2104-2127)
  found: Both the bar window and the sign windows read `vim.g.scrollview_winblend_gui` when `termguicolors` is on (true here). There is NO separate signs-winblend option in this version. The workaround at lines 2119-2126 that sets `winblend=0` for non-blank sign glyphs is guarded by `if not has('nvim-0.12')` and is skipped on installed Neovim v0.12.2.
  implication: `winblend_gui=100` makes the sign markers 100% transparent as well as the bar — a second independent reason the markers are invisible.
- timestamp: 2026-11-23T13:14:00Z
  checked: `lua/scrollview/contrib/gitsigns.lua` option list vs the call in `lua/plugins/scrollview.lua`
  found: Valid contrib options are `enabled`, `hide_full_add`, `only_first_line`, `add/change/delete_{symbol,highlight,priority}`. The repo passes `show_in_folds`, `current_only`, `priority` — none are recognized; they are silently copied into config and ignored.
  implication: The contrib config was written against assumed API. Not the primary cause, but confirms the phase was implemented without checking the pinned plugin's real interface.
- timestamp: 2026-11-23T13:15:00Z
  checked: Headless probe A (deployed config as-is), 200-line git fixture with 2 hunks, 21-line window
  found: `gitsigns_loaded=true, hunks_count=2, scrollview_base='left', column=1, winblend_gui=100, signs_overflow='left', overlap='off'`. After `ScrollViewRefresh`: `sign_windows=0, bar_windows=1`; the bar window had `winblend=100`.
  implication: Directly reproduces "no git markers" — zero marker windows exist despite real hunks and a visible bar.
- timestamp: 2026-11-23T13:16:00Z
  checked: Differential headless probe B (only `signs_overflow` changed left→right)
  found: `sign_windows=1` (symbol `┃`, col=1, `winblend=100`); bar still 1.
  implication: Confirms signs_overflow=left is the blocker; also shows opacity defect is independent (sign exists but fully transparent).
- timestamp: 2026-11-23T13:17:00Z
  checked: Differential probes C/D/E — C: column=2 only; D: column=2 + winblend_gui=0; E: overflow=right + winblend_gui=0
  found: C → sign window at col=0, winblend=100. D → sign window at col=0, winblend=0. E → sign window at col=1, winblend=0.
  implication: Complete geometry model confirmed: with `column=2`/`overflow=left` the marker lands far-left (col 0); winblend_gui alone controls opacity. Achieving the requested far-left marker needs a column/overflow change AND a non-transparent sign winblend (bar hidden some other way).
- timestamp: 2026-11-23T13:18:00Z
  checked: Clean controlled Neovim (`--clean -u NONE`) signcolumn probes for `yes:1..yes:4` with one sign, plus a two-sign probe at `yes:4`
  found: A single native sign always renders in the LEFTMOST sign cell; the extra reserved cells appear as blank space to its RIGHT before the line numbers (`yes:4`: `r1:_X_______1_aaa__`). Two signs on one line at `yes:4` render both in the left cells (`r1:_B A     1 aaa `), leaving blanks to the right.
  implication: Refutes RESEARCH's "right-aligns signs" claim. `signcolumn='yes:4'` cannot create a blank separator cell to the LEFT of gitsigns; it creates the "big empty space" AFTER them — exactly the user's complaint. It also cannot render a 1-pixel solid line (signcolumn cells are whole character cells).

## Resolution

root_cause: >
  DESIGN/CONFIG ROOT CAUSE (three interacting defects, AND-gate = yes): The Phase-07 far-left
  gutter was implemented from undocumented plugin assumptions and plugin defaults that were never
  verified. (a) scrollview's gitsign marker sign windows are computed to screen column 0 because
  `base='left', column=1` is combined with the plugin's default `signs_overflow='left'` and
  `signs_scrollbar_overlap='off'`; `is_valid_column()` rejects col<1, so ZERO markers are created.
  (b) `winblend_gui=100`, chosen to hide the scrollbar, is also applied by this pinned nvim-scrollview
  to sign windows (no separate option), and the pre-v0.12 workaround is skipped on v0.12.2, so any
  marker that is created is 100% transparent. (c) `signcolumn='yes:4'` rests on the false belief that
  Neovim right-aligns signs; it left-aligns them, so the 4 reserved cells render as
  `[native gitsigns][3 blank cells][numbers][text]` — the reported "big empty space" — and cannot
  provide a left-side separator or a 1-pixel solid line. Secondary: the contrib.gitsigns.setup()
  options (`show_in_folds`, `current_only`, `priority`) are invalid names and silently ignored.
fix: (none — find_root_cause_only mode; no changes applied)
verification: >
  Verified by four differential headless probes against the exact deployed config and pinned plugin
  commit b9e6ee00 on Neovim 0.12.2: A (as-is) 0 sign windows; B (overflow=right) 1 sign window;
  C/D (column=2) sign at col 0; D/E (winblend_gui=0) sign winblend 0. Plus clean signcolumn probes
  yes:1..yes:4 proving left alignment. No fix applied.
files_changed: []
