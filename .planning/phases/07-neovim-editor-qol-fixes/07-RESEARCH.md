# Phase 7 — Research (verified in-session, 2026-11-23)

Sources: live Neovim 0.12.2 headless probes against the deployed config, official plugin docs fetched from GitHub, and direct reads of the repo config.

## Diagnostic display

- `vim.diagnostic.config()` currently has `virtual_text = { prefix="●", source="if_many", spacing=4 }`, `float = true`, `update_in_insert = false`.
- No keymap in `lua/base/keymaps.lua` invokes `vim.diagnostic.open_float()`.
- `K` → `vim.lsp.buf.hover` already exists (`lua/plugins/lspconfig.lua:103`) — do not add a hover keybind.
- User explicitly wants a shortcut only; no wrapping, no Trouble install.

## Scrollview relocation — ABANDONED (UAT gap G-07-4)

**SUPERSEDED 2026-11-23 by UAT gap G-07-4: the far-left git-marker column plus one-pixel divider gutter is unachievable with the pinned nvim-scrollview and Neovim's signcolumn model, and the user decided to abandon that layout entirely rather than iterate further. The scrollview plugin spec, its lazy-lock pin and all divider/marker configuration have been removed. The gutter now shows native per-line gitsigns only — no separate marker column, no divider glyph, and no reserved-cell blank gap before the line numbers. The earlier G-07-1 findings were an attempt to make the rejected layout work and are no longer the design of record; the full diagnosis is retained in `.planning/debug/gutter-git-marker-separator-layout.md` as history.**

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
