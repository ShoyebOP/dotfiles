# Dotfiles — Unified Installer & Reliability Hardening

## What This Is

Efficiency-first Stow-based dotfiles for Arch/CachyOS/Ubuntu workstations and headless servers. Deploys Zsh (default), Neovim (lazy.nvim + 14 language modules), and desktop primitives (Alacritty, Starship, Wofi, Keyd) with a single installer; Nushell path is retained as a backup only. This milestone unifies install/remove into one Bash entry-point, fixes all non-Nushell bugs called out in `codebase/CONCERNS.md`, and adds QoL fixes (Zsh history/fzf, Neovim auto-LSP/which-key) plus gitignored machine-local overrides.

## Core Value

A fresh clone can go from `bash setup.sh` → working Zsh + Neovim + desktop environment on any supported distro/derivative with one interactive run, and cleanly reverse itself — no manual `stow` or `MasonInstallAll` required.

## Requirements

### Validated

- ✓ Stow-based deployment of 7 packages (`nvim`, `zsh`, `nushell`, `alacritty`, `starship`, `wofi`, `keyd`) — existing
- ✓ Dual-shell bootstrappers (`setup.nu`/`setup.zsh`, `teardown.nu`/`teardown.zsh`) with `--mode local|server`, `--dry-run`, `--stow-keyd` — existing
- ✓ Neovim with lazy.nvim, `settings.lua` language aggregator (14 langs), Mason + Treesitter, 21 plugins — existing
- ✓ Zsh with Zinit + Powerlevel10k, vi bindings, zoxide, Starship/Alacritty/Wofi theming — existing
- ✓ Keyd privileged install via `sudo stow --adopt -t / keyd` + `keyd reload`/`systemctl` — existing (with known risks)
- ✓ Unified Bash installer `bash setup.sh` with strict-mode guards, Termux-first family detection, per-family dep tables, verify→install→re-verify lock — Validated in Phase 1 (INST-01, INST-02, INST-05, DEPS-01, DEPS-02, DEPS-03)
- ✓ Interactive package checklist override before any write with 5-backend ladder, Termux disabled-row emulation, quarantine with manifest, folding-aware post-verify — Validated in Phase 1 (INST-04, STOW-01)

### Active

- [ ] Unified Bash installer (`setup.sh` or `install.sh`) replaces `setup.nu`/`setup.zsh`+`teardown.*` as the canonical entry point — handles **install and removal** (e.g., `--install`/`--uninstall` or `--remove` flag) with full automation and `--dry-run`
- [ ] Interactive flow: prompt **mode** (`local` full GUI vs `server` headless) → prompt **shell** (`zsh` default / `nushell` backup) → build package list → show **select/deselect package override** checklist (manual override before any writes) → execute
- [ ] Installer installs and configures the chosen shell itself before stowing configs (e.g., ensures `zsh` binary, sets up Zinit if missing, optionally offers to change default shell)
- [ ] OS/distro handling fixed: crashes eliminated; auto-install works end-to-end; normalize `ID`+`ID_LIKE` (covers `manjaro`, `endeavouros` etc.), detect package manager (`pacman` vs `apt`) rather than hard-coded allowlist, correct per-distro core/GUI dep lists, verify deps post-install and re-run `verify-deps`
- [ ] Fix all non-Nushell bugs/issues from `CONCERNS.md`: distro coupling, theme duplication centralization, `zsh/.zprofile` Hyprland `exec` guard for `server` mode, `telescope-fzf-native` `make` missing handling, `keyd --adopt` safety, `init.lua` lazy.nvim pin/verification, system package install locking, Stow symlink correctness, shell init ordering for Zsh, nvim single-toggle fragility, path dedup, lazy/Mason concerns
- [ ] Zsh QoL: working history search (`Ctrl+R` fzf), resolve `marlonrichert/zsh-autocomplete` vs `joshskidmore/zsh-fzf-history-search` conflicts and `bindkey` clashes, ensure fzf installs/works after setup (deferred polish: full history search tuning after core installer fixed)
- [ ] Neovim: dependencies/LSPs auto-install after setup without manual `:MasonInstallAll`; `python` (pyright/ruff/etc.) and other enabled languages work out-of-box; removal also cleans Mason/packages installed by nvim when uninstalling
- [ ] Neovim: which-key popup on `<Space>` (leader) showing available combos, with nested hints for subsequent keys (LazyVim-like)
- [ ] Machine-specific gitignored configs: e.g., `zsh/.zshrc.local` / `~/.zshrc.local` and `nvim/.config/nvim/lua/local.lua` (or `nvim/local.lua`) sourced if present, added to `.gitignore`, documented
- [ ] Installer self-test / dry-run: `--dry-run` previews all writes, and a self-check validates Stow symlinks, `z`/`zi`, `checkhealth` zero warnings, Mason packages, and starship/zoxide hooks — usable in VM
- [ ] Docs updated everywhere to reflect Zsh default, Nushell as backup, new Bash installer usage (`README.md`, `nvim/README.md`, in-code comments), and new project instruction file guidance
- [ ] Secrets hygiene: do not re-introduce hard-coded secrets; document external secret pattern (e.g., `~/.config/nushell/secrets.nu` ignored) if `MISTRAL_API_KEY` is referenced — but do not fix Nushell-only secret handling beyond documentation per scope

