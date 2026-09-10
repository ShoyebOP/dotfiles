<!-- GSD:project-start source:PROJECT.md -->

## Project

**Dotfiles — Unified Installer & Reliability Hardening**

Efficiency-first Stow-based dotfiles for Arch/CachyOS/Ubuntu workstations and headless servers. Deploys Zsh (default), Neovim (lazy.nvim + 14 language modules), and desktop primitives (Alacritty, Starship, Wofi, Keyd) with a single installer; Nushell path is retained as a backup only. This milestone unifies install/remove into one Bash entry-point, fixes all non-Nushell bugs called out in `codebase/CONCERNS.md`, and adds QoL fixes (Zsh history/fzf, Neovim auto-LSP/which-key) plus gitignored machine-local overrides.

**Core Value:** A fresh clone can go from `bash setup.sh` → working Zsh + Neovim + desktop environment on any supported distro/derivative with one interactive run, and cleanly reverse itself — no manual `stow` or `MasonInstallAll` required.

### Constraints

- **Shell default:** Zsh is default everywhere; Nushell is backup only — update all docs/comments to reflect this — why: user explicitly requested Zsh as canonical
- **Installer language:** Unified installer must be **Bash** — available by default — why: `bash` is preinstalled, avoids requiring Nushell/Zsh to bootstrap themselves
- **Scope filter:** Do not fix Nushell-only issues — why: Nushell is backup, avoid wasted work
- **OS support:** Must correctly handle Arch/CachyOS/Ubuntu **and derivatives** via `ID_LIKE` + package-manager presence (`pacman`/`apt`), not hard-coded `["arch","cachyos","ubuntu"]` — why: users on Manjaro/EndeavourOS hit hard errors
- **Machine-local:** Machine-specific overrides must be gitignored and auto-sourced if present — why: per-machine PATH/alias/theme differences must not dirty git
- **Reversibility:** Removal must clean Stow symlinks, Keyd config, and Mason/packages installed by nvim (when uninstalling) — why: user expects `teardown` parity in unified script
- **Safety:** No destructive writes without preview/confirmation; privileged `/etc/keyd` writes require explicit conflict check and user confirmation — why: `--adopt` currently risky

<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->

## Technology Stack

## Languages

- Lua 5.1+ / LuaJIT - Neovim configuration (`nvim/.config/nvim/lua/**/*.lua`, `nvim/.config/nvim/init.lua`) — core editor config, plugin specs, LSP, treesitter, language modules
- Nushell 0.110.0 - Shell bootstrap and environment (`nushell/.config/nushell/config.nu`, `nushell/.config/nushell/env.nu`, `setup.nu`, `teardown.nu`, `nushell/.config/nushell/scripts/*.nu`)
- Zsh - Alternative shell path (`zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`, `setup.zsh`, `teardown.zsh`) with vi-mode and Zinit plugin manager
- Shell (Bash/POSIX) — subshell fragments inside setup/teardown scripts
- TOML - Alacritty and Starship configuration (`alacritty/.config/alacritty/alacritty.toml`, `alacritty/.config/alacritty/catppuccin-mocha.toml`, `starship/.config/starship.toml`, `starship/.config/starship-minimal.toml`)
- CSS - Wofi launcher styling (`wofi/.config/wofi/style.css`)
- INI-like (keyd) — Keyboard remapping (`keyd/etc/keyd/default.conf`)
- Python (indirect) - Managed via `uv` for Neovim venv workflows (`nushell/.config/nushell/scripts/uv.nu`, `nushell/.config/nushell/scripts/venv.nu`)
- JSON - Plugin lockfiles and editor state (`nvim/.config/nvim/lazy-lock.json`, `nvim/.config/nvim/.neoconf.json`, `nushell/.config/nushell/history.json`)
- Markdown - Documentation (`README.md`, `nvim/.config/nvim/README.md`)

## Runtime

- Neovim >=0.10 (requires `nvim`, `gcc`, `make`, `luarocks`, `tree-sitter-cli`, `wl-clipboard`) — `nvim/.config/nvim/lazy-lock.json` tracks ~44 plugins
- Nushell 0.110.0+ (interactive shell, `setup.nu` validates via `$nu | is-not-empty`)
- Zsh with Zinit (`zsh/.zshrc` clones `https://github.com/zdharma-continuum/zinit` to `~/.local/share/zinit/zinit.git` on first run)
- Starship prompt (`starship/.config/starship.toml`, schema `https://starship.rs/config-schema.json`)
- GNU Stow - Dotfile deployment (`setup.nu`/`setup.zsh` use `stow --restow`, `teardown.nu`/`teardown.zsh` use `stow -D`)
- uv - Python package/tool installer and venv manager (`nushell/.config/nushell/scripts/uv.nu` provides `uv` completions and `uv generate-shell-completion` for Zsh in `setup.zsh`)
- npm - Node tooling for Neovim JS/TS language support (`setup.*` lists `node`, `npm` as core deps)
- Mason registry - In-editor LSP/formatter/linter installer (`nvim/.config/nvim/lua/utils/mason-install-all.lua`, `nvim/.config/nvim/lua/plugins/mason.lua`)
- lazy.nvim - Neovim plugin manager (`nvim/.config/nvim/init.lua` bootstraps `folke/lazy.nvim` from GitHub, pinned commits via `nvim/.config/nvim/lazy-lock.json`)
- No `package.json`/`Cargo.toml`/`pyproject.toml` at repo root — this is a configuration repo, not a buildable application
- Lockfile: `nvim/.config/nvim/lazy-lock.json` present (44 plugin pins), `nvim/.config/nvim/.editorconfig` present, no Node/Python lockfiles at root

