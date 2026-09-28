# External Integrations

**Analysis Date:** 2026-09-10

## APIs & External Services

**GitHub / Git:**
- lazy.nvim bootstrap — clones `https://github.com/folke/lazy.nvim.git --branch stable --filter=blob:none` on first run if `vim.loop.fs_stat(lazypath)` fails (`nvim/.config/nvim/init.lua:2-11`)
- All plugin sources pinned in `nvim/.config/nvim/lazy-lock.json` (44 entries e.g., `folke/lazy.nvim:85c7ff3`, `neovim/nvim-lspconfig:4b7fbaa`, `nvim-telescope/telescope.nvim:5063384`) — fetched via git
- Telescope git pickers (`nvim/.config/nvim/lua/plugins/telescope.lua`, `nvim/.config/nvim/lua/base/keymaps.lua:60-70`) call `Telescope git_commits` / `git_status` via `plenary.nvim`
- gitsigns (`lewis6991/gitsigns.nvim` at `nvim/.config/nvim/lua/plugins/gitsigns.lua`) shells to git for hunks

**Mason Registry (LSP/formatter distribution):**
- `mason-org/mason.nvim` + `mason-registry` — `nvim/.config/nvim/lua/plugins/mason.lua` and `nvim/.config/nvim/lua/utils/mason-install-all.lua` resolve packages named in `lua/lang/**/ *.lua` (`pyright`, `ruff`, `typescript-language-server`, `prettier`, etc.) and run `MasonInstall`
- Refresh via `mr.refresh()` callback; warns if `has_package` false; bulk `MasonInstall <list>` on `MasonInstallAll` user command
- Configured per language in `nvim/.config/nvim/lua/lang/init.lua` aggregator (`mason_packages`, `lsp_servers`, `treesitter_parsers`)

**Node / npm ecosystem:**
- `node`+`npm` required at OS level (`setup.nu:get-deps`, `setup.zsh:get_deps`); `nvim/.config/nvim/lua/lang/javascript/javascript.lua` declares `mason_packages = { "typescript-language-server", "prettier" }`; `lazy-lock.json` pins `nvim-ts-autotag`, `blink.cmp` (Rust/JS hybrid)
- `bun` support (`zsh/.zshrc` exports `BUN_INSTALL=~/.bun`, `PATH+=~/.bun/bin`; recent commits `938f923 add bun completions`, `9f2309b add bun install path`)

**Python / uv ecosystem:**
- `uv` completions and venv helpers (`nushell/.config/nushell/scripts/uv.nu` 400+ lines of `extern uv` definitions; `nushell/.config/nushell/scripts/venv.nu` + `venv-selector.nvim` `linux-cultist/venv-selector.nvim` at `nvim/.config/nvim/lua/lang/python/plugins.lua`)
- `pyright` + `ruff` via `nvim/.config/nvim/lua/lang/python/python.lua`

**AI / LLM:**
- Mistral API key present as env var `MISTRAL_API_KEY` in `nushell/.config/nushell/env.nu` (value not reproduced). No client wrapper found in repo; likely consumed by external tooling or Neovim plugin not vendored here

## Data Storage

**Databases:**
- None — dotfiles repo has no database client, ORM, or connection strings. Neovim state uses local filesystem: `nvim/.config/nvim/state/`, `nvim/.config/nvim/shada/`, `nvim/.config/nvim/cache/`, `nushell/.config/nushell/history.txt` / `history.json`, `zsh/.zsh_history`

**File Storage:**
- Local filesystem only via GNU Stow symlinks. Deployment targets: `$HOME`, `~/.config/nushell`, `~/.config/nvim`, `~/.config/alacritty`, `~/.config/starship.toml`, `~/.config/wofi`, `~/.local/bin`, and privileged `/etc/keyd` (`setup.nu:run-stow`, `setup.zsh:run_stow`)

**Caching:**
- lazy.nvim cache at Neovim `stdpath("data") .. "/lazy"` (`nvim/.config/nvim/init.lua:1`)
- Neovim undo persistence (`nvim/.config/nvim/lua/base/options.lua` sets `undofile=true`, `undolevels=500`); undodir at `nvim/.config/nvim/undo/`
- Ripgrep no cache; zoxide database at default `~/.local/share/zoxide/db.zo` (maintained by hooks in `nushell/.config/nushell/scripts/zoxide.nu` and `zsh/.zshrc`)

