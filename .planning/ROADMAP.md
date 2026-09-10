# Roadmap: Dotfiles — Unified Installer & Reliability Hardening

## Overview

From a broken set of mirrored Nushell/Zsh bootstrappers that crash on derivatives and require manual `stow` and `:MasonInstallAll`, to a single `bash setup.sh` that works on Arch/CachyOS, Ubuntu/Mint/Pop!_OS **and Termux**, previews before writing, lets users deselect `keyd`/`hyprland` via checklist, stows correctly, provisions Zsh, and leaves Neovim ready — then polishes shell history, PATH, and machine-local overrides, finishes editor autonomy with auto-LSP and which-key, and proves everything with a headless `--self-test`.

## Phases

- [x] **Phase 1: Universal Installer + Platform Foundations** - Bash entry + Termux-aware deps + correct stow; dry-run and checklist before any write (completed 2026-09-11)
- [ ] **Phase 2: Safe, Reversible & Server-Safe Deployment** - Uninstall/clean, privileged keyd gate, Hyprland guard, Zsh provisioned, docs flipped to Zsh default
- [ ] **Phase 3: Polished Shell, Theme & Local Overrides** - Ctrl+R fzf conflict-free, PATH dedup, machine-local gitignored, theme token consistent
- [ ] **Phase 4: Editor Autonomy & Verified Health** - Mason auto-install/cleanup, which-key popup, telescope fzf fast, headless health gates

## Phase Details

### Phase 1: Universal Installer + Platform Foundations