## Frameworks

- lazy.nvim (stable branch) - Plugin orchestration, lazy-loading defaults (`nvim/.config/nvim/init.lua` sets `defaults.lazy=true`, disables 23 built-in runtime plugins)
- Blink.cmp (`saghen/blink.cmp`) - Completion engine with LSP merging (`nvim/.config/nvim/lua/plugins/blink-cmp.lua`, integrates with `blink-ripgrep.nvim`)
- nvim-lspconfig + Mason - LSP provisioning (`nvim/.config/nvim/lua/plugins/lspconfig.lua`, `nvim/.config/nvim/lua/plugins/mason.lua`, `nvim/.config/nvim/lua/utils/mason-install-all.lua`)
- Treesitter (`nvim-treesitter` main branch) - Parsing and highlighting (`nvim/.config/nvim/lua/plugins/treesitter.lua`, `treesitter-context.lua`, `treesitter-textobjects.lua`)
- Powerlevel10k — Zsh prompt theme (`zsh/.p10k.zsh` generated 2026-04-26, instant prompt enabled in `zsh/.zshrc`)
- Zinit — Zsh plugin manager (auto-cloned, loaded in `zsh/.zshrc`)
- No formal test framework detected (no `jest.config.*`, `vitest.config.*`, `pytest.ini`, `Cargo.toml`). Lightweight smoke scripts only: `nushell/.config/nushell/scripts/test-venv.nu` and `nushell/.config/nushell/scripts/test-zoxide.nu`
- nvim's health via `:checkhealth` and Mason's `MasonInstallAll` command are ad-hoc validation
- `conform.nvim` (`stevearc/conform.nvim`) - Format-on-save orchestration (`nvim/.config/nvim/lua/plugins/conform.lua`, 3000ms timeout, `lsp_format=fallback`)
- `stow` + `setup.nu`/`setup.zsh` bootstrapper - Idempotent deployment with `--dry-run`, `--mode local|server`, `--stow-keyd` flags
- `zoxide` - Directory jumping (`nushell/.config/nushell/scripts/zoxide.nu`, `zsh/.zshrc` runs `eval "$(zoxide init zsh)"`, Nushell hooks `env_change.PWD` with `zoxide add -- $dir`)
- `ripgrep` (`rg`) - Grep engine (`nvim/.config/nvim/lua/base/options.lua` sets `grepprg=rg --vimgrep`, telescope live_grep)
- `uv` - Python venv and tool management (`nushell/.config/nushell/scripts/venv.nu` provides `venv-selector.nvim` integration `linux-cultist/venv-selector.nvim`)

## Key Dependencies

- `stow` - Must be present; `setup.nu:verify-deps` and `setup.zsh:verify_command` abort if missing — entire deployment depends on it
- `neovim` - Central editor; all `nvim/.config/nvim/lua/**` depends on lazy.nvim bootstrap and `vim.loop.fs_stat` check
- `starship` - Prompt for Nushell/Zsh; config at `starship/.config/starship.toml` with `catppuccin_latte` palette, powerline format with `os`, `directory`, `git_branch`, `c/rust/golang/nodejs/python`, `conda`, `time`
- `zoxide` - Navigation; `nushell/.config/nushell/scripts/zoxide.nu` and `zsh/.zshrc` both initialize hooks; aliases `z` and `zi`
- `uv` - Python tooling; `nushell/.config/nushell/scripts/uv.nu` (400+ line completion set), `nushell/.config/nushell/scripts/venv.nu`; Zsh generates `~/.config/zsh/completions/_uv`
- `ripgrep` (`rg`) - Required for telescope grep, `grep -r` patterns, and `options.lua:grepprg`
- `git` - Versioning and lazy.nvim cloning and telescope git_status/git_commits pickers
- `node`/`npm` + `wl-clipboard` + `gcc`/`make` — required per `nvim/.config/nvim/README.md` for treesitter builds and clipboard (`nvim/.config/nvim/lua/base/options.lua` sets `clipboard=unnamedplus` unless `SSH_TTY`)
- `keyd` - System key remapping (`keyd/etc/keyd/default.conf`, privileged `sudo stow --adopt -t / keyd` + `sudo keyd reload`, sudoers NOPASSWD for `systemctl start|stop keyd`)
- `alacritty` - Terminal (`alacritty/.config/alacritty/alacritty.toml` imports `catppuccin-mocha.toml`, JetBrainsMono Nerd Font 12.0)
- `wofi` + `waybar` + `grim`/`slurp`/`wl-copy` - Hyprland GUI stack (`setup.nu:get-deps` and `setup.zsh:get_deps` list `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-copy` for `local` mode on Arch/CachyOS; subset on Ubuntu)
- Catppuccin themes - `alacritty/.config/alacritty/catppuccin-mocha.toml`, `nushell/.config/nushell/scripts/catppuccin.nu`, Neovim `catppuccin` colorscheme (`catppuccin.lua`) plus `gruvbox`, `nightfox`, `tokyodark` (`tokyodark` active in `nvim/.config/nvim/lua/settings.lua`)
- Zsh extras: `fzf`/`make` for `telescope-fzf-native.nvim` (`nvim/.config/nvim/lua/plugins/telescope.lua` conditions on `vim.fn.executable("make")==1`), `bun` (`zsh/.zshrc` exports `BUN_INSTALL=~/.bun`, git log shows `add bun completions`/`add bun install path`)

