# Coding Conventions

**Analysis Date:** 2026-09-10

## Naming Patterns

**Files:**
- Stow packages: lowercase package name identical to deployed location — `nvim/`, `nushell/`, `zsh/`, `alacritty/`, `starship/`, `wofi/`, `keyd/` (repo root). Each mirrors target hierarchy (`nvim/.config/nvim/`, `keyd/etc/keyd/`)
- Neovim Lua: `kebab-case.lua` throughout `nvim/.config/nvim/lua/` — e.g., `lspconfig.lua`, `blink-cmp.lua`, `code_runner.lua`, `treesitter-textobjects.lua`, `lspkind.lua`; barrel `init.lua` per package (`lua/base/init.lua`, `lua/lang/init.lua`, `lua/colorschemes/init.lua`); language modules use lang name as filename (`lua/lang/python/python.lua` + companion `lua/lang/python/plugins.lua`)
- Nushell scripts: `kebab-case.nu` in `nushell/.config/nushell/scripts/` — `catppuccin.nu`, `completion.nu`, `uv.nu`, `venv.nu`, `zoxide.nu`, `test-venv.nu`, `test-zoxide.nu`
- Shell bootstrappers: `setup.nu`/`teardown.nu` (Nushell), `setup.zsh`/`teardown.zsh` (Zsh) — verb pattern
- TOML/CSS/config: `kebab-case.toml` + `style.css`/`config` e.g., `alacritty.toml`, `catppuccin-mocha.toml`, `starship.toml`, `starship-minimal.toml`, `wofi/config`
- Dotfiles: preserved with dot prefix inside stow package (`nvim/.config/nvim/.editorconfig`, `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`)

**Functions:**
- Lua (Neovim): `snake_case` for module locals and exports — `M.get_packages()`, `M.install_all()`, `mr.refresh(function() ... end)` in `nvim/.config/nvim/lua/utils/mason-install-all.lua`; `deduplicate(tbl)` helper in `nvim/.config/nvim/lua/lang/init.lua`; `opts = function() ... end` / `config = function(_, opts)` in `nvim/.config/nvim/lua/plugins/lspconfig.lua`; keymap descriptions use Title Case strings: `desc = "Find files"` in `nvim/.config/nvim/lua/base/keymaps.lua`
- Nushell: `kebab-case` with `def` — `def main`, `def get-distro []`, `def get-deps [distro, mode]`, `def verify-deps [deps]`, `def install-deps ...`, `def run-stow ...`, `def get-mode-interactive []` in `setup.nu`; helpers like `run-unstow`, `unstow-module` in `teardown.nu`
- Zsh: `snake_case` — `get_distro()`, `verify_command()`, `get_deps()`, `run_stow()`, `run_unstow()`, `get_mode_interactive()` in `setup.zsh`/`teardown.zsh`; `zle-keymap-select`, `zle-line-init`, `edit-command-line` autoloads in `zsh/.zshrc`

**Variables:**
- Lua: `snake_case` — `lazypath`, `specs`, `lang_config`, `plugin_specs`, `mason_packages`, `treesitter_parsers`, `status_ok`, `lang_module` in `nvim/.config/nvim/init.lua` and `nvim/.config/nvim/lua/lang/init.lua`; short `opt`, `o`, `g` aliases for `vim.opt`/`vim.o`/`vim.g` in `nvim/.config/nvim/lua/base/options.lua`
- Nushell: `snake_case` with `$` — `$distro`, `$selected_mode`, `$deps`, `$missing`, `$dry_run`, `$stow_keyd` in `setup.nu`; `$env.PATH`, `$env.EDITOR`, `$env.STARSHIP_CONFIG`, `$nu.default-config-dir` in `nushell/.config/nushell/*.nu`
- Zsh: `UPPER_SNAKE` for env/global plus `snake_case` for locals — `DRY_RUN`, `MODE`, `STOW_KEYD`, `SCRIPT_NAME`, `XDG_*`, `BUN_INSTALL`, `EDITOR` in `setup.zsh`/`zsh/.zshrc`; locals quoted like `local distro="$1"`; array syntax `local -a common=(...)`
- TOML/CSS: `snake_case` keys (`scan_timeout`/`add_newline` in `starship/.config/starship.toml`; `family`/`style` in `alacritty/.config/alacritty/alacritty.toml`)

