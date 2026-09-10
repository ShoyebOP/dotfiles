# Architecture Research

**Domain:** Dotfiles / Stow-based development environment — Unified Bash Installer & Reliability Hardening (7 Stow packages, Neovim lazy.nvim + 14 language modules, Zsh/Zinit/P10k, desktop primitives)
**Researched:** 2026-09-10
**Confidence:** HIGH (installer structure, Stow isolation, Neovim aggregator, Zsh ordering — validated against live repo + 6 codebase maps dated 2026-09-10), MEDIUM (TUI fallback nuances, theme token — inferred, cross-checked via ShellCheck/Bash strict docs)

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Delivery / Orchestration Layer (NEW)                      │
│  bash setup.sh ─┬─ get_distro (ID_LIKE + pm probe) ─┬─► distro family       │
│                 ├─ get_deps (distro × mode × shell) ─► package lists        │
│                 ├─ verify / install / re-verify ─────► host deps            │
│                 ├─ prompt: mode → shell → TUI checklist ─► selected set     │
│                 ├─ setup_shell (ensure zsh + Zinit + chsh offer)            │
│                 ├─ run_stow / run_unstow (stow --restow/-D)  ──────────────┤
│                 ├─ apply_theme (central token → sed check)                  │
│                 └─ self_test (--dry-run + --self-test health gates)         │
│    shim: setup.zsh / setup.nu → exec bash setup.sh (one release)           │
├──────────────────────┬──────────────────────┬───────────────┬────────────────┤
│   Shell Layer        │   Editor Layer       │  Terminal     │  Desktop/GUI   │
│  zsh/ (default)      │  nvim/               │  alacritty/   │  wofi/         │
│  .zshrc / .zprofile  │  init.lua + base/    │  starship/    │  keyd/         │
│  .p10k.zsh           │  lang/* aggregator   │  (prompt)     │  (hyprland*    │
│  nushell/ (backup)   │  plugins/* (21)      │               │   waybar*      │
│  scripts/ prefix     │  colorschemes/       │               │   grim/slurp)  │
└──────────┬───────────┴──────────┬───────────┴───────┬───────┴────────┬───────┘
           │                      │                   │                │
           ▼                      ▼                   ▼                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Host Primitives (no repo code)                        │
│  stow 2.4.1 • bash 5.2 • zsh 5.9 • nvim ≥0.10 (gcc/make/luarocks/ts-cli)    │
│  starship 1.24 • zoxide 0.9.8+ • fzf ≥0.48 • gum / whiptail • uv • rg • git│
└─────────────────────────────────────────────────────────────────────────────┘
  * hyprland/waybar/grim/slurp listed in get_deps GUI set; repo stores alacritty/wofi/keyd
    as Stow packages — hyprland package is generated via stow if added, or documented as
    external (existing setup.* gui_modules includes hyprland name; create hyprland/ package
    or keep as external dep — see Stow Isolation below).

*Existing drift this architecture eliminates:* `setup.nu` vs `setup.zsh` mirrored
`get-distro/get-deps/verify-deps/run-stow` with different syntax and diverging
`core=[nvim,nushell,starship]` vs `[nvim,zsh]` and GUI lists. Single Bash canonical + thin shims.
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|---------------|------------------------|
| **Unified Bash Installer** (`setup.sh` or `install.sh`) | Canonical entry for **install + uninstall** (`--install`/`--uninstall`/`--remove` + `--mode local\|server --shell zsh\|nushell --dry-run --stow-keyd y/n --yes --self-test`). Owns distro detection, dep verification/install/re-verify, interactive flow (mode → shell → TUI checklist before any write), shell self-install, Stow orchestration, theme consistency check, self-test gates. Must exit non-zero on unknown distro only after `ID_LIKE` + pm probe fails. | `bash 5.2` with `set -Eeuo pipefail; shopt -s inherit_errexit failglob extglob nullglob` + `SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"` preamble. Functions below. Keep ShellCheck `0.10.x` + `shfmt -i 4 -ci` gates. |
| **Distro / PM Probe** (`get_distro`, `get_pm_family`) | Normalize derivatives: `source /etc/os-release` → `ID` + space-separated `ID_LIKE` + `command -v pacman` / `apt-get` / `apt`. Map to `arch` family (pacman) or `debian` family (apt). Never hard-code `["arch","cachyos","ubuntu"]` alone. | `[[ $ID == arch ]] \|\| [[ " $ID_LIKE " == *" arch "* ]] \|\| command -v pacman &>/dev/null → arch`; `[[ " $ID_LIKE " == *" debian "* ]] \|\| command -v apt-get &>/dev/null → debian`. Priority: pm probe first, `ID_LIKE` second, `ID` third. See `man os-release(5)` pattern `[ "${ID_LIKE#*debian*}" != "$ID_LIKE" ]`. |
| **Dependency Resolver** (`get_deps`, `verify_deps`, `install_deps`, `verify_deps_strict`) | Per-`distro × mode × shell` package lists. `common` always + `gui` only if `mode==local` + shell-specific. Must add `make`+`gcc` to `common` (fixes silent `telescope-fzf-native` fallback). Verify via `command -v`, partition `core_missing` vs `gui_missing`, interactive `Install ALL / CORE only / Skip / Select`, run `pacman -S --needed` or `apt install -y` + **re-run verify** and abort with report if still missing. Detect `[[ ! -t 0 ]]` non-interactive → auto-install core, skip GUI. | `local -a common=(stow nvim starship git zoxide uv rg node npm make gcc)` + `case "$pm_family" in arch) gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy);; debian) gui=(alacritty wofi waybar grim slurp wl-copy);;`. Verify loop appends to `missing` with `+ installed / - missing` echo. Re-verify is the lock. |
| **Interactive Flow Controller** (`prompt_mode`, `prompt_shell`, `build_package_list`, `tui_checklist`) | User-specified `Mode → Shell only → manual select/deselect override before any writes`. Default shell `zsh`; Nushell is backup flag. Checklist must show candidate list with pre-checked ON/OFF per mode (core ON, gui ON only on `local`, privileged `keyd` OFF by default). | `gum choose --no-limit --header` primary (`pacman -S gum` / charm apt repo / `go install`); fallback ladder `whiptail --checklist 20 78 10 … 3>&1 1>&2 2>&3` (preinstalled Ubuntu) → `dialog` → `fzf --multi` → plain `read -p "numbers or 'all'"`. Skip checklist when `--yes` or `[[ ! -t 0 ]]` or both `--mode`+`--shell` already provided (use defaults). |
| **Shell Self-Installer** (`setup_shell`, `ensure_zinit`, `maybe_chsh`) | Eliminate bootstrap paradox: ensure chosen shell binary exists before stowing its config. For `zsh` default: `command -v zsh \|\| install zsh` then `[[ -d ~/.local/share/zinit/zinit.git ]] \|\| git clone --depth 1 $ZINIT_URL ~/.local/share/zinit/zinit.git` (commit-pinned) then `stow --restow zsh`. Offer `chsh -s $(which zsh)` after `which zsh \| sudo tee -a /etc/shells` **only on explicit `read -q` yes** — never auto-chsh. | Keep `zsh` as default; `nushell` backup path same check but no fixes per PROJECT.md scope filter. |
| **Stow Orchestrator** (`stow_module`, `run_stow`, `run_unstow`) | Deploy 7 packages via GNU Stow 2.4.1 from **repo root**. Map `mode×selection` → `stow --restow <selected>` + privileged `sudo stow -t / keyd` (after conflict gate). Unstow via `stow -D`. Always preview `stow --no --verbose` on `--dry-run`; assert repo root (`[[ -f ./setup.sh ]]`) + real-file guard before `rm -rf` of existing non-symlink target; verify `readlink -f ~/.config/nvim` post-stow. | `stow --dir="$SCRIPT_DIR" --restow` ensures correct directory even when invoked via symlink. `keyd -t /` target is special; never invoke from subdir. |
| **Theme Centralizer** (`apply_theme`, `check_theme_consistency`) | Single token solves 4-file duplication (`alacritty.toml` import, `catppuccin-mocha.toml`, `starship.toml palette`, `nvim/colorschemes/catppuccin.lua`, `nushell/catppuccin.nu`). Installer writes or validates `THEME=mocha/latte` / `theme.toml` at repo root and `sed`-checks or templates stowed files at install, warns on mismatch. | Option A (this milestone, minimal): `THEME=mocha` env + `setup.sh` `apply_theme()` that validates `starship.toml palette` == `alacritty import` and warns; single `catppuccin-mocha.toml` remains source. Option B (future): `chezmoi` templating — deferred (anti-feature). Keep `settings.colorscheme="tokyodark"` until unified. |
| **Self-Test / Health Gate** (`self_test`, `--self-test`/`--verify`) | VM-less validation: `stow --no --verbose` symlinks correct, `test -L ~/.config/nvim && readlink`, `zoxide --version && starship --version && fzf --version`, `zsh -i -c 'echo loaded'` + `bindkey \| grep fzf`, `nvim --headless -c "checkhealth" -c "qa"` parse for `ERROR`, `mason-tool-installer check_install(false,true)` or `MasonInstallAll` sync, `PATH` dedup empty `echo $PATH \| tr : '\n' \| sort \| uniq -d` is empty, `stow --version ≥2.4.1`. TAP output. | Reuses `--dry-run` preview. Runs headless in CI without VM. Capstone after all features. |
| **Shell Runtime — Zsh (default)** | Interactive shell: `zsh/.zshrc` (Zinit + P10k + vi bindings) + `zsh/.zprofile` + `zsh/.p10k.zsh` + `~/.zshrc.local` (machine-local, gitignored). Owns PATH dedup, prompt, completion, history fzf, zoxide. | See Zsh Init Ordering below. |
| **Shell Runtime — Nushell (backup)** | Backup shell, not fixed beyond docs per scope. Keep `nushell/.config/nushell/config.nu` + `env.nu` + `scripts/*.nu`; document `~/.config/nushell/secrets.nu` ignored pattern for `MISTRAL_API_KEY` instead of committed `env.nu:48`. | No code change in this milestone except docs + `.gitignore`. |
| **Editor Runtime — Neovim** | `nvim/.config/nvim/init.lua` + `lua/base/` + `lua/lang/` aggregator (14 langs) + `lua/plugins/` (21) + `lua/colorschemes/` + `lua/utils/` + `lua/local.lua` (gitignored). Owns LSP/formatter/treesitter/Mason via `settings.languages` single toggle. | See Neovim Lang Aggregator Hardening below. |
| **Presentation / Peripheral** | `alacritty/.config/alacritty/` (imports catppuccin), `starship/.config/starship.toml` (`palette` + `scan_timeout`), `wofi/.config/wofi/`, `keyd/etc/keyd/default.conf` (`-t /` privileged). Depend on Nerd Font + `starship`/`wofi`/`waybar` binaries. | `starship-minimal.toml` kept as `server` variant; switch documented not auto. |

---

## Recommended Project Structure

```
dotfiles/                          # Repo root — GNU Stow packages + Bash canonical installer
├── setup.sh                       # ★ Unified Bash installer (canonical, replaces 4 scripts)
│                                  #   --install/--uninstall/--remove, --mode local|server,
│                                  #   --shell zsh|nushell, --dry-run, --stow-keyd y/n,
│                                  #   --yes, --self-test/--verify, --help
├── setup.zsh                      # Shim → exec bash setup.sh "$@" (one release, then deprecate)
├── setup.nu                       # Shim → exec bash setup.sh "$@" (one release, then deprecate)
├── teardown.zsh / teardown.nu     # Shims → bash setup.sh --uninstall (one release)
├── manifest.toml  (or packages.json) # Optional declarative package manifest: per-distro core/gui
│                                  #   arrays + tag: core|gui|arch-only consumed by setup.sh
├── theme.toml  (or .theme)        # Single theme token: flavor=mocha + palette ref
│                                  #   consumed by apply_theme() at install
├── README.md                      # Flipped to Zsh default + bash setup.sh examples
├── .gitignore                     # + zsh/.zshrc.local, zsh/.zprofile.local,
│                                  #   nvim/.config/nvim/lua/local.lua,
│                                  #   nushell/.config/nushell/secrets.nu, .env.local
│
├── nvim/                          # Stow → ~/.config/nvim/
│   └── .config/nvim/
│       ├── init.lua               # Official lazy bootstrap + specs + base + colorscheme schedule
│       │                          #   + pcall(require,"local") tail for machine-local
│       ├── lua/
│       │   ├── base/              # options.lua / keymaps.lua / autocmds.lua / init.lua barrel
│       │   ├── lang/              # 14 modules: <lang>/<lang>.lua + optional plugins.lua
│       │   │   ├── init.lua       # Aggregator: deduplicate + pcall WARN + silent plugins.lua
│       │   │   ├── python/python.lua # returns {lsp_servers, mason_packages, treesitter, ...}
│       │   │   └── ...
│       │   ├── plugins/           # 21 specs + NEW which-key.lua (which-key v3 spec)
│       │   │   ├── which-key.lua  # folke/which-key.nvim preset=modern delay=200
│       │   │   ├── mason.lua      # mason-org/mason.nvim + build = ":MasonInstallAll"
│       │   │   └── telescope.lua  # cond executable("make")==1 + WARN toast (not silent)
│       │   ├── colorschemes/      # tokyodark (active) / catppuccin / nightfox / gruvbox + init
│       │   ├── utils/             # mason-install-all.lua (get_packages/install_all + :MasonInstallAll)
│       │   ├── settings.lua       # Single source: colorscheme + languages = {…} (14 + --"c")
│       │   └── local.lua          # ★ Machine-local overrides (gitignored, pcall sourced)
│       ├── lazy-lock.json         # 44 pins (commit reproducibility, include lazy.nvim pin)
│       └── ... state/cache/shada/undo/ (gitignored)
│
├── zsh/                           # Stow → ~/
│   ├── .zshrc                     # P10k instant prompt top → XDG → PATH dedup → Zinit → fzf → zoxide tail
│   │                              #   + FZF history fix + [[ -f ~/.zshrc.local ]] guard at tail
│   ├── .zprofile                  # Hyprland exec guarded by mode marker + executable check
│   ├── .zshrc.local.example       # Template for machine-local (gitignored real file)
│   └── .p10k.zsh                  # Powerlevel10k classic 2-line (frozen, keep)
│
├── nushell/                       # Stow → ~/.config/nushell/ (backup, docs only this milestone)
│   └── .config/nushell/
│       ├── config.nu / env.nu     # env.nu: $env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""
│       ├── secrets.nu.example     # Template → ~/.config/nushell/secrets.nu (gitignored)
│       └── scripts/               # uv.nu (400-line) / venv.nu / zoxide.nu (sourced last)
│
├── alacritty/                     # Stow → ~/.config/alacritty/
├── starship/                      # Stow → ~/.config/ (starship/.config/starship.toml → ~/.config/starship.toml via folding)
├── wofi/                          # Stow → ~/.config/wofi/
└── keyd/                          # Stow → /etc/keyd/ (privileged: sudo stow -t / keyd)
    └── etc/keyd/default.conf

Planned new files only: setup.sh, manifest.toml (optional), theme.toml, zsh/.zshrc.local.example,
nvim/.config/nvim/lua/local.lua.example, nvim/.config/nvim/lua/plugins/which-key.lua,
nushell/.config/nushell/secrets.nu.example.
No .github/workflows/ in this milestone (Out of Scope); self-test is CI-ready for v2.
```

### Structure Rationale

- **`setup.sh` at repo root as stow directory:** GNU Stow requires the repo root to be the stow directory (`stow --dir="$SCRIPT_DIR"`). Placing the installer at the root guarantees `stow --restow nvim zsh` resolves folding (`starship/.config/starship.toml → ~/.config/starship.toml`) regardless of `$HOME` layout. Invoking from a subdir would silently break folding — the installer `die`s unless `[[ -f ./setup.sh ]]`.
- **`manifest.toml` vs hard-coded arrays:** Current `get_deps`/`get-deps` hard-code `common=[stow,nvim,…]` and GUI arrays in two shell languages — drift already observable. A declarative manifest (`deps.toml` with `[[package]] name= tag=core|gui arch-only`) lets one table be consumed by Bash and validated by self-test, removing the mirror class of bugs (CONCERNS.md fix approach). Keep inline fallback if manifest missing.
- **Machine-local `*.local` beside stow package, not in `$HOME` alone:** `zsh/.zshrc.local` lives inside the `zsh/` package so `stow --restow zsh` deploys `~/.zshrc.local` alongside `~/.zshrc` if present, but `.gitignore` prevents committing the real file. The `.example` template is committed so new clones `cp …/local.lua.example …/local.lua` without editing code. Neovim `lua/local.lua` is `pcall(require,…)` so missing file is harmless.
- **Shims for one release:** Deleting `setup.nu/setup.zsh` immediately breaks docs/bookmarks. Shims `#!/usr/bin/env bash\nexec bash "$(dirname "$0")/setup.sh" "$@"` preserve existing `zsh setup.zsh --mode server` muscle memory while canonicalizing. Remove after README is updated and one tag ships.
- **No `src/` or `lib/` extraction:** At 7 packages this repo is a config monorepo, not an application. Extracting Bash functions into `lib/` adds indirection without reuse. Keep everything in `setup.sh` with section comments (`# ═══════ Mode × Shell × Checklist ═══════`). The only shared artifact is `manifest.toml`, if used.

---

## Architectural Patterns

### Pattern 1: Stow Packages as Bounded Contexts (GNU Stow Monorero)

**What:** Each top-level directory (`nvim/`, `zsh/`, `alacritty/`, `starship/`, `wofi/`, `keyd/`) is a self-contained GNU Stow package whose interior mirrors its deployment target (`nvim/.config/nvim/`, `zsh/.zshrc`, `starship/.config/starship.toml`, `keyd/etc/keyd/default.conf`). `setup.sh` never `ln -sf` manually — it only orchestrates `stow --restow <selected>` + `stow -D <selected>` from repo root.

**When to use:** Always. This is the project's core pattern (ARCHITECTURE.md Pattern Overview: "Stow-based Monorepo with Language-Oriented Plugin Composition"). Every new GUI app (`waybar/`, `grim/`) should be a new package, not a file appended to `nvim/` or `zsh/`.

**Trade-offs:** Pro: Stow handles folding, `--dotfiles` for `dot-foo`, conflict detection, and `--no --verbose` preview in one battle-tested Perl binary. Con: Folding is subtle — `starship/.config/starship.toml` deploys to `~/.config/starship.toml` only from repo root; moving the repo or invoking from `nvim/` breaks silently. Privileged `keyd -t /` needs `sudo` and distinct `-t /` target.

**Example — package isolation contract:**

```bash
# repo layout (bounded):
#   nvim/.config/nvim/init.lua      → ~/.config/nvim/init.lua
#   starship/.config/starship.toml  → ~/.config/starship.toml  (folding)
#   keyd/etc/keyd/default.conf      → /etc/keyd/default.conf   (-t /)

stow_module() {
  local pkg="$1"dry_run="$2"
  local -a flags=()
  if [[ "$dry_run" == true ]]; then flags+=(--no --verbose); fi
  if [[ "$pkg" == "keyd" ]]; then
    # privileged target — caller already did conflict gate + gum confirm
    (( dry_run )) && { echo "[DRY RUN] sudo stow --adopt -t / keyd"; return; }
    sudo stow "${flags[@]}" --restow -t / keyd
  else
    stow "${flags[@]}" --dir="$SCRIPT_DIR" --restow "$pkg"
  fi
}

# post-stow verification (self-test):
test -L ~/.config/nvim && [[ "$(readlink -f ~/.config/nvim/init.lua)" == *"/nvim/.config/nvim/init.lua" ]] \
  && echo "PASS stow nvim" || { echo "FAIL stow nvim: not symlinked from repo root"; exit 1; }
test -L ~/.config/starship.toml && echo "PASS stow starship folding" || echo "FAIL starship"
```

---

### Pattern 2: Language-Oriented Plugin Composition (Aggregator)

**What:** `nvim/.config/nvim/lua/settings.lua` is the single source of truth for `colorscheme` + `languages = { "bash","git","python",… }` (14 entries + `--"c"`). `nvim/.config/nvim/lua/lang/init.lua` iterates `languages`, `pcall(require, "lang."..lang.."."..lang)` for each, merges six concerns into one table `M = { lsp_servers, lsp_config, formatters, mason_packages, treesitter_parsers, plugin_specs }` with `deduplicate()`, then returns `M`. Callers (`plugins/conform.lua`, `plugins/mason.lua`, `plugins/treesitter.lua`, `init.lua` adding `plugin_specs`) simply `require("lang")`.

**When to use:** Adding a new language: create `lua/lang/<newlang>/<newlang>.lua` returning `{ lsp_servers={…}, mason_packages={…}, treesitter={…}, formatters={…} }` + optional `<newlang>/plugins.lua` returning lazy specs, then add `"<newlang>"` to `settings.languages`. No wiring elsewhere.

**Trade-offs:** Pro: Zero per-language wiring; `:MasonInstallAll` and `conform`/`treesitter` automatically pick up new langs. Con: Single toggle surface is fragile — typo `"pythoon"` only `vim.notify WARN` with silent feature loss; commenting a language does not auto-uninstall Mason package (stale binary). Keep `WARN` visible via `noice.nvim` routing, and make `setup.sh --uninstall` clean Mason artefacts.

**Example — hardened aggregator contract (existing + prescribed guards):**

```lua
-- lua/lang/init.lua (existing, keep deduplicate + pcall WARN; add optional validation)
local settings = require("settings")
local languages = settings.languages  -- single toggle

local M = { lsp_servers={}, mason_packages={}, treesitter_parsers={}, plugin_specs={}, formatters={}, lsp_config={} }

local function deduplicate(tbl) -- 12 lines, keep
  local seen, out = {}, {}
  for _, v in ipairs(tbl) do if not seen[v] then seen[v]=true; table.insert(out,v) end end
  return out
end

for _, lang in ipairs(languages) do
  local mod = "lang."..lang.."."..lang
  local ok, cfg = pcall(require, mod)
  if ok then
    for _, s in ipairs(cfg.lsp_servers or {}) do table.insert(M.lsp_servers, s) end
    for _, p in ipairs(cfg.mason_packages or {}) do table.insert(M.mason_packages, p) end
    for _, t in ipairs(cfg.treesitter or {}) do table.insert(M.treesitter_parsers, t) end
    -- … formatters / lsp_config / luasnip_extends …
  else
    vim.notify("Failed to load: "..mod.."\n"..tostring(cfg), vim.log.levels.WARN)
  end
  local pok, pspec = pcall(require, "lang."..lang..".plugins")
  if pok and type(pspec)=="table" then for _, s in ipairs(pspec) do table.insert(M.plugin_specs,s) end end
  -- silently ignore missing plugins.lua — intentional (only python/css/django/html/json/markdown need it)
end

M.lsp_servers = deduplicate(M.lsp_servers)
M.mason_packages = deduplicate(M.mason_packages)
M.treesitter_parsers = deduplicate(M.treesitter_parsers)
return M
```

**Prescribed hardening for this milestone (low risk, high payoff):**
1. **Do not change the `pcall` WARN pattern** — it is the only signal for a typo in `settings.languages`. Ensure `vim.notify` is not suppressed by `noice.nvim` routing (verify in `:Noice telescope`).
2. **Add `which-key.nvim` v3 spec** in `lua/plugins/which-key.lua` — auto-discovers `desc` already present in `base/keymaps.lua`:
   ```lua
   return {
     "folke/which-key.nvim",
     event = "VeryLazy",
     opts = {
       preset = "modern",
       delay = 200,
       triggers = { { "<auto>", mode = "nxso" } },
       spec = {
         { "<leader>f", group = "find" }, { "<leader>s", group = "search" },
         { "<leader>g", group = "git" },  { "<leader>e", group = "run" },
         { "<leader>t", group = "toggle" },{ "<leader>q", group = "session" },
       },
     },
   }
   ```
3. **Mason auto-install lifecycle** — keep existing `utils/mason-install-all.lua` (`mr.refresh` + `is_installed` filter + `MasonInstallAll` command) and add `WhoIsSethDaniel/mason-tool-installer.nvim` as canonical auto-install with `ensure_installed = require("lang").mason_packages, run_on_start=true, start_delay=3000, debounce_hours=24`. `setup.sh` post-stow invokes headless sync:
   ```bash
   nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"  # or
   nvim --headless -c "lua require('mason-tool-installer').check_install(false,true)" -c "qa"
   ```
   On `--uninstall` when `nvim` deselected: `rm -rf ~/.local/share/nvim/mason ~/.local/state/nvim ~/.cache/nvim` (document `stdpath("data").."/mason"` contract). Add `make`+`gcc` to `common` so `telescope-fzf-native` `cond = executable("make")==1` no longer silently falls back — add `vim.notify WARN` in `cond` else so editor surfaces it.
4. **`init.lua` bootstrap** — replace bare `vim.loop.fs_stat` + `git clone` with official snippet (context7 HIGH):
   ```lua
   vim.g.mapleader = " "
   local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
   if not (vim.uv or vim.loop).fs_stat(lazypath) then
     local out = vim.fn.system({ "git","clone","--filter=blob:none","https://github.com/folke/lazy.nvim.git","--branch=stable",lazypath })
     if vim.v.shell_error ~= 0 then
       vim.api.nvim_echo({{"Failed to clone lazy.nvim:\n"..out,"ErrorMsg"}}, true, {})
       vim.fn.getchar(); os.exit(1)
     end
   end
   vim.opt.rtp:prepend(lazypath)
   ```
   Pin `lazy.nvim` via `lazy-lock.json` `85c7ff3` vs `stable` tip verification `git -C "$lazypath" rev-parse HEAD` WARN on mismatch. Keep `performance.rtp.disabled_plugins` (23 entries) — refresh per Neovim release, verify with `nvim --headless -c "Lazy check" -c "qa"`. Add machine-local tail: `pcall(require,"local")` after `require("base")`.
5. **Do not eagerly install all 14 LSPs on every startup** — use `start_delay=3000` debounce, not synchronous `MasonInstall` in `init.lua` (would block startup on network, violating `defaults.lazy=true`).

---

### Pattern 3: Bash Installer Internal Structure — Strict-Mode, Single Source, Preview-First

**What:** Unified `setup.sh` with `set -Eeuo pipefail; shopt -s inherit_errexit failglob extglob nullglob` preamble, `SCRIPT_DIR`, `die`/`info`/`warn`/`confirm` helpers (gum-styled), `get_distro` (`ID_LIKE` + pm probe), `get_deps (distro mode shell)`, `verify_deps` + `verify_deps_strict` (re-run after install), `install_deps` (interactive partition + `select_skip_packages`), `prompt_mode`/`prompt_shell`/`build_package_list`/`tui_checklist` (gum → whiptail → fzf → read), `stow_module`/`run_stow`/`run_unstow`, `setup_shell`, `apply_theme`, `self_test`, and `main` arg parser with `${1-}` guard for `set -u`.

**When to use:** This is the canonical pattern for this milestone — it replaces the four mirrored scripts and is the only place mutation happens. Every other pattern (Stow isolation, lang aggregator, Zsh ordering, theme) is consumed by this installer.

**Trade-offs:** Pro: One source of truth, ShellCheck-clean, `--dry-run` preview covers every write (including privileged `keyd` and `chsh`). Con: Bash strict mode is subtle — `set -e` ignores failures in `if`/`while`/`&&`/`||`, `inherit_errexit` propagates into subshells, `yes | head -1` RC 141 trips `pipefail` (guard via `|| true`). Mitigate with explicit `if ! cmd; then` and `PIPESTATUS` where needed.

**Prescribed internal structure — copy this skeleton:**

```bash
#!/usr/bin/env bash
# setup.sh — Unified Dotfiles Installer (canonical, replaces setup.nu/setup.zsh + teardown.*)
set -Eeuo pipefail
shopt -s inherit_errexit failglob extglob nullglob shift_verbose
IFS=$'\n\t'
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly SCRIPT_NAME="${0##*/}"
DRY_RUN=false; ACTION="install"; MODE=""; SHELL_CHOICE="zsh"; STOW_KEYD=""; ASSUME_YES=false