## Configuration

- Nushell: `nushell/.config/nushell/env.nu` sets `XDG_CACHE_HOME/CONFIG_HOME/DATA_HOME`, `PATH` prepends `~/.local/bin`, `~/.local/sbin`, `~/.cargo/bin`, `~/.bun/bin`, `~/.npm-global/bin`, sets `EDITOR=nvim`, `STARSHIP_CONFIG=~/.config/starship.toml`, `PIPX_TOOL_INSTALLER=uv`, `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`, `LANG=en_US.UTF-8`; `.env` presence noted but never read (forbidden)
- Zsh: `zsh/.zshrc` mirrors XDG exports, `EDITOR=nvim`, `BUN_INSTALL`, `PATH`, `N8N_RESTRICT_FILE_ACCESS_TO=""`, `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`; `zsh/.zprofile` auto-`exec start-hyprland` on `tty1` without DISPLAY; `.p10k.zsh` controls prompt elements (`os_icon`, `dir`, `vcs`, `status`, `command_execution_time`, battery, todo, etc.)
- Neovim: `nvim/.config/nvim/lua/settings.lua` centralizes `colorscheme="tokyodark"` and `languages={bash,git,python,javascript,html,css,markdown,lua,sql,django,json,yaml,toml,docker}` (c disabled); `nvim/.config/nvim/lua/base/options.lua` defines 4-space indents, editor behavior, clipboard, folding, etc.; `.editorconfig` enforces `indent_style=space`, `indent_size=4`, `lf`, `utf-8`, `trim_trailing_whitespace`
- Starship: `starship/.config/starship.toml` (`scan_timeout=1000`, `add_newline=false`, custom powerline `format`/`right_format`); `starship/.config/starship-minimal.toml` variant exists but Nushell `env.nu` points to `starship.toml`
- Secret-like env: `MISTRAL_API_KEY` set in `nushell/.config/nushell/env.nu` (value not reproduced here — see CONCERNS.md)
- No compiled build; deployment is `stow` symlinking. `setup.nu`/`setup.zsh` verify distro (`arch`|`cachyos`|`ubuntu` else error) and missing deps, optionally `install-deps` then `run-stow`/`run_unstow`-equivalent. Flags: `--mode local|server`, `--dry-run`, `--stow-keyd y|n`, `--help`
- `nvim/.config/nvim/init.lua` bootstrap clones lazy.nvim if `vim.loop.fs_stat(lazypath)` fails; `lazy-lock.json` pins exact commits for reproducible installs; `MasonInstallAll` (`nvim/.config/nvim/lua/utils/mason-install-all.lua`) bulk-installs `mason_packages` from `lang` aggregation
- `zsh/.zshrc` completion generation: `uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv` (manual step in README)

## Platform Requirements

- Supported distros: Arch Linux / CachyOS / Ubuntu (checked in `setup.nu:get-distro` and `setup.zsh:get_distro` via `/etc/os-release` ID). Other distros error with manual instructions per `README.md`
- Core packages: `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm` (always). GUI extras for `--mode local`: Arch/CachyOS adds `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-copy`; Ubuntu adds `alacritty`, `wofi`, `waybar`, `grim`, `slurp`, `wl-copy`
- Nushell required for `setup.nu`/`teardown.nu` (`$nu | is-not-empty` guard); Zsh required for `setup.zsh`/`teardown.zsh` (`set -euo pipefail`)
- Editor toolchain: `gcc`, `make`, `luarocks`, `tree-sitter-cli`, `wl-clipboard`, `python3-pip` (per `nvim/.config/nvim/README.md`)
- Fonts: JetBrainsMono Nerd Font (Alacritty config)
- Deployment target: Local workstation or headless server — `README.md` defines two modes: `local` (full GUI) and `server` (headless: only `nvim`, `nushell`, `starship`, or `nvim`+`zsh` on Zsh path)
- Stow deployment maps repo subdirs to `$HOME`/`~/.config`/`/etc`; `keyd` requires root (`sudo stow --adopt -t / keyd`)
- No CI/CD hosting; git remote `origin` on `main` branch; backup branch `backup` exists locally

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

## Naming Patterns