**Types:**
- Lua: `snake_case` for type annotations with leading uppercase for class-style in comments — `---@class PluginLspOpts` in `nvim/.config/nvim/lua/plugins/lspconfig.lua`; module types inferred from returned tables `{lsp_servers = {}, mason_packages = {}, ...}` in `nvim/.config/nvim/lua/lang/init.lua`
- Nushell: type hints in `def` params — `[--mode: string]`, `[--dry-run]`, `[--stow-keyd: string]` in `setup.nu:def main`; no custom type defs beyond Nushell primitives
- No distinct type layer beyond Lua `---@class` and TOML schema `$schema = 'https://starship.rs/config-schema.json'`

## Code Style

**Formatting:**
- Tool: `conform.nvim` (`stevearc/conform.nvim`) with `format_on_save = { timeout_ms=3000, async=false, quiet=false, lsp_format="fallback" }` in `nvim/.config/nvim/lua/plugins/conform.lua` delegating per-filetype to `lang` formatters (e.g., `ruff_format`+`ruff_organize_imports` for python, `prettier` for js/ts/html/css/json in `nvim/.config/nvim/lua/lang/javascript/javascript.lua`)
- Core indent: 4 spaces, LF, `insert_final_newline=true`, `trim_trailing_whitespace=true`, `charset=utf-8` via `nvim/.config/nvim/.editorconfig` (`indent_style=space`, `indent_size=4`, `tab_width=4`, `max_line_length=off`); mirrored in `nvim/.config/nvim/lua/base/options.lua` `shiftwidth=4`, `tabstop=4`, `softtabstop=4`, `expandtab=true`, `smartindent/autointdent=true`
- Visible whitespace: `list=true`, `listchars={tab=". ", trail="_", nbsp="␣"}` in `nvim/.config/nvim/lua/base/options.lua`
- Nushell/Zsh: 4-space indents in `setup.nu`/`setup.zsh`, pipes on new lines in Nushell (`$deps | where { ... }`); Zsh uses `set -euo pipefail` + heredocs for `usage()`

**Linting:**
- Tool: Ruff for Python (via `nvim/.config/nvim/lua/lang/python/python.lua` `lsp_servers={pyright,ruff}` with `RUFF_TRACE=messages`, `logLevel=error`); ESLint not configured — JS/TS rely on `ts_ls` + `prettier`
- Diagnostics: `nvim/.config/nvim/lua/plugins/lspconfig.lua` sets `diagnostics={underline=true, update_in_insert=false, virtual_text={spacing=4, source="if_many", prefix="●"}, severity_sort=true, signs={ERROR="󰅙",WARN="",INFO="󰋼",HINT="󰌵"}}`; inlayHints enabled except vue; `folds.enabled=true`
- Editor: `.editorconfig` `root=true` with `g.editorconfig=true` in `nvim/.config/nvim/lua/base/options.lua` to respect repo policy

## Import Organization

**Order:**
1. Standard library / vim APIs (`vim.g`, `vim.opt`, `vim.fn`, `require("lang")`)
2. Third-party plugin modules (`require("lazy")`, `require("mason-registry")`, `require("telescope.actions")`)
3. Project-local modules (`require("base")`, `require("colorschemes")`, `require("settings")`)
4. Example: `nvim/.config/nvim/init.lua` does `vim.g.mapleader` → `lazypath` check → `specs={{import="plugins"}, require("colorschemes")}` → `pcall(require,"lang")` → `require("lazy").setup` → `require("base")` → `vim.schedule(colorscheme)`
   Nushell: `nushell/.config/nushell/config.nu` sources in fixed order `uv.nu` → `venv.nu` → `catppuccin.nu` → `completion.nu` and **last** `zoxide.nu` (comment: "must be sourced last to avoid hook overwrite"); Zsh: `zsh/.zshrc` loads Powerlevel10k instant prompt first, then aliases, XDG/ENV exports, then `zoxide init`, then `bindkey`/`setopt`, then edit-command-line widget