### Out of Scope

- Nushell-specific fixes — Nushell config is backup only; do not fix Nushell-only concerns: `zoxide` hook double-registration, `Nushell config sourcing 400-line uv.nu` eager loading, `env.nu` `MISTRAL_API_KEY` committed secret (beyond docs), Nushell init ordering, and other Nushell-isolated tech debt — why: user explicitly excluded Nushell scope
- New desktop environments or window managers beyond existing `hyprland/waybar/grim/slurp` local-mode set — why: not part of reliability milestone
- Cloud hosting / CI pipeline (GitHub Actions) beyond local self-test — why: can be follow-up after installer is solid
- Mobile or cross-platform (macOS) support — why: dotfiles targets Linux workstations/servers only

## Context

- **Repo:** `dotfiles` at `/home/shoyeb/dotfiles`, branch `main`, remote `origin`. Stow packages at repo root; deployment via GNU Stow to `$HOME`/`~/.config`/`/etc` (`keyd` privileged).
- **Prior state:** Dual bootstrappers (`setup.nu` + `setup.zsh` plus teardowns) with mirrored logic and drift (core modules differ: `[nvim,nushell,starship]` vs `[nvim,zsh]`). Manual `stow --restow` fallback documented. Issue: package installation crashes and never begins; derivatives (Manjaro, EndeavourOS) rejected; no manual package override stage.
- **Phase 1 complete (2026-09-11):** `setup.sh` 750 lines, `bash -n` clean, `--help`/`--help wins-anywhere`, Termux-first `detect_family`, per-family `get_deps`, `verify→install→re-verify` lock, `mode→shell→checklist` ladder, `quarantine_scan` `mv` to `.stow-conflicts/<ts>/MANIFEST`, `stow --dir/--target --restow` + `--no --verbose` preview, folding-aware `post_verify` via `readlink -f`, outside-root guard, keyd Phase-2 skip; `setup.nu`/`setup.zsh` deleted (no shims), `README.md` flipped, `.gitignore` quarantine entry; `bash setup.sh --mode server --shell zsh --dry-run` zero writes verified, derivative/Termux fixtures verified, 13/13 must-haves passed.
- **Codebase map (2026-09-10):** `ARCHITECTURE.md`, `STACK.md`, `STRUCTURE.md`, `CONCERNS.md` (tech debt, bugs, security, perf, fragile areas, scaling, missing features, test gaps), `CONVENTIONS.md`, `INTEGRATIONS.md`, `TESTING.md` available in `.planning/codebase/`.
- **Host tooling:** `stow`, `neovim`+`gcc`/`make`/`luarocks`/`tree-sitter-cli`, `starship`, `zoxide`, `uv`, `ripgrep`, `git`, `node`/`npm` + `bun` (Zsh path), `fzf`, `keyd`, `alacritty`/`wofi`/`waybar`/`grim`/`slurp`/`wl-copy` (local), `zinit`+`powerlevel10k`.
- **Current Zsh pain:** No working history fuzzy search; adding `fzf` conflicts with `zsh-autocomplete`/`zsh-fzf-history-search` and `bindkey` ordering (`^I` menu-select). `zsh/.zshrc` currently loads `zi light joshskidmore/zsh-fzf-history-search` then `zi light marlonrichert/zsh-autocomplete` with `^I` remapped.
- **Current Neovim pain:** LSPs (python `pyright`/`ruff` etc.) don't work after setup without manual `:MasonInstallAll`; no auto-install on startup; no which-key leader hints (LazyVim had this).
- **Validation plan:** User will test fresh install in a VM; installer must also provide `--dry-run` and self-test hooks so the agent can validate locally without a VM.

