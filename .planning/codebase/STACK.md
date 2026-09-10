# Technology Stack

**Analysis Date:** 2026-09-10

## Languages

**Primary:**
- Lua 5.1+ / LuaJIT - Neovim configuration (`nvim/.config/nvim/lua/**/*.lua`, `nvim/.config/nvim/init.lua`) — core editor config, plugin specs, LSP, treesitter, language modules
- Nushell 0.110.0 - Shell bootstrap and environment (`nushell/.config/nushell/config.nu`, `nushell/.config/nushell/env.nu`, `setup.nu`, `teardown.nu`, `nushell/.config/nushell/scripts/*.nu`)
- Zsh - Alternative shell path (`zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`, `setup.zsh`, `teardown.zsh`) with vi-mode and Zinit plugin manager
- Shell (Bash/POSIX) — subshell fragments inside setup/teardown scripts

**Secondary:**
- TOML - Alacritty and Starship configuration (`alacritty/.config/alacritty/alacritty.toml`, `alacritty/.config/alacritty/catppuccin-mocha.toml`, `starship/.config/starship.toml`, `starship/.config/starship-minimal.toml`)
- CSS - Wofi launcher styling (`wofi/.config/wofi/style.css`)
- INI-like (keyd) — Keyboard remapping (`keyd/etc/keyd/default.conf`)
- Python (indirect) - Managed via `uv` for Neovim venv workflows (`nushell/.config/nushell/scripts/uv.nu`, `nushell/.config/nushell/scripts/venv.nu`)
- JSON - Plugin lockfiles and editor state (`nvim/.config/nvim/lazy-lock.json`, `nvim/.config/nvim/.neoconf.json`, `nushell/.config/nushell/history.json`)
- Markdown - Documentation (`README.md`, `nvim/.config/nvim/README.md`)

## Runtime

**Environment:**
- Neovim >=0.10 (requires `nvim`, `gcc`, `make`, `luarocks`, `tree-sitter-cli`, `wl-clipboard`) — `nvim/.config/nvim/lazy-lock.json` tracks ~44 plugins
- Nushell 0.110.0+ (interactive shell, `setup.nu` validates via `$nu | is-not-empty`)
- Zsh with Zinit (`zsh/.zshrc` clones `https://github.com/zdharma-continuum/zinit` to `~/.local/share/zinit/zinit.git` on first run)
- Starship prompt (`starship/.config/starship.toml`, schema `https://starship.rs/config-schema.json`)

**Package Manager:**
- GNU Stow - Dotfile deployment (`setup.nu`/`setup.zsh` use `stow --restow`, `teardown.nu`/`teardown.zsh` use `stow -D`)
- uv - Python package/tool installer and venv manager (`nushell/.config/nushell/scripts/uv.nu` provides `uv` completions and `uv generate-shell-completion` for Zsh in `setup.zsh`)
- npm - Node tooling for Neovim JS/TS language support (`setup.*` lists `node`, `npm` as core deps)
- Mason registry - In-editor LSP/formatter/linter installer (`nvim/.config/nvim/lua/utils/mason-install-all.lua`, `nvim/.config/nvim/lua/plugins/mason.lua`)
- lazy.nvim - Neovim plugin manager (`nvim/.config/nvim/init.lua` bootstraps `folke/lazy.nvim` from GitHub, pinned commits via `nvim/.config/nvim/lazy-lock.json`)
- No `package.json`/`Cargo.toml`/`pyproject.toml` at repo root — this is a configuration repo, not a buildable application

- Lockfile: `nvim/.config/nvim/lazy-lock.json` present (44 plugin pins), `nvim/.config/nvim/.editorconfig` present, no Node/Python lockfiles at root

## Frameworks

**Core:**
- lazy.nvim (stable branch) - Plugin orchestration, lazy-loading defaults (`nvim/.config/nvim/init.lua` sets `defaults.lazy=true`, disables 23 built-in runtime plugins)
- Blink.cmp (`saghen/blink.cmp`) - Completion engine with LSP merging (`nvim/.config/nvim/lua/plugins/blink-cmp.lua`, integrates with `blink-ripgrep.nvim`)
- nvim-lspconfig + Mason - LSP provisioning (`nvim/.config/nvim/lua/plugins/lspconfig.lua`, `nvim/.config/nvim/lua/plugins/mason.lua`, `nvim/.config/nvim/lua/utils/mason-install-all.lua`)
- Treesitter (`nvim-treesitter` main branch) - Parsing and highlighting (`nvim/.config/nvim/lua/plugins/treesitter.lua`, `treesitter-context.lua`, `treesitter-textobjects.lua`)
- Powerlevel10k — Zsh prompt theme (`zsh/.p10k.zsh` generated 2026-04-26, instant prompt enabled in `zsh/.zshrc`)
- Zinit — Zsh plugin manager (auto-cloned, loaded in `zsh/.zshrc`)