**Path Aliases:**
- Neovim Lua: no path aliases — plain `require("lang.python.python")`, `require("plugins.telescope")` relative to `lua/` on `runtimepath` (`vim.opt.rtp:prepend(lazypath)` adds lazy path, not alias); `nvim/.config/nvim/lua/lang/init.lua` constructs `"lang."..lang.."."..lang` dynamically
- Nushell: `$nu.default-config-dir | path join "scripts" "uv.nu"` pattern in `nushell/.config/nushell/config.nu`; `$env.HOME | path join ...` for PATH extension in `nushell/.config/nushell/env.nu`
- Zsh: no alias plugin path; completions stored at `~/.config/zsh/completions/_uv` (manually generated) and `~/.local/share/zinit/`
- TOML: `import = ["~/.config/alacritty/catppuccin-mocha.toml"]` in `alacritty/.config/alacritty/alacritty.toml`; Nushell `$env.STARSHIP_CONFIG = $env.HOME | path join ".config" "starship.toml"` so starship locates config indirectly

## Error Handling

**Patterns:**
- **Guard + early exit:** Nushell `if not ($nu | is-not-empty) { print "Error: must run with Nushell"; exit 1 }` and `if $distro not-in ["arch","cachyos","ubuntu"] { print "Error: only supports ..."; exit 1 }` (`setup.nu:10`, `setup.nu:30`); Zsh `set -euo pipefail` + `verify_command || missing+=` + `usage; exit 1` for unknown flags (`setup.zsh:18`, `setup.zsh:verify_command`)
- **pcall/warn continue:** Lua protects dynamic loads `status_ok, lang_config = pcall(require, lang_module); if not status_ok then vim.notify("Failed to load: "..lang_module.."\n"..tostring(lang_config), WARN) end` (`nvim/.config/nvim/lua/lang/init.lua:25`) and similarly `pcall(require,"lang")` in `nvim/.config/nvim/init.lua:19` — bootstrap continues with empty `M`
- **Collection before action:** Bootstrappers gather `missing` deps list before installing; dry-run short-circuits (`if $dry_run { print "=== DRY RUN MODE ===" }` in `setup.nu:10`, `if [[ "$DRY_RUN" == true ]] then return` variants in `setup.zsh`/`teardown.*`)
- **Neovim safety:** `nvim/.config/nvim/lua/base/options.lua` sets `confirm=true` (prompt before closing unsaved), `exrc=true` + `secure=true` (prompt before trusting local `.nvim.lua`), `g.editorconfig=true`; fold and grep formats handle missing tools (`grepprg=rg --vimgrep` assumes rg present, `cond = vim.fn.executable("make")==1` for telescope-fzf-native)
- **Mason warnings:** `nvim/.config/nvim/lua/utils/mason-install-all.lua` warns on `not mr.has_package(package_name)` and skips `pkg:is_installed()` before `MasonInstall`; aggregates `to_install` then single `MasonInstall` command

## Logging

**Framework:** `print`/`echo` in shells; `vim.notify` + `nvim-notify` + `noice.nvim` in Neovim

**Patterns:**
- Shell bootstrap logs every step with `print $"Detected distribution: ($distro)"` and `print $"Dependencies for ($distro) in ($selected_mode) mode defined."` (Nushell `setup.nu`) vs `echo "\nVerifying dependencies..."` / `echo "All dependencies are satisfied."` (Zsh `setup.zsh`/`teardown.zsh`); teardown warns `print "⚠️  WARNING: Starting Teardown Process"` before requiring `yes`
- Neovim uses `vim.notify("Mason: Installing ... packages: "..table.concat(to_install, ", "), INFO)` or `"Mason: All packages already installed"` in `nvim/.config/nvim/lua/utils/mason-install-all.lua`; `vim.notify("Failed to load language configs: "..tostring(lang_config), ERROR)` on bootstrap failure
- No structured/log-level files; prompt-integrated feedback via `starship`/`p10k` showing `status` (exit code) and `command_execution_time`
- Never log secret values (though `env.nu` contains a committed key — see CONCERNS.md — no runtime logging reveals it per greps)

## Comments

