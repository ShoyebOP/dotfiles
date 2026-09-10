# Requirements: Dotfiles — Unified Installer & Reliability Hardening

**Defined:** 2026-09-10
**Core Value:** A fresh clone can go from `bash setup.sh` → working Zsh + Neovim + desktop environment on any supported distro/derivative with one interactive run, and cleanly reverse itself — no manual `stow` or `MasonInstallAll` required.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Installer — Unified Bash

- [x] **INST-01**: User can run `bash setup.sh` (canonical entry) to install entire environment via interactive prompts (mode `local|server` → shell `zsh` default/`nushell` backup) without needing Nushell or Zsh preinstalled
- [x] **INST-02**: User can preview every write with `--dry-run` (stow `--no --verbose`, package installs, `chsh`, `keyd` privileged) without modifying filesystem
- [ ] **INST-03**: User can cleanly uninstall/reverse with `bash setup.sh --uninstall` (or `--remove`) that runs `stow -D`, removes privileged keyd link via `stow -D -t /`, and cleans Mason packages when Neovim is deselected — with typed `yes` guard (bypassable via `--yes` for CI)
- [ ] **INST-04**: User can override the computed package list via interactive checklist after mode+shell, deselecting `keyd`/`hyprland`/`wofi` etc. before any write (gum primary → whiptail fallback → dialog → fzf → read)
- [x] **INST-05**: User can invoke `--help`, `--mode`, `--shell`, `--dry-run`, `--yes`, `--uninstall` flags with robust Bash parsing (`set -Eeuo pipefail`, `${1-}` guards) without crashes on `--help` or non-interactive TTY

### Distro & Dependencies

- [x] **DEPS-01**: User on derivative distro (Manjaro, EndeavourOS, Garuda, Mint, Pop!_OS) **and Termux** can install without hard error — installer probes `command -v pacman/apt/pkg` then `ID_LIKE` then `ID` per `os-release(5)` and maps to families `arch` vs `debian` vs `termux` (including `ID=termux` detection)
- [x] **DEPS-02**: User gets missing dependencies auto-installed and re-verified — `verify → install → re-verify` lock, `make`+`gcc`+`fzf`+`zsh` included in `common` so `telescope-fzf-native` and fzf history never silently fall back, partition `core` vs `gui` missing; **Termux uses separate package name list** (`pkg install` names vs `pacman`/`apt` names, no `sudo`, no `keyd` privileged) maintained as distinct `termux` family list
- [x] **DEPS-03**: User can re-run installer idempotently; second run with `stow --restow` and `pacman -S --needed`/`apt install -y`/`pkg install` is a safe no-op and handles missing `stow ≥2.4.1` upgrade

### Stow & Privileged Deployment

- [ ] **STOW-01**: User's Stow packages (nvim, zsh, starship→`~/.config/starship.toml` folding, alacritty, wofi, keyd) are correctly symlinked only from repo root (`stow --dir="$SCRIPT_DIR"`), with `stow --no --verbose` preview and `test -L` + `readlink -f` post-verify; invocation outside repo root aborts with clear message
- [ ] **STOW-02**: User's privileged `keyd` install is safe — installer previews `stow --no -t / keyd`, shows `diff` if `/etc/keyd/default.conf` exists and is not a symlink, requires explicit `gum confirm`/`Type 'yes'` before `sudo stow --adopt -t / keyd`, otherwise uses plain `sudo stow -t / keyd`; least-privilege sudoers documented
- [ ] **STOW-03**: User on `server` mode does not have login killed by Hyprland — `zsh/.zprofile` guarded by persisted `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true` before `exec`

### Shell — Zsh (Default)

- [ ] **SHEL-01**: User gets Zsh provisioned before stow — installer ensures `zsh` binary present, clones Zinit (commit-pinned) if missing, and offers `chsh -s $(which zsh)` only after explicit user confirmation (never auto)
- [ ] **SHEL-02**: User can fuzzy-search command history with `Ctrl+R` via `fzf` without conflicts — `fzf` in core deps, version-branch `source <(fzf --zsh)` ≥0.48 else legacy, plugin order fixed (`zsh-autocomplete` vs `zsh-fzf-history-search` double-bind resolved), `bindkey '^R' fzf-history-widget` normalized
- [ ] **SHEL-03**: User's `PATH` is deduped and stable — `typeset -U path` in `zsh/.zshrc`, no duplicates after reload (`echo $PATH | tr : '\n' | sort | uniq -d` empty)
- [ ] **SHEL-04**: User can add machine-local Zsh overrides via gitignored `~/.zshrc.local` (and `zsh/.zshrc.local`) auto-sourced at tail of `zsh/.zshrc` after `zoxide init` and before `p10k` apply — git stays clean on second machine

### Editor — Neovim

- [ ] **EDIT-01**: User's Neovim LSPs/formatters work after setup without manual `:MasonInstallAll` — installer triggers `nvim --headless -c "MasonInstallAll"` post-stow and `mason-tool-installer` deferred `ensure_installed = require("lang").mason_packages` (`run_on_start`/`start_delay`) ensures `pyright`/`ruff`/`typescript-language-server` etc. present; uninstall removes Mason artefacts when nvim deselected
- [ ] **EDIT-02**: User sees which-key popup on `<Space>` (leader) showing available combos with nested hints for subsequent keys (LazyVim-like) via `folke/which-key.nvim` v3 `preset=modern delay=200 spec`
- [ ] **EDIT-03**: User's `telescope-fzf-native` uses fast fzf sorter — `make`+`gcc` required, `cond` no longer silently falls back; `vim.notify WARN` if `executable("make")==0`
- [ ] **EDIT-04**: User can add machine-local Neovim overrides via gitignored `nvim/.config/nvim/lua/local.lua` (`pcall(require,"local")` at end of `init.lua`) without dirtying git