**Mode:** mvp
**Goal**: A fresh clone can run `bash setup.sh` on Arch, Debian-family, or Termux and get a correct deployment with no manual `stow` or preinstalled Zsh
**Depends on**: Nothing (first phase)
**Requirements**: INST-01, INST-02, INST-04, INST-05, DEPS-01, DEPS-02, DEPS-03, STOW-01
**Success Criteria** (what must be TRUE):

  1. User runs `bash setup.sh --help` (or with no TTY / missing arg) and sees usage without `unbound variable` or `pipefail` crash — `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards hold
  2. User on Manjaro, EndeavourOS, Garuda, Mint, or Pop!_OS installs without hard error — installer probes `command -v pacman` / `apt` first, then `ID_LIKE` (space-separated) then `ID`, maps to families `arch` vs `debian` vs `termux` (including `ID=termux`)
  3. User on Termux installs via `pkg install` from a distinct `termux` family list (no `sudo`, no `keyd` privileged stow) — `keyd`/`hyprland`/`wofi` automatically deselected for Termux, `nvim`/`zsh`/`starship` still link correctly
  4. User gets `verify → install → re-verify` lock — `verify_deps` lists partitioned `core_missing` vs `gui_missing`, installer runs `pacman -S --needed` / `apt install -y` / `pkg install`, includes `make`+`gcc`+`fzf`+`zsh` in `common` so `telescope-fzf-native` and fzf history never silently fall back, then re-verifies and aborts with `Still missing` if incomplete; idempotent second run is a safe no-op
  5. User sees interactive flow `mode (local/server) → shell (zsh default / nushell backup) → package checklist` **before any write** and can preview every write with `--dry-run` (`[DRY RUN] Would run:` + `stow --no --verbose`); invocation outside repo root (`[[ -f ./setup.sh ]]` missing) aborts with clear message; `stow --dir="$SCRIPT_DIR"` + `test -L` + `readlink -f` post-verify confirms `nvim`/`starship.toml` folding

**Plans**: 3/4 plans executed

Plans:

- [x] 01-03-PLAN.md
- [ ] 01-04-PLAN.md

**Wave 1**

- [x] 01-01-PLAN.md — Bash strict-mode entry, arg parsing, and Termux-aware distro/deps resolver with verify→install→re-verify lock

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — Stow orchestration core + dry-run + checklist ladder (gum → whiptail → dialog → fzf → read) before any write

### Phase 2: Safe, Reversible & Server-Safe Deployment

**Mode:** mvp
**Goal**: Deployment is safely previewable, overridable, and cleanly reversible; privileged and server-mode writes never surprise the user
**Depends on**: Phase 1
**Requirements**: INST-03, STOW-02, STOW-03, SHEL-01, DOCS-01
**Success Criteria** (what must be TRUE):

  1. User runs `bash setup.sh --uninstall` (or `--remove`) and must type `yes` (bypass with `--yes` for CI) before `stow -D` + `sudo stow -D -t / keyd` removes links and Mason artefacts are cleaned when Neovim was deselected — second uninstall and re-install are idempotent
  2. User who selects `keyd` sees `stow --no --verbose -t / keyd` preview and `diff -u` if `/etc/keyd/default.conf` exists and is not a symlink; installer requires `gum confirm` / `Type 'yes'` before `sudo stow --adopt -t / keyd`, otherwise uses plain `sudo stow -t / keyd` then `keyd reload`/`systemctl` with least-privilege handling
  3. User on `server` mode can log in on `tty1` without session death — `zsh/.zprofile` guarded by persisted `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true` before `exec`
  4. User gets Zsh provisioned before stow completes — installer ensures `zsh` binary present, clones Zinit commit-pinned if missing, stows `zsh`, and offers `chsh -s $(which zsh)` only after explicit confirmation (never auto)
  5. User reads `README.md`, `nvim/README.md`, and in-code comments and sees `Default: Zsh | Backup: Nushell`, primary example `bash setup.sh --mode local` / `--dry-run`, and correct `stow --restow nvim zsh starship` vs manual sections

**Plans**: TBD

Plans:

- [ ] 02-01: Reversible uninstall + privileged keyd safety gate + Hyprland server guard
- [ ] 02-02: Zsh self-provision (Zinit) + docs flipped to Zsh default

### Phase 3: Polished Shell, Theme & Local Overrides

**Mode:** mvp
**Goal**: Daily Zsh feels finished — history search just works, PATH is stable, machine-local tweaks stay gitignored, theme is consistent
**Depends on**: Phase 2
**Requirements**: SHEL-02, SHEL-03, SHEL-04, THEM-01, EDIT-04
**Success Criteria** (what must be TRUE):

  1. User presses `Ctrl+R` and gets fzf history search — `fzf` version-branched (`≥0.48` → `source <(fzf --zsh)` else legacy `/usr/share/fzf/key-bindings.zsh`), plugin order fixed (one history plugin policy resolves `marlonrichert/zsh-autocomplete` vs `joshskidmore/zsh-fzf-history-search`), `bindkey '^R' fzf-history-widget` normalized and `^I` not clobbered
  2. User reloads Zsh repeatedly and `echo $PATH | tr : '\n' | sort | uniq -d` is empty — `typeset -U path` in `zsh/.zshrc` dedupes PATH
  3. User creates `~/.zshrc.local` (and `zsh/.zshrc.local`) and sees it auto-sourced at tail of `zsh/.zshrc` after `zoxide init` and before `p10k` apply; git stays clean on second machine; `.gitignore` lists `*.local` with `*.example` templates
  4. User adds `nvim/.config/nvim/lua/local.lua` and it is loaded via `pcall(require,"local")` at end of `init.lua` without dirtying git; `.gitignore` + `local.lua.example` present
  5. User's theme is consistent — single `THEME` token and `setup.sh apply_theme()` warns on mismatch `alacritty catppuccin-mocha` vs `starship catppuccin_latte` vs `nvim` instead of silent 4-file drift

**Plans**: TBD
**UI hint**: yes

Plans:

- [ ] 03-01: Zsh fzf history conflict-free + PATH dedup + local overrides + theme token validation

### Phase 4: Editor Autonomy & Verified Health

**Mode:** mvp
**Goal**: Neovim works out-of-box with auto-installed LSPs, discoverable keys, fast telescope, and the whole system can be proven without a VM
**Depends on**: Phase 3
**Requirements**: EDIT-01, EDIT-02, EDIT-03, HLTH-01
**Success Criteria** (what must be TRUE):

  1. User opens Neovim after fresh install and `pyright`/`ruff`/`typescript-language-server` etc. work without manual `:MasonInstallAll` — installer triggered `nvim --headless -c "MasonInstallAll"` post-stow and `mason-tool-installer` deferred `ensure_installed = require("lang").mason_packages` (`run_on_start`/`start_delay`) ensures packages; uninstall removes Mason artefacts when nvim deselected
  2. User presses `<Space>` (leader) and sees which-key popup `folke/which-key.nvim` v3 `preset=modern delay=200 triggers={"<auto>"}` showing available combos with nested hints for subsequent keys (LazyVim-like)
  3. User's `telescope-fzf-native` uses fast fzf sorter — `make`+`gcc` already in `common` so `cond` never silently falls back; `vim.notify WARN` appears if `executable("make")==0`
  4. User or agent runs `bash setup.sh --self-test` / `--verify` headless and gets TAP `ok/not ok` for: `test -L` + `readlink -f` stow symlinks (`~/.config/nvim` + `starship.toml` folding), `z`/`zi`/`zoxide`/`starship`/`fzf`/`stow ≥2.4.1` versions, `nvim --headless -c "checkhealth"` zero errors, Mason packages list, `bindkey '^R'` and `zle -l | grep fzf`, `PATH` dedup, and `stow --no --verbose` preview including privileged `keyd`

**Plans**: TBD

Plans:

- [ ] 04-01: Mason auto-install/cleanup + which-key + telescope guard
- [ ] 04-02: Self-test / health gates TAP harness (headless, VM-less)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Universal Installer + Platform Foundations | 3/4 | In Progress|  |
| 2. Safe, Reversible & Server-Safe Deployment | 0/2 | Not started | - |
| 3. Polished Shell, Theme & Local Overrides | 0/1 | Not started | - |
| 4. Editor Autonomy & Verified Health | 0/2 | Not started | - |
