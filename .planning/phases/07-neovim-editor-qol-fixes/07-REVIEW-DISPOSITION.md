---
phase: 07-neovim-editor-qol-fixes
review: 07-REVIEW.md
recorded: 2026-11-23T14:20:00Z
status: issues_found
counts:
  critical: 0
  warning: 2
  info: 1
  open: 3
  fixed: 0
  skipped: 0
  deferred: 0
---

# Code Review Disposition

Advisory gate. Incremental review of the four files changed by the Phase-07 gap-closure plans (07-02 / 07-03) found 0 Critical, 2 Warning, and 1 Info. All findings are recorded as **open** — none were silently dropped. Code review never blocks execution; these are surfaced to the user with a recommendation to run `/gsd-code-review 07 --fix` or fold the two warnings into the UAT/gap-closure cycle. No scope expansion was performed mid-phase, per the project's no-scope-expansion norm.

| ID | Severity | Disposition | Reason | Source |
|----|----------|-------------|--------|--------|
| WR-01 | warning | open | Dead `User ScrollViewRefresh` autocmd: nvim-scrollview fires a `:ScrollViewRefresh` command, not a `User` autocmd event, so the callback never runs. Inert (separator redraw is already covered by BufEnter/WinEnter/VimResized/WinScrolled/WinClosed) but should be removed to avoid implying a refresh path that does not exist. Recommended for a small follow-up fix. | 07-REVIEW.md |
| WR-02 | warning | open | README insert-mode delivery test (`<C-v>` then the key) is defeated by this repo's own `map("i", "<C-v>", "<C-r>+")` paste remap, so users following it will not see the `^[` prefix. Doc-only defect that could mislead the kitty UAT; recommend documenting `:iunmap <C-v>` (or an unmapped literal-next prefix) before the probe. | 07-REVIEW.md |
| IN-01 | info | open | Separator float at `col = 2` may overlap the second native sign slot (`signcolumn="yes:2"` reserves cells at offsets 0 and 2). Headless geometry cannot composite final pixels; confirm visually during the kitty gutter UAT. No change recommended unless the visual check shows overlap. | 07-REVIEW.md |