- Stow packages: lowercase package name identical to deployed location — `nvim/`, `nushell/`, `zsh/`, `alacritty/`, `starship/`, `wofi/`, `keyd/` (repo root). Each mirrors target hierarchy (`nvim/.config/nvim/`, `keyd/etc/keyd/`)
- Neovim Lua: `kebab-case.lua` throughout `nvim/.config/nvim/lua/` — e.g., `lspconfig.lua`, `blink-cmp.lua`, `code_runner.lua`, `treesitter-textobjects.lua`, `lspkind.lua`; barrel `init.lua` per package (`lua/base/init.lua`, `lua/lang/init.lua`, `lua/colorschemes/init.lua`); language modules use lang name as filename (`lua/lang/python/python.lua` + companion `lua/lang/python/plugins.lua`)
- Nushell scripts: `kebab-case.nu` in `nushell/.config/nushell/scripts/` — `catppuccin.nu`, `completion.nu`, `uv.nu`, `venv.nu`, `zoxide.nu`, `test-venv.nu`, `test-zoxide.nu`
- Shell bootstrappers: `setup.nu`/`teardown.nu` (Nushell), `setup.zsh`/`teardown.zsh` (Zsh) — verb pattern
- TOML/CSS/config: `kebab-case.toml` + `style.css`/`config` e.g., `alacritty.toml`, `catppuccin-mocha.toml`, `starship.toml`, `starship-minimal.toml`, `wofi/config`
- Dotfiles: preserved with dot prefix inside stow package (`nvim/.config/nvim/.editorconfig`, `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`)
- Lua (Neovim): `snake_case` for module locals and exports — `M.get_packages()`, `M.install_all()`, `mr.refresh(function() ... end)` in `nvim/.config/nvim/lua/utils/mason-install-all.lua`; `deduplicate(tbl)` helper in `nvim/.config/nvim/lua/lang/init.lua`; `opts = function() ... end` / `config = function(_, opts)` in `nvim/.config/nvim/lua/plugins/lspconfig.lua`; keymap descriptions use Title Case strings: `desc = "Find files"` in `nvim/.config/nvim/lua/base/keymaps.lua`
- Nushell: `kebab-case` with `def` — `def main`, `def get-distro []`, `def get-deps [distro, mode]`, `def verify-deps [deps]`, `def install-deps ...`, `def run-stow ...`, `def get-mode-interactive []` in `setup.nu`; helpers like `run-unstow`, `unstow-module` in `teardown.nu`
- Zsh: `snake_case` — `get_distro()`, `verify_command()`, `get_deps()`, `run_stow()`, `run_unstow()`, `get_mode_interactive()` in `setup.zsh`/`teardown.zsh`; `zle-keymap-select`, `zle-line-init`, `edit-command-line` autoloads in `zsh/.zshrc`
- Lua: `snake_case` — `lazypath`, `specs`, `lang_config`, `plugin_specs`, `mason_packages`, `treesitter_parsers`, `status_ok`, `lang_module` in `nvim/.config/nvim/init.lua` and `nvim/.config/nvim/lua/lang/init.lua`; short `opt`, `o`, `g` aliases for `vim.opt`/`vim.o`/`vim.g` in `nvim/.config/nvim/lua/base/options.lua`
- Nushell: `snake_case` with `$` — `$distro`, `$selected_mode`, `$deps`, `$missing`, `$dry_run`, `$stow_keyd` in `setup.nu`; `$env.PATH`, `$env.EDITOR`, `$env.STARSHIP_CONFIG`, `$nu.default-config-dir` in `nushell/.config/nushell/*.nu`
- Zsh: `UPPER_SNAKE` for env/global plus `snake_case` for locals — `DRY_RUN`, `MODE`, `STOW_KEYD`, `SCRIPT_NAME`, `XDG_*`, `BUN_INSTALL`, `EDITOR` in `setup.zsh`/`zsh/.zshrc`; locals quoted like `local distro="$1"`; array syntax `local -a common=(...)`
- TOML/CSS: `snake_case` keys (`scan_timeout`/`add_newline` in `starship/.config/starship.toml`; `family`/`style` in `alacritty/.config/alacritty/alacritty.toml`)
- Lua: `snake_case` for type annotations with leading uppercase for class-style in comments — `---@class PluginLspOpts` in `nvim/.config/nvim/lua/plugins/lspconfig.lua`; module types inferred from returned tables `{lsp_servers = {}, mason_packages = {}, ...}` in `nvim/.config/nvim/lua/lang/init.lua`
- Nushell: type hints in `def` params — `[--mode: string]`, `[--dry-run]`, `[--stow-keyd: string]` in `setup.nu:def main`; no custom type defs beyond Nushell primitives
- No distinct type layer beyond Lua `---@class` and TOML schema `$schema = 'https://starship.rs/config-schema.json'`

## Code Style