# ── helpers ─────────────────────────────────────────────────────────────────
die()  { printf '\e[31m[ERROR]\e[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\e[34m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }
confirm() { # confirm "prompt" → 0=yes 1=no; uses gum confirm if present
  local prompt="$1"
  if command -v gum &>/dev/null && [[ -t 0 ]]; then gum confirm "$prompt" && return 0 || return 1; fi
  read -rp "$prompt [y/N]: " r; [[ "$r" == [Yy]* ]]
}

usage() { cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]
  --mode local|server        Deployment mode (default: prompt)
  --shell zsh|nushell        Shell (default: zsh; nushell is backup)
  --install | --uninstall | --remove  Action (default: --install)
  --dry-run                  Preview without writes (stow --no --verbose)
  --stow-keyd y|n            Privileged keyd (default: prompt, OFF checklist)
  --yes                      Assume defaults / skip checklist confirmation
  --self-test | --verify     Run health gates (symlinks, checkhealth, Mason, zoxide)
  -h, --help
EOF
}

# ── distro + pm family (ID_LIKE + probe) ────────────────────────────────────
get_distro() {
  local id="" id_like=""
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    id="${ID:-}"; id_like="${ID_LIKE:-}"
  fi
  # normalize to lowercase
  id="${id,,}"; id_like="${id_like,,}"
  # probe package manager first — most reliable on derivatives
  if command -v pacman &>/dev/null; then echo "arch"; return; fi
  if command -v apt-get &>/dev/null || command -v apt &>/dev/null; then echo "debian"; return; fi
  # fall back to ID_LIKE
  if [[ " $id_like " == *" arch "* ]] || [[ "$id" == "arch" ]] || [[ "$id" == "cachyos" ]] \
     || [[ "$id" == "manjaro" ]] || [[ "$id" == "endeavouros" ]] || [[ "$id" == "garuda" ]]; then echo "arch"; return; fi
  if [[ " $id_like " == *" debian "* ]] || [[ " $id_like " == *" ubuntu "* ]] \
     || [[ "$id" == "ubuntu" ]] || [[ "$id" == "debian" ]] || [[ "$id" == "linuxmint" ]] || [[ "$id" == "pop" ]]; then echo "debian"; return; fi
  echo "unknown"
}