## Authentication & Identity

**Auth Provider:**
- None — no user auth in this repo. Git operations rely on host SSH/HTTPS credentials. No OAuth, no session handling

**MCP / AI Tooling:**
- Opencode / Conductor config at `~/.config/opencode/opencode.json` declares MCP `gsd` via `npx -y -p @opengsd/gsd-core gsd-mcp-server` and provider `omniroute` at `http://100.68.211.114:20128/v1` (seen in opencode.json outside repo but influences dev loop). Not part of dotfiles runtime but present on host

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Neovim notifies via `vim.notify` with `nvim-notify` (`rcarriga/nvim-notify` in `nvim/.config/nvim/lazy-lock.json`) and `noice.nvim` (`folke/noice.nvim` at `nvim/.config/nvim/lua/plugins/noice.lua`)
- Nushell/Zsh bootstrap prints to stdout (`print "Starting Unified Bootstrapper…"`, `echo "\nStarting unstow process…"`) — see `setup.nu` and `setup.zsh`
- `starship` prompt shows `command_execution_time`, `status` (exit code) via `zsh/.p10k.zsh` `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` and `starship/.config/starship.toml` `$cmd_duration`
- No centralized logging service

## CI/CD & Deployment

**Hosting:**
- Local workstation/server only — `README.md` describes stow deployment to local `$HOME` and `/etc/keyd`. Git remote `origin` on branch `main`; `backup` branch local. No cloud hosting

**CI Pipeline:**
- No CI config detected — no `.github/workflows/`, no `.gitlab-ci.yml`, no `Jenkinsfile`, no `Dockerfile`, no `docker-compose*.yml` at repo root
- Validation is manual: `setup.nu --dry-run` / `setup.zsh --dry-run` preview, `:checkhealth` in Neovim, `MasonInstallAll` idempotence

## Environment Configuration

**Required env vars:**
- `EDITOR=nvim` (set in `nushell/.config/nushell/env.nu` and `zsh/.zshrc`)
- `XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME` (set to `~/.cache`, `~/.config`, `~/.local/share` in both shells)
- `STARSHIP_CONFIG=~/.config/starship.toml` (`nushell/.config/nushell/env.nu`)
- `BUN_INSTALL=~/.bun` plus `PATH` extensions for `~/.local/bin`, `~/.local/sbin`, `~/.cargo/bin`, `~/.bun/bin`, `~/.npm-global/bin` (`nushell/.config/nushell/env.nu`, `zsh/.zshrc`)
- `PIPX_TOOL_INSTALLER=uv`, `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true`, `LANG=en_US.UTF-8`, `N8N_RESTRICT_FILE_ACCESS_TO=""`
- `MISTRAL_API_KEY` — present in `nushell/.config/nushell/env.nu` (not required for core deployment, but exported unconditionally)
- `DISPLAY` / `tty` — checked in `zsh/.zprofile` for Hyprland autostart; Nushell `env.nu` contains commented Hyprland launch guard

**Secrets location:**
- `.env` files are explicitly forbidden for reading/quoting per workflow; none detected at repo root (`.gitignore` ignores `nushell/.config/nushell/history.txt`, `nvim/shada`, etc., not secrets)
- The only secret-like value in repo is `MISTRAL_API_KEY` hard-coded in `nushell/.config/nushell/env.nu` — it is committed to git (see CONCERNS.md). No `.env`, `*.pem`, `credentials.*`, `secrets/` patterns found
- `~/.config/opencode/opencode.json` (outside repo) contains `apiKey: sk-c52e0b07efa603b2-...` for `omniroute` — not part of dotfiles payload but relevant host secret

## Webhooks & Callbacks

**Incoming:**
- None — no HTTP server or webhook endpoints in repo

**Outgoing:**
- lazy.nvim git fetches to GitHub on plugin install/update
- Mason registry HTTP fetches for LSP/formatter binaries on `MasonInstallAll`
- `zoxide` does not phone home; fully local
- No webhook dispatch code in `setup.nu`/`setup.zsh`/`teardown.nu`/`teardown.zsh` — only `stow`, `which`, `git`, and `sudo keyd reload`/`systemctl` invocations

---

*Integration audit: 2026-09-10*
