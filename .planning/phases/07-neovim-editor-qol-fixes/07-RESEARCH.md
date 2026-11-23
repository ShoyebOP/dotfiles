# Phase 7 — Research (verified in-session, 2026-11-23)

Sources: live Neovim 0.12.2 headless probes against the deployed config, official plugin docs fetched from GitHub, and direct reads of the repo config.

## Diagnostic display

- `vim.diagnostic.config()` currently has `virtual_text = { prefix="●", source="if_many", spacing=4 }`, `float = true`, `update_in_insert = false`.
- No keymap in `lua/base/keymaps.lua` invokes `vim.diagnostic.open_float()`.
- `K` → `vim.lsp.buf.hover` already exists (`lua/plugins/lspconfig.lua:103`) — do not add a hover keybind.
- User explicitly wants a shortcut only; no wrapping, no Trouble install.

## Scrollview relocation

**CORRECTED 2026-11-23 (UAT gap G-07-1): the original Phase-07 gutter design recorded here was disproved by headless differential probes against the pinned nvim-scrollview `b9e6ee00` on Neovim 0.12.2. This correction supersedes the original Phase-07 design and was triggered by UAT gap G-07-1 (full diagnosis in `.planning/debug/gutter-git-marker-separator-layout.md`).**

- `lua/plugins/scrollview.lua` was changed in 07-01 to `base="left"`, `column=1`, `winblend_gui=100`, `signs_on_startup={"gitsigns"}`, `signs_scrollbar_overlap="off"`, plus a `scrollview.contrib.gitsigns` setup.
- Official `:help scrollview-configuration` confirms: `base` (`left`/`right`/`buffer`), `column` (>=1), `winblend_gui` (opacity with termguicolors), `signs_on_startup`, `signs_scrollbar_overlap`, `signs_overflow`, `signs_show_in_folds`, `hide_on_text_intersect`, `hide_on_cursor_intersect`, `hide_on_float_intersect`, `hide_bar_for_insert`, `signs_hidden_for_insert`.
- **Sign alignment (verified):** Neovim left-aligns native signs in the signcolumn. Extra reserved cells therefore appear to the RIGHT of the signs and produced the reported empty gap before the line numbers — they cannot form a left-side separator. A true one-pixel solid line cannot be built from whole character cells, so the separator is a dedicated one-column float (`│`, U+2502), not spare signcolumn cells.
- **Marker geometry (verified):** markers render only when the scrollbar column geometry leaves a valid screen column. With `base="left", column=1` and the default `signs_overflow="left"`, the marker column computes to 0 and `is_valid_column()` rejects it, so ZERO sign windows are drawn. `column=2` with an explicit `signs_overflow="left"` places the marker in the far-left valid column.
- **Bar visibility (verified):** this pinned build reads `winblend_gui` for BOTH the scrollbar and the sign windows (no separate signs-winblend option; the pre-v0.12 workaround is skipped on v0.12.2), so `winblend_gui=100` hid the markers too. The bar is now hidden by linking its own highlight group `ScrollView` to `Normal`, while `winblend_gui=0` keeps the marker sign windows opaque.
- **Signcolumn (verified):** `signcolumn = "yes:2"` is the narrowest width that still holds a native diagnostic sign and a gitsigns sign on one line. The former four-cell target layout `[scrollview git markers, col 1][blank separator, col 2][native signs, cols 3-4][numbers][text]` is superseded; `yes:4` created the trailing blank gap the user complained about.
- **Contrib keys (verified):** `scrollview.contrib.gitsigns.setup()` only reads `enabled`, `hide_full_add`, `only_first_line`, `add/change/delete_symbol`, `add/change/delete_highlight`, and `add/change/delete_priority`. The original `show_in_folds`, `current_only` and `priority` keys were silently ignored.

## Surround plugin

- No surround plugin in `lazy-lock.json`; `mini.pairs` only auto-closes delimiters.
- `kylechui/nvim-surround` default maps: `ys{motion}{char}`, `yss{char}`, `ds{char}`, `cs{old}{new}`, visual `S{char}`. Visual `S` is currently unbound (no conflicts found).
- Alternative rejected by user context: `mini.surround`; chosen: nvim-surround.

## Keybind availability

- `maparg()` probe with real config loaded: `<C-,>`, `<C-.>`, `<M-,>`, `<M-.>` → NONE in `n`, `i`, `v`, `x`, `t` modes.
- blink.cmp `keymap` (lua/plugins/blink-cmp.lua:85-90): preset "enter", `<Tab>`, `<S-Tab>`, `<C-y>` only.
- Terminal caveat: Alacritty config has no `key_bindings`, `TERM=xterm-256color`; distinct key delivery must be verified live.

## Stale keymap inventory

- `<leader>sr` requires `grug-far` — not in lockfile/specs.
- `<leader>ql` requires `persistence` — not in lockfile/specs.
- `dv`, `<leader>dq`, `dh` use `:Diffview*` — no diffview plugin.
- `<leader>xt`, `<leader>xT` use `:Trouble` — no trouble.nvim plugin.
- `which-key.lua` group label `"trouble/buffer"` for `<leader>x` should be renamed (e.g. `"buffer"`).

## Cosmetic cleanup

- `lua/base/options.lua:70` has `opt.smoothscroll = true`. Remove it as a cosmetic preference. Do NOT link it to cursor behavior in any plan text.