- Tool: `conform.nvim` (`stevearc/conform.nvim`) with `format_on_save = { timeout_ms=3000, async=false, quiet=false, lsp_format="fallback" }` in `nvim/.config/nvim/lua/plugins/conform.lua` delegating per-filetype to `lang` formatters (e.g., `ruff_format`+`ruff_organize_imports` for python, `prettier` for js/ts/html/css/json in `nvim/.config/nvim/lua/lang/javascript/javascript.lua`)
- Core indent: 4 spaces, LF, `insert_final_newline=true`, `trim_trailing_whitespace=true`, `charset=utf-8` via `nvim/.config/nvim/.editorconfig` (`indent_style=space`, `indent_size=4`, `tab_width=4`, `max_line_length=off`); mirrored in `nvim/.config/nvim/lua/base/options.lua` `shiftwidth=4`, `tabstop=4`, `softtabstop=4`, `expandtab=true`, `smartindent/autointdent=true`
- Visible whitespace: `list=true`, `listchars={tab=". ", trail="_", nbsp="␣"}` in `nvim/.config/nvim/lua/base/options.lua`
- Nushell/Zsh: 4-space indents in `setup.nu`/`setup.zsh`, pipes on new lines in Nushell (`$deps | where { ... }`); Zsh uses `set -euo pipefail` + heredocs for `usage()`
- Tool: Ruff for Python (via `nvim/.config/nvim/lua/lang/python/python.lua` `lsp_servers={pyright,ruff}` with `RUFF_TRACE=messages`, `logLevel=error`); ESLint not configured — JS/TS rely on `ts_ls` + `prettier`
- Diagnostics: `nvim/.config/nvim/lua/plugins/lspconfig.lua` sets `diagnostics={underline=true, update_in_insert=false, virtual_text={spacing=4, source="if_many", prefix="●"}, severity_sort=true, signs={ERROR="󰅙",WARN="",INFO="󰋼",HINT="󰌵"}}`; inlayHints enabled except vue; `folds.enabled=true`
- Editor: `.editorconfig` `root=true` with `g.editorconfig=true` in `nvim/.config/nvim/lua/base/options.lua` to respect repo policy

## Import Organization

- Neovim Lua: no path aliases — plain `require("lang.python.python")`, `require("plugins.telescope")` relative to `lua/` on `runtimepath` (`vim.opt.rtp:prepend(lazypath)` adds lazy path, not alias); `nvim/.config/nvim/lua/lang/init.lua` constructs `"lang."..lang.."."..lang` dynamically
- Nushell: `$nu.default-config-dir | path join "scripts" "uv.nu"` pattern in `nushell/.config/nushell/config.nu`; `$env.HOME | path join ...` for PATH extension in `nushell/.config/nushell/env.nu`
- Zsh: no alias plugin path; completions stored at `~/.config/zsh/completions/_uv` (manually generated) and `~/.local/share/zinit/`
- TOML: `import = ["~/.config/alacritty/catppuccin-mocha.toml"]` in `alacritty/.config/alacritty/alacritty.toml`; Nushell `$env.STARSHIP_CONFIG = $env.HOME | path join ".config" "starship.toml"` so starship locates config indirectly

## Error Handling

- **Guard + early exit:** Nushell `if not ($nu | is-not-empty) { print "Error: must run with Nushell"; exit 1 }` and `if $distro not-in ["arch","cachyos","ubuntu"] { print "Error: only supports ..."; exit 1 }` (`setup.nu:10`, `setup.nu:30`); Zsh `set -euo pipefail` + `verify_command || missing+=` + `usage; exit 1` for unknown flags (`setup.zsh:18`, `setup.zsh:verify_command`)
- **pcall/warn continue:** Lua protects dynamic loads `status_ok, lang_config = pcall(require, lang_module); if not status_ok then vim.notify("Failed to load: "..lang_module.."\n"..tostring(lang_config), WARN) end` (`nvim/.config/nvim/lua/lang/init.lua:25`) and similarly `pcall(require,"lang")` in `nvim/.config/nvim/init.lua:19` — bootstrap continues with empty `M`
- **Collection before action:** Bootstrappers gather `missing` deps list before installing; dry-run short-circuits (`if $dry_run { print "=== DRY RUN MODE ===" }` in `setup.nu:10`, `if [[ "$DRY_RUN" == true ]] then return` variants in `setup.zsh`/`teardown.*`)
- **Neovim safety:** `nvim/.config/nvim/lua/base/options.lua` sets `confirm=true` (prompt before closing unsaved), `exrc=true` + `secure=true` (prompt before trusting local `.nvim.lua`), `g.editorconfig=true`; fold and grep formats handle missing tools (`grepprg=rg --vimgrep` assumes rg present, `cond = vim.fn.executable("make")==1` for telescope-fzf-native)
- **Mason warnings:** `nvim/.config/nvim/lua/utils/mason-install-all.lua` warns on `not mr.has_package(package_name)` and skips `pkg:is_installed()` before `MasonInstall`; aggregates `to_install` then single `MasonInstall` command

## Logging

- Shell bootstrap logs every step with `print $"Detected distribution: ($distro)"` and `print $"Dependencies for ($distro) in ($selected_mode) mode defined."` (Nushell `setup.nu`) vs `echo "\nVerifying dependencies..."` / `echo "All dependencies are satisfied."` (Zsh `setup.zsh`/`teardown.zsh`); teardown warns `print "⚠️  WARNING: Starting Teardown Process"` before requiring `yes`
- Neovim uses `vim.notify("Mason: Installing ... packages: "..table.concat(to_install, ", "), INFO)` or `"Mason: All packages already installed"` in `nvim/.config/nvim/lua/utils/mason-install-all.lua`; `vim.notify("Failed to load language configs: "..tostring(lang_config), ERROR)` on bootstrap failure
- No structured/log-level files; prompt-integrated feedback via `starship`/`p10k` showing `status` (exit code) and `command_execution_time`
- Never log secret values (though `env.nu` contains a committed key — see CONCERNS.md — no runtime logging reveals it per greps)

## Comments

