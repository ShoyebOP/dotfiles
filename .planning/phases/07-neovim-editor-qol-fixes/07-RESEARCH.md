# Phase 7 — Research (verified in-session, 2026-11-23)

Sources: live Neovim 0.12.2 headless probes against the deployed config, official plugin docs fetched from GitHub, and direct reads of the repo config.

## Diagnostic display

- `vim.diagnostic.config()` currently has `virtual_text = { prefix="●", source="if_many", spacing=4 }`, `float = true`, `update_in_insert = false`.
- No keymap in `lua/base/keymaps.lua` invokes `vim.diagnostic.open_float()`.
- `K` → `vim.lsp.buf.hover` already exists (`lua/plugins/lspconfig.lua:103`) — do not add a hover keybind.
- User explicitly wants a shortcut only; no wrapping, no Trouble install.

## Scrollview relocation

- `lua/plugins/scrollview.lua` currently: `base="right"`, `column=1`, `signs_on_startup={"diagnostics","search","gitsigns"}`, `diagnostics_severities={ERROR}`, plus `scrollview.contrib.gitsigns` setup.
- Official `:help scrollview-configuration` confirms: `base` (`left`/`right`/`buffer`), `column` (>=1), `winblend_gui` (opacity with termguicolors), `signs_on_startup`, `signs_scrollbar_overlap`, `hide_on_text_intersect`, `hide_on_cursor_intersect`, `hide_on_float_intersect`, `hide_bar_for_insert`, `signs_hidden_for_insert`. No explicit "hide bar, keep signs" toggle → use `winblend_gui = 100` for a fully transparent bar.
- `lua/base/options.lua:12` has `signcolumn = "yes"`; v0.12 accepts `yes:3` and `yes:4` (verified). Neovim right-aligns signs in a widened signcolumn.
- Target layout (locked plan decision): `signcolumn = "yes:4"` → `[scrollview git markers, col 1][blank separator, col 2][native diagnostic/gitsigns signs, cols 3-4][numbers][text]`. `yes:3` was rejected because a diagnostic + git sign on the same line fills all three cells and removes the separator.

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
