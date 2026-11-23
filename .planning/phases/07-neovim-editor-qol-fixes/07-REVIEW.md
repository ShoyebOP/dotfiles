---
phase: 07-neovim-editor-qol-fixes
reviewed: 2026-11-23T12:49:18Z
depth: deep
files_reviewed: 7
files_reviewed_list:
  - nvim/.config/nvim/lua/base/keymaps.lua
  - nvim/.config/nvim/lua/base/options.lua
  - nvim/.config/nvim/lua/plugins/scrollview.lua
  - nvim/.config/nvim/lua/plugins/which-key.lua
  - nvim/.config/nvim/lua/plugins/surround.lua
  - nvim/.config/nvim/lazy-lock.json
  - nvim/.config/nvim/README.md
findings:
  critical: 0
  high: 0
  medium: 0
  low: 2
  warning: 0
  info: 2
  total: 2
  necessity: 0
status: issues_found
severity_scheme: CRITICAL/HIGH/MEDIUM/LOW
---

# Phase 07: Code Review Report — Neovim Editor QoL Fixes

**Reviewed:** 2026-11-23T12:49:18Z
**Depth:** deep
**Files Reviewed:** 7
**Status:** issues_found (2 LOW — maintenance/dead-config only; no functional or security defects)
**Severity scheme:** CRITICAL / HIGH / MEDIUM / LOW (LOW is mapped to the GSD INFO tier in the `findings` counts above.)

## Summary

Reviewed the three production commits (`5e4f704`, `68514df`, `a986fca`) covering QOL-01 … QOL-06 at deep depth: read every changed file in full, inspected each commit diff, cross-referenced the rest of the Neovim config, read the installed plugin source/docs for nvim-scrollview, which-key.nvim and lazy.nvim, and re-ran the plan's headless behavior probes in this environment.

**No correctness, security, or data-loss defects were found.** All six locked requirements are implemented as specified. Every area the dispatcher called out was independently verified and came back clean:

- `<leader>vd` float: exactly one `vim.diagnostic.open_float` call in the whole config with `scope="line"`, `border="rounded"`, `focusable=true`; exactly one `K → vim.lsp.buf.hover` binding remains in `lspconfig.lua:103` — no duplicate, no conflict (different lhs, different purpose). Headless probe opened a real rounded float (`floats=1`).
- Dead keymap removal: all four regions (`<leader>sr`/grug-far, `<leader>ql`/persistence, `dv`/`<leader>dq`/`dh` Diffview, `<leader>xt`/`<leader>xT` Trouble) are gone; the gitsigns `pcall` block (`keymaps.lua:105-109`), TodoFzfLua maps (`:144-145`) and `<leader>x` Bdelete map (`:96`) all survive. None of the four plugins exist in any spec or in `lazy-lock.json`, so nothing still-needed was removed. (One benign pre-existing `grug-far` filetype string survives in `autocmds.lua:55` as a "close with q" pattern — harmless, not a keymap, not introduced by this phase.)
- Scrollview: diff confirms only `base`, `signs_on_startup`, and the two added lines changed; `excluded_filetypes` and the entire `scrollview.contrib.gitsigns` block are byte-identical to HEAD. `signs_scrollbar_overlap="off"` and `winblend_gui=100` are valid values per the installed scrollview docs.
- nvim-surround pin: `2e93e154de9ff326def6480a4358bfc149d5da2c` is a genuine 40-hex commit, resolves to tag `v4.0.5`, and matches the installed plugin HEAD; spec shape (`version="*"`, `event="VeryLazy"`, `opts={}`) is exact and lazy.nvim's own lockfile writer only records `branch`+`commit`, so `branch: "main"` is normal, not a mismatch. All 40 lockfile pins match installed HEADs.
- `<C-,>` / `<C-.>`: only these two normal-mode bindings exist; no shadowing of any n/i/v/x/t binding; `<Tab>`/`<S-Tab>` remain solely with blink.cmp. Terminal-delivery and Alacritty caveats are documented.
- Smoothscroll removal: `vim.o.smoothscroll == false` verified.

The two findings below are LOW-severity quality/maintenance observations, not behavior bugs.

## Findings