### Docs, Theme & Health

- [ ] **THEM-01**: User's theme is consistent — single `THEME` token (e.g., `theme.toml`/`THEME` env) and `setup.sh apply_theme()` validates `alacritty catppuccin-mocha` vs `starship catppuccin_latte` vs `nvim` mismatch warns instead of silent 4-file drift
- [ ] **DOCS-01**: User sees documentation flipped to Zsh default — `README.md` table shows `Default: Zsh | Backup: Nushell`, primary example is `bash setup.sh --mode local`, manual `stow --restow nvim zsh starship` vs `nvim nushell starship` sections, plus `nvim/README.md` and in-code comments updated; `AGENTS.md` guidance included
- [ ] **HLTH-01**: User or agent can validate without a VM via `--self-test`/`--verify` health gates — TAP output checks Stow symlinks (`readlink -f`), `z`/`zi`/`zoxide`, `starship`/`zoxide` hooks, `nvim --headless -c "checkhealth"` zero errors, Mason packages, `bindkey '^R'`, `PATH` dedup, `stow --no --verbose` folding

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Secrets & Hardening

- **SECR-01**: User can manage secrets via `sops`/`age`/`pass` with git-ignored `secrets.nu` and pre-commit `gitleaks` scanning — deferred per scope (docs only in v1)
- **SECR-02**: Historical `MISTRAL_API_KEY` committed secret is purged from git history via `filter-repo`/`BFG` with force-push coordination

### Automation & Scale

- **AUTO-01**: User's installer automatically snapshots current dotfiles before destructive `teardown` (`tar` + `setup.sh --restore`) — deferred, document manual `tar -czf ~/dotfiles-backup-$(date +%F).tar.gz …` one-liner in v1
- **AUTO-02**: CI matrix validates `local`/`server` × `Arch`/`Ubuntu` headlessly via `--self-test` in GitHub Actions — deferred after gates are solid
- **AUTO-03**: Number of Stow packages scales beyond 7 via declarative `manifest.toml` with `tag: core|gui|arch-only` generating stow commands — deferred

### Shell & Desktop Future

- **SHEL-05**: Nushell QoL re-parity (zoxide double-hook guard, `uv.nu` lazy-load, init ordering) if Nushell becomes default again — deferred per backup scope
- **DESK-01**: Starship `scan_timeout` tuning and `starship-minimal.toml` auto-switch for `server` mode
- **DESK-02**: Additional desktop environments / macOS / `brew` support

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Fix Nushell-specific tech debt (zoxide double-reg, uv.nu eager 400-line sourcing, env.nu secret, Nushell init ordering) | Nushell is backup only — PROJECT.md constraint; fixing reintroduces mirrored drift just unified to Bash |
| Re-implement GNU Stow logic as custom Bash `ln -sf` loop | Stow 2.4.1 already fixes folding/adopt bugs; custom engine mishandles `starship` folding and `keyd -t /` privilege |
| Blind `stow --adopt` or silent `chsh` without confirmation | Privileged and shell-changing operations must be explicit; auto would lock users out or pollute repo |
| Synchronous auto-install of all 14 LSPs on every Neovim startup | Startup would hang on network (~500MB parsers); deferred `mason-tool-installer` debounce is correct |
| Chezmoi/yadm templating or bare-git migration | Total rewrite at 7 packages; single `THEME` token + `*.local` solves 95% — defer until >15 packages |
| Elaborate TUI frameworks (Bubbletea/textual) | `gum`/`whiptail`/`dialog`/`fzf` ladder covers flow with preinstalled/static binaries; no build toolchain needed |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INST-01 | Phase 1 | Complete |
| INST-02 | Phase 1 | Complete |
| INST-03 | Phase 2 | Pending |
| INST-04 | Phase 1 | Pending |
| INST-05 | Phase 1 | Complete |
| DEPS-01 | Phase 1 | Complete |
| DEPS-02 | Phase 1 | Complete |
| DEPS-03 | Phase 1 | Complete |
| STOW-01 | Phase 1 | Pending |
| STOW-02 | Phase 2 | Pending |
| STOW-03 | Phase 2 | Pending |
| SHEL-01 | Phase 2 | Pending |
| SHEL-02 | Phase 3 | Pending |
| SHEL-03 | Phase 3 | Pending |
| SHEL-04 | Phase 3 | Pending |
| EDIT-01 | Phase 4 | Pending |
| EDIT-02 | Phase 4 | Pending |
| EDIT-03 | Phase 4 | Pending |
| EDIT-04 | Phase 3 | Pending |
| THEM-01 | Phase 3 | Pending |
| DOCS-01 | Phase 2 | Pending |
| HLTH-01 | Phase 4 | Pending |

**Coverage:**

- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-10*
*Last updated: 2026-09-10 after roadmap (4 phases, Termux families mapped)*