## Constraints

- **Shell default:** Zsh is default everywhere; Nushell is backup only — update all docs/comments to reflect this — why: user explicitly requested Zsh as canonical
- **Installer language:** Unified installer must be **Bash** — available by default — why: `bash` is preinstalled, avoids requiring Nushell/Zsh to bootstrap themselves
- **Scope filter:** Do not fix Nushell-only issues — why: Nushell is backup, avoid wasted work
- **OS support:** Must correctly handle Arch/CachyOS/Ubuntu **and derivatives** via `ID_LIKE` + package-manager presence (`pacman`/`apt`), not hard-coded `["arch","cachyos","ubuntu"]` — why: users on Manjaro/EndeavourOS hit hard errors
- **Machine-local:** Machine-specific overrides must be gitignored and auto-sourced if present — why: per-machine PATH/alias/theme differences must not dirty git
- **Reversibility:** Removal must clean Stow symlinks, Keyd config, and Mason/packages installed by nvim (when uninstalling) — why: user expects `teardown` parity in unified script
- **Safety:** No destructive writes without preview/confirmation; privileged `/etc/keyd` writes require explicit conflict check and user confirmation — why: `--adopt` currently risky

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Unified Bash `setup.sh` for install + remove (replaces 4 scripts) | Bash is preinstalled; single entry reduces drift vs mirrored `setup.nu`/`setup.zsh` | Phase 1: `setup.sh` (750 lines, bash 5.2.21, strict header, source-guard) replaces `setup.nu`/`setup.zsh` (deleted, no shims); `teardown.*` retained for Phase 2 |
| Flow: mode → shell (zsh default) → package checklist → execute | User specified `Mode → Shell only`, then manual select/deselect override | Phase 1: `mode (local/server)→shell (zsh/nushell)→7-package checklist` before any write, `gum→whiptail→dialog→fzf→read` ladder, `DRY_RUN` preview via `stow --no --verbose` |
| Installer installs shell binary itself before stowing | Ensures `zsh` exists even on minimal server images | Phase 1: dep tables include `zsh` in `common`; `make`+`gcc`+`fzf`+`zsh` ensure `telescope-fzf-native` never silently falls back; stow 2.4.1 auto-upgrade via `sort -V` |
| Distro detection via `ID_LIKE` + `pacman`/`apt` probing, with post-install verify | Fixes crashes and derivative rejections reported in CONCERNS | Phase 1: 4-tier `detect_family` (Termux env/pkg → manager → `ID_LIKE` tokens → `ID` → manager fallback), `OS_RELEASE_FILE` seam, `grep` parsing (no sourcing), fixtures `manjaro→arch`/`pop→debian`/`termux` verified; `verify→install→re-verify` with `Still missing` abort and idempotent `--needed`/`-y` |
| Nushell fixes excluded | Nushell is backup only per user | Honored — no `uv`/`zoxide` Nushell fixes |
| Zsh default in all docs | Correct historical Nushell-favored docs | Phase 1: `README.md` flipped to `bash setup.sh --mode/--shell` Zsh default/Nushell backup, `stow --dir="$SCRIPT_DIR"` one-liners, `nvim/README.md` audited (no dangling pointer) |
| Machine-local gitignored configs (`*.local` pattern) | Isolates per-host differences | Phase 3 (not yet) |
| Mason auto-install on setup + cleanup on uninstall | User: "everything should work after setup script is ran; removal should remove nvim packages too" | Phase 4 (not yet) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-11 after Phase 1 completion*
