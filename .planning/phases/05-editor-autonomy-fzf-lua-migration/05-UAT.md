---
status: testing
phase: 05-editor-autonomy-fzf-lua-migration
source: [05-VERIFICATION.md]
started: 2026-10-03T16:30:00Z
updated: 2026-10-03T16:30:00Z
---

## Current Test

number: 1
name: which-key popup visual
expected: |
  Open nvim, press `<Space>` and then `f` / `s` / `g`. LazyVim-like which-key popup appears (preset modern, ~200ms delay) with group labels (find, search/todo, git, …) and nested leaf hints from keymap desc strings.
awaiting: user response

## Tests

### 1. which-key popup visual
expected: Open nvim, press `<Space>` and then `f` / `s` / `g`. LazyVim-like popup appears (preset modern, ~200ms delay) with group labels and nested leaf hints from desc strings.
result: [pending]

### 2. Interactive picker pass (all rebound keys)
expected: In a live nvim session, invoke each rebound picker once: `<leader>ff fa fg fb fh fo ma cm gt f th st sT N`, `<C-f>`/`<C-fg>` in nvim-tree, dashboard `ff r k th`, `:ColorschemeWithPreview`. Every key opens the fzf-lua picker with correct scope; EXPECTED DEVIATIONS under test: `<leader>sT` shows ALL todos unfiltered (WR-01); first-ever `<leader>fa`/`<leader>f`/`<leader>th` before any `:FzfLua` may fail module-not-found (WR-04); `<C-f>` outside the tree errors (WR-03).
result: [pending]

### 3. Live destructive wipe (disposable host only)
expected: On a disposable clone/VM (NEVER the daily driver): run `bash setup.sh --uninstall`, deselect nvim, type `yes`, confirm `~/.local/share/nvim` is gone; then reinstall and confirm LSPs restore via the headless trigger. Whole data dir removed behind typed-yes gate; reinstall restores plugins + Mason packages.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