**Testing:**
- No formal test framework detected (no `jest.config.*`, `vitest.config.*`, `pytest.ini`, `Cargo.toml`). Lightweight smoke scripts only: `nushell/.config/nushell/scripts/test-venv.nu` and `nushell/.config/nushell/scripts/test-zoxide.nu`
- nvim's health via `:checkhealth` and Mason's `MasonInstallAll` command are ad-hoc validation

**Build/Dev:**
- `conform.nvim` (`stevearc/conform.nvim`) - Format-on-save orchestration (`nvim/.config/nvim/lua/plugins/conform.lua`, 3000ms timeout, `lsp_format=fallback`)
- `stow` + `setup.nu`/`setup.zsh` bootstrapper - Idempotent deployment with `--dry-run`, `--mode local|server`, `--stow-keyd` flags
- `zoxide` - Directory jumping (`nushell/.config/nushell/scripts/zoxide.nu`, `zsh/.zshrc` runs `eval "$(zoxide init zsh)"`, Nushell hooks `env_change.PWD` with `zoxide add -- $dir`)
- `ripgrep` (`rg`) - Grep engine (`nvim/.config/nvim/lua/base/options.lua` sets `grepprg=rg --vimgrep`, telescope live_grep)
- `uv` - Python venv and tool management (`nushell/.config/nushell/scripts/venv.nu` provides `venv-selector.nvim` integration `linux-cultist/venv-selector.nvim`)

## Key Dependencies

**Critical:**
- `stow` - Must be present; `setup.nu:verify-deps` and `setup.zsh:verify_command` abort if missing — entire deployment depends on it
- `neovim` - Central editor; all `nvim/.config/nvim/lua/**` depends on lazy.nvim bootstrap and `vim.loop.fs_stat` check
- `starship` - Prompt for Nushell/Zsh; config at `starship/.config/starship.toml` with `catppuccin_latte` palette, powerline format with `os`, `directory`, `git_branch`, `c/rust/golang/nodejs/python`, `conda`, `time`
- `zoxide` - Navigation; `nushell/.config/nushell/scripts/zoxide.nu` and `zsh/.zshrc` both initialize hooks; aliases `z` and `zi`
- `uv` - Python tooling; `nushell/.config/nushell/scripts/uv.nu` (400+ line completion set), `nushell/.config/nushell/scripts/venv.nu`; Zsh generates `~/.config/zsh/completions/_uv`
- `ripgrep` (`rg`) - Required for telescope grep, `grep -r` patterns, and `options.lua:grepprg`
- `git` - Versioning and lazy.nvim cloning and telescope git_status/git_commits pickers
- `node`/`npm` + `wl-clipboard` + `gcc`/`make` — required per `nvim/.config/nvim/README.md` for treesitter builds and clipboard (`nvim/.config/nvim/lua/base/options.lua` sets `clipboard=unnamedplus` unless `SSH_TTY`)

**Infrastructure:**
- `keyd` - System key remapping (`keyd/etc/keyd/default.conf`, privileged `sudo stow --adopt -t / keyd` + `sudo keyd reload`, sudoers NOPASSWD for `systemctl start|stop keyd`)
- `alacritty` - Terminal (`alacritty/.config/alacritty/alacritty.toml` imports `catppuccin-mocha.toml`, JetBrainsMono Nerd Font 12.0)
- `wofi` + `waybar` + `grim`/`slurp`/`wl-copy` - Hyprland GUI stack (`setup.nu:get-deps` and `setup.zsh:get_deps` list `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-copy` for `local` mode on Arch/CachyOS; subset on Ubuntu)
- Catppuccin themes - `alacritty/.config/alacritty/catppuccin-mocha.toml`, `nushell/.config/nushell/scripts/catppuccin.nu`, Neovim `catppuccin` colorscheme (`catppuccin.lua`) plus `gruvbox`, `nightfox`, `tokyodark` (`tokyodark` active in `nvim/.config/nvim/lua/settings.lua`)
- Zsh extras: `fzf`/`make` for `telescope-fzf-native.nvim` (`nvim/.config/nvim/lua/plugins/telescope.lua` conditions on `vim.fn.executable("make")==1`), `bun` (`zsh/.zshrc` exports `BUN_INSTALL=~/.bun`, git log shows `add bun completions`/`add bun install path`)