get_pm_family() { get_distro; }  # alias — installer uses "arch" vs "debian" families

# ── deps per distro × mode × shell ──────────────────────────────────────────
get_deps() {
  local pm_family="$1" mode="$2" shell_choice="${3:-zsh}"
  local -a common=(stow nvim starship git zoxide uv rg node npm make gcc)
  # shell binary itself is part of deps (bootstrap paradox fix)
  if [[ "$shell_choice" == "zsh" ]]; then common+=(zsh fzf); else common+=(nushell); fi
  local -a gui=()
  case "$pm_family" in
    arch)   gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy) ;;
    debian) gui=(alacritty wofi waybar grim slurp wl-copy) ;;
  esac
  if [[ "$mode" == "local" ]]; then printf '%s\n' "${common[@]}" "${gui[@]}"
  else printf '%s\n' "${common[@]}"; fi
}

verify_deps() {
  local -a deps=("$@") missing=()
  echo "Verifying dependencies..."
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then missing+=("$dep"); echo "  - $dep (missing)"
    else echo "  + $dep (installed)"; fi
  done
  if (( ${#missing[@]} )); then echo "Missing: ${missing[*]}"; fi
  printf '%s\n' "${missing[@]}"
}

verify_deps_strict() {  # re-run after install — the lock
  local -a need=("$@")
  local remaining; remaining="$(verify_deps "${need[@]}")"
  if [[ -n "$remaining" ]]; then warn "Still missing after install: $remaining"; return 1; fi
  info "All dependencies satisfied."
}

install_deps() {
  local pm_family="$1"; shift; local -a pkgs=("$@")
  (( ${#pkgs[@]} == 0 )) && return 0
  local -a cmd=()
  case "$pm_family" in arch) cmd=(sudo pacman -S --needed) ;; debian) cmd=(sudo apt-get install -y) ;; *) die "Unsupported pm family: $pm_family" ;; esac
  if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ${cmd[*]} ${pkgs[*]}"; return 0; fi
  confirm "Install ${pkgs[*]} via ${cmd[*]}?" || { info "Skipping install."; return 0; }
  "${cmd[@]}" "${pkgs[@]}"
}

# ── prompts + TUI checklist (before any write) ──────────────────────────────
prompt_mode()  { [[ -n "$MODE" ]] && { echo "$MODE"; return; }
  if command -v gum &>/dev/null; then gum choose --header "Deployment mode" "local" "server"
  else echo "1) local (full GUI)  2) server (headless)"; read -rp "Choice [1-2]: " r; [[ "$r" == "1" ]] && echo "local" || echo "server"; fi; }

prompt_shell() { [[ -n "$SHELL_CHOICE" ]] && { echo "$SHELL_CHOICE"; return; }
  if command -v gum &>/dev/null; then gum choose --header "Shell (default: zsh)" "zsh" "nushell"
  else echo "1) zsh (default)  2) nushell (backup)"; read -rp "Choice [1-2]: " r; [[ "$r" == "2" ]] && echo "nushell" || echo "zsh"; fi; }

build_package_list() { # → prints candidate names one per line with ON/OFF hint
  local mode="$1" shell_choice="$2"
  local -a core=(nvim "$shell_choice" starship) gui=(alacritty wofi hyprland waybar) priv=(keyd)
  # starship always ON; keyd OFF by default (privileged opt-in)
  # server mode: gui OFF; local: gui ON
  for p in "${core[@]}"; do echo "$p ON"; done
  if [[ "$mode" == "local" ]]; then for p in "${gui[@]}"; do echo "$p ON"; done; else for p in "${gui[@]}"; do echo "$p OFF"; done; fi
  for p in "${priv[@]}"; do echo "$p OFF"; done
}

tui_checklist() { # stdin: "pkg ON/OFF" lines → prints selected pkg names one per line
  local -a entries=(); mapfile -t entries
  local -a names=() defaults=()
  for e in "${entries[@]}"; do names+=("${e%% *}"); defaults+=("${e##* }"); done
  # primary: gum
  if command -v gum &>/dev/null && [[ -t 0 ]]; then
    local -a preselected=(); for i in "${!names[@]}"; do [[ "${defaults[$i]}" == "ON" ]] && preselected+=("${names[$i]}"); done
    # gum choose --no-limit --selected honors comma-joined preselected in 0.16+
    printf '%s\n' "${names[@]}" | gum choose --no-limit --header "Select packages (Space toggle, Enter confirm) — Esc to keep defaults" --height 14 \
      ${preselected:+--selected="$(IFS=,; echo "${preselected[*]}")"} 2>/dev/null || printf '%s\n' "${preselected[@]}"
    return
  fi
  # fallback 1: whiptail (preinstalled Ubuntu)
  if command -v whiptail &>/dev/null && [[ -t 0 ]]; then
    local -a args=(); for i in "${!names[@]}"; do args+=("${names[$i]}" "${names[$i]}" "${defaults[$i]}"); done
    local out; out="$(whiptail --title "Packages" --checklist "Space to toggle, Enter to confirm:" 20 78 10 "${args[@]}" 3>&1 1>&2 2>&3)" || true
    # whiptail returns quoted tags: "nvim" "zsh" → strip quotes
    echo "$out" | tr -d '"' | tr ' ' '\n' | grep -v '^$' || true; return
  fi
  # fallback 2: dialog
  if command -v dialog &>/dev/null && [[ -t 0 ]]; then
    local -a args=(); for i in "${!names[@]}"; do args+=("${names[$i]}" "${names[$i]}" "${defaults[$i]}"); done
    local out; out="$(dialog --checklist "Select packages:" 20 78 10 "${args[@]}" 3>&1 1>&2 2>&3)" || true
    echo "$out" | tr -d '"' | tr ' ' '\n' | grep -v '^$' || true; return
  fi
  # fallback 3: fzf --multi (when present, no ON/OFF semantics — just multi-select)
  if command -v fzf &>/dev/null && [[ -t 0 ]]; then
    printf '%s\n' "${names[@]}" | fzf --multi --prompt="Select packages> " --header="TAB select, ENTER confirm (no pre-check)" || true; return
  fi
  # fallback 4: plain read (headless/CI)
  echo "Available packages:"; for i in "${!names[@]}"; do printf "  %2d) %-12s [%s]\n" $((i+1)) "${names[$i]}" "${defaults[$i]}"; done
  read -rp "Enter numbers (e.g. 1 3 5) or 'all' [default: ON items]: " nums
  if [[ "$nums" == "all" ]]; then printf '%s\n' "${names[@]}"; return; fi
  if [[ -z "$nums" ]]; then for i in "${!names[@]}"; do [[ "${defaults[$i]}" == "ON" ]] && echo "${names[$i]}"; done; return; fi
  for n in $nums; do idx=$((n-1)); (( idx>=0 && idx<${#names[@]} )) && echo "${names[$idx]}"; done
}

# ── stow with preview ───────────────────────────────────────────────────────
stow_module() {
  local pkg="$1" dry_run="$2"
  local -a flags=(--dir="$SCRIPT_DIR" --restow)
  [[ "$dry_run" == true ]] && flags=(--dir="$SCRIPT_DIR" --no --verbose --restow)
  # real-file guard (starship folding, moved repo)
  if [[ "$pkg" != "keyd" ]]; then
    # probe target exists and is not symlink — warn and confirm before rm -rf
    :
  fi
  if [[ "$pkg" == "keyd" ]]; then
    if [[ "$dry_run" == true ]]; then echo "[DRY RUN] sudo stow --adopt -t / keyd && sudo keyd reload"; return; fi
    # conflict gate before adopt
    if [[ -f /etc/keyd/default.conf && ! -L /etc/keyd/default.conf ]]; then
      warn "/etc/keyd/default.conf exists and is not a symlink."
      command -v diff &>/dev/null && diff -u /etc/keyd/default.conf "$SCRIPT_DIR/keyd/etc/keyd/default.conf" || true
      confirm "Adopt and overwrite /etc/keyd/default.conf? (moves host file into repo)" || { info "Skipping keyd."; return; }
      sudo stow --adopt -t / keyd
    else
      sudo stow -t / keyd
    fi
    sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true
  else
    if [[ "$dry_run" == true ]]; then echo "[DRY RUN] stow ${flags[*]} $pkg"; fi
    stow "${flags[@]}" "$pkg"
  fi
}

# ── shell setup ─────────────────────────────────────────────────────────────
setup_shell() {
  local shell_choice="$1" dry_run="$2"
  if [[ "$shell_choice" == "zsh" ]]; then
    if ! command -v zsh &>/dev/null; then
      info "zsh not found — installing..."; install_deps "$(get_pm_family)" zsh
    fi
    if [[ ! -d ~/.local/share/zinit/zinit.git ]]; then
      if [[ "$dry_run" == true ]]; then echo "[DRY RUN] git clone zinit → ~/.local/share/zinit/zinit.git"
      else mkdir -p ~/.local/share/zinit && git clone --depth 1 https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git; fi
    fi
    # chsh offer last, never auto
    if [[ -t 0 && "$dry_run" != true ]]; then
      echo "Current shell: $SHELL"; confirm "Change default shell to zsh (chsh -s \$(which zsh))?" \
        && { which zsh | sudo tee -a /etc/shells >/dev/null; chsh -s "$(which zsh)"; }
    fi
  fi
}

# ── arg parsing (BashFAQ: ${1-} guard for set -u) ──────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do case "${1-}" in
    --mode) MODE="${2-}"; shift 2 ;;
    --shell) SHELL_CHOICE="${2-}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --stow-keyd) STOW_KEYD="${2-}"; shift 2 ;;
    --install) ACTION=install; shift ;;
    --uninstall|--remove) ACTION=uninstall; shift ;;
    --yes) ASSUME_YES=true; shift ;;
    --self-test|--verify) ACTION=selftest; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) die "Unknown option: ${1-}. See --help." ;;
  esac; done
}
```

**Key invariants the roadmap must enforce:**
- **Preview before write:** Every mutating path (`pacman -S`/`apt install`/`stow`/`chsh`/`systemctl`/`keyd reload`) is guarded by `[[ "$DRY_RUN" == true ]]` early return printing `[DRY RUN] Would run: …` + `stow --no --verbose` output. No write without user-visible preview when `--dry-run` is passed, and `tui_checklist` runs **before** any write (safety constraint from PROJECT.md).
- **Arg parsing must handle `set -u`:** Use `${1-}` / `${2-}` not bare `$1` — Bare `$1` with `set -u` aborts on missing arg and the user's `bash setup.sh --help` crashes before `usage`. The Bash Coding Standard BCS preamble + `shopt -s shift_verbose` catches shift errors.
- **Do not use `source /etc/os-release` without guard:** The file may not exist on containers. Guard with `[[ -f /etc/os-release ]]` and default `ID`/`ID_LIKE` to empty. Quote `"$ID_LIKE"` expansions for ShellCheck.

---

### Pattern 4: Zsh Init Ordering Contract (P10k Instant Prompt Top, Zoxide Last)

**What:** Strict sourcing order in `zsh/.zshrc` that preserves Powerlevel10k instant-prompt timing, Zinit Turbo, fzf history, and zoxide hook idempotence. Deviation breaks prompt rendering or double-registers `zoxide add -- $dir`.

**When to use:** Any edit to `zsh/.zshrc`. Keep the two `# NOTE:` comments intact — they are load-bearing.