- Block banners for major sections: `-- ╔═══════════════[ Mode Selection ]═══════════════╗` and `-- ╔════════════ NEOVIM SETTINGS ═╗` in `nvim/.config/nvim/lua/settings.lua` and `nvim/.config/nvim/lua/base/options.lua` (grouped UI/Clipboard/Indentation/Search/Mouse/Splits/Undo/Folding)
- Rationale comments where order matters: `# NOTE: zoxide.nu is sourced at the END ... to ensure hooks are not overwritten` and `# NOTE: cd alias is defined AFTER zoxide.nu` in `nushell/.config/nushell/config.nu`; `# Enable Powerlevel10k instant prompt. Should stay close to the top ... Initialization code that may require console input must go above` in `zsh/.zshrc`
- Per-option inline docs: `o.shiftwidth = 4 -- Indent width` and `opt.listchars = { tab = ". " -- Tabs shown as ▸ }` in `nvim/.config/nvim/lua/base/options.lua` (also clarifies `ignorecase` semantics: `Ignore case when searching --> Example: /hello matches "Hello"`)
- Language module headers: `-- ══════════════ Language Configuration Loader ══════════════` + `This file automatically loads ... To add/remove languages, edit lua/settings.lua` in `nvim/.config/nvim/lua/lang/init.lua`
- Avoid TODO/FIXME comments — only references are in plugin `to-do.lua` alt lists and keymap descriptions (`<leader>sT` for TodoTelescope), not code
- Sparse — Lua uses `---@diagnostic disable: undefined-global` at top of `nvim/.config/nvim/lua/base/keymaps.lua` and `---@class PluginLspOpts` in `nvim/.config/nvim/lua/plugins/lspconfig.lua`; most functions are undocumented beyond `desc = "Toggle NvimTree"` style keymap descriptors; Nushell/Zsh/TOML have no JSDoc equivalent

## Function Design

## Module Design

<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

## System Overview

```text

```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Bootstrapper (Nushell) | Distro detection, dep verification, stow orchestration, dry-run, keyd prompt | `setup.nu`, `teardown.nu` |
| Bootstrapper (Zsh) | Same as Nushell path but for Zsh users | `setup.zsh`, `teardown.zsh` |
| Shell: Nushell | Vi-mode, completions, history menus, zoxide/venv/uv integration | `nushell/.config/nushell/config.nu`, `nushell/.config/nushell/env.nu`, `nushell/.config/nushell/login.nu`, `nushell/.config/nushell/scripts/*.nu` |
| Shell: Zsh | Zinit plugin mgmt, Powerlevel10k prompt, vi keybindings, zoxide/bun paths | `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh` |
| Editor core | Lazy bootstrap, global options, keymaps, autocmds, settings aggregation | `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lua/base/options.lua`, `nvim/.config/nvim/lua/base/keymaps.lua`, `nvim/.config/nvim/lua/base/autocmds.lua`, `nvim/.config/nvim/lua/settings.lua` |
| Lang aggregator | Loads enabled `languages[]`, merges LSP/formatters/mason/treesitter/plugin specs | `nvim/.config/nvim/lua/lang/init.lua` |
| Language modules | Per-language LSP, formatters, Mason packages, treesitter parsers, plugins | `nvim/.config/nvim/lua/lang/bash/bash.lua`, `nvim/.config/nvim/lua/lang/python/python.lua`, `nvim/.config/nvim/lua/lang/javascript/javascript.lua`, `nvim/.config/nvim/lua/lang/css/*` etc. (14 languages) |
| Plugin layer | Conform, Telescope, LSPconfig, Treesitter, UI plugins | `nvim/.config/nvim/lua/plugins/*.lua` (21 files) |
| Colorschemes | Theme switcher (tokyodark active, catppuccin/nightfox/gruvbox alternatives) | `nvim/.config/nvim/lua/colorschemes/*.lua`, `nvim/.config/nvim/lua/colorschemes/init.lua` |
| Prompt/Terminal | Powerline Starship prompt, Alacritty terminal theme | `starship/.config/starship.toml`, `starship/.config/starship-minimal.toml`, `alacritty/.config/alacritty/alacritty.toml`, `alacritty/.config/alacritty/catppuccin-mocha.toml` |
| Input/Launcher | Key remapping and app launcher | `keyd/etc/keyd/default.conf`, `wofi/.config/wofi/config`, `wofi/.config/wofi/style.css` |
| Icons/Utils | LSP kind icons, Mason bulk installer, LSP restart helper | `nvim/.config/nvim/lua/icons/lspkind.lua`, `nvim/.config/nvim/lua/utils/mason-install-all.lua`, `nvim/.config/nvim/lua/utils/lsp-restart.lua` |

## Pattern Overview

