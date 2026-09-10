<!-- refreshed: 2026-09-10 -->
# Architecture

**Analysis Date:** 2026-09-10

## System Overview

```text
┌───────────────────────────────────────────────────────────────────────┐
│                    Delivery / Stow Layer                               │
│   `setup.nu` / `setup.zsh`  ──►  GNU Stow  ──►  $HOME / ~/.config / /etc│
│   `teardown.nu`/`teardown.zsh` ◄── unstow                               │
├──────────────────┬──────────────────┬──────────────────┬───────────────┤
│  Shell Layer     │  Editor Layer    │  Terminal Layer  │  Desktop      │
│ `nushell/`       │ `nvim/`          │ `alacritty/`     │ `wofi/`       │
│ `zsh/`           │  init.lua+bases  │ `starship/`      │ `keyd/`       │
│ config.nu/env.nu│  lang/* + plugins│  alacritty.toml  │ default.conf  │
└────────┬─────────┴────────┬─────────┴────────┬─────────┴──────┬────────┘
         │                  │                  │                │
         ▼                  ▼                  ▼                ▼
┌───────────────────────────────────────────────────────────────────────┐
│                 Host Primitives (no code)                              │
│  Neovim runtime • Nushell/Zsh • Starship • zoxide • uv • git • ripgrep │
└───────────────────────────────────────────────────────────────────────┘
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

**Overall:** Stow-based Monorepo with Language-Oriented Plugin Composition and Dual-Shell Deployment

**Key Characteristics:**
- **Stow packages as bounded contexts** — each top-level directory (`nvim/`, `nushell/`, `zsh/`, `alacritty/`, `starship/`, `wofi/`, `keyd/`) is a self-contained GNU Stow package mapping to a distinct XDG/system target; `README.md` describes `stow --restow nvim nushell starship` vs `stow --restow nvim zsh` paths
- **Aggregator pattern for language support** — `nvim/.config/nvim/lua/lang/init.lua` dynamically `pcall(require, "lang."..lang.."."..lang)` aggregating six concerns (lsp_servers, lsp_config, formatters, mason_packages, treesitter_parsers, plugin_specs) with deduplication; callers like `nvim/.config/nvim/lua/plugins/conform.lua` and `mason.lua` simply `require("lang")`
- **Declarative centralized settings** — `nvim/.config/nvim/lua/settings.lua` is the single source of truth for `colorscheme` and `languages[]`; consumers read it at startup; init.lua applies colorscheme after lazy completes via `vim.schedule`
- **Dual-shell parity without sharing** — Nushell and Zsh implement the same `get-distro`, `get-deps`, `verify-deps`, `run-stow` flow in native syntax but share no code; README documents "Choose your shell path" table
- **Lazy-loading by default** — `nvim/.config/nvim/init.lua` sets `defaults.lazy=true` and disables 23 built-in runtime plugins for startup performance; individual plugin specs declare `event`, `cmd`, `ft`, `keys` triggers

## Layers

**Delivery/Orchestration:**
- Purpose: Validate host, install missing deps, symlink configs, handle privileged `keyd` path
- Location: `setup.nu`, `setup.zsh`, `teardown.nu`, `teardown.zsh` (repo root)
- Contains: `get-distro()`, `get-deps(distro, mode)`, `verify-deps`, `install-deps`, `run-stow`/`run_unstow` functions, interactive `get-mode-interactive` prompts, `DRY_RUN`/`STOW_KEYD` flags
- Depends on: Host `stow`, `which`/`command -v`, `git`, `/etc/os-release`, `sudo` for keyd
- Used by: Manual invocation `nu setup.nu --mode server` or `zsh setup.zsh --mode local`; README documents both

**Shell Runtime:**
- Purpose: Interactive shell behavior, env, prompt, directory jumping, Python venv helpers
- Location: `nushell/.config/nushell/` (config.nu, env.nu, login.nu, scripts/*), `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.p10k.zsh`
- Contains: Nushell vi-mode, completion menus, starship/MISTRAL env; Zsh Zinit bootstrap, Powerlevel10k instant prompt, vi `bindkey`, `zoxide init`, `fzf` wiring
- Depends on: `starship`, `zoxide`, `uv`, `starship/.config/starship.toml`, `nushell/.config/nushell/scripts/zoxide.nu`
- Used by: User login shell

**Editor Runtime (Neovim):**
- Purpose: Editing, LSP, formatting, navigation, theming
- Location: `nvim/.config/nvim/init.lua`, `nvim/.config/nvim/lua/base/*`, `nvim/.config/nvim/lua/plugins/*`, `nvim/.config/nvim/lua/lang/*`, `nvim/.config/nvim/lua/colorschemes/*`, `nvim/.config/nvim/lua/utils/*`
- Contains: Base options/keymaps/autocmds, lazy spec aggregation, 21 plugin configs, 14 language modules, 4 theme stubs, icons/lsp helpers
- Depends on: `nvim/.config/nvim/lua/settings.lua` (active languages/theme), `nvim/.config/nvim/lazy-lock.json`, Mason registry, treesitter binaries
- Used by: `EDITOR=nvim` everywhere (`nushell/.config/nushell/env.nu`, `zsh/.zshrc`)

**Presentation/Peripheral:**
- Purpose: Terminal rendering, prompt theming, key remapping, app launching
- Location: `alacritty/.config/alacritty/*`, `starship/.config/starship.toml`, `wofi/.config/wofi/*`, `keyd/etc/keyd/default.conf`
- Contains: Alacritty catppuccin import, Starship powerline format, Wofi CSS, keyd `default.conf`
- Depends on: Fonts (JetBrainsMono Nerd Font), `starship`, `wofi`/`waybar`/`grim` on Hyprland
- Used by: GUI sessions (`zsh/.zprofile` auto `exec start-hyprland` on tty1)

## Data Flow

### Primary Request Path — Stow Deployment

1. User runs entry point `setup.nu --mode local --dry-run` or `setup.zsh --mode server` (`setup.nu:1`, `setup.zsh:1`)
2. `get-distro()` reads `/etc/os-release` ID (`setup.nu:get-distro`, `setup.zsh:get_distro`) and validates against `["arch","cachyos","ubuntu"]` else abort
3. `get-deps distro mode` returns `common=[stow,nvim,starship,git,zoxide,uv,rg,node,npm]` plus GUI extras if `mode==local` (`setup.nu:get-deps`, `setup.zsh:get_deps`)
4. `verify-deps deps` checks `which`/`command -v` for each; collects `missing` (`setup.nu:verify-deps`, `setup.zsh:verify_command`)
5. `install-deps distro missing dry_run` dispatches to `pacman -S` or `apt install` unless `dry_run` (`setup.nu:install-deps`, `setup.zsh`)
6. `run-stow selected_mode dry_run stow_keyd` maps mode → module list (`core=[nvim,nushell,starship]` or `[nvim,zsh]` vs `gui=[hyprland,alacritty,wofi,keyd...]`) and executes `stow --restow <modules>` and optionally `sudo stow --adopt -t / keyd && sudo keyd reload && sudo systemctl` with NOPASSWD wiring (`setup.nu:run-stow`, `setup.zsh:run_stow`)
7. Shell reload / Neovim launch picks up symlinks (`nushell/.config/nushell/config.nu` sources `scripts/uv.nu`, `scripts/venv.nu`, `scripts/catppuccin.nu`, `scripts/completion.nu` then `scripts/zoxide.nu` last)

### Secondary Flow — Neovim Startup

1. `nvim/.config/nvim/init.lua:1` bootstraps `lazy.nvim` via `vim.loop.fs_stat(lazypath)` fallback `git clone --filter=blob:none`
2. `nvim/.config/nvim/init.lua:12` builds `specs={{import="plugins"}, require("colorschemes")}` plus language plugin specs from `nvim/.config/nvim/lua/lang/init.lua` (`for lang in languages do pcall(require, "lang."..lang..".plugins")`)
3. `nvim/.config/nvim/init.lua:44` calls `require("lazy").setup(specs, opts)` with `defaults.lazy=true`, disabled builtins, icon overrides
4. `nvim/.config/nvim/lua/lang/init.lua:20-120` loads `settings.languages`, aggregates `lsp_servers/mason_packages/treesitter_parsers` with dedup, returns `M`
5. Post-setup, `vim.schedule(function() vim.cmd.colorscheme(settings.colorscheme) end)` applies selected theme (`nvim/.config/nvim/init.lua:78`)
6. Demand-driven: `nvim/.config/nvim/lua/plugins/lspconfig.lua` on `BufReadPre`, `conform.lua` on `BufReadPre/BufNewFile` with `format_on_save`, `telescope.lua` on `cmd Telescope`, `blink-cmp.lua` on insert — each consumes aggregated `require("lang")`

### Secondary Flow — Nushell Shell Startup

1. `nushell/.config/nushell/env.nu` runs before `config.nu` — sets XDG, PATH, `EDITOR`, `STARSHIP_CONFIG`, `MISTRAL_API_KEY`, `uv` completions base
2. `nushell/.config/nushell/config.nu:5` sources `scripts/uv.nu`, `scripts/venv.nu`, `scripts/catppuccin.nu`, `scripts/completion.nu`; configures `$env.config` with vi-mode, menus (history_menu, help_menu, smart_history), keybindings
3. Tail of `nushell/.config/nushell/config.nu` (and `env.nu` docs) sources `scripts/zoxide.nu` last to avoid hook overwrite; `env.nu` `hooks.env_change.PWD` appended with `zoxide add -- $dir`

**State Management:**
- Stateless dotfiles — no runtime DB, no server session. State persists only as filesystem artifacts: `nushell/.config/nushell/history.txt|json` (nushell history), `zsh/.zsh_history`, `nvim/.config/nvim/undo/`, `nvim/.config/nvim/shada/`, `nvim/.config/nvim/state/`, `nvim/.config/nvim/cache/`, `zoxide` db. Neovim LSP state transient; Mason installs to `stdpath("data")`

## Key Abstractions

**Stow Package:**
- Purpose: Single deployable unit mapping repo subdir → XDG/system location
- Examples: `nvim/.config/nvim/**`, `nushell/.config/nushell/**`, `alacritty/.config/alacritty/**`, `keyd/etc/keyd/default.conf`
- Pattern: GNU Stow convention — repo root contains packages, each contains `.[config|local]/...` mirror of deployment tree; `setup.*` passes package names directly to `stow --restow`

**Language Module (`lang.<name>`):**
- Purpose: Declare everything a language needs so editor composes it without per-language wiring
- Examples: `nvim/.config/nvim/lua/lang/python/python.lua` (returns `{lsp_servers={pyright,ruff}, maso_packages, treesitter={python}, formatters, lsp_config}`), `nvim/.config/nvim/lua/lang/javascript/javascript.lua`, `nvim/.config/nvim/lua/lang/docker/docker.lua`, `nvim/.config/nvim/lua/lang/django/django.lua`
- Pattern: Each `<lang>.lua` returns table with optional keys `lsp_servers`, `lsp_config`, `formatters`, `formatters_config`, `mason_packages`, `treesitter`, `luasnip_extends`; companion `<lang>/plugins.lua` returns array of lazy specs (e.g., `ven-selector.nvim` for python). Aggregator deduplicates

**Base Layer:**
- Purpose: Editor fundamentals independent of language
- Examples: `nvim/.config/nvim/lua/base/options.lua` (UI, clipboard, indentation, search, folds, grep), `nvim/.config/nvim/lua/base/keymaps.lua` (window/nav, telescope, formatting, terminal), `nvim/.config/nvim/lua/base/autocmds.lua`, `nvim/.config/nvim/lua/base/init.lua` (re-export), `nvim/.config/nvim/lua/settings.lua` (central toggle)
- Pattern: `base` re-exported after init; keymaps use `vim.keymap.set` with `desc`; options via `vim.opt`/`vim.o`/`vim.g` with `editorconfig=true`

**Bootstrapper Function Group:**
- Purpose: Reusable helpers for mode-aware deployment
- Examples: `get-distro`, `get-deps`, `verify-deps`, `install-deps`, `run-stow`, `get-mode-interactive` in both `setup.nu` and `setup.zsh` (mirrored logic, different syntax)
- Pattern: `DRY_RUN` guard returns early without exec; missing-deps collection before install; keyd handled specially due to `/etc` target and sudo

## Entry Points

**Bootstrapper CLI:**
- Location: `setup.nu`, `setup.zsh` (deploy), `teardown.nu`, `teardown.zsh` (unstow)
- Triggers: Manual CLI `nu setup.nu [--mode local|server] [--dry-run] [--stow-keyd y|n]` or `zsh setup.zsh --mode local`; teardown asks `Type 'yes' to confirm` (Nushell) or `read REPLY`
- Responsibilities: Validate distro, verify deps, optionally install, stow/unstow core vs GUI modules, reload keyd, print summary; `README.md` documents both shell paths

**Neovim `init.lua`:**
- Location: `nvim/.config/nvim/init.lua`
- Triggers: `nvim` launch (or `EDITOR=nvim` via `git commit`, `edit-command-line` in `zsh/.zshrc` Ctrl+X Ctrl+E)
- Responsibilities: Bootstrap lazy.nvim, compose language + plugin specs, configure lazy with performance rtp disabled_plugins, require `base`, schedule colorscheme

**Shell Login:**
- Location: `nushell/.config/nushell/env.nu` + `config.nu` + `login.nu` ; `zsh/.zshrc` + `zsh/.zprofile` + `zsh/.p10k.zsh`
- Triggers: Login or interactive shell; `zsh/.zprofile` `exec start-hyprland` on tty1
- Responsibilities: Export env/PATH, init zoxide/starship, set vi-mode, load completions, configure prompt; Alacritty/Wofi/Keyd read their configs on process start (not shell-triggered)

**Stow Direct:**
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

**What happens:** `MISTRAL_API_KEY` value is inlined in `nushell/.config/nushell/env.nu:48` and committed to git
**Why it's wrong:** Every clone gains a live API credential; history retains it even after rotation; violates forbidden-files contract for `MISTRAL_API_KEY` disclosure
**Do this instead:** Use `MISTRAL_API_KEY` from external secret (`$env.MISTRAL_API_KEY` sourced from `~/.config/nushell/secrets.nu` ignored by git, or `sops`/`pass`), and keep `env.nu` as ` $env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""` placeholder

### Mirrored bootstrapper logic without shared module

**What happens:** `setup.nu` and `setup.zsh` duplicate `get-distro`, `get-deps`, `verify-deps`, `run-stow` with different syntax; bug fix in one does not propagate
**Why it's wrong:** Drift risk already visible (`setup.nu` core=`[nvim,nushell,starship]` plus gui includes `hyprland`; `setup.zsh` core=`[nvim,zsh]` and `teardown.nu` vs `teardown.zsh` core lists differ slightly)
**Do this instead:** Extract distro/deps table to a declarative file (e.g., `manifest.toml`) consumed by thin shell wrappers, or keep one canonical bootstrapper and shim the other

## Error Handling

**Strategy:** Fail-fast with messages plus fallback to warn; no retries; DRY_RUN suppresses writes

**Patterns:**
- `setup.nu:main` guards `if not ($nu | is-not-empty) { print "Error: must run with Nushell"; exit 1 }` and `if $distro not-in ["arch","cachyos","ubuntu"] { exit 1 }`; `setup.zsh` uses `set -euo pipefail`, `verify_command || missing+=`, `usage; exit 1` for unknown flags
- Neovim language loading uses `pcall(require, lang_module)` then `vim.notify(..., WARN)` on failure (`nvim/.config/nvim/lua/lang/init.lua:23`), recovers with empty `M`; `init.lua` wraps `pcall(require, "lang")` similarly, notifying on error but continuing
- `teardown.nu:main` requires `input "Type 'yes' to confirm"` unless `dry_run`; `teardown.zsh` uses `read REPLY` confirmation; both abort unless exact `yes`
- `mason-install-all.lua:mr.refresh(function() ... if mr.has_package then ... else vim.notify("Warning: Mason doesn't have package: ...", WARN) end)` — missing registry entry is warning not error

## Cross-Cutting Concerns

**Logging:** `print`/`echo` to stdout in shell scripts; `vim.notify` with `nvim-notify`/`noice.nvim` in Neovim; no file logs. Starship shows `$cmd_duration` and exit `status` as prompt feedback

**Validation:** Distro allowlist, dep `which` checks, `vim.loop.fs_stat` for lazy path, `pcall(require, ...)` for modules, `vim.fn.executable("make")==1` cond for `telescope-fzf-native`, `exists($file)` guards before sourcing in `zsh/.zshrc` (`[[ -f "$HOME/.shell_aliases" ]] && source ...`)

**Authentication:** None for repo itself; `sudo` for `keyd` (`sudo stow --adopt -t / keyd && sudo keyd reload && sudo systemctl start|stop keyd`), with recommended `visudo` NOPASSWD line documented in `README.md`

---

*Architecture analysis: 2026-09-10*