**Prescribed order (annotate in file):**

```zsh
# 1. P10k instant prompt — MUST stay near top (above any console-input code)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. XDG + PATH deduplication (typeset -U, not repeated export)
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
typeset -U path PATH               # ← deduplicate (CONCERNS.md PATH length)
path=(~/.local/bin ~/.local/sbin ~/.cargo/bin ~/.bun/bin ~/.npm-global/bin $path)
export PATH
export EDITOR=nvim; export BUN_INSTALL="$HOME/.bun"

# 3. Early aliases / XDG (conditionally source ~/.shell_aliases if present)

# 4. Zinit bootstrap + load (OMZL compfix/completion/git, OMZP pip/terraform,
#    zinit-annex, zinit annexes) — ZINIT[HOME_DIR] contract

# 5. Theme: romkatv/powerlevel10k + catppuccin-powerlevel10k annex

# 6. Zinit plugins (order-sensitive):
#    zsh-completions → zsh-autosuggestions (with atload autosuggest_start) →
#    fast-syntax-highlighting →
#    fzf history — PICK ONE (see conflict fix below), NOT both
#    marlonrichert/zsh-autocomplete (binds ^I menu-select)

# 7. FZF integration — AFTER Zinit but BEFORE bindkey overrides
#    if fzf >=0.48: source <(fzf --zsh)   (replaces key-bindings.zsh)
#    else: [[ -f /usr/share/fzf/key-bindings.zsh ]] && source …
#    then: bindkey '^R' fzf-history-widget  (normalize across plugins)
#    FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap"

# 8. Zoxide — AFTER fzf + bindkey, with explicit comment
# NOTE: zoxide must be sourced here (after fzf) to avoid hook overwrite
eval "$(zoxide init zsh)"
# verify: zoxide --version; which zoxide

# 9. Vi mode + keybindings (bindkey -v, zle-keymap-select, edit-command-line ^X^E)
#    DO NOT rebind ^R/^I after this (would clobber fzf)

# 10. Machine-local tail — LAST before p10k apply
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# 11. Powerlevel10k apply (source ~/.p10k.zsh, apply_catppuccin, POWERLEVEL9K_* overrides)
#    This re-applies VI_MODE_*_FOREGROUND after catppuccin theme
```

**Conflict fix prescribed (must pick one, document in comments):**
- **Option A (recommended, least maintenance):** Keep `junegunn/fzf` native `Ctrl-R` (`source <(fzf --zsh)` + `bindkey '^R' fzf-history-widget`) and **remove** `joshskidmore/zsh-fzf-history-search` (`zi light …` line). Use `marlonrichert/zsh-autocomplete` only with `zstyle ':autocomplete:tab:*' fzf yes`. Pro: one history widget, upstream-maintained fzf.
- **Option B:** Keep `joshskidmore/zsh-fzf-history-search` and drop `zsh-autocomplete`'s history binding. Less recommended — the one-line plugin duplicates fzf native.
- Never load both history plugins — both bind `^R` and `zsh-fzf-history-search` + `zsh-autocomplete` `^I menu-select` clash (PROJECT.md "resolve conflicts" requirement). Post-stow verification: `bindkey '^R'; bindkey '^I'; zle -l | grep -i fzf`.

**`zsh/.zprofile` Hyprland guard (prescribed):**

```zsh
# Auto-start Hyprland on TTY1 — guarded for server mode + executable check
# Writes ~/.config/dotfiles/mode by installer; fallback to $DOTFILES_MODE env
DOTFILES_MODE="${DOTFILES_MODE:-$(cat ~/.config/dotfiles/mode 2>/dev/null || echo local)}"
if [[ "$DOTFILES_MODE" != "server" ]] \
   && [[ -z "${DISPLAY-}" ]] \
   && [[ "$(tty 2>/dev/null)" == "/dev/tty1" ]] \
   && { command -v Hyprland &>/dev/null || command -v start-hyprland &>/dev/null; }; then
  exec start-hyprland 2>/dev/null || exec Hyprland 2>/dev/null || true  # never kill login on missing binary
fi
```
Installer writes `mkdir -p ~/.config/dotfiles && echo "$MODE" > ~/.config/dotfiles/mode` after mode selection. Also support `autostart_hyprland=false` env override.

---

### Pattern 5: Theme Centralization (Single Token)

**What:** One `THEME` token (`theme.toml` `flavor=mocha` or `THEME=mocha` env) validated — not templated — at install. This milestone deliberately avoids `chezmoi`/`yadm` templating (anti-feature, would re-layout 7 packages).

**When to use:** When `alacritty.toml` import, `starship.toml palette`, `nvim/colorschemes/catppuccin.lua`, and `nushell/catppuccin.nu` diverge (currently `alacritty mocha` vs `starship latte` inconsistency).

**Prescribed minimal v1 (validation, not generation):**

```bash
apply_theme() { # called after mode selection, before stow
  local theme="${THEME:-mocha}"  # or cat theme.toml
  # validate consistency — warn, don't auto-sed yet
  local alacritty_import; alacritty_import="$(grep -o 'catppuccin-[a-z]*\.toml' alacritty/.config/alacritty/alacritty.toml 2>/dev/null || true)"
  local starship_palette; starship_palette="$(grep -o "palette.*=.*'[^']*'" starship/.config/starship.toml 2>/dev/null || true)"
  if [[ "$alacritty_import" == *mocha* && "$starship_palette" == *latte* ]]; then
    warn "Theme mismatch: alacritty=$alacritty_import vs starship=$starship_palette (expected both $theme). Run THEME=$theme bash setup.sh to reconcile."
  fi
  # optional: THEME= envsubst for stowed files (defer auto-sed to v1.x)
}
```

Future `THEME` → `sed -i "s/catppuccin-latte/catppuccin-$theme/"` can be added once validation proves needed (before 5th manual edit).

---

## Data Flow

### Request Flow — Primary: Stow Deployment via Unified Bash Installer