- **Stow packages as bounded contexts** — each top-level directory (`nvim/`, `nushell/`, `zsh/`, `alacritty/`, `starship/`, `wofi/`, `keyd/`) is a self-contained GNU Stow package mapping to a distinct XDG/system target; `README.md` describes `stow --restow nvim nushell starship` vs `stow --restow nvim zsh` paths
- **Aggregator pattern for language support** — `nvim/.config/nvim/lua/lang/init.lua` dynamically `pcall(require, "lang."..lang.."."..lang)` aggregating six concerns (lsp_servers, lsp_config, formatters, mason_packages, treesitter_parsers, plugin_specs) with deduplication; callers like `nvim/.config/nvim/lua/plugins/conform.lua` and `mason.lua` simply `require("lang")`
- **Declarative centralized settings** — `nvim/.config/nvim/lua/settings.lua` is the single source of truth for `colorscheme` and `languages[]`; consumers read it at startup; init.lua applies colorscheme after lazy completes via `vim.schedule`
- **Dual-shell parity without sharing** — Nushell and Zsh implement the same `get-distro`, `get-deps`, `verify-deps`, `run-stow` flow in native syntax but share no code; README documents "Choose your shell path" table
- **Lazy-loading by default** — `nvim/.config/nvim/init.lua` sets `defaults.lazy=true` and disables 23 built-in runtime plugins for startup performance; individual plugin specs declare `event`, `cmd`, `ft`, `keys` triggers

## Layers

