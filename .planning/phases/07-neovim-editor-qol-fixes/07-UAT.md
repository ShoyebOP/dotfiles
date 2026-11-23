---
status: complete
phase: 07-neovim-editor-qol-fixes
source: [07-VERIFICATION.md]
started: 2026-11-23T12:49:44Z
updated: 2026-11-23T13:10:08.872Z
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

## Summary

total: 3
passed: 1
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-07-1
  truth: "scrollview git markers render in the far-left gutter (column 1), the scrollbar itself is invisible (winblend_gui=100), a blank separator cell sits before gitsigns' native per-line signs, and the separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4)"
  status: failed
  reason: "User reported: no the whole thing is wrong, first i don't see any git markers, the perline gitsigns is in the far left currently, after that there is a big empty space then line numbers and then text. what i wanted was git markers to the far left a very thin one pixel solid line separator, then perline gitsigns"
  severity: major
  test: 1
  artifacts: []
  missing: []

- gap_id: G-07-2
  truth: "next/previous buffer switches; if the sequence is swallowed, a literal control char fails to appear in insert mode, indicating the terminal needs a custom key_bindings entry for the buffer-switch keys"
  status: failed
  reason: "User reported: nope this also not works, i am not using alacritty but kitty. even though the problem might be same, i'm open to change the bind with any of the following combinations- \"alt+,/alt+.\", \"ctrl+;/ctrl+'\" or \"ctrl+[/ctrl+]\" and btw i was talking about only the keys not the text itself"
  severity: major
  test: 2
  artifacts: []
  missing: []