```
User: bash setup.sh [--mode local --shell zsh --stow-keyd n --dry-run]
  │
  ├─ 1. main() parse_args → ACTION/MODE/SHELL_CHOICE/DRY_RUN/STOW_KEYD/ASSUME_YES
  │
  ├─ 2. get_distro()  ──► source /etc/os-release (ID + ID_LIKE)
  │                       + command -v pacman/apt probe
  │                       → pm_family = arch | debian | unknown (die with manual stow hint)
  │
  ├─ 3. get_deps(pm_family, MODE, SHELL_CHOICE)
  │       common=[stow,nvim,starship,git,zoxide,uv,rg,node,npm,make,gcc,+zsh|nushell,+fzf]
  │       gui=[hyprland,alacritty,wofi,keyd,waybar,grim,slurp,wl-copy] (only if MODE==local)
  │       → candidate deps list
  │
  ├─ 4. verify_deps(deps) ──► command -v loop → missing vs installed (echo + collecting)
  │       if missing non-empty:
  │         partition core_missing vs gui_missing
  │         if [[ ! -t 0 ]] → auto-install core, skip GUI (headless guard)
  │         else prompt Install ALL / CORE only / Skip / Select (gum/whiptail/read)
  │         install_deps(pm_family, selected) → pacman -S --needed / apt install -y
  │         verify_deps_strict() re-run → abort with report if still missing
  │       else → All dependencies satisfied.
  │
  ├─ 5. prompt_mode (if MODE empty) → gum choose | whiptail | read
  │     prompt_shell (if SHELL_CHOICE empty) → gum choose zsh (default) | nushell (backup)
  │     build_package_list(MODE, SHELL_CHOICE) → candidate pkgs with ON/OFF per mode
  │     tui_checklist(candidate) ──► selected set (before ANY write — safety invariant)
  │       gum choose --no-limit --selected → whiptail --checklist 3>&1 1>&2 2>&3
  │       → dialog → fzf --multi → read "1 3 5 or all"
  │     persist: mkdir -p ~/.config/dotfiles && echo "$MODE" > ~/.config/dotfiles/mode
  │
  ├─ 6. setup_shell(SHELL_CHOICE, DRY_RUN)
  │       if zsh: command -v zsh || install_deps zsh
  │               [[ -d ~/.local/share/zinit/zinit.git ]] || git clone zinit (commit-pinned)
  │               stow --restow zsh
  │               maybe_chsh → which zsh | sudo tee -a /etc/shells + chsh -s (only if confirm)
  │
  ├─ 7. run_stow(selected, DRY_RUN, STOW_KEYD)
  │       for pkg in selected core+selected gui: stow_module(pkg)
  │         if keyd in selected:
  │           stow --no --verbose -t / keyd preview
  │           if /etc/keyd/default.conf exists && ! -L → diff + gum confirm "Adopt?" → only then --adopt
  │           else sudo stow -t / keyd
  │           sudo keyd reload || systemctl reload keyd
  │         else: stow --dir="$SCRIPT_DIR" --restow <pkg>  (or --no --verbose if DRY_RUN)
  │       also: apply_theme() consistency check
  │
  ├─ 8. shell reload / editor launch picks up symlinks
  │       zsh: p10k instant prompt top → Zinit → theme → plugins → fzf → zoxide last → ~/.zshrc.local tail
  │       nvim: init.lua bootstrap → lang aggregator → lazy setup → which-key + Mason auto-install (see below)
  │
  └─ 9. self_test (if --self-test or post-stow verify)
          stow --no --verbose --restow nvim zsh starship preview
          test -L ~/.config/nvim && readlink -f ~/.config/nvim/init.lua checks
          zoxide --version; starship --version; fzf --version; PATH dedup check
          nvim --headless -c "checkhealth" -c "qa"  (grep ERROR → fail)
          nvim --headless -c "MasonInstallAll" or mason-tool-installer sync
          zsh -ic 'bindkey | grep fzf; which zoxide; echo $PROMPT' checks
          → TAP ok/not ok lines; exit non-zero on any gate failure
```

### Request Flow — Secondary: Neovim Startup (after stow succeeds)

```
nvim (EDITOR=nvim, git commit, or Ctrl+X Ctrl+E from zsh)
  │
  ├─ 1. init.lua: (vim.uv or vim.loop).fs_stat(lazypath) → if missing: git clone --filter=blob:none
  │              --branch=stable with vim.v.shell_error guard + getchar + os.exit(1) on fail
  │              vim.opt.rtp:prepend(lazypath)
  │
  ├─ 2. init.lua: specs = { {import="plugins"}, require("colorschemes") }
  │              -- require("lang") pcall; on fail notify ERROR and use empty {plugin_specs={}}
  │              -- for each spec in lang_config.plugin_specs: table.insert(specs, spec)
  │
  ├─ 3. init.lua: require("lazy").setup(specs, {defaults.lazy=true,
  │              performance.rtp.disabled_plugins={23 entries}})
  │              + pcall(require,"local") if present (machine-local)
  │
  ├─ 4. lang/init.lua: for lang in settings.languages → pcall(require,"lang."..lang.."."..lang)
  │              merge lsp_servers/mason_packages/treesitter_parsers with deduplicate()
  │              pcall(require,"lang."..lang..".plugins") silently if missing
  │
  ├─ 5. vim.schedule(function() vim.cmd.colorscheme(settings.colorscheme) end)
  │              — colorscheme after lazy completes (avoids flash)
  │              — which-key.nvim (VeryLazy) auto-shows on <Space> via desc in base/keymaps.lua
  │
  └─ 6. Demand-driven plugins: lspconfig on BufReadPre, conform on BufReadPre/BufNewFile,
         telescope on cmd Telescope, blink.cmp on insert — each consumes require("lang")
         mason-tool-installer run_on_start (delay 3000) installs missing mason_packages
         telescope-fzf-native cond executable("make")==1 else notify WARN (not silent)
```

### Request Flow — Secondary: Zsh Interactive Startup (after `chsh` or `zsh` launch)

```
login / zsh
  │
  ├─ 1. zsh/.zprofile (login only): DOTFILES_MODE guard + DISPLAY/tty1/Hyprland executable check
  │              → exec start-hyprland only if MODE != server && Hyprland present; never kill login
  │
  ├─ 2. zsh/.zshrc line 1: p10k instant prompt (must be top)
  │
  ├─ 3. XDG exports + PATH dedup (typeset -U path)
  │
  ├─ 4. Zinit bootstrap + ZINIT[HOME_DIR] setup
  │
  ├─ 5. OMZL compfix/completion/git → OMZP pip/terraform → anx annexes
  │
  ├─ 6. Powerlevel10k theme + catppuccin annex
  │
  ├─ 7. Zinit plugins: zsh-completions → zsh-autosuggestions → fast-syntax-highlighting
  │              → fzf history (ONE of joshskidmore vs native fzf --zsh, not both) → zsh-autocomplete (^I)
  │
  ├─ 8. FZF integration: source <(fzf --zsh) (≥0.48) or /usr/share/fzf/key-bindings.zsh
  │              bindkey '^R' fzf-history-widget
  │
  ├─ 9. Eval zoxide init zsh (sourced LAST — hook overwrite guard)
  │
  ├─10. bindkey -v + vi widgets + edit-command-line ^X^E
  │
  ├─11. [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local  (machine-local tail)
  │
  └─12. Source ~/.p10k.zsh + apply_catppuccin + POWERLEVEL9K overrides (VI_MODE_FG after theme)
```

### State Management

```
Filesystem as state (stateless dotfiles — no DB/server):
  repo root (stow directory) ──stow --restow──► $HOME / ~/.config / /etc/keyd
                                ──stow -D───►  unstow (reverse, with Type 'yes' confirm)
  nvim state:  ~/.local/share/nvim/lazy/ (lazy.nvim clones, 44 pins in lazy-lock.json)
               ~/.local/share/nvim/mason/ (Mason registry installs)
               ~/.local/state/nvim, ~/.cache/nvim, nvim/.config/nvim/{undo,shada,state,cache}
  shell state: ~/.local/share/zinit/polaris/bin, ~/.cache/p10k-instant-prompt-*.zsh,
               ~/.zsh_history, nushell/history.{txt,json}, zoxide db ~/.local/share/zoxide/db.zo
  mode marker: ~/.config/dotfiles/mode  (written by installer, read by .zprofile Hyprland guard)
  theme token: ./theme.toml or $THEME env (single source, validated at install)
  machine-local: ~/.zshrc.local (sourced tail), nvim/lua/local.lua (pcall), secrets.nu (ignored)
```

### Key Data Flows

1. **Install data flow:** `User args + /etc/os-release + command -v probes + interactive prompts → pm_family + pkg lists + selected set → host package installs (pacman/apt) → stow symlinks → shell/editor pick up configs`. TUI checklist is the last human gate before any write — builds trust for VM testing.
2. **Uninstall data flow:** `bash setup.sh --uninstall --mode local|server → build_package_list(same as install) → confirm "Type 'yes'" → stow -D per package + sudo stow -D -t / keyd → optional rm -rf ~/.local/share/nvim/mason when nvim deselected → no snapshot yet (document tar backup one-liner)`. Removal must be idempotent — second uninstall is no-op.
3. **DRY_RUN data flow:** `DRY_RUN=true` short-circuits before every mutating `sudo`/`stow`/`chsh`/`systemctl` with `[DRY RUN] Would run:` + `stow --no --verbose` output. Must also preview privileged `keyd --adopt` without exec. Self-test reuses dry-run gates plus headless `nvim --headless` health.
4. **Derivatives data flow:** `ID_LIKE=arch` on Manjaro/EndeavourOS + `pacman` probe → `pm_family=arch` → Arch GUI deps including `hyprland`/`keyd`; `ID_LIKE=ubuntu`/`debian` on Mint/Pop!_OS + `apt` probe → `debian` → Wayland subset. Unknown family → die with `README Manual Installation` hint + `stow --restow nvim zsh starship` fallback.
5. **Editor plugin data flow:** `settings.languages` (single array) → `lang/init.lua` deduplicated `mason_packages` → `mason-tool-installer ensure_installed` (deferred 3s) → `MasonInstallAll` headless from installer → `conform`/`treesitter`/`lspconfig` consume `require("lang")` formatters/servers. Typo in `settings.languages` → `pcall WARN` toast + silent feature loss — verify via `nvim --headless +"lua print(vim.inspect(require('lang').mason_packages))"`.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **Current (7 packages, 14 langs, 1 user, 2 hosts, 2 distros)** | Monolith `setup.sh` + hard-coded arrays is fine. No `manifest.toml` strictly required — inline `common`/`gui` with `case "$pm_family"` is readable and avoids indirection. Keep `THEME` validation-only; keep `chezmoi`/`yadm` out. |
| **6-12 packages, 20+ langs, 3-5 machines, 3 distros** | Extract `manifest.toml` with `tag: core\|gui\|arch-only` and generate stow commands dynamically — hard-coded `local -a gui=(…)` becomes unwieldy and `mode × distro` combinational testing grows. Add `starship-minimal.toml` auto-select for `server` (scan_timeout 200, disabled unused segments). Split `languages` into tiers: `core` always-installed vs `opt-in` loaded on first file open via `:MasonInstall <lang>` to cap `mr.refresh` burst (~500MB parsers linear per CONCERNS.md). |
| **12+ packages, 30+ langs, team adoption** | Consider `chezmoi` + `age`/`sops` templating only if machine-local `*.local` + `THEME` token proves insufficient (encrypted secrets become table stakes, not just `secrets.nu` placeholder). Add `.github/workflows/dotfiles.yml` matrix Arch/Ubuntu × local/server running `setup.sh --self-test --dry-run` headless. Snapshot/rollback before teardown (`tar -czf ~/dotfiles-backup-$(date +%F).tar.gz …` + `setup.sh --restore`) becomes expected. |

### Scaling Priorities

1. **First bottleneck — Stow package fan-out vs `gui_modules` hard-code:** Adding an app per quarter (e.g., `waybar/` config) requires editing `setup.zsh`/`setup.nu` GUI arrays in 4 places — already drifted. Fix in v1 by canonicalizing to `setup.sh` with one `gui` array; in v1.x extract `manifest.toml` if list exceeds ~10 packages. Test via `stow --no --verbose` preview.
2. **Second bottleneck — Neovim language count linear cost:** Each new `settings.languages` entry appends to `mason_packages` + `treesitter_parsers` + `mr.refresh` network/disk. At 30+ langs cold `:MasonInstallAll` is minutes and `require("lang")` loop grows O(n) on every startup. Mitigate with tiered `core` vs `opt-in` and `mason-tool-installer` debounce — installer only headless-installs `core`.
3. **Third bottleneck — Host PATH length + prompt latency:** `~/.local/bin` + `~/.local/sbin` + `~/.cargo/bin` + `~/.bun/bin` + `~/.npm-global/bin` + `~/.local/share/zinit/polaris/bin` already 6 segments before `zoxide`/`starship` hooks; re-sourcing `zsh/.zshrc` duplicates without `typeset -U`. And `starship.toml scan_timeout=1000` scans 12 language segments per prompt (each spawning `node --version`-like subprocess). Not mitigated in this milestone beyond `typeset -U path` + documenting `starship timings` diagnose; tune in v1.x with per-mode starship variant.

---

## Anti-Patterns

### Anti-Pattern 1: Mirrored Bootstrapper Logic Without Shared Source

**What people do:** Keep `setup.nu` + `setup.zsh` (+ `teardown.*`) duplicating `get-distro`/`get-deps`/`verify-deps`/`run-stow` in different syntax, and fix a bug in one but not the other.