**When to Comment:**
- Block banners for major sections: `-- ╔═══════════════[ Mode Selection ]═══════════════╗` and `-- ╔════════════ NEOVIM SETTINGS ═╗` in `nvim/.config/nvim/lua/settings.lua` and `nvim/.config/nvim/lua/base/options.lua` (grouped UI/Clipboard/Indentation/Search/Mouse/Splits/Undo/Folding)
- Rationale comments where order matters: `# NOTE: zoxide.nu is sourced at the END ... to ensure hooks are not overwritten` and `# NOTE: cd alias is defined AFTER zoxide.nu` in `nushell/.config/nushell/config.nu`; `# Enable Powerlevel10k instant prompt. Should stay close to the top ... Initialization code that may require console input must go above` in `zsh/.zshrc`
- Per-option inline docs: `o.shiftwidth = 4 -- Indent width` and `opt.listchars = { tab = ". " -- Tabs shown as ▸ }` in `nvim/.config/nvim/lua/base/options.lua` (also clarifies `ignorecase` semantics: `Ignore case when searching --> Example: /hello matches "Hello"`)
- Language module headers: `-- ══════════════ Language Configuration Loader ══════════════` + `This file automatically loads ... To add/remove languages, edit lua/settings.lua` in `nvim/.config/nvim/lua/lang/init.lua`
- Avoid TODO/FIXME comments — only references are in plugin `to-do.lua` alt lists and keymap descriptions (`<leader>sT` for TodoTelescope), not code

**JSDoc/TSDoc:**
- Sparse — Lua uses `---@diagnostic disable: undefined-global` at top of `nvim/.config/nvim/lua/base/keymaps.lua` and `---@class PluginLspOpts` in `nvim/.config/nvim/lua/plugins/lspconfig.lua`; most functions are undocumented beyond `desc = "Toggle NvimTree"` style keymap descriptors; Nushell/Zsh/TOML have no JSDoc equivalent

## Function Design

**Size:** Small, single-purpose helpers — Nushell `get-distro` ~10 lines, `get-deps` returns two arrays, `verify-deps` filters `which`, `run-stow` maps mode→modules and calls `stow`; Lua `deduplicate(tbl)` 12 lines, `M.get_packages()` ~5 lines, `M.install_all()` ~30 lines plus `mr.refresh` callback in `nvim/.config/nvim/lua/utils/mason-install-all.lua`; Zsh helpers similarly <30 lines each

**Parameters:** Positional rest for collections — Nushell `def get-deps [distro, mode]`, `def verify-deps [deps]`, Zsh `get_deps() { local distro="$1"; local mode="$2"; local -a common=...; }`, Lua `M.install_all()` is nullary (reads `require("lang")` internally); bootstrapper `main` uses named flags `--mode: string`, `--dry-run` (flag), `--stow-keyd: string` (Nushell `def main`) or `while [[ $# -gt 0 ]]; do case $1 in --mode) MODE="$2"; shift 2 ;;` (Zsh `parse_args`) with `usage()` terminating on `--help`

**Return Values:** Lua modules return table `M` or `return { "neovim/nvim-lspconfig", event=..., dependencies=..., opts=function() ... end, config=function(_,opts) ... end }` lazy spec (`nvim/.config/nvim/lua/plugins/lspconfig.lua`); Nushell helpers return values (`return $id`, `return ($common | append $gui)`), Zsh helpers `echo` mode string (`echo "local" && return`) or set global `STOW_KEYD` array

## Module Design

**Exports:** Single default export per file — Lua `return M` (aggregator), `return { lsp_servers = {...}, mason_packages={...}, treesitter={...} }` (language), `return { "plugin/name", event=..., opts=..., config=... }` (plugin); Nushell `def main [...] { ... }` + `def get-distro [] { return $id }` collected implicitly; Zsh `function zle-keymap-select { ... } ; zle -N ...`

**Barrel Files:** `nvim/.config/nvim/lua/base/init.lua` re-exports base (required as `require("base")` in `init.lua:75`); `nvim/.config/nvim/lua/lang/init.lua` is the language barrel aggregating all `lang/<lang>/*.lua`; `nvim/.config/nvim/lua/colorschemes/init.lua` re-exports theme specs for `require("colorschemes")` in `init.lua:13`; Neovim plugins auto-imported via `{ import = "plugins" }` lazy directive (no manual barrel needed); Nushell `nushell/.config/nushell/config.nu` is the barrel sourcing `scripts/*.nu` into one config

---

*Convention analysis: 2026-09-10*
