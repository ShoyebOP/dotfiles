---
phase: 07-neovim-editor-qol-fixes
reviewed: 2026-11-23T14:15:12Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - nvim/.config/nvim/README.md
  - nvim/.config/nvim/lua/base/keymaps.lua
  - nvim/.config/nvim/lua/base/options.lua
  - nvim/.config/nvim/lua/plugins/scrollview.lua
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
  necessity: 0
status: issues_found
---

# Phase 07: Code Review Report — Gap-Closure Changes (G-07-1 / G-07-2)

**Reviewed:** 2026-11-23T14:15:12Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found (2 Warning, 1 Info — no critical defects)

## Summary

Incremental review of the four gap-closure files against base `11b9a081b1e0fd067395a4f563ea3a16d1c52bb1`: the scrollview git-marker/separator rework (options.lua + scrollview.lua, G-07-1) and the Alt+comma/Alt+period buffer-cycle rebind plus kitty documentation (keymaps.lua + README.md, G-07-2).

I read every changed file in full, examined the exact diff, and verified claims against the installed pinned plugin (`nvim-scrollview` @ `b9e6ee00`, matching `lazy-lock.json`), Neovim's own help, and headless behavior probes. Two of the three findings are on the documentation/refresh side; the third is a geometry concern on the separator float that I could only verify analytically (reported as Info).

Verified clean (no finding):
- **G-07-2 keybinds** (`keymaps.lua:94-95`): `<M-,>` / `<M-.>` correctly bound to `BufferLineCycleNext` / `BufferLineCyclePrev`; rhs, `desc`, order, and the adjacent `<leader>x` Bdelete map are untouched. No stale `<C-,>` / `<C-.>` literals remain. Per `:help map-alt-keys`, kitty's ESC-prefixed Alt bytes decode as `<M-,>` / `<M-.>` within `ttimeoutlen`, and the pre-existing `<Esc>` → `noh` map does not block that (no `timeoutlen` override is present). Tab/Shift-Tab remain with completion.
- **gitsigns contrib options** (`scrollview.lua:34-39`): `enabled`, `add_priority`, `change_priority`, `delete_priority` are all real keys in the installed `scrollview/contrib/gitsigns.lua`; the previously ignored `show_in_folds`/`current_only`/`priority` are correctly removed. `signs_show_in_folds`, `signs_overflow`, `winblend_gui`, `diagnostics_severities` are valid setup keys.
- **Bar hiding** (`scrollview.lua:20-33`): linking `ScrollView`→`Normal` to hide only the scrollbar while `winblend_gui=0` keeps sign windows opaque matches the pinned plugin's source (`winblend_gui` is read for both bar and sign windows on this build); the `vim.schedule` + `ColorScheme` re-assert correctly handles the plugin's `highlight default link ScrollView Visual` and later theme loads.
- **No security surface**: no eval, shell exec, untrusted input, or secrets in any changed file.

## Warnings

### WR-01: Dead `User ScrollViewRefresh` autocmd — event is never fired

**File:** `nvim/.config/nvim/lua/plugins/scrollview.lua:86-92`
**Issue:** The config registers `vim.api.nvim_create_autocmd("User", { pattern = "ScrollViewRefresh", ... })` expecting it to redraw the separator when scrollview refreshes. The pinned plugin never fires that event: `ScrollViewRefresh` is only a **command** (`autoload/scrollview.vim:510-511`: `command -bar ScrollViewRefresh lua require('scrollview').refresh()`). A full scan of the installed plugin (`lua/`, `autoload/`, `plugin/`) finds **no** `doautocmd` / `nvim_exec_autocmds` for any `User` event — the gitsigns contrib uses `User GitSignsUpdate` plus the `:ScrollViewRefresh` command (`contrib/gitsigns.lua:151,237`) — and a repo-wide scan finds no code firing `User ScrollViewRefresh` either. `nvim_create_autocmd("User", …)` does not hook into a command of the same name. The callback therefore never executes: the intended refresh-time resync is silently absent and the block is dead code built on a false API assumption. Practical impact is limited (the separator is a static full-height line already redrawn by `BufEnter`/`WinEnter`/`VimResized`/`WinScrolled`), which is why this is a Warning rather than a Critical.
**Fix:** Remove the dead block:
```lua
-- DELETE lines 86-92 in full:
-- vim.api.nvim_create_autocmd("User", {
--     group = sep_group,
--     pattern = "ScrollViewRefresh",
--     callback = function() vim.schedule(draw_separator) end,
-- })
```
If refresh-time resync is genuinely required, wire `draw_separator()` into a wrapper around the actual `:ScrollViewRefresh` command rather than a non-existent `User` event; otherwise rely on the four geometry autocmds already registered at lines 82-85.

### WR-02: README delivery test is broken by this config's own insert-mode `<C-v>` remap

**File:** `nvim/.config/nvim/README.md:32` (and the pointer to it at `:34`); cross-reference `nvim/.config/nvim/lua/base/keymaps.lua:174`
**Issue:** The rewritten delivery test instructs: "enter insert mode, press `<C-v>` followed by the key … and confirm a literal `^[` (ESC) prefix is inserted". But `keymaps.lua:174` maps `map("i", "<C-v>", "<C-r>+", { noremap = true, desc = "Paste clipboard" })`, so in insert mode `<C-v>` pastes the clipboard instead of inserting the next typed character literally. Anyone following the documented test will never see `^[` and can wrongly conclude the terminal swallows Alt+comma / Alt+period — precisely the failure mode the G-07-2 documentation exists to diagnose. This invalidates both the primary kitty test (line 32) and the Alacritty note that reuses it (line 34).
**Fix:** Run the probe under a config that does not install the remap, e.g.:
```markdown
Delivery test (any terminal): run `nvim --clean`, enter insert mode, press `<C-v>`
followed by the key (for example `<C-v>` then Alt+comma) and confirm a literal `^[`
(ESC) prefix is inserted rather than nothing. (`--clean` is required because this
repo remaps insert-mode `<C-v>` to paste from the clipboard.)
```

## Info

### IN-01: Separator float at `col = 2` sits on the second native sign slot — verify visually

**File:** `nvim/.config/nvim/lua/plugins/scrollview.lua:68`; cross-reference `nvim/.config/nvim/lua/base/options.lua:12`
**Issue:** Headless geometry probes show `signcolumn="yes:2"` reserves **four** cells (Neovim doubles the `:N` count: `getwininfo().textoff = 4` with `nonumber`), i.e. two 2-cell native sign slots at window offsets 0 and 2. `nvim_open_win({ relative = "win", col = 2 })` maps to screen offset 2 (`win_screenpos` confirmed float `col=0→+0`, `col=1→+1`, `col=2→+2` from the window's left edge) — i.e. exactly the second native sign slot. `options.lua:12` states `yes:2` was chosen specifically to hold both a native diagnostic sign and a gitsigns sign on one line, so on such lines the opaque full-height `│` float (zindex 45) will overlap the second native sign; the scrollview marker float at offset 0 likewise overlays the first. This could leave the "native per-line gitsigns" the change aims to preserve visually hidden. I could not composite the final pixels without a real terminal UI (`screenstring()` under headless is unreliable for floats), so this is Info, not a Warning — please confirm on a line carrying both a diagnostic and a gitsigns sign.
**Fix:** Verify with a real TUI screenshot. If the second sign is covered, move the separator to a genuinely free cell (e.g. `col = 3`, the padding cell) or reconsider the `yes:2` + overlay combination so the second native sign slot is not occupied by an opaque float.

---

_Reviewed: 2026-11-23T14:15:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