## Configuration

**Environment:**
- Nushell: `nushell/.config/nushell/env.nu` sets `XDG_CACHE_HOME/CONFIG_HOME/DATA_HOME`, `PATH` prepends `~/.local/bin`, `~/.local/sbin`, `~/.cargo/bin`, `~/.bun/bin`, `~/.npm-global/bin`, sets `EDITOR=nvim`, `STARSHIP_CONFIG=~/.config/starship.toml`, `PIPX_TOOL_INSTALLER=uv`, `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`, `LANG=en_US.UTF-8`; `.env` presence noted but never read (forbidden)
- Zsh: `zsh/.zshrc` mirrors XDG exports, `EDITOR=nvim`, `BUN_INSTALL`, `PATH`, `N8N_RESTRICT_FILE_ACCESS_TO=""`, `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`; `zsh/.zprofile` auto-`exec start-hyprland` on `tty1` without DISPLAY; `.p10k.zsh` controls prompt elements (`os_icon`, `dir`, `vcs`, `status`, `command_execution_time`, battery, todo, etc.)
- Neovim: `nvim/.config/nvim/lua/settings.lua` centralizes `colorscheme="tokyodark"` and `languages={bash,git,python,javascript,html,css,markdown,lua,sql,django,json,yaml,toml,docker}` (c disabled); `nvim/.config/nvim/lua/base/options.lua` defines 4-space indents, editor behavior, clipboard, folding, etc.; `.editorconfig` enforces `indent_style=space`, `indent_size=4`, `lf`, `utf-8`, `trim_trailing_whitespace`
- Starship: `starship/.config/starship.toml` (`scan_timeout=1000`, `add_newline=false`, custom powerline `format`/`right_format`); `starship/.config/starship-minimal.toml` variant exists but Nushell `env.nu` points to `starship.toml`
- Secret-like env: `MISTRAL_API_KEY` set in `nushell/.config/nushell/env.nu` (value not reproduced here — see CONCERNS.md)

**Build:**
- No compiled build; deployment is `stow` symlinking. `setup.nu`/`setup.zsh` verify distro (`arch`|`cachyos`|`ubuntu` else error) and missing deps, optionally `install-deps` then `run-stow`/`run_unstow`-equivalent. Flags: `--mode local|server`, `--dry-run`, `--stow-keyd y|n`, `--help`
- `nvim/.config/nvim/init.lua` bootstrap clones lazy.nvim if `vim.loop.fs_stat(lazypath)` fails; `lazy-lock.json` pins exact commits for reproducible installs; `MasonInstallAll` (`nvim/.config/nvim/lua/utils/mason-install-all.lua`) bulk-installs `mason_packages` from `lang` aggregation
- `zsh/.zshrc` completion generation: `uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv` (manual step in README)

## Platform Requirements

**Development:**
- Supported distros: Arch Linux / CachyOS / Ubuntu (checked in `setup.nu:get-distro` and `setup.zsh:get_distro` via `/etc/os-release` ID). Other distros error with manual instructions per `README.md`
- Core packages: `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm` (always). GUI extras for `--mode local`: Arch/CachyOS adds `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-copy`; Ubuntu adds `alacritty`, `wofi`, `waybar`, `grim`, `slurp`, `wl-copy`
- Nushell required for `setup.nu`/`teardown.nu` (`$nu | is-not-empty` guard); Zsh required for `setup.zsh`/`teardown.zsh` (`set -euo pipefail`)
- Editor toolchain: `gcc`, `make`, `luarocks`, `tree-sitter-cli`, `wl-clipboard`, `python3-pip` (per `nvim/.config/nvim/README.md`)
- Fonts: JetBrainsMono Nerd Font (Alacritty config)

**Production:**
- Deployment target: Local workstation or headless server — `README.md` defines two modes: `local` (full GUI) and `server` (headless: only `nvim`, `nushell`, `starship`, or `nvim`+`zsh` on Zsh path)
- Stow deployment maps repo subdirs to `$HOME`/`~/.config`/`/etc`; `keyd` requires root (`sudo stow --adopt -t / keyd`)
- No CI/CD hosting; git remote `origin` on `main` branch; backup branch `backup` exists locally

---

*Stack analysis: 2026-09-10*