### LOW-01 — Force-added lockfile leaves contradictory `.gitignore` rules and freezes all 40 plugins

**File:** `.gitignore:5` and `.gitignore:22`; `nvim/.config/nvim/lazy-lock.json` (tracked as of `a986fca`)
**Severity:** LOW (maintenance)

**Issue:** `lazy-lock.json` was force-added because `.gitignore:5` and `.gitignore:22` ignore it. The file is now tracked, so the ignore rules are inert, but they were left in place — the repo now simultaneously ignores and tracks the same path, which is misleading to future maintainers (the file reads as a generated/ephemeral artifact while actually being a committed source of truth). Separately, committing the whole lockfile — not just the nvim-surround pin — changes the project's reproducibility policy for all 40 third-party plugins as a side effect of QOL-04. This is sound in isolation (all 40 pins were verified to match installed, working plugin HEADs) but is a broader change than "pin nvim-surround" and should be an explicit, documented policy rather than an incidental consequence of `git add -f`.

**Fix:** Remove the two now-obsolete `nvim/.config/nvim/lazy-lock.json` lines from `.gitignore` (lines 5 and 22) so the tracked file is not falsely marked ignored, and add a short note to `nvim/.config/nvim/README.md` that the lockfile is committed and regenerated on `Lazy update`. If pinning *only* nvim-surround was intended, use a narrower mechanism instead of force-tracking the entire lockfile.

### LOW-02 — `<leader>x` which-key group spec is now inert (dead config)

**File:** `nvim/.config/nvim/lua/plugins/which-key.lua:19`
**Severity:** LOW (dead configuration / cosmetic-only change)

**Issue:** QOL-02 removed the only child maps of the `<leader>x` prefix (`<leader>xt`/`<leader>xT`). The only remaining `<leader>x*` entry anywhere in the config is the `<leader>x` Bdelete leaf mapping (`keymaps.lua:96`); the group spec at `which-key.lua:19` now has zero children. In which-key v3, `Node:is_group()` returns `can_expand() or count() > 0` (installed `which-key/node.lua:97-99`), and `view.lua:192` uses `is_group()` to decide whether to render a group label. With no children and no `expand`/`proxy`, `is_group()` is false, so the retitled `"buffer"` label is never displayed — the change from `"trouble/buffer"` to `"buffer"` has no runtime effect. It is harmless (the `<leader>x` Bdelete mapping still fires as a plain leaf, verified via source), but it is dead config left behind by a "clean the keymap surface" task.

**Fix:** Either delete the now-inert group spec from `which-key.lua`, or make `<leader>x` a genuine prefix again (e.g., move close-buffer to `<leader>xb` with a real `desc`, so the `"buffer"` group label is actually shown). If the label was intentionally kept purely as documentation, remove it to avoid misleading future readers.

## Verification Notes (checks performed, no findings)

- `grep` over all of `nvim/.config/nvim/lua/`: one `<leader>vd`, one `vim.diagnostic.open_float`, one `vim.lsp.buf.hover` (on `K`).
- `git show` for all three production commits: confirmed exactly four keymap regions removed, survivors intact, scrollview `excluded_filetypes` and gitsigns contrib block unchanged byte-for-byte.
- Installed scrollview docs: `signs_scrollbar_overlap` values `off/over/under` valid; `winblend_gui` 0–100 valid; `base=left`/`column>=1` valid.
- Installed nvim-surround: `git describe --tags` at locked commit = `v4.0.5`; all 40 lockfile commits match installed plugin HEADs.
- lazy.nvim `manage/lock.lua`: lockfile writer stores only `branch` + `commit`; no `version` field expected even with `version="*"`.
- which-key source (`node.lua`, `tree.lua`, `view.lua`): a group with no children is not rendered as a group; no `<leader>x` shadowing of the Bdelete mapping.
- Re-ran headless probes: `VD-BEHAVIOR-OK floats=1`, `BUFFER-MAPS-OK`, `SCROLLVIEW-OPTS-OK`, `SURROUND-SPEC-OK` all passed.
- No security surface introduced: no eval, no shell exec, no secrets, no untrusted input paths in any changed file.

---

_Reviewed: 2026-11-23T12:49:18Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
