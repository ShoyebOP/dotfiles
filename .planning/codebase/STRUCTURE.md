# Codebase Structure

**Analysis Date:** 2026-09-10

## Directory Layout

```
dotfiles/                          # Repo root — GNU Stow packages + bootstrap scripts
├── setup.nu / setup.zsh           # Bootstrappers (deploy via stow)
├── teardown.nu / teardown.zsh     # Reverse bootstrappers (unstow)
├── README.md                      # Overview, manual + auto setup docs
├── .gitignore                     # Ignores nvim state/history/machinespecific
├── .git/                          # Git history (main + backup branches)
│
├── nvim/                          # Stow package → ~/.config/nvim/
│   └── .config/nvim/
│       ├── init.lua               # Bootstrap + lazy setup + base + colorscheme
│       ├── lazy-lock.json         # 44 plugin pins (reproducible installs)
│       ├── .editorconfig          # 4-space, LF, trim whitespace
│       ├── .neoconf.json          # Neoconf local config
│       ├── README.md              # Showcase + install notes
│       ├── lua/
│       │   ├── base/              # Editor fundamentals
│       │   ├── lang/              # Per-language modules (bash/c/css/docker/git/html/js/json/lua/md/py/sql/toml/yaml/django)
│       │   ├── plugins/           # 21 plugin specs
│       │   ├── colorschemes/      # 5 theme files (catppuccin/gruvbox/nightfox/tokyodark + init)
│       │   ├── icons/             # lspkind
│       │   ├── utils/             # mason-install-all, lsp-restart
│       │   └── settings.lua       # Central colorscheme + languages toggle
│       ├── state/ cache/ shada/ undo/ # Runtime state (gitignored)
│       └── .hidden/               # Showcase images (code+tree.png, home.png)
│
├── nushell/                       # Stow package → ~/.config/nushell/ + ~/.local/bin/
│   └── .config/nushell/
│       ├── config.nu              # Vi-mode, menus, keybindings, sources scripts/*
│       ├── env.nu                 # XDG, PATH, EDITOR, STARSHIP_CONFIG, MISTRAL_API_KEY
│       ├── login.nu               # Login hook
│       ├── history.txt / .json    # History (gitignored)
│       ├── scripts/
│       │   ├── uv.nu              # ~400-line uv completions/externs
│       │   ├── venv.nu            # Python venv helpers (venv-selector bridge)
│       │   ├── zoxide.nu          # zoxide hooks/commands (must be sourced last)
│       │   ├── catppuccin.nu      # Theme helpers
│       │   ├── completion.nu      # External completer wiring
│       │   ├── test-venv.nu       # Smoke check
│       │   └── test-zoxide.nu     # Smoke check
│   └── .local/bin/toggle-keyd.nu  # Keyd toggle helper
│
├── zsh/                           # Stow package → ~/
│   ├── .zshrc                     # Zinit bootstrap, Powerlevel10k, vi bindings, zoxide, aliases
│   ├── .zprofile                  # Hyprland autostart on tty1
│   ├── .zsh_history               # History (gitignored)
│   └── .p10k.zsh                  # Powerlevel10k wizard config (classic, 2-line, icons)
│
├── alacritty/                     # Stow package → ~/.config/alacritty/
│   └── .config/alacritty/
│       ├── alacritty.toml         # Main terminal config (imports catppuccin)
│       └── catppuccin-mocha.toml  # Flavor import
│
├── starship/                      # Stow package → ~/.config/starship.toml
│   └── .config/
│       ├── starship.toml          # Active config (catppuccin_latte, powerline, scan_timeout 1000)
│       └── starship-minimal.toml  # Variant
│
├── wofi/                          # Stow package → ~/.config/wofi/
│   └── .config/wofi/
│       ├── config                 # Wofi launch config
│       └── style.css              # Theming
│
└── keyd/                          # Stow package → /etc/keyd/ (privileged)
    └── etc/keyd/default.conf      # Key remapping config
```

## Directory Purposes

