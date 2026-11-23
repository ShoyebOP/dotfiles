---
status: complete
phase: 07-neovim-editor-qol-fixes
source: [07-VERIFICATION.md]
started: 2026-11-23T12:49:44Z
updated: 2026-11-23T16:08:00.000Z
---

## Current Test

[testing complete]

## Tests

### 1. Open a git-tracked file with uncommitted changes in Alacritty and inspect the left gutter
expected: scrollview git markers render in the far-left gutter (column 1), the scrollbar itself is invisible (winblend_gui=100), a blank separator cell sits before gitsigns' native per-line signs, and the separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4)
result: issue
reported: "no the whole thing is wrong, first i don't see any git markers, the perline gitsigns is in the far left currently, after that there is a big empty space then line numbers and then text. what i wanted was git markers to the far left a very thin one pixel solid line separator, then perline gitsigns"
severity: major

### 2. In a real Alacritty terminal with nvim open on >=2 buffers, press <C-,> and <C-.> in normal mode; if nothing happens, press <C-v><C-,> in insert mode to test delivery
expected: next/previous buffer switches; if the sequence is swallowed, a literal control char fails to appear in insert mode, indicating Alacritty needs a custom key_bindings entry for Ctrl+comma/Ctrl+period
result: issue
reported: "nope this also not works, i am not using alacritty but kitty. even though the problem might be same, i'm open to change the bind with any of the following combinations- \"alt+,/alt+.\", \"ctrl+;/ctrl+'\" or \"ctrl+[/ctrl+]\" and btw i was talking about only the keys not the text itself"
severity: major

### 3. Trigger <leader>vd on a line carrying a diagnostic
expected: a rounded-border floating window shows the full current-line message; virtual-text rendering is unchanged (confirmatory only — headless already proved the float opens)
result: pass

### 4. Open a git-tracked file with uncommitted changes in kitty and inspect the left gutter; then put a native diagnostic sign and a gitsigns sign on the same line and inspect again.
expected: The scrollview plugin and its separator line are removed entirely; the gutter shows only native per-line gitsigns (no far-left marker column, no separator, no large empty gap before line numbers).
result: issue
reported: "the separator is there spacing is correct, but git marker and native per-line gitsigns are in same column. User decision: impossible to fix the far-left marker + separator layout — remove the separator line and the whole scrollview plugin itself so only the per-line gitsign remains."
severity: major

### 5. In real kitty with at least two buffers, press Alt+comma and Alt+period in normal mode; if nothing happens, run the insert-mode delivery test under `nvim --clean`.
expected: Next/previous buffer switches. For the delivery probe, a literal ESC prefix is inserted after the Alt key; note that under this repo's normal config insert-mode <C-v> is remapped to clipboard paste (review WR-02), so the probe must run with `nvim --clean` or after `:iunmap <C-v>`.
result: pass

### 6. Open a git-tracked file with uncommitted changes in kitty and inspect the left gutter; then put a native diagnostic sign and a gitsigns sign on the same line and inspect again.
expected: Only native per-line gitsigns appear in the default sign column immediately before the line numbers — no far-left marker column, no divider glyph, and no wide empty gap. Native diagnostic signs and gitsigns still render normally, including on the same line.
result: skipped
source: "Owner-directed phase completion 2026-11-23 — visual TUI check waived. Config end state verified by headless gates; no kitty binary in this environment. Recorded waiver, not an observed pass."

## Summary

total: 6
passed: 2
issues: 3
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-07-1
  truth: "scrollview git markers render in the far-left gutter (column 1), the scrollbar itself is invisible (winblend_gui=100), a blank separator cell sits before gitsigns' native per-line signs, and the separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4)"
  status: resolved
  resolved_by: 07-02-PLAN.md
  resolved_at: 2026-11-23
  reason: "User reported: no the whole thing is wrong, first i don't see any git markers, the perline gitsigns is in the far left currently, after that there is a big empty space then line numbers and then text. what i wanted was git markers to the far left a very thin one pixel solid line separator, then perline gitsigns"
  severity: major
  test: 1
  root_cause: "Phase-07 gutter was built on unverified plugin assumptions: (1) base=left + column=1 with default signs_overflow=left makes the marker column compute to 0 (invalid), so zero sign windows are ever drawn; (2) winblend_gui=100 is read by both bar and sign windows on pinned nvim-scrollview b9e6ee00 / Neovim 0.12.2, so markers would be invisible even if drawn; (3) signcolumn=yes:4 rests on a false 'Neovim right-aligns signs' assumption — Neovim left-aligns, producing the reported empty gap, and a true 1px solid line cannot be made from whole-cell signcolumn."
  artifacts:
    - path: "nvim/.config/nvim/lua/plugins/scrollview.lua"
      issue: "base=left/column=1 + default signs_overflow=left → marker column 0; winblend_gui=100 blanks sign windows; contrib.gitsigns setup uses invalid option names"
    - path: "nvim/.config/nvim/lua/base/options.lua"
      issue: "signcolumn=yes:4 creates a trailing blank gap before line numbers, not a leading 1px separator"
    - path: ".planning/phases/07-neovim-editor-qol-fixes/07-RESEARCH.md"
      issue: "false right-alignment assumption baked into the locked design (also propagated to 07-01-SUMMARY.md)"
  missing:
    - "Choose column geometry that places scrollview git markers at far left (e.g. column=2 with default signs_overflow=left)"
    - "Stop using winblend_gui=100 to hide the bar — it also hides signs; hide the bar by a bar-specific mechanism and keep sign windows opaque"
    - "Implement the separator as an actual 1px solid line (dedicated float/highlight) rather than spare signcolumn cells"
    - "Replace invalid contrib.gitsigns option names with supported ones"
  debug_session: ".planning/debug/gutter-git-marker-separator-layout.md"