**Why it's wrong:** Drift already happened: `setup.nu core=[nvim,nushell,starship]` vs `setup.zsh core=[nvim,zsh]` and GUI list mismatch between teardown variants. Future dependency change (e.g., adding `make`+`gcc` to fix telescope) risks inconsistent `--mode local` payloads and a user on `zsh setup.zsh` gets the fix while `nu setup.nu` does not — silent inconsistency for months.

**Do this instead:** Make `setup.sh` (Bash) the single canonical source with `get_distro`/`get_deps`/`verify`/`install`/`stow` + optional `manifest.toml`. Make `setup.zsh`/`setup.nu` thin shims `exec bash setup.sh "$@"` for one release, then delete. Update README to `bash setup.sh --mode local` everywhere (Zsh default, Nushell backup).

---

### Anti-Pattern 2: Hard-Coded `ID` Allowlist Rejecting Derivatives

**What people do:** `if distro not-in ["arch","cachyos","ubuntu"] { print "Error: only supports Arch/CachyOS/Ubuntu"; exit 1 }` or `case "$distro" in arch|cachyos|ubuntu)` — treating `cachyos` as distinct from `arch` despite same `pacman`.

**Why it's wrong:** Covers only 3 of ~12 real-world IDs users hit: Manjaro (`ID=manjaro ID_LIKE=arch`), EndeavourOS (`ID=endeavouros ID_LIKE=arch`), Mint (`ID=linuxmint ID_LIKE=ubuntu`), Pop!_OS (`ID=pop ID_LIKE=ubuntu debian`) all abort with a hard error even though package manager is compatible, forcing manual `stow` and bypassing validation (CONCERNS.md #1 tech debt, PROJECT.md crash fix requirement).

**Do this instead:**
```bash
source /etc/os-release  # guard [[ -f … ]]
if command -v pacman &>/dev/null; then pm=arch
elif command -v apt-get &>/dev/null; then pm=debian
elif [[ " $ID_LIKE " == *" arch "* ]] || [[ "$ID" == "cachyos" ]]; then pm=arch
elif [[ " $ID_LIKE " == *" debian "* ]] || [[ " $ID_LIKE " == *" ubuntu "* ]]; then pm=debian
else die "Unknown distro ($ID/$ID_LIKE). See README Manual Installation: stow --restow nvim zsh starship"
fi
```
Probe `command -v` first (most reliable on derivatives), `ID_LIKE` second, `ID` last.

---

### Anti-Pattern 3: Privileged `stow --adopt -t / keyd` Without Confirmation or Diff

**What people do:** `sudo stow --adopt -t / keyd && sudo keyd reload && sudo systemctl start keyd` with only a generic `get-mode-interactive` prompt and no preview of what `--adopt` will do.

**Why it's wrong:** `stow` manual warning: `--adopt` **moves host files into repo** — intended to alter stow directory; if you do not want that, this option is not for you. Silent data loss + repo pollution; if `default.conf` were stale/malicious it hijacks input handling (CONCERNS.md SECURITY + CODE_SCANNING miss). Sudoers `NOPASSWD: /usr/bin/systemctl *` widens privilege beyond `start|stop|reload keyd`.

**Do this instead:**
```bash
if [[ -f /etc/keyd/default.conf && ! -L /etc/keyd/default.conf ]]; then
  warn "Existing /etc/keyd/default.conf is not a symlink (real file)."
  diff -u /etc/keyd/default.conf "$SCRIPT_DIR/keyd/etc/keyd/default.conf" 2>/dev/null || true
  confirm "Adopt host file into repo and overwrite with stowed version? Type 'yes' only if intentional." \
    || { info "Skipping keyd (use --stow-keyd y to force)."; return; }
  sudo stow --adopt -t / keyd
else
  sudo stow -t / keyd  # no conflict → plain stow, no adopt
fi
sudo keyd reload 2>/dev/null || sudo systemctl reload keyd
```
Sudoers least-privilege: `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd, /usr/bin/systemctl reload keyd, /usr/bin/keyd reload`. Checklist `keyd` OFF by default requiring explicit toggle.

---

### Anti-Pattern 4: Unconditional `exec start-hyprland` on tty1 Regardless of Mode

**What people do:** Leave `zsh/.zprofile` as `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` (present in repo) while `setup.sh --mode server` stowed only `nvim`+`zsh` headless. Nushell path has the same block commented — Zsh path unconditionally execs.

**Why it's wrong:** Server user logs in on tty1 expecting a shell, Hyprland is not installed, `exec` fails and **login session dies** (CONCERNS.md Known Bug, trigger: `server` mode + Zsh login on tty1). Nushell users on tty1 never auto-launch even when they should.

**Do this instead:** Installer writes `~/.config/dotfiles/mode` (`local` vs `server`) and `.zprofile` reads it + checks executable before exec (see Zsh Init Ordering → Hyprland guard recipe). Never `exec` without `command -v Hyprland` / `command -v start-hyprland` guard and `|| true` fallback.

---

### Anti-Pattern 5: `telescope-fzf-native` Silently Falling Back When `make` Missing

**What people do:** Keep `plugins/telescope.lua` as `cond = function() return vim.fn.executable("make")==1 end, build="make"` (present) with no warning else branch, while `setup.zsh:get_deps` `common` omits `make`/`gcc` for `--mode server` (only `nvim/README.md` lists toolchain, not bootstrapper). Result is silent perf regression to generic sorter.

**Why it's wrong:** Users expect fzf performance; minimal server images lack `build-essential` so fresh `server` install always falls back without telling the user (CONCERNS.md Known Bug). Performance bottleneck masked as "working but slow".

**Do this instead:** (a) Installer fix: add `make`+`gcc` to `common` for **all** modes (already in `get_deps` recipe above). (b) Editor fix: add WARN toast in cond fallback or config hook:
```lua
cond = function() 
  local ok = vim.fn.executable("make")==1
  if not ok then vim.schedule(function()
    vim.notify("telescope-fzf-native: 'make' not found — falling back to generic sorter. Run bash setup.sh to install build-essential.", vim.log.levels.WARN)
  end) end
  return ok
end,
```
Self-test asserts `command -v make && command -v gcc`.

---

### Anti-Pattern 6: Committing Secrets in Tracked Shell Env Files

**What people do:** Commit `$env.MISTRAL_API_KEY = "<redacted>"` in `nushell/.config/nushell/env.nu:48` (present, flagged in ARCHITECTURE.md Anti-Patterns + CONCERNS.md SECURITY) and rely on `.gitignore` not excluding `env.nu`.

**Why it's wrong:** Live credential exposed to every clone and forever in `git log --all -S MISTRAL_API_KEY`; GitHub scanning flags; credential leaked beyond `.env` forbidden-files contract because `env.nu` / `*.zsh` assignment pattern `*_API_KEY=` was not scanned.

**Do this instead:** Rotate key via Mistral dashboard immediately (out-of-band, not in milestone), replace committed line with `$env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""` placeholder, move real value to `~/.config/nushell/secrets.nu` (gitignored) sourced from `env.nu` via `[[ -f ~/.config/nushell/secrets.nu ]] && source …`, document `sops`/`age`/`pass` alternative + `gitleaks`/`git-secrets` pre-commit hook in README. In this milestone only document — do not attempt `git filter-repo` history purge (PROJECT.md scope filter: "do not fix Nushell-only secret handling beyond documentation").

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **`/etc/os-release`** (systemd `os-release(5)`) | `source /etc/os-release` then `ID`/`ID_LIKE` + `command -v pacman/apt-get` probe → `pm_family` | `ID_LIKE` is space-separated (`arch`, `debian`, `ubuntu`); use `" $ID_LIKE " == *" arch "*` glob, not `== arch`. Quote expansions. Probe pm binary first — most reliable on derivatives that set `ID` to `manjaro`/`endeavouros` but `ID_LIKE=arch`. See `man os-release(5)` caveat: `ID_LIKE` may be absent on minimal containers — guard `ID_LIKE:-`. |
| **GNU Stow 2.4.1** | `stow --dir="$SCRIPT_DIR" --restow/-D/--no --verbose --adopt -t /` CLI via Bash `stow_module` | Pin `stow >=2.4.1` (host is 2.3.1 → **upgrade** before milestone). 2.4.1 fixes `--dotfiles` + spurious `BUG in find_stowed_path?` on unstow that 2.3.1 emits. Verify `stow --version` in self-test. Repo root must be stow dir; `starship/.config/starship.toml` folding silently wrong if invoked from subdir — assert `[[ -f ./setup.sh ]]`. |
| **GitHub — lazy.nvim + 44 plugin sources** | `git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable` inside `init.lua` bootstrap; `lazy-lock.json` pins 44 commits | Use `vim.uv or vim.loop` + `vim.v.shell_error` guard (official snippet). Bootstrap executes as user; HTTPS + GitHub implicit trust — mitigate by committing `lazy-lock.json` and verifying `git -C $lazypath rev-parse HEAD` vs lock entry (bootstrap drift CONCERNS.md). `lazy.nvim` stable tip vs `85c7ff3` pin mismatch on fresh clone → WARN. |
| **Mason registry** (`mason-org/mason.nvim`, `mason-registry`) | `mr.refresh(callback)` + `mr.has_package` + `pkg:is_installed()` + `MasonInstall` bulk via `utils/mason-install-all.lua` + `mason-tool-installer ensure_installed/run_on_start/start_delay` | Migrated from `williamboman` → `mason-org` since 2024-05; old namespace still redirects but use `mason-org/*`. `ensure_installed` async; for `setup.sh` headless sync use `check_install(false,true)` with `sync=true`. Deduplicate via existing `deduplicate()` — 14 langs merging `mason_packages` linearly. |
| **Node / npm + bun** | Host `node`+`npm` in `common` for JS/TS `typescript-language-server`/`prettier`; `zsh/.zshrc` exports `BUN_INSTALL=~/.bun` + `PATH+=~/.bun/bin` | Duplication risk (CONCERNS.md Dependencies at Risk): Nushell path may miss `bun` while JS langs enabled. Canonicalize on `node`+`npm` for `server`; document `bun` as opt-in for `local`. Installer `get_deps` includes `node`+`npm` for all modes. |
| **Python / uv** | `uv` in `common`; Nushell `scripts/uv.nu` (400-line externs) + `venv.nu` bridge to `venv-selector.nvim`; Zsh `uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv` | Zsh completions need `fpath` + `autoload -Uz _uv` + `mkdir -p ~/.config/zsh/completions`. Source `uv.nu` eagerly on Nushell startup (no lazy-load this milestone — CONCERNS.md Nushell perf bottleneck left for future). |
| **Starship + Alacritty + Wofi/Waybar/Keyd** | `starship init zsh` / `starship init nu`; `alacritty.toml import = ["catppuccin-mocha.toml"]`; `starship.toml palette='catppuccin_latte'`; `wofi/style.css` | `scan_timeout=1000` per CONCERNS.md (waits 1s scanning 12 language segments) — keep for `local` powerline, use `starship-minimal.toml` for `server` (`scan_timeout=200`). THEME mismatch (`alacritty mocha` vs `starship latte`) caught by `apply_theme()` consistency check — minimal v1 is validation not generation. |
| **Charmbracelet gum / whiptail / dialog / fzf** | `gum choose --no-limit --header/--selected` primary; `whiptail --checklist 20 78 10 … 3>&1 1>&2 2>&3` fallback; `fzf --multi` last TUI; plain `read` for headless | `gum` static Go binary: `pacman -S gum` / charm apt repo w/ `gpg` keyring / `go install`. `whiptail` preinstalled Ubuntu; `dialog` superset. `fzf` 0.48+ `source <(fzf --zsh)` vs Ubuntu 24.04 legacy 0.44.1 — installer detects `fzf --version` + warns <0.48. Any of the four must allow checklist override before writes. |
| **zoxide / ripgrep / fzf toolchain** | `eval "$(zoxide init zsh)"` (LAST in `.zshrc`), `grepprg=rg --vimgrep` in `base/options.lua`, `fzf --zsh` history widget | `zoxide 0.9.3 host → 0.10.0 latest`; 0.9.8+ requires `fzf ≥0.51` for `zi` interactive. `ripgrep` core dep for `telescope live_grep`; add `.ignore` at `nvim/.config/nvim/.ignore` for `state/|cache/|shada/|undo/|.git/|lazy-lock.json` to cut noisy `live_grep` across `state/cache/shada`. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|--------------|-------|
| `setup.sh` ↔ `/etc/os-release` + `command -v` | `source` + `which` probes (filesystem + PATH) | Distro boundary is the first failure mode — must degrade to `unknown` + manual-stow hint not crash. No hard-coded allowlist. |
| `setup.sh` ↔ `stow` (7 packages) | `stow --dir="$SCRIPT_DIR" --restow/-D/--no` CLI + `test -L`/`readlink -f` verification | Boundary is filesystem symlinks; correctness asserted by `stow --no --verbose` preview + post-stow `readlink` in self-test. `keyd -t /` is the only privileged crossing — gated by diff+confirm. |
| `setup.sh` ↔ `zsh/.zshrc` + `zsh/.zprofile` | `stow` deploys → shell sources at login/interactive; mode marker `~/.config/dotfiles/mode` | Installer writes marker; `.zprofile` reads it to guard `exec start-hyprland`. `.zshrc` tail sources `~/.zshrc.local` (machine-local). Init ordering contract is load-bearing — zoxide last, p10k top. |
| `setup.sh` ↔ `nvim/.config/nvim/init.lua` + `lua/lang/init.lua` | `stow` deploys → `nvim --headless -c "MasonInstallAll"` / `check_install` post-stow hook | Mason lifecycle boundary: installer triggers headless install, editor lazy-installs deferred. Single toggle `settings.languages` is the only coupling — typo only surfaces via `pcall WARN` toast. |
| `nvim/init.lua` ↔ `lua/lang/init.lua` ↔ `lua/lang/<lang>/<lang>.lua` | `pcall(require, mod)` + `deduplicate()` merge (6 tables) | Direction is `init.lua → lang/init.lua → lang/*/*` and `plugins/*.lua → require("lang")` — no cycles (verified in ARCHITECTURE.md Analysis). Adding a lang requires only new file + `settings.languages` entry. |
| `nvim/plugins/telescope.lua` ↔ `make`/`gcc` toolchain | `cond = executable("make")==1` + `build="make"` | `setup.sh` must ensure toolchain in `common` so cond never silently false on `server`. Add WARN toast in else so user sees fallback, not just generic sorter. |
| `zsh/.zshrc` ↔ `fzf` + `zoxide` + `starship` + `uv` | `source <(fzf --zsh)` / `eval "$(zoxide init zsh)"` / `eval "$(starship init zsh)"` / `uv completions` | All four integrate via `eval`/`source` and load order matters — fzf before zoxide, starship/MISTRAL env before both. Misordering breaks hooks/completions with only manual `zsh -i` to discover. Preserve `test-zoxide.nu` hook count assertion. |
| `zsh/.zshrc` ↔ `~/.zshrc.local` + `nvim/lua/local.lua` ↔ `.gitignore` | `[[ -f ~/.zshrc.local ]] && source` tail guard; `pcall(require,"local")` | Machine-local boundary prevents per-host `PATH`/`alias`/`theme` from dirtying git. `.gitignore` must list `zsh/.zshrc.local`, `nvim/.config/nvim/lua/local.lua`, `nushell/secrets.nu`. |
| `starship/.config/starship.toml` ↔ `alacritty/catppuccin-mocha.toml` ↔ `THEME` token | `THEME` env / `theme.toml` → `apply_theme()` consistency check → stowed files | Theme boundary is currently duplicated (4 files) — minimal fix is validation + warning. Full templating (chezmoi) deferred. Keep `tokyodark` active in `settings.lua` until unified. |