**`nvim/`:**
- Purpose: Complete Neovim distribution (editor core + modular languages + plugins)
- Contains: `init.lua`, `lua/base/*.lua`, `lua/lang/<lang>/*.lua`, `lua/plugins/*.lua`, `lua/colorschemes/*.lua`, `lua/utils/*.lua`, `lazy-lock.json`, `.editorconfig`, `README.md`
- Key files: `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lua/settings.lua`, `nvim/.config/nvim/lua/lang/init.lua`, `nvim/.config/nvim/lua/base/options.lua`, `nvim/.config/nvim/lua/base/keymaps.lua`, `nvim/.config/nvim/lazy-lock.json`

**`nushell/`:**
- Purpose: Nushell shell environment and Python helpers
- Contains: `config.nu`, `env.nu`, `login.nu`, `scripts/*.nu`, history files, `toggle-keyd.nu` helper
- Key files: `nushell/.config/nushell/config.nu`, `nushell/.config/nushell/env.nu`, `nushell/.config/nushell/scripts/zoxide.nu`, `nushell/.config/nushell/scripts/uv.nu`, `nushell/.config/nushell/scripts/venv.nu`

**`zsh/`:**
- Purpose: Zsh shell environment (alternative shell path to Nushell)
- Contains: `.zshrc`, `.zprofile`, `.p10k.zsh`, `.zsh_history`
- Key files: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`

**`alacritty/`:**
- Purpose: Terminal emulator configuration
- Contains: `alacritty.toml`, `catppuccin-mocha.toml`
- Key files: `alacritty/.config/alacritty/alacritty.toml`

**`starship/`:**
- Purpose: Cross-shell prompt configuration (shared by Nushell and Zsh)
- Contains: `starship.toml`, `starship-minimal.toml`
- Key files: `starship/.config/starship.toml`

**`wofi/`:**
- Purpose: Wayland application launcher (Hyprland local mode)
- Contains: `config`, `style.css`
- Key files: `wofi/.config/wofi/config`, `wofi/.config/wofi/style.css`

**`keyd/`:**
- Purpose: System-wide key remapping daemon config (privileged)
- Contains: `default.conf`
- Key files: `keyd/etc/keyd/default.conf`

**Root:**
- Purpose: Orchestration and documentation
- Contains: `setup.nu`, `setup.zsh`, `teardown.nu`, `teardown.zsh`, `README.md`, `.gitignore`, `.git/`
- Key files: `setup.nu`, `setup.zsh`, `teardown.nu`, `teardown.zsh`, `README.md`, `.gitignore`

## Key File Locations

**Entry Points:**
- `setup.nu` — Nushell bootstrapper CLI (`--mode local|server --dry-run --stow-keyd y|n`)
- `setup.zsh` — Zsh bootstrapper CLI (same flags, `set -euo pipefail`)
- `teardown.nu` — Nushell reverse (unstow, requires `yes` confirmation)
- `teardown.zsh` — Zsh reverse (unstow)
- `nvim/.config/nvim/init.lua` — Neovim startup (lazy bootstrap + base + colorscheme schedule)
- `nushell/.config/nushell/config.nu` + `nushell/.config/nushell/env.nu` — Nushell interactive + env entry
- `zsh/.zshrc` + `zsh/.zprofile` — Zsh interactive + login entry; `zsh/.p10k.zsh` prompt config

**Configuration:**
- `nvim/.config/nvim/lua/settings.lua` — Single source for colorscheme & enabled languages
- `nvim/.config/nvim/lua/base/options.lua` — Editor options (indent 4, clipboard, folds, grep alias)
- `nvim/.config/nvim/lazy-lock.json` — Pinned plugin commits
- `nvim/.config/nvim/.editorconfig` — Formatting policy (space, 4, LF, final newline, trim)
- `alacritty/.config/alacritty/alacritty.toml` — Terminal font/theme/import
- `starship/.config/starship.toml` — Prompt format/palette
- `keyd/etc/keyd/default.conf` — Keyd mapping

**Core Logic:**
- `nvim/.config/nvim/lua/lang/init.lua` — Language aggregator (merges lsp/formatters/mason/treesitter/plugins with dedup)
- `nvim/.config/nvim/lua/lang/<lang>/<lang>.lua` — Language definitions (14 languages: bash, c, css, django, docker, git, html, javascript, json, lua, markdown, python, sql, toml, yaml)
- `nvim/.config/nvim/lua/lang/<lang>/plugins.lua` — Per-language plugin specs where needed (e.g., `django`, `python` venv-selector, `html`, `json`, `markdown`, `css`)
- `nvim/.config/nvim/lua/plugins/*.lua` — 21 plugin specs (alpha, blink-cmp, bufferline, code_runner, conform, gitsigns, indentscope, lspconfig, lualine, mason, mini-pairs, noice, nvim-tree, render-markdown, scrollview, telescope, to-do, toggleterm, treesitter, treesitter-context, treesitter-textobjects)
- `nvim/.config/nvim/lua/utils/mason-install-all.lua` — Bulk Mason installer (`MasonInstallAll` command)
- `nushell/.config/nushell/scripts/*.nu` — Nushell helpers (uv completions ~400 lines, zoxide hooks, venv, catppuccin, completion)

**Testing:**
- `nushell/.config/nushell/scripts/test-venv.nu` — Venv smoke test
- `nushell/.config/nushell/scripts/test-zoxide.nu` — Zoxide smoke test
- No formal test suite; Neovim checked via `:checkhealth` and manual `MasonInstallAll`

## Naming Conventions

**Files:**
- Nushell scripts: `kebab-case.nu` in `nushell/.config/nushell/scripts/` e.g., `catppuccin.nu`, `test-venv.nu`, `uv.nu`, `zoxide.nu`, `venv.nu`, `completion.nu`
- Neovim Lua: `kebab-case.lua` with barrel `init.lua` per package; language files reuse lang name as filename (`nvim/.config/nvim/lua/lang/python/python.lua`, `nvim/.config/nvim/lua/lang/python/plugins.lua`); base as `options.lua`, `keymaps.lua`, `autocmds.lua`; plugins as `<plugin>.lua` e.g., `telescope.lua`, `conform.lua`, `lspconfig.lua`
- TOML/CSS: `kebab-case.toml`/`style.css` e.g., `alacritty.toml`, `catppuccin-mocha.toml`, `starship.toml`, `starship-minimal.toml`
- Shell bootstrappers: `setup.nu`, `setup.zsh`, `teardown.nu`, `teardown.zsh` (verb noun)
- Stow package directories: lowercase package name identical to deployment target (`nvim/`, `nushell/`, `zsh/`, `alacritty/`, `starship/`, `wofi/`, `keyd/`)

**Directories:**
- Stow packages: flat lowercase at repo root (`nvim/`, `nushell/`, `alacritty/`, etc.) — each mirrors target hierarchy inside (e.g., `nvim/.config/nvim/`)
- Neovim lua hierarchy: `lua/base/`, `lua/lang/<lang>/`, `lua/plugins/`, `lua/colorschemes/`, `lua/icons/`, `lua/utils/` — grouping by concern
- Nushell scripts: `nushell/.config/nushell/scripts/` for modular `source` includes
- Runtime state: `nvim/.config/nvim/{cache,state,shada,undo}/` (gitignored via `.gitignore`)

## Where to Add New Code

**New Feature (e.g., new GUI app config):**
- Primary code: Create stow package `newapp/.config/newapp/config.toml` (mirroring target XDG path), reference in `README.md` table
- Update bootstrappers: Add package name to `gui_modules` or `core_modules` arrays in both `setup.nu:get-deps`/`run-stow` and `setup.zsh:get_deps`/`run_stow`, and mirror in `teardown.nu:run-unstow` and `teardown.zsh:run_unstow` (keep parity)
- Docs: Add per-mode note in `README.md` Manual Installation sections

**New Neovim Language Support:**
- Implementation: Create directory `nvim/.config/nvim/lua/lang/<newlang>/` with `<newlang>.lua` returning `{lsp_servers, lsp_config, formatters, mason_packages, treesitter}` and optional `plugins.lua` returning lazy specs; follow existing peers like `nvim/.config/nvim/lua/lang/python/python.lua` and `nvim/.config/nvim/lua/lang/json/json.lua`
- Enable: Add `"<newlang>"` to `languages = { ... }` list in `nvim/.config/nvim/lua/settings.lua:24`; aggregator `nvim/.config/nvim/lua/lang/init.lua` picks it up automatically with deduplication
- Dependencies: If language needs LSP/formatter, add to `mason_packages`; user runs `:MasonInstallAll` or `:MasonInstall <pkg>` modeled after `nvim/.config/nvim/lua/utils/mason-install-all.lua`
- Tests: Manual open a `<newlang>` file, verify `:LspInfo`, `:ConformInfo`, `:TSInstallInfo`

**New Neovim Plugin (global, not language-scoped):**
- Implementation: Add `nvim/.config/nvim/lua/plugins/<name>.lua` returning lazy spec table (see `nvim/.config/nvim/lua/plugins/telescope.lua` for dependencies/build/opts/config pattern, or simpler `bufferline.lua`/`gitsigns.lua`)
- Registration: No manual registration needed — `nvim/.config/nvim/init.lua:14` does `{import="plugins"}` which auto-imports all specs in `lua/plugins/`; run `:Lazy sync` and verify `lazy-lock.json` updates

**Utilities:**
- Shared Neovim helpers: `nvim/.config/nvim/lua/utils/<helper>.lua` (see `nvim/.config/nvim/lua/utils/lsp-restart.lua`, `nvim/.config/nvim/lua/utils/mason-install-all.lua`)
- Shared Nushell helpers: `nushell/.config/nushell/scripts/<helper>.nu` and `source` from `nushell/.config/nushell/config.nu` (keep `zoxide.nu` last to preserve hook)
- Zsh helpers: append to `zsh/.zshrc` or extract to `~/.shell_aliases`/`~/.shell_functions` which `zsh/.zshrc` conditionally sources

**New Shell Theme/Config:**
- Starship: edit `starship/.config/starship.toml` (and sync `starship/.config/starship-minimal.toml` if used); reference `https://starship.rs/config-schema.json` and `catppuccin_latte` palette
- Alacritty: add flavor file `alacritty/.config/alacritty/<flavor>.toml` and update `alacritty/.config/alacritty/alacritty.toml` `import` array

## Special Directories

**`nvim/.config/nvim/state/` `nvim/.config/nvim/shada/` `nvim/.config/nvim/cache/` `nvim/.config/nvim/undo/`:**
- Purpose: Neovim runtime persistence (undo history, shada session, view cache)
- Generated: Yes (created by Neovim on run, `options.lua:undofile=true`)
- Committed: No (all listed in `.gitignore`: `nvim/.config/nvim/undo/`, `nvim/.config/nvim/shada/`, `nvim/.config/nvim/state/`, `nvim/.config/nvim/cache/`)

**`nushell/.config/nushell/history.txt` + `nushell/.config/nushell/history.json` and `zsh/.zsh_history`:**
- Purpose: Shell history
- Generated: Yes (shells maintain automatically)
- Committed: No (`.gitignore` ignores `nushell/.config/nushell/history.txt|json`)

**`nvim/.config/nvim/lazy-lock.json` and `nvim/.config/nvim/.neoconf.json`:**
- Purpose: Reproducible plugin commits and local Neoconf overrides
- Generated: Yes (by `:Lazy` and `neoconf`); `.neoconf.json` is local
- Committed: `lazy-lock.json` YES (desired for reproducibility); `.neoconf.json` listed in `.gitignore`? Actually `.gitignore` lists `nvim/.config/nvim/.neoconf.json` so treated as ignored per file

**`keyd/etc/keyd/default.conf` target `/etc/keyd/`:**
- Purpose: System daemon config
- Generated: No (hand-authored)
- Committed: Yes; deployment requires `sudo stow --adopt -t / keyd` to overlay `/etc`

**`.git/` and ignored `*.swp`:**
- Purpose: Git objects and Vim swap files
- Generated: Yes (editor/git)
- Committed: No (`.gitignore` excludes `*.swp`, history files, undo/shada/state/cache)

---

*Structure analysis: 2026-09-10*
