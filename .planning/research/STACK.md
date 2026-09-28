# Stack Research

**Domain:** Dotfiles bootstrappers & unified Bash installers (GNU Stow, Bash/Zsh/Nushell, Neovim, desktop primitives)
**Researched:** 2026-09-10
**Confidence:** HIGH (core installer/Stow/Neovim), MEDIUM (TUI selection tradeoffs)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **GNU Bash** | **5.2.x** (host: 5.2.21) ≥5.1 required, 5.2+ recommended | Unified installer `setup.sh` / `install.sh` canonical entry (install + `--uninstall`/`--remove` + `--dry-run`) | Only shell guaranteed on every Arch/CachyOS/Ubuntu minimal image; no bootstrap paradox (Nushell/Zsh must be installed first). Bash 5.1+ gives associative arrays, `[[` strict tests, `set -euo pipefail` + `shopt -s inherit_errexit` that older 4.x lacks. Empirically: current host runs 5.2.21 (Ubuntu 24.04 + CachyOS both ship 5.2). Bash 5.3 exists (2025-07) but not yet in Ubuntu repos — pinning to 5.2 maximizes compatibility without sacrificing strict-mode. |
| **GNU Stow** | **2.4.1** (8 Sep 2024) **required**; host currently 2.3.1 → **upgrade** | Dotfile deployment `stow --restow`, `stow -D`, `--adopt` (keyd `/etc`) and `stow --no --verbose` dry-run | 2.4.0 fixes `--dotfiles` for `dot-foo` directories + spurious `BUG in find_stowed_path? Absolute/relative mismatch` warning on unstow that 2.3.1 emits. 2.4.1 fixes ignore-list + `.stowrc` spaces + Perl 5.40 warning. This project uses `--restow`/`-D`/`--adopt -t /`; 2.4.x is the only stable that handles all three cleanly. Official manual & GNU FTP both list 2.4.1 as latest (verified via gnu.org/manual/stow.html). Lock `stow >=2.4.1`. |
| **Zsh** | **5.9** (Ubuntu 24.04) / 5.8+ | Default interactive shell; target of `chsh -s` | Zsh 5.9 is current LTS; older 5.8 misses `zsh-autosuggestions` 2024 fixes. Installer must install `zsh` binary itself before stowing (minimal server images lack it). Keep `setopt AUTO_CD`, `bindkey -v`, `edit-command-line` as existing. |
| **Neovim** | **≥0.10.0, recommended 0.11.x / 0.12.2** (host: v0.12.2) | Editor runtime; `lazy.nvim` + `nvim-treesitter main` + `blink.cmp` stack | lazy.nvim stable + treesitter `main` branch require NVIM 0.10+ (`vim.uv` API, `vim.lsp` 0.10+). Project already on 0.12.2; pin README to `neovim >=0.10` with `gcc`+`make`+`luarocks`+`tree-sitter-cli`+`wl-clipboard` as companion toolchain. |
| **lazy.nvim** | **stable branch, pin via `commit` or rely on `lazy-lock.json` 85c7ff3** | Neovim plugin manager, 44 plugins, `defaults.lazy=true`, `install.colorscheme` | Official bootstrap (context7 `/folke/lazy.nvim` HIGH confidence) is `vim.uv or vim.loop` + `git clone --filter=blob:none --branch=stable` with `vim.v.shell_error` guard + `vim.fn.getchar()`+`os.exit(1)`. Use exactly that snippet. Pin `lazy.nvim` itself via `commit` in spec or verify post-clone `HEAD` against `lazy-lock.json` (CONCERNS.md bootstrap drift). 23-plugin `disabled_plugins` list must be refreshed per Neovim release. |
| **Powerlevel10k** | **`romkatv/powerlevel10k` @ `master` latest commit; treat as frozen** | Zsh prompt theme (existing `zsh/.p10k.zsh` classic, 2-line) | Project already invested in `~/.p10k.zsh` (2026-04-26 wizard) + `catppuccin-powerlevel10k` annex. P10k is **life-support since 2024-05-23** (issue #2690, 2026-01-05 update: "Very limited support; no new features; most bugs unfixed; help ignored; no commit rights to others"). It will keep working if you already use it (do not rip out), but do NOT adopt for new installs. |
| **Starship** | **1.24.2** (host) → **1.24.x** cross-shell prompt | Nushell + Zsh unified prompt; `catppuccin_latte` palette | Actively maintained Rust binary (status 100% uptime Apr-Jun 2026). Replaces P10k long-term. Already deployed via `starship/.config/starship.toml` (`scan_timeout=1000`, `palette='catppuccin_latte'`). Init `eval "$(starship init zsh)"` / `starship init nu | save...`. Document both prompts co-existing during migration. |
| **Distro detection** | `/etc/os-release` + `command -v pacman`/`apt` | Correctly handle Arch/CachyOS/Ubuntu **and derivatives** (Manjaro, EndeavourOS, Mint, Pop!_OS) | Hard-coded `["arch","cachyos","ubuntu"]` is the #1 crash cause (CONCERNS.md). Correct pattern (systemd `os-release(5)` man, verified): `source /etc/os-release` → check `ID` + space-separated `ID_LIKE`; Bash idiom `[[ $ID == arch ]] \|\| [[ " $ID_LIKE " == *" arch "* ]] \|\| command -v pacman &>/dev/null` for Arch-family; `[[ $ID == ubuntu ]] \|\| [[ " $ID_LIKE " == *" debian "* ]] \|\| [[ " $ID_LIKE " == *" ubuntu "* ]] \|\| command -v apt &>/dev/null` for Debian-family. Priority: probe `command -v` first, fall back to `ID_LIKE`. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Zinit** (`zdharma-continuum/zinit`) | **commit-pinned clone** of `https://github.com/zdharma-continuum/zinit` (Turbo mode) | Zsh plugin manager (existing 391-line `zsh/.zshrc`) | **Keep for this milestone** — zero migration cost, Turbo yields 50-80% faster startup, already hosts 7 plugins + annexes. Pin clone via commit SHA (`git clone --depth 1` then `git checkout <sha>`) and `ZINIT[HOME_DIR]="$HOME/.local/share/zinit"` contract. |
| **mason.nvim** (`mason-org/mason.nvim`) | **`b03fb0f` (main) → v2.x registry** | LSP/formatter/linter installer (`mason-registry`) | Use for all 14 languages' `mason_packages`. Requires `mason-org` namespace since 2024 (migrated from `williamboman/mason.nvim`). Setup `ui.border="rounded"` + `require("utils.mason-install-all")`. |
| **mason-lspconfig.nvim** (`mason-org/mason-lspconfig.nvim`) | **latest main** | Bridge mason → nvim-lspconfig; `ensure_installed` | Use when you want `ensure_installed = { "pyright","lua_ls","ts_ls" }` to auto-install LSPs. Non-blocking, skips if headless (`:h mason-lspconfig-automatic-installation`). |
| **mason-tool-installer.nvim** (`WhoIsSethDaniel/mason-tool-installer.nvim`) | **v1.x latest** | **Recommended auto-install orchestrator** | **Use instead of hand-rolled `MasonInstallAll`** for greenfield auto-install. Config: `require("mason-tool-installer").setup{ ensure_installed = <list>, run_on_start=true, start_delay=3000, debounce_hours=24 }`. Handles versions, `auto_update`, `condition`, and `sync=true` for headless `--headless -c "lua require('mason-tool-installer').check_install(false,true)"`. Project can keep `utils/mason-install-all.lua` for parity but add `mason-tool-installer` as the canonical auto-install path. |
| **which-key.nvim** (`folke/which-key.nvim`) | **v3.x (latest, `preset=modern`)** | Leader popup `<Space>` with nested hints (LazyVim-like) | Add as `event="VeryLazy"` spec. v3 breaking change (2024) moves from `register()` to `spec` + `triggers = { "<auto>" }`. Use snippet from context7 (verified): `opts = { preset="modern", delay=200, spec={ { "<leader>f", group="find"... } } }`. Required for PROJECT.md "Neovim: which-key popup on `<Space>`". |
| **fzf** (`junegunn/fzf`) | **≥0.48.0 recommended (host 0.44.1 legacy; target 0.48+ / 0.51+)** | Zsh `Ctrl-R` history search + Bash TUI checklist fallback | 0.48+ introduces `source <(fzf --zsh)` / `eval "$(fzf --bash)"` unified integration (replaces `/usr/share/fzf/key-bindings.zsh`). Zoxide 0.9.8+ requires fzf ≥0.51.0 (`zi` interactive). On Ubuntu 24.04 (0.44.1) installer must `apt install fzf` + detect version `fzf --version` and warn if <0.48. |
| **charmbracelet/gum** | **0.16.2 (Alpine edge) → 0.17.0 latest; use ≥0.15.0** | **Primary TUI checklist** (`gum choose --no-limit --header`) for mode→shell→package select/deselect | Best DX for Bash: `gum choose --no-limit --header "Select packages"` returns newline-separated picks; `gum confirm`, `gum input`, `gum spin`, `gum style` also useful. Single static Go binary; `pacman -S gum` / `apt` via charm repo / `go install`. |
| **whiptail** (`newt 0.52.24`) | **0.52.24** (preinstalled on Ubuntu) | **Fallback TUI** when gum absent and non-gum terminal | `whiptail --checklist "Select:" 20 70 10 "nvim" "Editor" ON "zsh" "Shell" ON 3>&1 1>&2 2>&3` — note `3>&1 1>&2 2>&3` fd swap (common pitfall). Checklist returns quoted tags: `"nvim" "zsh"`. Preinstalled on Debian/Ubuntu, no Go runtime. |
| **dialog** | **1.3-20240101+** | whiptail superset alternative | Same as whiptail but supports `--buildlist`, `--treeview`, richer `--colors`. Use only if whiptail unavailable and gum absent; otherwise avoid (extra dep). |
| **zoxide** | **0.9.3 host → 0.9.8+ / 0.10.0 (2026-07-04) latest** | Directory jumping `z`/`zi`; hooks in both shells | `eval "$(zoxide init zsh)"` (Zsh) / `zoxide init nushell` (handled). 0.9.8 adds `--score`, `doctor` (diagnoses `PROMPT_COMMAND`/`ble.sh`), Tcsh support; 0.10.0 adds `import` (atuin), `cd --` style. Installer must `verify-deps` for `zoxide`. |
| **ripgrep** | **14.x / 15.x** (`rg --vimgrep`) | Telescope live_grep + `grepprg` | Keep `rg` as core dep (already in `get-deps` common). |
| **uv** | **0.8+ / 0.9+** (Python) | Python venv + completions (`uv generate-shell-completion zsh`) | Existing `nushell/scripts/uv.nu` 400-line externs; Zsh writes `~/.config/zsh/completions/_uv`. Installer must ensure `uv` then `mkdir -p ~/.config/zsh/completions`. |
| **keyd** | **2.4.3+ / latest** | System key remapping `keyd/etc/keyd/default.conf` | Privileged `sudo stow --adopt -t / keyd` → `keyd reload` + `systemctl`. Must guard `--adopt` (see Pitfalls). |
| **Tree-sitter CLI + C toolchain** | `gcc` `make` `luarocks` `tree-sitter-cli` | `telescope-fzf-native` `make` + Treesitter parsers | Already `cond = vim.fn.executable("make")==1` in `telescope.lua`; installer must add `make`/`gcc` to core deps for `--mode server` (currently missing → silent fzf fallback). |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **ShellCheck** `0.10.x` | Static analysis for Bash installer (catch `set -u` unbound, quoting, `${var:-}`) | Run `shellcheck -S warning setup.sh` in CI/self-test. Catches `MAYBE` installer bugs the BashFAQ warns about. Required dev dep; Arch `pacman -S shellcheck`, Ubuntu `apt install shellcheck`. |
| **shfmt** `3.10+` | Bash formatter (`--indent 4 --binary-next-line --case-indent`) | Enforce `nvim/.editorconfig` 4-space policy on shell scripts. `shfmt -i 4 -ci -w setup.sh`. |
| **Bats** (`bats-core` 1.11+) | Bash unit tests (optional for later phase) | If formal tests added: `tests/stow.bats` for `--dry-run` preview, distro mock via `ID=manjaro ID_LIKE=arch`. Keep co-located `test-*.nu` for now. |
| **stylua** `2.x` + **conform.nvim** | Lua formatting | Already via `conform.nvim` `format_on_save` (3000ms) — keep. |
| **nvim --headless** | Self-test gate | `nvim --headless -c "checkhealth" -c "qa"` + `MasonInstallAll` sync check + `Lazy check`. |

## Installation

```bash
# --- Core (Arch / CachyOS) ---
sudo pacman -S --needed \
  bash stow neovim git zoxide starship ripgrep nodejs npm \
  zsh fzf fzf-telescope-keybindings \
  gcc make luarocks tree-sitter-cli wl-clipboard \
  gum shellcheck shfmt

# Gum not in core repos? fallback
yay -S gum  # or: go install github.com/charmbracelet/gum@latest

# --- Core (Ubuntu 24.04 Noble) ---
sudo apt update && sudo apt install -y \
  bash stow neovim git zoxide ripgrep nodejs npm \
  zsh fzf \
  gcc make luarocks wl-clipboard \
  whiptail dialog shellcheck shfmt
# Starship (not in apt 24.04): curl -sS https://starship.rs/install.sh | sh
# Gum (charm repo): sudo mkdir -p /etc/apt/keyrings && curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg && echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list && sudo apt update && sudo apt install gum
# Zoxide 0.10 deb: cargo install zoxide --locked  # if apt lags at 0.9.3

# --- Zsh plugin manager (Zinit) ---
# Pinned clone (do NOT use floating latest in CI):
mkdir -p ~/.local/share/zinit
git clone https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git
# Optional pin:
# (cd ~/.local/share/zinit/zinit.git && git checkout <pinned-sha>)

# --- Neovim post-stow auto-install (headless, replaces manual :MasonInstallAll) ---
# Option A: keep existing utils/mason-install-all.lua
nvim --headless -c "MasonInstallAll" -c "qa"
# Option B (recommended for new installs): mason-tool-installer headless sync
nvim --headless -c "lua require('mason-tool-installer').check_install(false,true)" -c "qa"
# Verify:
nvim --headless -c "checkhealth" -c "qa"
stow --no --verbose --restow nvim zsh starship  # preview

# --- Verify fzf integration (≥0.48) ---
fzf --version  # want 0.48.0+
source <(fzf --zsh)   # zsh 0.48+ canonical
eval "$(fzf --bash)"  # bash 0.48+ canonical
# Legacy fallback if <0.48:
# source /usr/share/fzf/key-bindings.zsh && source /usr/share/fzf/completion.zsh
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **Zinit** (keep) | **Sheldon** (`rossmacarthur/sheldon` Rust, TOML `plugins.toml`) | Choose Sheldon when you want declarative `sheldon.lock` + `cargo`-like speed and minimal Zsh code injection. Benchmark shows `antibody/antidote/sheldon/zimfw` all excellent; Sheldon wins on reproducibility and lockfile. Migration cost: rewrite 391-line `zsh/.zshrc` plugin section. Defer unless Zinit maintenance worsens. |
| **Zinit** | **Antidote** (`mattmc3/antidote`, pure Zsh, 1.9.4-1 noble / 2.3.0 stonking) | Choose Antidote when you want pure-Zsh, fastest static `antidote bundle < .zsh_plugins.txt > .zsh_plugins.zsh` (concurrent, no annex DSL). Ideal for dotfiles that want `~/.zsh_plugins.txt` manifest. Tradeoff: no Turbo, annex ecosystem missing. |
| **Zinit** | **zplug** / **Antigen** (8k stars) | Antigen is simpler but slow, no Turbo, legacy `antigen bundle` dsl. Use only for minimal one-liner setups; not recommended for 7-plugin stack. |
| **Powerlevel10k (frozen)** | **Starship** (active, cross-shell) | Use Starship for any new machine or when P10k bug appears (no fix will ship). Starship is Rust, `starship.toml` shared Nushell+Zsh, supports `palette` theming. HyDE migrated (issue #491 2025-04-17 → closed 2025-05-05) citing "improved performance + multi-config". Keep P10k during milestone but document Starship as successor. |
| **Powerlevel10k** | **Pure** (minimal) | Use Pure when you want fastest prompt (benchmark: Pure < P10k < Starship) and minimal glyphs. Loses `vi_mode`, `todo`, `battery` segments used in `.p10k.zsh`. |
| **gum** (primary TUI) | **whiptail** (fallback) | Use whiptail when gum binary absent, on headless server, or minimal image where Go toolchain unwanted. Gum prettier (Lip Gloss), inline (no ncurses flicker), supports `--height`, `--header`, `--limit`; whiptail is ncurses, needs fd swap, limited theming. Installer should try `gum` → `whiptail --checklist` → `dialog --checklist` → plain `read` fallback ladder. |
| **gum choose/filter** | **fzf `--multi --prompt` checklist** | Use `printf "%s\n" "${pkgs[@]}" \| fzf --multi --prompt="Select packages: "` when fzf is present but gum is not desired. Works, but no `ON/OFF` pre-select semantics; gum's API is cleaner for checklist. |
| **mason-tool-installer `ensure_installed` + `run_on_start`** | **Hand-rolled `utils/mason-install-all.lua` `mr.refresh` loop** | Hand-rolled is already in repo and works; keep for parity. Use `mason-tool-installer` when you want debounce, version pinning, `condition` per-tool, and headless `sync=true`. Can co-exist: call `MasonInstallAll` user command from headless. |
| **lazy.nvim `stable` branch + lockfile** | `branch = false` / pinned tags per-plugin | Pin per-plugin (`tag="v0.6"`, `commit="a1b2c3d"`, `pin=true`, `version="^0.1"`) only when upstream introduces breaking change (e.g., `nvim-treesitter main` migration). Default to `stable` + `lazy-lock.json` + `:Lazy restore` for reproducibility. |
| **Bash `set -euo pipefail` + `shopt -s inherit_errexit`** | `set -eu` without `pipefail` / no strict | Without `pipefail`, `grep … | sort` masks failures; without `inherit_errexit`, `set -e` does not propagate into subshells. Use full strict preamble per Bash Coding Standard BCS. Guard `SIGPIPE` cases (`yes | head -1` RC 141) via `trap '' PIPE` or `|| true` where intentional. |
| **`/etc/os-release` ID + ID_LIKE + `command -v` probe** | Hard-coded `ID` allowlist `["arch","cachyos","ubuntu"]` (current) | Hard-coded is the bug. Use `ID_LIKE` (man7.org os-release(5) + systemd example: `if [ "${ID:-linux}" = "debian" ] || [ "${ID_LIKE#*debian*}" != "${ID_LIKE}" ]`). Probe `pacman`/`apt` first — most reliable on derivatives (Manjaro `ID=manjaro ID_LIKE=arch`, EndeavourOS `ID=endeavouros ID_LIKE=arch`, Mint `ID=linuxmint ID_LIKE=ubuntu`). |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Stow 2.3.1 or `brew` Stow 2.3.x** | Has `find_stowed_path` spurious warning on unstow + `--dotfiles` broken for `dot-foo` directories; 2.4.1 fixes both (NEWS 2024-04-08 / 2024-09-08). Silent break on `dot-config` style packages. | **Stow 2.4.1** (GNU FTP `stow-2.4.1.tar.gz`, MSYS2 2.4.1-1, Gentoo 2.4.1 EAPI 8). Verify `stow --version`. |
| **`sudo stow --adopt -t / keyd` without `--no` preview + confirmation** | `--adopt` **moves host files into repo** (`stow` manual warning: "intended to alter contents of your stow directory; if you do not want that, this option is not for you"). Silent data loss / repo pollution; CONCERNS.md flags code scanning miss. Sudoers `NOPASSWD: /usr/bin/systemctl *` widens privilege incorrectly. | `stow --no --verbose --adopt -t / keyd` preview first; then `confirm` (`gum confirm` / `read -p "Adopt /etc/keyd/default.conf? [y/N]"`); plain `sudo stow -t / keyd` after manual `diff`; least-privilege sudoers `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd, /usr/bin/systemctl reload keyd, /usr/bin/keyd reload` only. |
| **`init.lua` bootstrap `vim.loop.fs_stat` + `git clone --branch stable` without `vim.v.shell_error` check** | Every startup blocks on `vim.fn.system` git; MITM / flaky network hangs nvim for seconds; no pin verification; pre-lock check (CONCERNS.md bootstrap drift). | Official snippet (context7 HIGH): `if not (vim.uv or vim.loop).fs_stat(lazypath) then local out = vim.fn.system({...}) if vim.v.shell_error ~= 0 then vim.api.nvim_echo(...) vim.fn.getchar() os.exit(1) end end`. Use `vim.uv` (NVIM 0.10+) with `vim.loop` fallback. Optionally `commit=` pin for `folke/lazy.nvim` itself. |
| **`marlonrichert/zsh-autocomplete` + `joshskidmore/zsh-fzf-history-search` both `^R` + `^I` without ordering** | Both bind `^I` (`menu-select` vs autocomplete) and history `^R`; PROJECT.md calls this out as crash/conflict source. `marlonrichert/zsh-autocomplete` aggressively owns Tab, masks fzf completions. | **Choose one**: keep `fzf --zsh` native `Ctrl-R` (fzf wiki: `FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap"`) and disable `joshskidmore/zsh-fzf-history-search` OR keep `zsh-autocomplete` with `zstyle ':autocomplete:*' fzf-completion yes` and remove the history plugin. Installer must document conflict and test `bindkey \| grep -E '\^R|\^I'` after stow. |
| **`setup.nu` / `setup.zsh` dual bootstrappers** (mirrored logic, drift `core=[nvim,nushell,starship]` vs `[nvim,zsh]`) | Drift already visible in GUI lists; CONCERNS.md #1 tech debt; future dep change → inconsistent `--mode local` payload → missing configs on one shell path. | **Unified `setup.sh` Bash** canonical; `setup.nu`/`setup.zsh` become shims (`exec bash setup.sh "$@"`) or deleted. Extract declarative `manifest.toml`/`packages.json` for per-distro core/gui arrays consumed by Bash (or single source table). |
| **Hard-coded `ID` allowlist or `distro` case without `ID_LIKE`** | Rejects Manjaro/EndeavourOS/Arco/Garuda (all `ID_LIKE=arch`) and Mint/Pop!_OS (ID_LIKE=ubuntu/debian) with `Error: only supports Arch/CachyOS/Ubuntu` even though `pacman`/`apt` works. | `ID_LIKE` case-insensitive match + `command -v pacman/apt` probe (see Core Technologies row). |
| **`starship.toml` `scan_timeout=1000` on server mode** | Waits 1s per prompt scanning 12 language modules (`c/rust/golang/.../haskell`) each spawning subprocess; prompt lag on headless. | Set `scan_timeout=200` + `disabled=true` for unused languages in server variant (`starship-minimal.toml`), or ship per-mode toml: `local` = powerline rich, `server` = minimal (`format="$directory$git_branch$character"`). Run `starship timings` to audit. |
| **Committing `MISTRAL_API_KEY` / `sk-` / `*_API_KEY` in `env.nu` / `*.zsh` tracked files** | Git history retains secret forever; GitHub scanning flags; credential leaked to every clone (CONCERNS.md SECURITY). `.gitignore` currently misses `env.nu` assignment. | `.gitignore` + `secrets.nu` / `~/.config/nushell/secrets.nu` gitignored + placeholder `\$env.MISTRAL_API_KEY = \$env.MISTRAL_API_KEY? \| default ""`; document `sops`/`age`/`pass` alternative; add `gitleaks` pre-commit hook scanning `API_KEY|SECRET|TOKEN`. |
| **`which-key.nvim` v2 API (`register()`)** | v3 (2024) is breaking: `register()` removed, `spec` is canonical; using old API → no popup. LazyVim migrated to `spec` + `triggers`. | Use v3 spec from context7: `{ "folke/which-key.nvim", event="VeryLazy", opts={ preset="modern", spec={ {"<leader>f", group="find"} } } }`. |
| **`mason-registry` `williamboman` namespace** | Renamed to `mason-org/mason.nvim` + `mason-org/mason-registry` since 2024-05; old `williamboman/mason.nvim` redirects but stale docs cause `has_package` miss. | Use `mason-org/mason.nvim` spec string exactly (repo already migrated per lock). |
| **`eval "$(zoxide init zsh)"` at random position** | Init order fragile (CONCERNS.md): Nushell `zoxide.nu must be sourced last`, Zsh instant prompt must be top, `zoxide init` must be after `fpath` + before `bindkey -v` but after `ZINIT`. Wrong order → hook overwritten. | Keep explicit comments `# NOTE: zoxide.nu is sourced at the END` + `# p10k instant prompt should stay close to top`; add `zoxide --version` check; `test-zoxide.nu` hook count assertion. |
| **Bash `set -e` without `inherit_errexit` / without `PIPESTATUS` handling** | `set -e` silently ignores failures in `if`, `while`, `&&`/`||`, subshells per BashFAQ 105; `yes | head -1` RC 141 trips `pipefail` erroneously. Arch forum warns "Don't trust blogs… set -euo pipefail is not recommended". | Use full BCS preamble: `set -Eeuo pipefail; shopt -s inherit_errexit failglob extglob nullglob shift_verbose` and explicit `|| true` / `if ! cmd; then` for intentional non-zero; check `PIPESTATUS` where needed. Run ShellCheck to complement. |

## Stack Patterns by Variant

**If building unified Bash installer (canonical `setup.sh`):**
- Use preamble:
  ```bash
  #!/usr/bin/env bash
  set -Eeuo pipefail
  shopt -s inherit_errexit failglob extglob nullglob
  IFS=$'\n\t'
  readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  readonly SCRIPT_NAME="${0##*/}"
  ```
- Argument parsing: `while [[ ${#} -gt 0 ]]; do case "$1" in --mode) MODE="$2"; shift 2;; --dry-run) DRY_RUN=true; shift;; --stow-keyd) STOW_KEYD="$2"; shift 2;; --install|--uninstall|--remove) ACTION="$1"; shift;; -h|--help) usage; exit 0;; --) shift; break;; *) die "Unknown: $1";; esac; done` with `${1-}` guard for `set -u` (gist pattern).
- Flow: `get_distro` → `get_deps distro mode` → `verify_deps deps` → `prompt_mode` (if not provided) → `prompt_shell` (`zsh` default / `nushell` backup) → `build_package_list` (core+gui+shell) → **TUI checklist override** (manual select/deselect before any write) → `install-deps` with `pacman -S --needed` / `apt install -y` + post-install `verify-deps` re-run → `run_stow selected_mode dry_run stow_keyd` → self-test (`stow --no --verbose`, `checkhealth`, `mason`, `zoxide`).
- Provide `die()`, `info()`, `warn()`, `confirm()` helpers with `gum style` / fallback `printf` coloring.
- Because PROJECT.md requires `--dry-run` preview of all writes + privileged `/etc/keyd` confirmation.

**If selecting TUI for package checklist (mode→shell→package select/deselect):**
- **Primary: `gum choose --no-limit --header "Select packages (Space to toggle, Enter to confirm)" --height 12 nvim zsh nushell starship alacritty wofi keyd`** → captures `mapfile -t SELECTED < <(printf "%s\n" "${ALL_PKGS[@]}" | gum choose --no-limit --header "...")`. Use `--selected` to pre-check `ON` items per mode.
- **Fallback 1: `whiptail --checklist`** (present on Ubuntu by default): `whiptail --title "Packages" --checklist "Select (SPACE to toggle):" 20 78 10 "nvim" "Neovim + Mason" ON "zsh" "Zsh + Zinit" ON "nushell" "Nushell (backup)" OFF 3>&1 1>&2 2>&3` — parse quoted output `tr -d '"' | xargs -n1`.
- **Fallback 2: `dialog --checklist`** superset if whiptail absent.
- **Fallback 3: `fzf --multi`** `printf "%s\n" "${ALL_PKGS[@]}" | fzf --multi --prompt="Select packages> " --header="TAB to select, ENTER to confirm"` — works when neither gum/whiptail installed.
- **Fallback 4: plain `read`** numbered list + `read -p "Enter numbers (e.g. 1 3 5 or 'all')"` for headless/CI where no TUI available.
- Because `setup.sh` must run on fresh Ubuntu server (no gum) and Arch live ISO; graceful degradation is required.

**If fixing non-Nushell CONCERNS (project scope filter):**
- **Distro:** Replace `get_distro`/`get-distro` hard-coded `if distro not-in ["arch","cachyos","ubuntu"]` with `source /etc/os-release` + `ID_LIKE` regex + `command -v pacman/apt` probe; see `man os-release(5)` example `if [ "$ID" = "debian" ] || [ "${ID_LIKE#*debian*}" != "$ID_LIKE" ]`.
- **Theme duplication:** Centralize `theme.toml` or `THEME=mocha` env + `sed` template; or at minimum symlink `catppuccin-mocha.toml` as single source imported by `alacritty.toml` (`import = ["~/.config/alacritty/catppuccin-mocha.toml"]`), `starship.toml` (`palette`), `nvim/colorschemes/catppuccin.lua`, `nushell/scripts/catppuccin.nu`.
- **`zsh/.zprofile` Hyprland guard:** Add `if [[ "$SETUP_MODE" == "server" ]]` or `[[ -f /usr/bin/Hyprland ]]` + `[[ -z $DISPLAY && $(tty) == /dev/tty1 && $MODE != server ]]` guard so server stow does not `exec start-hyprland` and kill login.
- **`telescope-fzf-native` `make`:** Add `make`+`gcc` to core deps (already in `nvim/README.md` but missing from `setup.*` `common` on Ubuntu) and `cond = vim.fn.executable("make")==1` warning toast instead of silent fallback.
- **`keyd --adopt` safety:** See What NOT to Use; add conflict check `if [[ -f /etc/keyd/default.conf && ! -L /etc/keyd/default.conf ]]; then gum confirm "Overwrite existing /etc/keyd/default.conf?" || exit 1; fi` before `sudo stow --adopt`.
- **`init.lua` lazy pinning:** Apply official `vim.uv` bootstrap + optionally `commit` pin; document `lazy-lock.json` `85c7ff3` vs `stable` tip drift verification `git -C "$lazypath" rev-parse HEAD`.
- **Stow symlink correctness:** Always `stow --no --verbose` preview; verify `test -L ~/.config/nvim && readlink ~/.config/nvim` post-stow; ensure repo root is stow directory (`stow --dir="$SCRIPT_DIR"`).
- **Path dedup:** `typeset -U path PATH` in Zsh or `printf "%s\n" "$PATH" | awk -v RS=: '!seen[$0]++' | paste -sd:` in Bash to deduplicate `~/.local/bin:~/.bun/bin:~/.cargo/bin` expansions.

**If Zsh QoL (history fzf + autocomplete conflict):**
- Install `fzf >=0.48` via `setup.sh`; source `source <(fzf --zsh)` **after** `bindkey -v` and `ZINIT` but before `bindkey '^R'` overrides.
- **Decide:** Drop `joshskidmore/zsh-fzf-history-search` (one-line plugin, maintenance low) and use native `fzf --zsh` `Ctrl-R` (supports `FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview,ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"`), or keep `marlonrichert/zsh-autocomplete` with `zstyle ':autocomplete:tab:*' fzf yes`. Never load both history plugins.
- Test post-stow: `bindkey '^R'`, `bindkey '^I'`, `zle -l | grep fzf`, `history | fzf --tac`.

**If Neovim QoL (which-key + Mason auto-install):**
- Add `folke/which-key.nvim` spec `event="VeryLazy"` `preset="modern"` `delay=200` as above; no extra keymaps needed — it auto-shows on `<Space>` (`vim.g.mapleader=" "`).
- Mason auto-install: either keep `utils/mason-install-all.lua` (`:MasonInstallAll` + `build = ":MasonInstallAll"` in `mason.lua`) or add `mason-tool-installer` with `ensure_installed = require("lang").mason_packages` + `run_on_start=true` + headless `check_install(false,true)` in `setup.sh` post-stow (`nvim --headless -c "MasonInstallAll" -c "qa"`). Removal (`--uninstall`) must also `rm -rf ~/.local/share/nvim/mason` / `stdpath("data").."/mason"` when `nvim` package unstowed.
- Because PROJECT.md requires "python (pyright/ruff/etc.) works out-of-box without manual `:MasonInstallAll`".

**If machine-local gitignored configs:**
- Add to `.gitignore`:
  ```
  zsh/.zshrc.local
  zsh/.zprofile.local
  nvim/.config/nvim/lua/local.lua
  nushell/.config/nushell/secrets.nu
  .env.local
  ```
- Source guards:
  ```bash
  # zsh/.zshrc tail
  [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
  [[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
  # alternatively stow package: zsh/.zshrc.local.example → ~/.zshrc.local
  ```
  ```lua
  -- nvim init.lua after require("base")
  pcall(require, "local")
  -- or lua/local.lua.example
  ```
- Document pattern in `README.md` + `nvim/README.md`; ensures per-machine `PATH`/`alias`/`theme` does not dirty git.

**If `--dry-run` + self-test VM gate (PROJECT.md validation plan):**
- Installer `DRY_RUN=true` short-circuits before `pacman -S`/`apt install`/`stow`/`chsh`/`systemctl`; prints `[DRY RUN] Would run: ...` + `stow --no --verbose` output.
- Self-test entry `setup.sh --self-test` runs:
  ```bash
  stow --no --verbose --restow nvim zsh starship
  test -L ~/.config/nvim && echo "PASS stow nvim"
  zoxide --version && starship --version && fzf --version
  nvim --headless -c "checkhealth" -c "qa" 2>&1 | grep -q "ERROR" && exit 1
  nvim --headless -c "lua require('mason-tool-installer').check_install(false,true)" -c "qa"
  # starship/zoxide hooks: zsh -ic 'which starship; which zoxide; echo $PROMPT'
  ```

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| **Bash 5.2.x** | Stow 2.4.1, zsh 5.9, fzf 0.44-0.65, gum 0.15+, whiptail 0.52 | Bash 5.1+ required for associative arrays (`declare -A`) and `[[ -v var ]]`. 5.2 adds `patsub_replacement` fix for `ID_LIKE` glob. |
| **Stow 2.4.1** | Perl 5.36-5.40, bash 5.x | 2.4.1 avoids Perl 5.40 spurious warning that 2.4.0 emits. `--dotfiles` fix needs `dot-` prefix files; not needed for this repo (no `dot-` prefix) but included for completeness. |
| **Neovim 0.10+** | lazy.nvim stable, mason.nvim 2.x, which-key 3.x, blink.cmp main, nvim-treesitter main | `vim.uv` replaces `vim.loop` in 0.10; use `vim.uv or vim.loop` for compat. Treesitter `main` branch (4916d65) requires NVIM 0.10+; older 0.9 would need `master`. |
| **lazy.nvim stable @ 85c7ff3** | Neovim 0.10+, lazy-lock.json 44 plugins | Keep `lazy-lock.json` committed; `:Lazy restore` syncs across machines. `pin=true` overrides lock for specific plugins (use for `telescope-fzf-native` `make` edge). |
| **which-key 3.x** | Neovim 0.9+ (0.10 recommended), lazy.nvim | v3 `spec` + `preset` replaces v2 `register()`; not back-compat. Tested with `preset="modern"` + `delay=200`. |
| **mason.nvim 2.x (mason-org)** | mason-lspconfig, mason-tool-installer 1.x, nvim-lspconfig `master` 4b7fbaa | Old `williamboman/mason.nvim` path still redirects but use `mason-org/*`. `ensure_installed` async; for headless CI pass `sync=true`. |
| **fzf 0.48+** | zsh 5.9, zoxide 0.9.8+ (requires 0.51+), bash 5.2 | `source <(fzf --zsh)` only ≥0.48; Ubuntu 24.04 ships 0.44 → needs upgrade path (`apt` + `go install` fallback). |
| **gum 0.16+** | fzf 0.48+, zsh 5.9, bash 5.2, bubbletea 1.3.6, lipgloss 1.1 | Binary 14.8MiB (Alpine edge); `GUM_CHOOSE_*` envs control height/cursor. `--no-limit` available since 0.13. |
| **zoxide 0.9.3 host / 0.10.0 latest** | fzf 0.51+ (for `zi`), bash 4.4+, zsh 5.8+, nushell 0.94-0.106 | 0.9.8 `doctor` diagnoses `PROMPT_COMMAND`/`ble.sh`; 0.10 `import` auto-detects `atuin`. Nushell 0.110 host → 0.10 `nushell 0.106+` ok. |
| **Starship 1.24.2** | zsh 5.9, nushell 0.110, bash 5.2, catppuccin palette | `starship init zsh` / `starship init nu` divergent; `STARSHIP_CONFIG=~/.config/starship.toml` must agree. `scan_timeout` 30ms default but project uses 1000 → consider per-mode. |
| **Powerlevel10k (frozen)** | zsh 5.9, zinit Turbo, JetBrainsMono Nerd Font 12.0 | No version bump expected; keep last commit before 2024-05 life-support. Catppuccin `classic mocha` annex compatible. |
| **whiptail 0.52.24** | bash 5.2, dialog 1.3 | `whiptail --checklist` fd `3>&1 1>&2 2>&3` required; `--separate-output` variant on some builds. Test on Ubuntu minimal. |
| **uv 0.8+** | Python 3.10+, zsh completions, venv-selector.nvim bcb2f58 | `uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv` needs `fpath` + `autoload -Uz _uv`. |

## Sources

- **GNU Stow 2.4.1 manual** — https://www.gnu.org/software/stow/manual/stow.html — Stow 2.4.1 (8 Sep 2024) symlink farm manager, `--dotfiles`, `--adopt` warning, release NEWS — HIGH (official)
- **GNU Stow release notes** — https://lists.gnu.org/archive/html/info-gnu/2024-04/msg00000.html (2.4.0) + https://lists.gnu.org/archive/html/info-gnu/2024-09/msg00003.html (2.4.1) — `--dotfiles` directory fix, spurious warning fix — HIGH (official)
- **man7.org os-release(5)** + **systemd os-release example** — `ID_LIKE` space-separated, `[ "${ID_LIKE#*debian*}" != "$ID_LIKE" ]` probe, `source /etc/os-release` pattern — HIGH (official)
- **Context7 /folke/lazy.nvim** — bootstrap `vim.uv or vim.loop` + `git clone --filter=blob:none --branch=stable` + `vim.v.shell_error` guard + versioning `pin/tag/commit/version` + lockfile — MEDIUM (verified)
- **Context7 /mason-org/mason.nvim** + **/mason-org/mason-lspconfig.nvim** + **/whoissethdaniel/mason-tool-installer.nvim** — `Registry.refresh`/`pkg:install`/`is_installed`, `ensure_installed`, `run_on_start`/`start_delay`/`check_install(false,true)` sync — MEDIUM (verified)
- **Context7 /folke/which-key.nvim v3** — `preset="modern"`, `spec`/`triggers = {"<auto>"}`, `delay=200`, `event="VeryLazy"` — MEDIUM (verified)
- **Context7 /charmbracelet/gum** — `gum choose --no-limit --header`, `gum filter --limit/--no-limit`, `gum confirm` exit codes, `GUM_CHOOSE_*` envs — MEDIUM (verified)
- **Context7 /websites/starship_rs** + **/junegunn/fzf** — `starship init zsh`/`nu` cmds, `FZF_CTRL_R_COMMAND=`, `FZF_CTRL_R_OPTS`, `source <(fzf --zsh)` 0.48+ — MEDIUM (verified)
- **fzf CHANGELOG + ArchWiki fzf** — 0.48 `eval "$(fzf --bash)"`/`source <(fzf --zsh)`, 0.51 `fzf --zsh` history widget, key bindings — LOW→MEDIUM (web, cross-checked)
- **zoxide CHANGELOG + Docs.rs 0.9.0-0.10.0** — 0.9.8 `doctor`/`--score`/Tcsh, 0.10.0 `import` (atuin), fzf 0.51 minimum — LOW→MEDIUM (web, cross-checked)
- **Powerlevel10k life-support** — Issue #2690 (2024-05-26, updated 2026-01-05), HN 2024-05-23, Hash Milhan 2025-06-25 "Life Support. Hello Starship!", HyDE #491 (2025-04-17) migration to Starship — MEDIUM (verified via primary issue)
- **Zinit vs Sheldon vs Antidote benchmark** — `rossmacarthur/zsh-plugin-manager-benchmark` + `zdharma-continuum/zinit` README (Turbo 50-80%) + `antidote.sh` install (static `antidote bundle > .zsh_plugins.zsh`) — LOW→MEDIUM (web, cross-checked)
- **Shell TUI cheat-sheet** — `cdocsa/cheat-sheets` dialog/whiptail/gum comparison + `whiptail --checklist 3>&1 1>&2 2>&3` fd swap — LOW (secondary but cross-checked with man pages)
- **Bash strict mode** — `linuxize.com` 2026-04-20 + `Bash Coding Standard` `set -o pipefail` rightmost non-zero + Arch BBS BashFAQ 105 dissent — LOW→MEDIUM (web, debated; mitigated with ShellCheck recommendation)
- **Host probes (ground truth)** — `bash 5.2.21`, `stow 2.3.1`, `zsh 5.9`, `nvim v0.12.2`, `fzf 0.44.1`, `whiptail 0.52.24`, `starship 1.24.2`, `zoxide 0.9.3`, `gum not found`, `/etc/os-release ID=ubuntu ID_LIKE=debian` — HIGH (local execution)

---
*Stack research for: Dotfiles — Unified Installer & Reliability Hardening*
*Researched: 2026-09-10*