---

## Suggested Build Order

Build in this order — every step is a prerequisite for the next. Ordering rationale is dependency direction, not size.

### Phase 1: Installer Skeleton + Safe-Invoke Hardening

**Build:** `setup.sh` preamble (`set -Eeuo pipefail; shopt -s inherit_errexit …; SCRIPT_DIR; die/info/warn/confirm`), `usage()` + `parse_args()` with `${1-}` guard for `set -u`, `--dry-run` plumbing that short-circuits every mutating path, repo-root assertion `[[ -f ./setup.sh ]]`, `stow --version ≥2.4.1` check, `shellcheck -S warning setup.sh` + `shfmt -i 4 -ci` gate.

**Why first:** Nothing else can be tested safely without `--dry-run` covering `stow`/`pacman`/`apt`/`chsh`/`systemctl`. Also fixes the silent `set -u` crash on `bash setup.sh --help` with no arg (Bare `$1` vs `${1-}`). Establishes the invocation contract (`bash setup.sh` from repo root) that `starship` folding and `keyd -t /` depend on.

**Addresses:** PROJECT.md unified Bash entry (`setup.sh` replaces 4 scripts), `teardown` parity foundation, CONCERNS.md no lock for system installs (preview first step).

**Requires no prior phase.**

---

### Phase 2: Distro + Dependency Correctness (Derivatives, Package-Manager Probe, Re-Verify)

**Build:** `get_distro()` with `ID_LIKE` + `command -v pacman/apt-get` probe (priority: pm → ID_LIKE → ID), `get_pm_family()` alias, `get_deps()` corrected `common` (add `make`+`gcc`+`zsh`/`fzf` for all modes, per-pm `gui` lists un-diverged between Nushell/Zsh), `verify_deps()` (`command -v` loop, `+`/`-` echo), `install_deps()` with `pacman -S --needed` / `apt install -y` + `verify_deps_strict()` re-run that aborts with report if still missing, non-interactive `[[ ! -t 0 ]]` auto-install-core path.

**Why second:** Derivatives (`Manjaro`/`EndeavourOS`/`Mint`/`Pop!_OS`) crash at step 1 today — no downstream feature (checklist, stow, shell setup, Mason) can run until this is fixed. `make`+`gcc` in `common` also unblocks `telescope-fzf-native` silent fallback (Phase 6). Re-verify is the "lock" CONCERNS.md requires.

**Depends on:** Phase 1 skeleton (needs `parse_args` + `DRY_RUN` plumbing to preview `pacman -S` without exec).

**Research flag:** Low — pattern is well-known (`man os-release(5)`); only nuance is quoting `ID_LIKE` glob for ShellCheck.

---

### Phase 3: Interactive Flow — Mode → Shell → TUI Checklist (Before Any Write)