- Purpose: Validate host, install missing deps, symlink configs, handle privileged `keyd` path
- Location: `setup.nu`, `setup.zsh`, `teardown.nu`, `teardown.zsh` (repo root)
- Contains: `get-distro()`, `get-deps(distro, mode)`, `verify-deps`, `install-deps`, `run-stow`/`run_unstow` functions, interactive `get-mode-interactive` prompts, `DRY_RUN`/`STOW_KEYD` flags
- Depends on: Host `stow`, `which`/`command -v`, `git`, `/etc/os-release`, `sudo` for keyd
- Used by: Manual invocation `nu setup.nu --mode server` or `zsh setup.zsh --mode local`; README documents both
- Purpose: Interactive shell behavior, env, prompt, directory jumping, Python venv helpers
- Location: `nushell/.config/nushell/` (config.nu, env.nu, login.nu, scripts/*), `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`
- Contains: Nushell vi-mode, completion menus, starship/MISTRAL env; Zsh Zinit bootstrap, Powerlevel10k instant prompt, vi `bindkey`, `zoxide init`, `fzf` wiring
- Depends on: `starship`, `zoxide`, `uv`, `starship/.config/starship.toml`, `nushell/.config/nushell/scripts/zoxide.nu`
- Used by: User login shell
- Purpose: Editing, LSP, formatting, navigation, theming
- Location: `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lua/base/*`, `nvim/.config/nvim/lua/plugins/*`, `nvim/.config/nvim/lua/lang/*`, `nvim/.config/nvim/lua/colorschemes/*`, `nvim/.config/nvim/lua/utils/*`
- Contains: Base options/keymaps/autocmds, lazy spec aggregation, 21 plugin configs, 14 language modules, 4 theme stubs, icons/lsp helpers
- Depends on: `nvim/.config/nvim/lua/settings.lua` (active languages/theme), `nvim/.config/nvim/lazy-lock.json`, Mason registry, treesitter binaries
- Used by: `EDITOR=nvim` everywhere (`nushell/.config/nushell/env.nu`, `zsh/.zshrc`)
- Purpose: Terminal rendering, prompt theming, key remapping, app launching
- Location: `alacritty/.config/alacritty/*`, `starship/.config/starship.toml`, `wofi/.config/wofi/*`, `keyd/etc/keyd/default.conf`
- Contains: Alacritty catppuccin import, Starship powerline format, Wofi CSS, keyd `default.conf`
- Depends on: Fonts (JetBrainsMono Nerd Font), `starship`, `wofi`/`waybar`/`grim` on Hyprland
- Used by: GUI sessions (`zsh/.zprofile` auto `exec start-hyprland` on tty1)

## Data Flow

### Primary Request Path — Stow Deployment

### Secondary Flow — Neovim Startup

### Secondary Flow — Nushell Shell Startup

- Stateless dotfiles — no runtime DB, no server session. State persists only as filesystem artifacts: `nushell/.config/nushell/history.txt|json` (nushell history), `zsh/.zsh_history`, `nvim/.config/nvim/undo/`, `nvim/.config/nvim/shada/`, `nvim/.config/nvim/state/`, `nvim/.config/nvim/cache/`, `zoxide` db. Neovim LSP state transient; Mason installs to `stdpath("data")`

## Key Abstractions

- Purpose: Single deployable unit mapping repo subdir → XDG/system location
- Examples: `nvim/.config/nvim/**`, `nushell/.config/nushell/**`, `alacritty/.config/alacritty/**`, `keyd/etc/keyd/default.conf`
- Pattern: GNU Stow convention — repo root contains packages, each contains `.[config|local]/...` mirror of deployment tree; `setup.*` passes package names directly to `stow --restow`
- Purpose: Declare everything a language needs so editor composes it without per-language wiring
- Examples: `nvim/.config/nvim/lua/lang/python/python.lua` (returns `{lsp_servers={pyright,ruff}, maso_packages, treesitter={python}, formatters, lsp_config}`), `nvim/.config/nvim/lua/lang/javascript/javascript.lua`, `nvim/.config/nvim/lua/lang/docker/docker.lua`, `nvim/.config/nvim/lua/lang/django/django.lua`
- Pattern: Each `<lang>.lua` returns table with optional keys `lsp_servers`, `lsp_config`, `formatters`, `formatters_config`, `mason_packages`, `treesitter`, `luasnip_extends`; companion `<lang>/plugins.lua` returns array of lazy specs (e.g., `ven-selector.nvim` for python). Aggregator deduplicates
- Purpose: Editor fundamentals independent of language
- Examples: `nvim/.config/nvim/lua/base/options.lua` (UI, clipboard, indentation, search, folds, grep), `nvim/.config/nvim/lua/base/keymaps.lua` (window/nav, telescope, formatting, terminal), `nvim/.config/nvim/lua/base/autocmds.lua`, `nvim/.config/nvim/lua/base/init.lua` (re-export), `nvim/.config/nvim/lua/settings.lua` (central toggle)
- Pattern: `base` re-exported after init; keymaps use `vim.keymap.set` with `desc`; options via `vim.opt`/`vim.o`/`vim.g` with `editorconfig=true`
- Purpose: Reusable helpers for mode-aware deployment
- Examples: `get-distro`, `get-deps`, `verify-deps`, `install-deps`, `run-stow`, `get-mode-interactive` in both `setup.nu` and `setup.zsh` (mirrored logic, different syntax)
- Pattern: `DRY_RUN` guard returns early without exec; missing-deps collection before install; keyd handled specially due to `/etc` target and sudo

## Entry Points

- Location: `setup.nu`, `setup.zsh` (deploy), `teardown.nu`, `teardown.zsh` (unstow)
- Triggers: Manual CLI `nu setup.nu [--mode local|server] [--dry-run] [--stow-keyd y|n]` or `zsh setup.zsh --mode local`; teardown asks `Type 'yes' to confirm` (Nushell) or `read REPLY`
- Responsibilities: Validate distro, verify deps, optionally install, stow/unstow core vs GUI modules, reload keyd, print summary; `README.md` documents both shell paths
- Location: `nvim/.config/nvim/init.lua`
- Triggers: `nvim` launch (or `EDITOR=nvim` via `git commit`, `edit-command-line` in `zsh/.zshrc` Ctrl+X Ctrl+E)
- Responsibilities: Bootstrap lazy.nvim, compose language + plugin specs, configure lazy with performance rtp disabled_plugins, require `base`, schedule colorscheme
- Location: `nushell/.config/nushell/env.nu` + `config.nu` + `login.nu` ; `zsh/.zshrc` + `zsh/.zprofile` + `zsh/.p10k.zsh`
- Triggers: Login or interactive shell; `zsh/.zprofile` `exec start-hyprland` on tty1
- Responsibilities: Export env/PATH, init zoxide/starship, set vi-mode, load completions, configure prompt; Alacritty/Wofi/Keyd read their configs on process start (not shell-triggered)
- Location: Any `nvim/`, `nushell/`, `alacritty/`, `starship/`, `wofi/`, `keyd/` directory
- Triggers: Manual `stow --restow <package>` per README "Manual Installation" sections
- Responsibilities: Symlink single package without bootstrapper validation

## Architectural Constraints

- **Threading:** Single-threaded shell scripts; Neovim is single event loop with async jobs for LSP/formatters/treesitter installs via `mr.refresh(callback)` and `MasonInstall` jobs
- **Global state:** `nvim/.config/nvim/lua/lang/init.lua` singleton `M` table aggregated once and required elsewhere; `vim.g`, `vim.o`, `vim.opt` are global editor state; `settings.languages` is global toggle; `zsh/.zshrc` global `PATH`, `EDITOR`, `BUN_INSTALL`; `nushell/.config/nushell/env.nu` global `$env.*`
- **Circular imports:** None detected; dependency direction is `init.lua → lang/init.lua → lang/*/*` and `plugins/*.lua → require("lang")` (plugins depend on aggregator, not vice versa); `colorschemes` imported as lazy spec does not depend on plugins
- **Stow package isolation:** Packages must not overlap paths; adding a file under `nvim/.config/nvim/` affects only nvim package; cross-package imports (e.g., Nushell script reading `~/.config/starship.toml`) are via installed location not repo relative path
- **Mason as side-effect:** Language modules declare `mason_packages` but installation is manual `MasonInstallAll` not automatic on startup; drift between declared and installed is possible (see CONCERNS.md)

## Anti-Patterns

### Hard-coded secret in committed env file

### Mirrored bootstrapper logic without shared module

## Error Handling

- `setup.nu:main` guards `if not ($nu | is-not-empty) { print "Error: must run with Nushell"; exit 1 }` and `if $distro not-in ["arch","cachyos","ubuntu"] { exit 1 }`; `setup.zsh` uses `set -euo pipefail`, `verify_command || missing+=`, `usage; exit 1` for unknown flags
- Neovim language loading uses `pcall(require, lang_module)` then `vim.notify(..., WARN)` on failure (`nvim/.config/nvim/lua/lang/init.lua:23`), recovers with empty `M`; `init.lua` wraps `pcall(require, "lang")` similarly, notifying on error but continuing
- `teardown.nu:main` requires `input "Type 'yes' to confirm"` unless `dry_run`; `teardown.zsh` uses `read REPLY` confirmation; both abort unless exact `yes`
- `mason-install-all.lua:mr.refresh(function() ... if mr.has_package then ... else vim.notify("Warning: Mason doesn't have package: ...", WARN) end)` — missing registry entry is warning not error

## Cross-Cutting Concerns

<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
