---
status: testing
phase: 07-neovim-editor-qol-fixes
source: [07-VERIFICATION.md]
started: 2026-11-23T12:49:44Z
updated: 2026-11-23T12:49:44Z
---

## Current Test

number: 1
name: Open a git-tracked file with uncommitted changes in Alacritty and inspect the left gutter
expected: |
  scrollview git markers render in the far-left gutter (column 1), the scrollbar itself is invisible (winblend_gui=100), a blank separator cell sits before gitsigns' native per-line signs, and the separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4)
awaiting: user response

## Tests

### 1. Open a git-tracked file with uncommitted changes in Alacritty and inspect the left gutter
expected: scrollview git markers render in the far-left gutter (column 1), the scrollbar itself is invisible (winblend_gui=100), a blank separator cell sits before gitsigns' native per-line signs, and the separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4)
result: [pending]

### 2. In a real Alacritty terminal with nvim open on >=2 buffers, press <C-,> and <C-.> in normal mode; if nothing happens, press <C-v><C-,> in insert mode to test delivery
expected: next/previous buffer switches; if the sequence is swallowed, a literal control char fails to appear in insert mode, indicating Alacritty needs a custom key_bindings entry for Ctrl+comma/Ctrl+period
result: [pending]

### 3. Trigger <leader>vd on a line carrying a diagnostic
expected: a rounded-border floating window shows the full current-line message; virtual-text rendering is unchanged (confirmatory only — headless already proved the float opens)
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