**Build:** `prompt_mode()` + `prompt_shell()` (gum primary → plain `read` fallback, zsh default pre-select), `build_package_list()` (core ON, gui ON only if `mode==local`, `keyd` OFF), `tui_checklist()` fallback ladder `gum → whiptail --checklist 3>&1 1>&2 2>&3 → dialog → fzf --multi → read "1 3 5 or all"`, mode marker `mkdir -p ~/.config/dotfiles && echo "$MODE" > ~/.config/dotfiles/mode` + `DOTFILES_MODE` env, `--yes` bypass for CI, **ordering invariant: these prompts run before any `install_deps`/`stow`/**, optional `manifest.toml` declarative package list.

**Why third:** PROJECT.md specified `Mode → Shell only, then manual select/deselect override before any writes` — checklist is the shopping-cart confirmation that lets users override `keyd`/`hyprland` on server-with-GPU or deselect `wofi` on Ubuntu without editing code. Without it `local` vs `server` mismatch can't be recovered without code edit. TUI ladder is required because fresh Ubuntu server has `whiptail` but not `gum`, and Arch live ISO may have neither.

**Depends on:** Phase 2 (checklist needs `get_deps` output to build candidate list), Phase 1 skeleton (needs `confirm` helper + `DRY_RUN`).

**Research flag:** MEDIUM — `whiptail` fd swap `3>&1 1>&2 2>&3` + quoted tag parsing is a known foot-gun; `gum --selected` pre-check nuance; test on both Ubuntu (`whiptail 0.52.24`) and Arch (`gum`).

---

### Phase 4: Stow Orchestration Hardening + Shell Self-Install + Shims

**Build:** `stow_module()` + `run_stow()`/`run_unstow()` with `stow --dir="$SCRIPT_DIR" --restow/-D` + `--no --verbose` dry-run, real-file guard (`[[ -e ~/.config/starship.toml && ! -L … ]]` → WARNING + `read`/`gum confirm` before `rm -rf`), `keyd` privileged gate (preview `stow --no --verbose -t / keyd`, `diff -u` if conflict, typed `yes` before `--adopt`, plain `stow -t / keyd` otherwise, `keyd reload`/`systemctl reload keyd` with fallback), `setup_shell()` (ensure `zsh` binary, `ZINIT` clone commit-pinned, `stow --restow zsh`, `maybe_chsh` offer last never-auto), `apply_theme()` consistency check, thin shims `setup.zsh`/`setup.nu`/`teardown.*` → `exec bash setup.sh`.

**Why fourth:** Silent wrong symlink (`starship` folding, moved repo) is the most user-visible "success but broken" failure (CONCERNS.md fragile areas); keyd is the only privileged write and needs the diff gate; shell self-install fixes bootstrap paradox on minimal server images (`zsh` missing → stowed `.zshrc` dead). Shims preserve backwards compat for one release.

**Depends on:** Phase 3 checklist (stow operates on `selected` set), Phase 2 distro (pm family needed for shell install), Phase 1 skeleton (DRY_RUN preview for `keyd --adopt` without exec).

**Research flag:** MEDIUM — `stow --adopt` semantics + `-t /` privileged target are subtle; test `stow --no --verbose --adopt -t / keyd` preview vs real with a temp `/etc/keyd` overlay.

---

### Phase 5: Zsh Reliability + PATH + Hyprland Guard + Docs Flip

**Build:** `zsh/.zshrc` PATH dedup (`typeset -U path`), fix init ordering (keep p10k top + Zinit + fzf after Zinit before `bindkey`/`zoxide` last), fzf history conflict resolution (drop one of `joshskidmore/zsh-fzf-history-search` vs `zsh-autocomplete` `^R`/`^I`, normalize to `source <(fzf --zsh)` ≥0.48 fallback + `bindkey '^R' fzf-history-widget`), `zsh/.zprofile` Hyprland guard reading `~/.config/dotfiles/mode` + `command -v Hyprland/start-hyprland` + `|| true` (never kill login), `~/.zshrc.local` machine-local `[[ -f … ]] && source` tail guard + `.gitignore` entries + `zsh/.zshrc.local.example` template, docs flip (`README.md` table `Default: Zsh (Backup: Nushell)` + `bash setup.sh --mode local` primary, `nvim/README.md`, in-code comments).

**Why fifth:** These are all pure file edits (no installer logic beyond marker write) that become safe to land once `setup.sh` correctly deploys them — premature `.zprofile` guard or fzf ordering fix shipped without installer stow would be manually stowed and inconsistently tested. PATH dedup is a two-line win with visible `echo $PATH` effect. Docs flip must wait until `bash setup.sh` actually works or new users follow a broken primary path.

**Depends on:** Phase 4 stow (deploys the edited `zsh/.zshrc` + `zsh/.zprofile`); Phase 3 mode marker (Hyprland guard reads it).

**Research flag:** Low for Hyprland/PATH/docs; MEDIUM for fzf plugin ordering — verify via `bindkey '^R'; bindkey '^I'; zle -l | grep fzf` + manual `Ctrl+R` smoke on fresh `zsh -i`.

---

### Phase 6: Neovim Hardening — Mason Auto-Install + Which-Key + FZF/Make Warning + Lazy Pin

**Build:** `lua/plugins/which-key.lua` (v3 `preset=modern delay=200 spec`), `mason-tool-installer.nvim` add (`ensure_installed = require("lang").mason_packages, run_on_start=true, start_delay=3000`) OR enhance `utils/mason-install-all.lua` + `mason.lua build=":MasonInstallAll"`, `setup.sh` post-stow headless hook `nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"`, `lua/plugins/telescope.lua` WARN toast on `make` miss, `init.lua` official `vim.uv or vim.loop` bootstrap + `lazy-lock.json` HEAD verification, `lua/local.lua` (`pcall(require,"local")` + `.gitignore` + `local.lua.example`), `nvim --headless` self-test probes for this phase.

**Why sixth:** Editor lifecycle depends on `stow nvim` being correct (Phase 4) and `make`+`gcc` already in `common` (Phase 2). Installing 14 LSPs before distro/deps are stable would hammer Mason registry on a half-broken install. Which-key + Mason headless hook are low-risk polish once stow is proven. Lazy pin verification is defensive — only matters on fresh clones where `stable` tip has drifted from `85c7ff3` lock.

**Depends on:** Phase 4 stow (`nvim` package), Phase 2 deps (`make`/`gcc`), Phase 5 docs (`nvim/README.md` update).

**Research flag:** Low for which-key (copy verified snippet); MEDIUM for Mason headless sync (test `--headless -c "lua require('mason-tool-installer').check_install(false,true)"` timeout + `checkhealth` WARN parse).

---

### Phase 7: Self-Test / Health Gates Capstone

**Build:** `setup.sh --self-test` / `--verify` entry that runs every gate: `stow --no --verbose --restow nvim zsh starship` preview, `test -L ~/.config/nvim && readlink -f`, `~/.config/starship.toml` folding check, `zoxide --version && starship --version && fzf --version && stow --version ≥2.4.1`, `nvim --headless -c "checkhealth" -c "qa"` WARN/ERROR parse, `mason_packages` installed check, `zsh -i -c 'which zoxide; which starship; bindkey ^R'`, `PATH` dedup `tr : '\n' | sort | uniq -d` empty, TAP `ok/not ok` output, `--dry-run` preview of all writes—runnable without VM per PROJECT.md validation plan.

**Why last:** Self-test validates **everything** — Stow + shell self-install + Mason + PATH + prompt + fzf in one headless run. It is meaningless until every upstream phase exists. Building it last also lets it be the acceptance gate for VM testing (user runs `bash setup.sh --dry-run --self-test` before VM, then VM tests fresh install). Keep it CI-ready (TAP) for v2 `.github/workflows/` without adding CI orchestration this milestone (Out of Scope).

**Depends on:** All of Phase 1-6.

**Research flag:** MEDIUM — `nvim --headless -c "checkhealth"` output parsing is fragile across Neovim versions; `mason-tool-installer` sync timeout needs tuning; `zsh -i` non-interactive quirks on CI.

---

### Dependency Graph (build must respect)

```
Phase 1 (skeleton + --dry-run + ShellCheck)
  └─► Phase 2 (ID_LIKE + pm probe + get_deps per distro×mode + make/gcc + re-verify)
        ├─► Phase 3 (mode → shell → TUI checklist before any write, mode marker)
        │     └─► Phase 4 (stow orchestration + keyd diff gate + shell self-install + shims)
        │           ├─► Phase 5 (zsh init ordering + fzf fix + PATH dedup + Hyprland guard + docs)
        │           │     └─► Phase 6 (which-key + Mason auto-install/cleanup + init.lua pin + local.lua)
        │           │           └─► Phase 7 (self-test/vm-less health gates)
        │           └─► Phase 6 (parallel with Phase 5 after Phase 4 — editor vs shell are independent)
        └─► Phase 6 also needs make/gcc from Phase 2 (telescope-fzf-native cond)
```

- **Phase 5 and 6 are parallel after Phase 4** — Zsh fixes (`zsh/.zshrc` + `.zprofile`) and Neovim hardening (`which-key`, Mason hook) touch disjoint packages; schedule them concurrently to reduce calendar time.
- **Phase 3 cannot be deferred past Phase 4** — stow operating before checklist violates PROJECT.md safety constraint ("manual override before any writes") and would require re-stowing after checklist deselection.
- **Phase 7 must be strictly last** — Gates that validate Mason, `bindkey '^R'`, and stow folding are tautological if those features don't exist yet.

---

## Scaling Considerations — Dotfiles-Specific

*(See also Scaling Considerations table above — this section adds operational guidance.)*

- **Do not extract `lib/` before 10 packages.** The installer is a single-file Bash script by design — extracting `lib/distro.sh`, `lib/stow.sh`, `lib/tui.sh` adds sourcing complexity and `set -u` scoping gotchas for zero reuse. Extract only when `manifest.toml` parsing or TUI ladder exceeds ~400 lines in one section.
- **Do not add snapshot/rollback in this milestone.** CONCERNS.md notes missing snapshot before `teardown` — but `Type 'yes'` + `--dry-run` preview is sufficient safety for now. Automated `tar` + `setup.sh --restore` is a feature with I/O, disk, and UX questions (where to store snapshot? how long?) that competes with core reliability (PROJECT.md Anti-feature). Document `tar -czf ~/dotfiles-backup-$(date +%F).tar.gz ~/.config/nvim ~/.config/starship.toml ~/.zshrc /etc/keyd/default.conf` one-liner instead.
- **Do not migrate to `chezmoi`/`yadm` at 7 packages.** Theme duplication and machine-local `*.local` are solvable with a `THEME` token + `pcall(require,"local")` without re-laying out all packages into encrypted templates. Re-evaluate only if encrypted secrets become table stakes or package count exceeds 15.

---

## Anti-Patterns — Additional Dotfiles Traps

*(Primary anti-patterns are in Architectural Patterns → each pattern's pitfalls. This section adds two more.)*

### Using `source` Inside `set -u` Without Guarding Unbound Vars

**What people do:** `source /etc/os-release` then `if [[ "$ID_LIKE" == *"arch"* ]]` without `:-` fallback — minimal containers omit `ID_LIKE`.

**Why it's wrong:** `set -u` makes unbound `ID_LIKE` abort the installer before distro detection can fall back to `command -v pacman`. The crash looks like a distro error but is a shell error.

**Do this instead:** `ID="${ID:-}"; ID_LIKE="${ID_LIKE:-}"` after sourcing, or `[[ " ${ID_LIKE:-} " == *" arch "* ]]`.

---

### Re-Implementing GNU Stow with `ln -sf` Loops

**What people do:** Write a custom `"for f in nvim/.config/nvim/*; do ln -sf $PWD/$f ~/.config/nvim/; done"` loop to avoid `stow` dependency.

**Why it's wrong:** Reimplements directory folding, `--adopt`, `--dotfiles`, conflict detection, `.stowrc` ignores, and `--no` preview that Stow 2.4.1 fixed (ignore-list spaces, Perl 5.40 warning). Custom loops mishandle `starship/.config/starship.toml` folding and `keyd -t /` privileged target.

**Do this instead:** Depend on `stow >=2.4.1` and orchestrate via `stow --restow/-D/--no`. Leverage upstream fixes.

---

## Integration Points — Cross-Cutting Notes

- **Logging:** Bash installer `info`/`warn`/`die` + `gum style` / `printf` coloring; Neovim `vim.notify` with `nvim-notify`/`noice.nvim`; Starship `status`/`cmd_duration` in prompt. No file logs — self-test TAP is the audit trail.
- **Validation:** `stow --no --verbose` preview + `test -L`/`readlink -f` post-stow + `command -v` for deps + `vim.loop.fs_stat` for lazy path + `vim.fn.executable("make")==1` + `exists($file)` guards before sourcing. Missing `ID_LIKE` guarded via `:-`.
- **Authentication:** None for repo; `sudo stow -t / keyd` + `NOPASSWD: systemctl start|stop|reload keyd, keyd reload` least-privilege only. No `MISTRAL_API_KEY` handling beyond docs this milestone (PROJECT.md scope).
- **Error handling:** Fail-fast (`set -e`) + graceful WARN continue (`pcall(require,…)` with `vim.notify WARN`), collection-before-action (`missing` list before install), `DRY_RUN` suppresses writes, `teardown` requires `Type 'yes'` unless `--yes` (CI).

---

## Sources

- **Primary — Codebase maps (HIGH, 2026-09-10, local):** `ARCHITECTURE.md` (Stow monorepo + Aggregator + dual-shell, 6 data flows, 23-plugin disabled_plugins, 5 component responsibilities), `CONCERNS.md` (tech debt: mirrored bootstrappers/ID_LIKE/THEME/drift; bugs: zprofile Hyprland/fzf-native cond/keyd --adopt/init.lua pin; security: MISTRAL_API_KEY/keyd --adopt/lazy clone; perf: lazy fs_stat/starship scan_timeout/uv.nu 400 lines; fragile: settings.lua single toggle/init.lua sched/stow folding/shell ordering), `STRUCTURE.md` (7 packages + 14 langs + 21 plugins + lang file layout), `STACK.md` (languages: Lua/Nushell/Zsh/Bash/TOML/CSS, tool versions, plugin manager details), `CONVENTIONS.md` / `INTEGRATIONS.md` / `TESTING.md` (naming, integrations: lazy GitHub, Mason registry, Node/bun, uv, Mistral; testing: no runner, history smoke scripts only)
- **Primary — Live repo reads (HIGH, 2026-09-10, local execution):** `setup.zsh` (get_distro hard-coded arch|cachyos/ubuntu, get_deps common vs gui, verify/install interactive menu+select_skip, run_stow keyd --adopt), `setup.nu` (same mirrored in Nushell def main/get-distro/get-deps/verify-deps/install-deps/run-stow/stow-module with $dry_run guard), `zsh/.zshrc` (P10k instant prompt top, XDG, PATH repeats, Zinit bootstrap+379-line plugin+theme+annex, Oh-My-Zsh/PZT snippets, zsh-autosuggestions/fast-syntax-highlighting + conflicting joshskidmore fzf-history-search + marlonrichert zsh-autocomplete bound ^I), `zsh/.zprofile` (unconditional exec start-hyprland on tty1 without server guard), `nvim/.config/nvim/init.lua` (vim.loop.fs_stat lazy bootstrap with vim.loop only, no vim.v.shell_error guard, specs with lang.plugin_specs loop), `nvim/.config/nvim/lua/lang/init.lua` (deduplicate+pcall WARN+silent plugins.lua), `nvim/.config/nvim/lua/settings.lua` (colorscheme tokyodark + 14 langs), `nvim/.config/nvim/lua/plugins/mason.lua` (mason-org/mason.nvim build :MasonInstallAll), `nvim/.config/nvim/lua/utils/mason-install-all.lua` (mr.refresh, has_package, is_installed filter), `nvim/.config/nvim/lua/lang/python/python.lua` (lsp/mason/treesitter triple), `starship/.config/starship.toml` (scan_timeout=1000, palette catppuccin_latte), `alacritty/.config/alacritty/alacritty.toml` (import catppuccin-mocha), `teardown.zsh` (run_unstow with local/server switch, sudo stow -D -t / keyd, --dry-run)
- **Primary — PROJECT.md constraints (HIGH, 2026-09-10):** Unified Bash installer replaces 4 scripts (install+uninstall+--dry-run), mode→shell→checklist flow, shell self-install before stow, OS/distro ID_LIKE+pm probe fix, fix non-Nushell CONCERNS (distro/theme/Hyprland/fzf-native/keyd/init.lua/stow/PATH), Zsh fzf history + fzf present, Neovim Mason auto-install+cleanup + which-key + machine-local gitignored configs + self-test VM gate, docs updated to Zsh default, Bash preinstalled, Zsh default/Nushell backup scope, Arch/CachyOS/Ubuntu+derivatives, reversibility, safety (preview+confirm for privileged writes)
- **Secondary — STACK.md / FEATURES.md research caches (MEDIUM, 2026-09-10):** GNU Stow 2.4.1 manual + release notes (2.4.1 8 Sep 2024), systemd os-release(5) ID_LIKE + command -v probe pattern, lazy.nvim official bootstrap (vim.uv or vim.loop + git clone --filter=blob:none --branch=stable + vim.v.shell_error guard), mason-tool-installer ensure_installed/run_on_start/start_delay/check_install sync, which-key.nvim v3 spec/preset/triggers, gum 0.16.2 choose --no-limit/--header, fzf 0.48+ source <(fzf --zsh) vs 0.44 legacy, Powerlevel10k life-support (2024-05-23 #2690), Zinit vs Sheldon vs Antidote benchmark, whiptail 0.52.24 checklist fd swap 3>&1 1>&2 2>&3, zoxide 0.10.0 import/doctor, starship 1.24.2 + catppuccin palette, Bash 5.2 inherit_errexit/pipefail BCS strict, host probes (bash 5.2.21, stow 2.3.1→2.4.1 upgrade required, zsh 5.9, nvim 0.12.2, fzf 0.44.1 legacy, whiptail 0.52.24, starship 1.24.2, zoxide 0.9.3)
- **Secondary — Template contract (MEDIUM):** `/home/shoyeb/.config/opencode/gsd-core/templates/research-project/ARCHITECTURE.md` (System Overview box diagram, Component Responsibilities, Recommended Project Structure, Patterns, Data Flow, Scaling, Anti-Patterns, Integration Points)

---

*Architecture research for: Dotfiles — Unified Installer & Reliability Hardening*
*Researched: 2026-09-10*