- gap_id: G-07-2
  truth: "next/previous buffer switches; if the sequence is swallowed, a literal control char fails to appear in insert mode, indicating the terminal needs a custom key_bindings entry for the buffer-switch keys"
  status: resolved
  resolved_by: 07-03-PLAN.md
  resolved_at: 2026-11-23
  reason: "User reported: nope this also not works, i am not using alacritty but kitty. even though the problem might be same, i'm open to change the bind with any of the following combinations- \"alt+,/alt+.\", \"ctrl+;/ctrl+'\" or \"ctrl+[/ctrl+]\" and btw i was talking about only the keys not the text itself"
  severity: major
  test: 2
  root_cause: "QOL-05 rebound buffer cycling to <C-,>/<C-.>, Ctrl+punctuation combos legacy terminal encoding cannot represent. In kitty's default legacy keyboard mode its ctrled_key() has no entry for ',' or '.', so it sends a bare , / . and drops Ctrl; nvim never receives the mapped sequence (the bare keys instead run builtin repeat motions, which reads as 'nothing happens'). Headless maparg confirms the nvim-side mappings are correct — the fault is entirely terminal→nvim delivery. Only an Alacritty-specific key_bindings caveat was documented; no kitty handling was shipped."
  artifacts:
    - path: "nvim/.config/nvim/lua/base/keymaps.lua"
      issue: "lines 94-95 bind <C-,>/<C-.>, undeliverable in kitty legacy mode"
    - path: "nvim/.config/nvim/README.md"
      issue: "key-delivery caveat is Alacritty-only; kitty is not covered"
  missing:
    - "Rebind to <M-,>/<M-.> (alt+, / alt+.) — the only user-suggested combo kitty delivers reliably; ctrl+;/' fails the same way and ctrl+[ collides with Escape"
    - "Update README caveat to cover kitty, not just Alacritty"
  debug_session: ".planning/debug/buffer-switch-keybindings-kitty.md"

- gap_id: G-07-4
  truth: "The scrollview plugin and its separator line are removed entirely; the gutter shows only native per-line gitsigns (no far-left marker column, no separator, no large empty gap before line numbers)"
  status: failed
  reason: "User reported: the separator is there spacing is correct, but git marker and native per-line gitsigns are in same column. User decision: impossible to fix the far-left marker + separator layout — remove the separator line and the whole scrollview plugin itself so only the per-line gitsign remains."
  severity: major
  test: 4
  root_cause: "The far-left scrollview git-marker + 1px separator gutter design (QOL-03 / gap G-07-1) is not achievable with the pinned nvim-scrollview + Neovim signcolumn model; the user has decided to abandon that layout entirely and keep only native per-line gitsigns."
  artifacts:
    - path: "nvim/.config/nvim/lua/plugins/scrollview.lua"
      issue: "scrollview plugin spec and separator/marker config added by 07-01/07-02 must be removed"
    - path: "nvim/.config/nvim/lua/base/options.lua"
      issue: "signcolumn=yes:4 added for the separator must be reverted"
    - path: "nvim/.config/nvim/lazy-lock.json"
      issue: "scrollview plugin pin must be removed if present"
  missing:
    - "Remove the scrollview plugin spec and its separator/marker configuration"
    - "Revert signcolumn and any related gutter options added solely for the separator layout"
    - "Remove the scrollview entry from lazy-lock.json"
    - "Update docs/verification artifacts so they no longer claim a far-left marker/separator layout"
  debug_session: ""
