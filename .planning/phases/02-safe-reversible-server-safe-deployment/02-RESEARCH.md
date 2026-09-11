# Phase 02: Safe, Reversible & Server-Safe Deployment - Research

**Researched:** 2026-09-11
**Domain:** Bash uninstall reversibility, privileged GNU Stow deployment to `/etc`, Hyprland `zsh/.zprofile` server guard, Zsh/Zinit self-provision, `chsh` offers, docs canonical flip
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

> **Source:** `.planning/phases/02-safe-reversible-server-safe-deployment/02-CONTEXT.md` — copied verbatim. Planner MUST honor these; do not explore alternatives to locked decisions.

### Locked Decisions

#### Uninstall & cleanup scope (INST-03)

- **D-01:** `bash setup.sh --uninstall` / `--remove` does `stow -D <pkg>` for selected pkgs + `sudo stow -D -t / keyd` when keyd was selected; never `rm -rf` repo package directories. — **Reversibility:** reversible — repo stays intact (recoverable via `stow --restow`); mirrors Phase 1 D-03 no-shims via git history
- **D-02:** When `nvim` is not selected at uninstall time (previously stowed but now deselected, or full uninstall), remove Mason artefacts `~/.local/share/nvim/mason` (and related state/cache if present). Otherwise leave Mason intact — matches SUCCESS #1 "Mason artefacts are cleaned when Neovim was deselected"
- **D-03:** Typed guard is exact case-sensitive `Type 'yes' to confirm:`; `--yes` bypasses the prompt for CI only for uninstall/privileged flows; `--dry-run --uninstall` prints `[DRY RUN] Would run: stow -D ...` and `sudo stow -D -t / --no --verbose` without touching filesystem — consistent with Phase 1 D-08 `--help` wins and `DRY_RUN` early-return before every mutation
- **D-04:** Second `bash setup.sh --uninstall` and re-install after uninstall are idempotent safe no-ops (check `test -L` before `stow -D`; skip missing targets with warning, not error). `.stow-conflicts/<timestamp>/` quarantine is never auto-deleted on uninstall — remains as safety backup (Phase 1 D-13/D-14). No persisted mode file exists after Hyprland decision (D-10/D-11), so uninstall has no `~/.config/dotfiles/mode` to clear; if a legacy file exists from a pre-Phase-2 install, remove it on full uninstall with no error if absent
- **D-05:** Uninstall must offer to remove **all** system packages that `setup.sh` installed during the verify→install→re-verify lock — not only stow-config-related pkgs. User verbatim twice: "it should offer to remove all the packages not only stow config related ones, all the packages that were installed with setup". Implementation: list the `SELECTED_DEPS` / toolchain packages that were installed via `pacman -S --needed` / `apt install -y` / `pkg install` and offer `pacman -Rns` / `apt remove -y` / `pkg uninstall` only after the same `yes` guard (gum confirm → `Type 'yes'` fallback), with `--dry-run` preview `[DRY RUN] Would run: sudo pacman -Rns ...`. Never auto-remove without explicit confirmation

#### Privileged keyd safety gate (STOW-02)

- **D-06:** Every `keyd` install shows preview before any `/etc` write: run `stow --no --verbose -t / keyd` (or `stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd`) and if `/etc/keyd/default.conf` exists and is a regular file (not a symlink), also print `diff -u /etc/keyd/default.conf $SCRIPT_DIR/keyd/etc/keyd/default.conf`. Shown in both normal runs (before the confirmation) and as `[DRY RUN] Would run: sudo stow ...` + diff preview when `--dry-run`
- **D-07:** Only use `sudo stow --adopt -t / keyd` when a conflict file exists as a regular file AND the user explicitly confirms the privileged adopt path; otherwise use plain `sudo stow -t / keyd`. Never force `--adopt` without confirmation; never silently move host file into repo — matches CONCERNS.md `keyd --adopt` risk (D-13 quarantine elsewhere is `mv` only, never `--adopt` unless confirmed)
- **D-08:** Confirmation ladder for privileged `/etc` writes is `gum confirm` primary → `Type 'yes'` fallback (case-sensitive `Type 'yes' to confirm privileged keyd install:`), same ladder as uninstall guard. `--yes` bypasses the prompt for CI (consistent with D-03). On plain `read` fallback, do not accept `y/n`
- **D-09:** After successful privileged stow, run `sudo keyd reload` (or `sudo systemctl reload keyd` / `restart keyd` with `|| true` so failure never kills session) and document least-privilege sudoers in `README.md` (e.g., `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload keyd, /usr/bin/keyd reload`), not blanket `systemctl start|stop`. Dry-run prints `[DRY RUN] Would run: sudo keyd reload`

#### Hyprland server guard (STOW-03) — removed

- **D-10:** Remove the `exec start-hyprland` block from `zsh/.zprofile` entirely — no `tty1` auto-start. Current `zsh/.zprofile:2-4` `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` is deleted. User verbatim: "no need for that remove that i no longer use tty login so that is redundent" — session death on server-mode tty1 (CONCERNS.md) is fixed by deletion, not by guard. — **Reversibility:** reversible — block recoverable via git history; no migration needed
- **D-11:** No persisted mode file is written or read. Earlier SUCCESS criteria required `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true` before `exec`; with the `exec` removed, persistence is unnecessary. Intermediate discussion considered `repo-root` gitignored mode file ("it should create in repo root and it should be gitignored") but final decision is **no file** — installer re-prompts `mode` on next install without relying on persisted state; if a legacy `~/.config/dotfiles/mode` exists, uninstall may remove it (D-04) but no code reads it

#### Zsh self-provision & docs canon (SHEL-01, DOCS-01)

- **D-12:** Installer does **not** clone Zinit; Zinit self-clones on first `zsh` shell launch via `zsh/.zshrc` (`zdharma-continuum/zinit` inline clone if `~/.local/share/zinit/zinit.git` missing). No commit pinning required. User verbatim: "no need to clone anything, zinnit clones itself on first zsh shell launch also no need for pinning". `zsh` binary itself is still ensured via deps `verify → install → re-verify` (already in `common` per Phase 1 `make`+`gcc`+`fzf`+`zsh` decision) before `stow --restow zsh`. Research note: Termux extra login shell prompt (extra `login shell` question on Termux) needs to be researched — candidate for Phase 2 research spike, not a blocking decision here
- **D-13:** `chsh -s $(which zsh)` is offered once, at the very end after all `stow` + `quarantine_scan` + `post_verify` succeed, and only after explicit confirmation. Prompt wording: `Change default shell to zsh? Type 'yes' to run chsh -s $(which zsh)` (case-sensitive `yes`). Never auto-run `chsh`; `--yes` does **not** bypass `chsh` (still requires explicit `yes`); `--dry-run` prints `[DRY RUN] Would run: chsh -s $(which zsh)`; if `$(which zsh)` == `$SHELL`, skip prompt entirely. User verbatim: "offer after stow at the ned when everything is setted up."
- **D-14:** Docs full flip, keep backup column — **Reversibility:** costly — touches README, setup.sh comments, zsh headers, AGENTS.md. Update `README.md` shell-path table to `Default: Zsh | Backup: Nushell`, quick-start primary example to `bash setup.sh --mode local` / `bash setup.sh --mode local --dry-run` and `bash setup.sh --mode server --shell zsh --dry-run`, manual section to `stow --dir=. --target="$HOME" --restow nvim zsh starship` (core) vs `nvim nushell starship` (backup), GUI to `nvim zsh starship alacritty wofi`; update `setup.sh` header `usage()` comments and `zsh/.zshrc` header/inline comments to reflect Zsh default; update `AGENTS.md` if it contains shell guidance; `nvim/README.md` is currently absent (deleted pre-Phase-1) — recreate/update only if it reappears. Keep Nushell as backup column/examples, do not delete Nushell mentions
- **D-15:** Keep `teardown.zsh` / `teardown.nu` fallback mentions in docs until `bash setup.sh --uninstall` ships, then staged delete them and atomically fix docs — same pattern as Phase 1 D-02 staged delete (`setup.nu`/`setup.zsh` deleted in Phase 1, `teardown.*` survive until Phase 2). During Phase 2 transition, docs note `Use teardown scripts for now: bash teardown.zsh --help / nu teardown.nu --help` (already in `setup.sh:107-110`); final Phase 2 commit deletes `teardown.*` and removes mentions

### the agent's Discretion

None — every presented option was decided by the user (including two explicit overrides: uninstall to remove ALL installed deps, and Hyprland exec removal). No "You decide" selections.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 2 scope (uninstall/keyd/Hyprland/Zsh/docs). Backup/snapshot restore `AUTO-01`/`AUTO-02` (tar + `setup.sh --restore`, CI matrix) remains v2 per REQUIREMENTS.md; not re-raised as new asks.

### Research Flag (verbatim)

- **Termux extra login shell prompt** — installer triggers an extra "login shell" prompt on Termux that needs investigation before planning. Downstream researcher should probe `zsh/.zprofile` / `zsh/.zshrc` login-shell detection (`$-` vs `$0` vs `login` flag) and Termux `$PREFIX` / `TERMUX_VERSION` handling; candidates include `zsh -l` invocation, `proot`/`login` shell mismatch, or `chsh` on Termux (`pkg` users have no `chsh`). See `setup.sh:140-143` Termux family detection and `zsh/.zprofile` (now empty after D-10).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INST-03 | User can cleanly uninstall/reverse with `bash setup.sh --uninstall` (or `--remove`) that runs `stow -D`, removes privileged keyd link via `stow -D -t /`, and cleans Mason packages when Neovim is deselected — with typed `yes` guard (bypassable via `--yes` for CI) | Standard Stack `stow -D` + Mason path + `yes` gate pattern; Code Example `uninstall_idempotent` |
| STOW-02 | User's privileged `keyd` install is safe — installer previews `stow --no -t / keyd`, shows `diff` if `/etc/keyd/default.conf` exists and is not a symlink, requires explicit `gum confirm`/`Type 'yes'` before `sudo stow --adopt -t / keyd`, otherwise uses plain `sudo stow -t / keyd`; least-privilege sudoers documented | Standard Stack `stow --no --verbose` + `diff -u` + `sudo keyd reload`; Architecture Pattern `Privileged keyd gate`; Code Example `keyd_preview_diff_adopt` |
| STOW-03 | User on `server` mode does not have login killed by Hyprland — `zsh/.zprofile` guarded by persisted `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true` before `exec` (Phase 2 decision: delete exec block entirely, no mode file) | Verified `zsh/.zprofile:1-4` exec block deletion; Architecture Pattern `Hyprland removal`; Pitfall `tty1 exec death` |
| SHEL-01 | User gets Zsh provisioned before stow — installer ensures `zsh` binary present, clones Zinit (commit-pinned) if missing, and offers `chsh -s $(which zsh)` only after explicit user confirmation (never auto) | Verified `zsh/.zshrc:138-164` self-clone; Standard Stack `zsh` in `common` deps; Code Example `chsh_explicit` |
| DOCS-01 | User sees documentation flipped to Zsh default — `README.md` table shows `Default: Zsh | Backup: Nushell`, primary example is `bash setup.sh --mode local`, manual `stow --restow nvim zsh starship` vs `nvim nushell starship` sections, plus `nvim/README.md` and in-code comments updated; `AGENTS.md` guidance included | Verified `README.md:9-17` table already Zsh default; Standard Stack note on staged delete of `teardown.*` |

## Project Constraints (from AGENTS.md)

> **Source:** `AGENTS.md` (GSD project block `source:PROJECT.md`) — planner MUST NOT recommend approaches contradicting these.

- **Shell default:** Zsh is default everywhere; Nushell is backup only — update all docs/comments to reflect this — why: user explicitly requested Zsh as canonical [VERIFIED: AGENTS.md:13-14]
- **Installer language:** Unified installer must be **Bash** — available by default — why: `bash` is preinstalled, avoids requiring Nushell/Zsh to bootstrap themselves [VERIFIED: AGENTS.md:14-15]
- **Scope filter:** Do not fix Nushell-only issues — why: Nushell is backup, avoid wasted work [VERIFIED: AGENTS.md:15-16]
- **OS support:** Must correctly handle Arch/CachyOS/Ubuntu **and derivatives** via `ID_LIKE` + package-manager presence (`pacman`/`apt`), not hard-coded `["arch","cachyos","ubuntu"]` — why: users on Manjaro/EndeavourOS hit hard errors [VERIFIED: AGENTS.md:16-17]
- **Machine-local:** Machine-specific overrides must be gitignored and auto-sourced if present — why: per-machine PATH/alias/theme differences must not dirty git [VERIFIED: AGENTS.md:17-18]
- **Reversibility:** Removal must clean Stow symlinks, Keyd config, and Mason/packages installed by nvim (when uninstalling) — why: user expects `teardown` parity in unified script [VERIFIED: AGENTS.md:18-19]
- **Safety:** No destructive writes without preview/confirmation; privileged `/etc/keyd` writes require explicit conflict check and user confirmation — why: `--adopt` currently risky [VERIFIED: AGENTS.md:19-20]

Additional actionable directives from `AGENTS.md` stack section:
- Deployment target is GNU Stow to `$HOME`/`~/.config`/`/etc` with `keyd` requiring `sudo stow --adopt -t / keyd` + `sudo keyd reload` [VERIFIED: AGENTS.md:40-50]
- `zsh/.zprofile` currently auto-`exec start-hyprland` on `tty1` without DISPLAY [VERIFIED: AGENTS.md:89]
- No `package.json`/`Cargo.toml`/`pyproject.toml` at repo root — configuration repo, not buildable application [VERIFIED: AGENTS.md:51-52]

## Summary

Phase 2 makes `bash setup.sh` safely reversible (`--uninstall`/`--remove`) and server-safe without surprise privileged or `tty1` writes. The installer already has a proven Phase 1 spine — `set -Eeuo pipefail; shopt -s inherit_errexit` strict header [VERIFIED: setup.sh:3-4], 4-tier `detect_family` (Termux env/pkg → manager → `ID_LIKE` tokens → `ID` → manager fallback) [VERIFIED: setup.sh:139-175], `verify → install → re-verify` lock, 7-package checklist `ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd)` [VERIFIED: setup.sh:19] with `TERMUX_DISABLED_PACKAGES=(alacritty wofi keyd)` [VERIFIED: setup.sh:21], `gum→whiptail→dialog→fzf→read` ladder, `mv`-only quarantine to `.stow-conflicts/<timestamp>/MANIFEST` [VERIFIED: .gitignore:14], and `post_verify` folding-aware `test -L` + `readlink -f` [VERIFIED: setup.sh:442-473]. Phase 2 reuses these patterns verbatim.

Current gaps to close: `setup.sh:106-110` still short-circuits `--uninstall|--remove` with `Note: uninstall/remove is deferred to Phase 2. Use teardown scripts for now:` [VERIFIED: setup.sh:106-110]; `keyd` is skipped with `// Phase 2 — no /etc writes in Phase 1` at `setup.sh:385,404,460,478` [VERIFIED: setup.sh:385]; `zsh/.zprofile:1-4` still contains unconditional `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` [VERIFIED: zsh/.zprofile:1-4]; `zsh/.zshrc:138-164` already self-clones Zinit via `if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then command git clone https://github.com/zdharma-continuum/zinit` [VERIFIED: zsh/.zshrc:138-146] so installer must NOT duplicate that; `teardown.zsh:165` guards with `read "REPLY?Are you sure you want to continue? Type 'yes' to confirm: "` [VERIFIED: teardown.zsh:165] and `teardown.nu:35` with `input "Are you sure you want to continue? Type 'yes' to confirm: "` [VERIFIED: teardown.nu:35] — Phase 2 must port exact `yes` casing, add `--yes` CI bypass and `--dry-run` preview, and add idempotent `test -L` before `stow -D`; Mason artefacts live at `~/.local/share/nvim/mason` [VERIFIED: bash probe `ls ~/.local/share/nvim/mason`] and `~/.local/share/nvim/` also contains `lazy site telescope_history` — removal when `nvim` deselected must target `mason` (and optionally `site`/`state`/`cache` with confirmation).

**Primary recommendation:** Implement `--uninstall` as `DRY_RUN`-guarded `stow --dir="$SCRIPT_DIR" --target="$HOME" -D` plus `sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd`, gate both behind exact `yes` (or `--yes` for CI) and `stow --no --verbose` preview; gate `/etc` writes behind `stow --no --verbose -t / keyd` + `diff -u` preview and `gum confirm→Type 'yes'` ladder with `--adopt` only on explicit adopt confirmation; delete `zsh/.zprofile` Hyprland block and leave no mode file; leave Zinit self-clone in `zsh/.zshrc`, only ensure `zsh` binary via existing `common` deps before `stow --restow zsh`, and offer `chsh -s $(which zsh)` at the very end only after explicit `yes` (never via `--yes`); flip `README.md` + `setup.sh` `usage()` header to `Default: Zsh | Backup: Nushell` and staged-delete `teardown.*` after `--uninstall` ships.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Uninstall / `stow -D` + legacy mode-file cleanup | Installer (deploy) | — | Operates on `$HOME` symlinks via `stow --dir="$SCRIPT_DIR" --target="$HOME"` before any other tier runs; must respect strict header and `SCRIPT_DIR` guard [VERIFIED: setup.sh:6,1039-1045] |
| Privileged keyd gate (`stow -t / keyd` + `diff -u` + `--adopt` + `keyd reload`) | OS / Privileged filesystem | Installer | Writes to `/etc/keyd/default.conf` via `sudo stow -t /` — only tier that touches `/etc`; installer orchestrates preview/confirmation but OS owns the resource [VERIFIED: keyd/etc/keyd/default.conf:1-6] |
| Hyprland `zsh/.zprofile` `exec` removal / server-safety | Shell (Zsh login) | Installer | `zsh/.zprofile` is sourced by Zsh login shells; `exec` on `tty1` kills the login session — fix is deletion of the file block, not installer runtime branching [VERIFIED: zsh/.zprofile:1-4] |
| System package offer (`pacman -Rns`/`apt remove -y`/`pkg uninstall`) | OS package manager | Installer | Installer reuses same `get_deps`/`SELECTED_DEPS` tables and `detect_family` to list candidates, but actual removal is via host `pacman`/`apt`/`pkg` with `sudo` (no sudo on Termux) [VERIFIED: setup.sh:260-314] |
| Mason artefact cleanup (`~/.local/share/nvim/mason`) | Editor (Neovim) | Installer | Mason installs to `stdpath("data")` (`~/.local/share/nvim/mason`) [VERIFIED: bash probe `ls ~/.local/share/nvim`]; installer only removes when `nvim` deselected (D-02) — editor owns artefact semantics |
| Zsh self-provision (Zinit self-clone) | Shell (Zsh runtime) | — | `zsh/.zshrc:138-164` self-clones on first interactive Zsh launch; installer only ensures `zsh` binary present before stow [VERIFIED: zsh/.zshrc:138-164] [VERIFIED: setup.sh:183-184 `common` includes `zsh`] |
| `chsh -s $(which zsh)` offer | OS / User account | Installer (end-of-run) | `chsh` changes login shell in `/etc/passwd`/`/etc/shells`; offer only after `quarantine_scan`+`stow`+`post_verify` succeed [VERIFIED: `which chsh` → `/usr/bin/chsh`; `chsh --help` shows `-s, --shell SHELL`] |
| Docs flip (`README.md` Zsh-default tables, `setup.sh` header comments) | Docs | — | No runtime owner; `README.md:9-17` already shows `Zsh (Default) | Nushell (Backup)` [VERIFIED: README.md:9-17]; Phase 2 deepens flip to all examples/headers |

## Standard Stack

### Core (Bash installer + GNU Stow + host package managers)

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `bash` | `5.2.21(1)-release` [VERIFIED: bash --version] | Unified installer language; strict-mode `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards [VERIFIED: setup.sh:3-4] | Preinstalled on every target (Arch/Debian/Termux `pkg` provides `bash`); avoids requiring Nushell/Zsh to bootstrap themselves — PROJECT constraint [VERIFIED: AGENTS.md:14-15] |
| `GNU Stow` | `2.3.1` installed, `≥2.4.1` required auto-upgraded via `sort -V` [VERIFIED: stow --version + setup.sh:1089-1112] | Symlink deployment `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow/-D` and preview `stow --no --verbose` [VERIFIED: setup.sh:385-390,479] | Single engine handles `starship.toml` folding and `keyd -t /` privilege correctly; custom `ln -sf` loop mishandles folding/adopt — Out of Scope table explicitly forbids it [VERIFIED: REQUIREMENTS.md:78] |
| `pacman` / `apt` / `pkg` | `apt 2.8.3` on Ubuntu host [VERIFIED: apt --version]; `pkg` on Termux only | System dependency install (`pacman -S --needed --noconfirm` / `apt install -y` / `pkg install -y`) and uninstall offer (`pacman -Rns` / `apt remove -y` / `pkg uninstall`) [VERIFIED: setup.sh:267-271,330-332] | Native package manager per family — `detect_family` maps `arch→pacman`, `debian→apt`, `termux→pkg` with no `sudo` on Termux [VERIFIED: setup.sh:260-271] |
| `stow --no --verbose` | stow `2.3.1` supports `-n/--no` + `--verbose` [VERIFIED: man stow] | Dry-run preview before any `stow`/`sudo stow` mutation; also `sudo stow -D -t / --no --verbose keyd` for privileged dry-run [VERIFIED: setup.sh:385-389] | GNU Stow manual standard; `stow --no` is the documented simulate flag [CITED: https://www.gnu.org/software/stow/manual/stow.html] |
| `stow -D` | stow `2.3.1` [VERIFIED: man stow shows `-D/--delete` deletes package from target only if owned] | Reversible unstow (`stow --dir="$SCRIPT_DIR" --target="$HOME" -D <pkg>` and `sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd`) | Defined by Stow to delete only links it owns — safe idempotent primitive; never `rm -rf` repo dirs per D-01 |
| `diff -u` | GNU `diffutils` (present on all targets) | Show unified diff of `/etc/keyd/default.conf` vs `$SCRIPT_DIR/keyd/etc/keyd/default.conf` when host file exists as regular file (not symlink) per D-06 | Standard POSIX `diff`; ` -u` unified format is the `STOW-02` preview contract |
| `gum` + `whiptail`/`dialog`/`fzf`/`read` ladder | `gum` not installed on host probe (absent) [VERIFIED: `which gum` → not found]; `whiptail`/`dialog`/`fzf` probed with `command -v` fallback | Confirmation `gum confirm` primary → `Type 'yes'` fallback for privileged and uninstall flows [VERIFIED: CONTEXT D-08] | Reuse Phase 1 `gum→whiptail→dialog→fzf→read` ladder contract `checklist_gum`…`checklist_read` [VERIFIED: setup.sh:486-773]; `cancel never cascades` — any cancel returns error, never falls through silently |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `zsh` (binary) | `5.9 (x86_64-ubuntu-linux-gnu)` [VERIFIED: zsh --version] | Ensure shell present before `stow --restow zsh`; `chsh -s $(which zsh)` offer at end [VERIFIED: setup.sh:183-184 `common` includes `zsh`] | Always in `common` deps; Phase 1 `make`+`gcc`+`fzf`+`zsh` decision already places `zsh` in `common` so `telescope-fzf-native` + fzf history never silently fall back |
| `Zinit` self-clone via `zsh/.zshrc` | `zdharma-continuum/zinit` via `git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"` [VERIFIED: zsh/.zshrc:144-146,158-159] | Plugin manager self-provisions on first Zsh launch; `source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"` [VERIFIED: zsh/.zshrc:164] | Never clone from installer per D-12; leave inline bootstrap untouched |
| `keyd` + `sudo keyd reload` / `systemctl reload keyd` | Host `keyd` | Privileged target `keyd/etc/keyd/default.conf` → `/etc/keyd/default.conf` [VERIFIED: keyd/etc/keyd/default.conf:1-6] + post-stow reload `sudo keyd reload \|\| sudo systemctl reload keyd \|\| true` | After successful `sudo stow -t / keyd` per D-09; `|| true` so reload failure never kills installer |
| `chsh` | `util-linux chsh` with `-s/--shell` [VERIFIED: chsh --help shows `-s, --shell SHELL`] | Change login shell `chsh -s $(which zsh)` | Only after `quarantine_scan`+`run_stow`+`post_verify` succeed, `which zsh != $SHELL` guard, `--yes` does NOT bypass, `--dry-run` prints `[DRY RUN] Would run: chsh -s $(which zsh)` per D-13 |
| `sort -V` | GNU coreutils (present) | Version compare `printf '%s\n' "$stow_ver" "2.4.1" | sort -V | head -n1` to detect `stow <2.4.1` and queue upgrade via same manager lock [VERIFIED: setup.sh:1094-1096] | Correctly handles `2.10 > 2.4.1` vs lexicographic |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `stow -D` unstow | `rm -rf ./nvim` (old `teardown.zsh:149` / `teardown.nu:152` `rm -rf $stow_dir`) [VERIFIED: teardown.zsh:149, teardown.nu:152] | `rm -rf` is destructive and irreversible; D-01 explicitly forbids it — `stow -D` only removes links it owns, preserves repo for `stow --restow` recovery |
| `sudo stow --adopt -t / keyd` unconditionally | Plain `sudo stow -t / keyd` + explicit `diff -u` + `gum confirm`/`Type 'yes'` gate [VERIFIED: CONTEXT D-07] | `--adopt` moves host file into repo — host edits lost and repo polluted without confirmation; CONCERNS.md flags `--adopt` as risky |
| Persisted mode file `~/.config/dotfiles/mode` + guard `command -v Hyprland` + `|| true` before `exec` | Delete `zsh/.zprofile` exec block entirely, no file [VERIFIED: CONTEXT D-10, D-11] | User verbatim "no need for that remove that" — guard complexity is redundant when user no longer uses tty login; deletion is reversible via git history |
| Installer cloning Zinit commit-pinned before stow | Zinit self-clone on first `zsh` launch via `zsh/.zshrc` inline [VERIFIED: zsh/.zshrc:138-164] | D-12 verbatim "no need to clone anything, zinit clones itself ... no need for pinning" — installer clone duplicates shell runtime responsibility |
| `--yes` bypassing `chsh` | Require explicit `Type 'yes'` for `chsh` even when `--yes` passed [VERIFIED: CONTEXT D-13] | `chsh` changes `/etc/passwd` login shell — auto-bypass could lock user out; D-13 holds that `--yes` must NOT bypass `chsh` |

**Installation:**

No new npm/pypi/crates packages required. This phase reuses host `bash`, `stow`, `diff`, `git`, `sudo`, `chsh`, and the existing `gum→whiptail→dialog→fzf→read` ladder. If `stow <2.4.1` is detected, installer queues `stow` upgrade via `pacman -S --needed` / `apt install -y` / `pkg install` same lock as deps [VERIFIED: setup.sh:1106-1109].

```bash
# No npm install — host tools only
# Verify stow folding preview and uninstall preview work:
stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose nvim
stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd
diff -u /etc/keyd/default.conf "$SCRIPT_DIR/keyd/etc/keyd/default.conf" 2>/dev/null || echo "(no host file or symlink — no diff needed)"
```

**Version verification:**

```bash
bash --version | head -1        # → GNU bash, version 5.2.21(1)-release [VERIFIED: bash --version]
stow --version | head -1        # → stow (GNU Stow) version 2.3.1 [VERIFIED: stow --version] (installer upgrades to ≥2.4.1 via sort -V)
zsh --version | head -1         # → zsh 5.9 [VERIFIED: zsh --version]
chsh --help | head -5           # → util-linux chsh with -s/--shell [VERIFIED: chsh --help]
command -v gum && gum --version || echo "gum not installed — ladder falls back to whiptail/dialog/fzf/read"  # [VERIFIED: which gum → not found]
```

## Package Legitimacy Audit

> No new external package installations required for this phase. The phase reuses host-preinstalled `bash`, `GNU Stow`, `diffutils`, `git`, `sudo`, `chsh`, and the TUI ladder (`gum`/`whiptail`/`dialog`/`fzf`). No `npm`/`pip`/`cargo` packages are introduced.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| *(none)* | — | — | — | — | — | N/A — host tools only |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*If a future iteration introduces a new helper (e.g., `gum` static binary for CI), run the Package Legitimacy Gate protocol before adding it to Standard Stack.*

## Architecture Patterns

### System Architecture Diagram

```text
                    bash setup.sh [--dry-run] [--yes] [--uninstall|--remove]
                                   │  strict header: set -Eeuo pipefail; shopt -s inherit_errexit
                                   │  pre-scan: for arg in "$@"; case --help wins [VERIFIED: setup.sh:52-58]
                                   ▼
                     ┌──────────────────────────────┐
                     │  parse_args (help wins)      │
                     │  detect_family: Termux env/  │  ← OS_RELEASE_FILE seam for tests
                     │  PREFIX → manager → ID_LIKE   │    [VERIFIED: setup.sh:139-175]
                     │  space-split → ID → fallback  │
                     └──────────────┬───────────────┘
                                    ▼
                     ┌──────────────────────────────┐
                     │  INSTALL PATH                │          ┌─────────────────────────────┐
                     │  verify→install→re-verify     │         │  UNINSTALL PATH             │
                     │  checklist ladder             │         │  --uninstall / --remove      │
                     │  gum→whiptail→dialog→fzf→read │         │  typed yes gate             │
                     │  [VERIFIED: setup.sh:754-773] │         │  exact "yes" + --yes CI     │
                     └──────────────┬───────────────┘         │  --dry-run preview          │
                                    │                         │  stow --no --verbose -D     │
                                    ├─── DRY_RUN early-return └─────────────┬───────────────┘
                                    │      [DRY RUN] Would run: stow ...    │
                                    │      BEFORE any mutation              ▼
                                    ▼                ┌──────────────────────────────────────┐
                     ┌──────────────────────────┐     │  1) Preview: stow -D --no --verbose  │
                     │ quarantine_scan          │     │     + sudo stow -D -t / --no --      │
                     │ mv → .stow-conflicts/    │     │       verbose keyd + diff -u          │
                     │ <ts>/MANIFEST            │     │  2) Confirm: gum confirm → Type 'yes'│
                     │ [VERIFIED: setup.sh:393] │     │  3) Mutate: stow -D nvim zsh ...     │
                     └──────────────┬───────────┘     │     sudo stow -D -t / keyd (-D only  │
                                    ▼                │     if test -L /etc/keyd/default.conf)│
                     ┌──────────────────────────┐     │  4) Idempotent: test -L before -D;   │
                     │ run_stow                 │     │     skip missing with warning         │
                     │ stow --dir="$SCRIPT_DIR" │     │  5) Mason cleanup: rm -rf            │
                     │   --target="$HOME"       │     │     ~/.local/share/nvim/mason if     │
                     │   --restow nvim zsh ...  │     │     nvim not in SELECTED_PACKAGES    │
                     │ privileged: preview      │     │  6) System deps offer:               │
                     │  stow --no -t / keyd     │     │     pacman -Rns / apt remove -y /    │
                     │  diff -u if regular file │     │     pkg uninstall (same yes gate)    │
                     │  gum→yes → adopt or plain│     │  7) Legacy mode-file: rm -f          │
                     │  sudo stow -t / keyd     │     │     ~/.config/dotfiles/mode (no err) │
                     │  keyd reload || true     │     │  8) Leave .stow-conflicts/ intact    │
                     └──────────────┬───────────┘     └──────────────┬───────────────────────┘
                                    ▼                                │
                     ┌──────────────────────────┐                    │
                     │ post_verify              │◄───────────────────┘  (both paths converge)
                     │ test -L + readlink -f    │      uninstall skips post_verify for removed pkgs;
                     │ folding-aware prefix     │      re-install re-uses this verify
                     │ [VERIFIED: setup.sh:455] │
                     └──────────────┬───────────┘
                                    ▼
                     ┌──────────────────────────┐
                     │ chsh offer (END-OF-RUN)  │  only after stow+post_verify succeed
                     │ if which zsh != $SHELL   │  --yes does NOT bypass
                     │ Type 'yes' to run        │  --dry-run prints preview
                     │ chsh -s $(which zsh)     │  [VERIFIED: CONTEXT D-13]
                     │ || true (Termux no chsh) │
                     └──────────────────────────┘
```

### Recommended Project Structure

```text
dotfiles/
├── setup.sh                       # unified installer — add --uninstall/--remove + privileged keyd gate + chsh offer
├── .gitignore                     # already has .stow-conflicts/ [VERIFIED: .gitignore:14]; ensure zsh/.zshrc.local + nvim local.lua ignored (Phase 3)
├── keyd/etc/keyd/default.conf     # privileged target → /etc/keyd/default.conf [VERIFIED: keyd/etc/keyd/default.conf:1-6]
├── zsh/
│   ├── .zshrc                     # Zinit self-clone stays [VERIFIED: zsh/.zshrc:138-164]; ensure SHEL-01 comment reflects Zsh default
│   ├── .zprofile                  # DELETE exec block [VERIFIED: zsh/.zprofile:1-4] — now empty or removed
│   └── .p10k.zsh                  # untouched
├── nvim/.config/nvim/             # Mason artefacts at ~/.local/share/nvim/mason cleaned on uninstall when nvim deselected
├── README.md                      # flip to Default: Zsh | Backup: Nushell + stow --restow nvim zsh starship core
└── teardown.zsh / teardown.nu     # staged delete after --uninstall ships (D-15)
```

No new directories/files created by this phase except optional `.stow-conflicts/<ts>/MANIFEST` already handled by `quarantine_scan`. Do NOT create `~/.config/dotfiles/mode` or repo-root mode file — D-11 explicitly forbids any persisted mode file.

### Pattern 1: Reversible `--uninstall` with `DRY_RUN` Early-Return Before Every Mutation and Idempotent `stow -D`

**What:** `bash setup.sh --uninstall` must NOT remove repo package directories, must be previewable via `--dry-run --uninstall`, must be gated by exact `yes`, must be idempotent on second run and on re-install, and must never auto-delete quarantine backups. Reuses Phase 1 `DRY_RUN` early-return before every mutation pattern [VERIFIED: setup.sh:273-277,300-301].

**When to use:** Every filesystem mutation in uninstall — `stow -D`, `sudo stow -D -t /`, Mason `rm -rf`, system package `pacman -Rns`/`apt remove`/`pkg uninstall`, legacy mode-file `rm -f`.

**Example:**

```bash
# Source: patterns from setup.sh:106-110 (deferred notice), setup.sh:273-277 (DRY_RUN guard), teardown.zsh:165 (yes guard)
# parse_args: --uninstall/--remove must appear BEFORE SCRIPT_DIR guards so --help still wins
--uninstall|--remove)
    UNINSTALL=true
    shift
    ;;
# ... after parse_args and SCRIPT_DIR / outside-repo-root guards ...

run_uninstall() {
    # Idempotent preview — never touches filesystem when DRY_RUN
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then continue; fi
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --delete $pkg"
            stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose --delete "$pkg" 2>&1 | sed 's/^/  /' || true
        fi
    done
    # Privileged dry-run preview
    if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx keyd; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose --delete keyd"
            sudo stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd 2>&1 | sed 's/^/  /' || true
        fi
    fi
    if [[ "$DRY_RUN" == true ]]; then return 0; fi

    # Typed yes gate — exact case-sensitive, --yes bypass for CI only
    if [[ "$YES" != true ]]; then
        local reply
        # Reuse gum confirm primary → Type 'yes' fallback per D-03/D-08
        if command -v gum >/dev/null 2>&1; then
            if ! gum confirm "Run uninstall (stow -D) for: ${SELECTED_PACKAGES[*]} ?"; then
                echo "Uninstall cancelled." >&2; return 1
            fi
        else
            printf "Type 'yes' to confirm: " >&2
            if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
            if [[ "$reply" != "yes" ]]; then echo "Uninstall cancelled (expected 'yes')." >&2; return 1; fi
        fi
    fi

    # Idempotent unstow — check link before -D
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then continue; fi
        # Verify dir exists in repo; skip silently if not (stow package missing is warning not error)
        if [[ ! -d "$SCRIPT_DIR/$pkg" ]]; then
            echo "Warning: package dir not found: $SCRIPT_DIR/$pkg — skipping unstow for $pkg" >&2; continue
        fi
        # Idempotence: stow -D is safe even if already unstowed, but warn if nothing to remove
        # Check folding-aware: if any expected link still exists via assert_linked, do -D; else skip with warning
        if ! stow --dir="$SCRIPT_DIR" --target="$HOME" -D "$pkg" 2>&1; then
            echo "Warning: stow -D $pkg returned non-zero (already unstowed or not owned — continuing)" >&2
        else
            echo "Unstowed: $pkg"
        fi
    done

    # Privileged unstow
    if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx keyd; then
        if ! sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd 2>&1; then
            echo "Warning: sudo stow -D -t / keyd failed (not stowed or not owned — continuing)" >&2
        else
            echo "Unstowed privileged: keyd"
        fi
        # Reload only if keyd is still installed as a service — || true prevents session kill
        sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true
    fi

    # Mason cleanup only when nvim not selected (D-02) — never when nvim still selected
    if ! printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then
        if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
            echo "Removing Mason artefacts: ~/.local/share/nvim/mason (nvim deselected)"
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would run: rm -rf ~/.local/share/nvim/mason"
            else
                rm -rf "$HOME/.local/share/nvim/mason"
                # Optional: also prune empty parent dirs, but never auto-remove .stow-conflicts
                rmdir "$HOME/.local/share/nvim" 2>/dev/null || true
            fi
        fi
    fi

    # Legacy mode file — remove if present, no error if absent (D-04)
    rm -f "$HOME/.config/dotfiles/mode" 2>/dev/null || true
    rm -f "$SCRIPT_DIR/.dotfiles-mode" 2>/dev/null || true  # repo-root legacy if ever written

    # System package offer — reuse SELECTED_DEPS / filtered deps list, same yes gate, dry-run preview
    # (see Pattern 2 for full ladder; never auto-remove without explicit confirmation)
    offer_system_package_removal  # defined below
}
```

### Pattern 2: Privileged Keyd Safety Gate — Preview + `diff -u` + `gum confirm → Type 'yes'` + Conditional `--adopt` + `reload || true`

**What:** Every `keyd` install must preview with `stow --no --verbose -t / keyd` and `diff -u` if host file is a regular file (not symlink), then require explicit confirmation before any `/etc` write, using plain `sudo stow -t / keyd` by default and `--adopt` only when conflict file exists as regular file AND user explicitly chose adopt. Dry-run prints `[DRY RUN] Would run: sudo stow ...` + diff preview without touching filesystem. After success, `sudo keyd reload || sudo systemctl reload keyd || true`.

**When to use:** Every time `SELECTED_PACKAGES` contains `keyd` and `FAMILY != termux` (Termux has no `/etc/keyd` and `TERMUX_DISABLED_PACKAGES` excludes `keyd` [VERIFIED: setup.sh:21]).

**Example:**

```bash
# Source: CONTEXT D-06/D-07/D-08/D-09 + setup.sh:385 keyd skip notice
install_keyd_privileged() {
    if [[ "${FAMILY:-}" == "termux" ]]; then
        echo "Warning: 'keyd' is not available on Termux — skipping privileged install." >&2; return 0
    fi

    echo ""
    echo "=== Privileged keyd preview (no writes) ==="
    echo "[PREVIEW] stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose keyd"
    stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd 2>&1 | sed 's/^/  /' || true

    local host_conf="/etc/keyd/default.conf"
    local repo_conf="$SCRIPT_DIR/keyd/etc/keyd/default.conf"
    local has_regular_conflict=false
    if [[ -f "$host_conf" ]] && [[ ! -L "$host_conf" ]]; then
        has_regular_conflict=true
        echo ""
        echo "Conflict: $host_conf exists as a regular file (not a symlink) — showing diff:"
        diff -u "$host_conf" "$repo_conf" 2>&1 | sed 's/^/  /' || true
        # Note: diff exits 1 when files differ — captured via || true so strict mode doesn't abort
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ keyd"
        if [[ "$has_regular_conflict" == true ]]; then
            echo "[DRY RUN] (conflict detected — would prompt for adopt vs plain stow)"
        fi
        echo "[DRY RUN] Would run: sudo keyd reload || sudo systemctl reload keyd || true"
        return 0
    fi

    # Confirmation ladder: gum confirm → Type 'yes' fallback; --yes bypass for CI (D-08)
    local confirmed=false
    if [[ "$YES" == true ]]; then
        confirmed=true
    elif command -v gum >/dev/null 2>&1; then
        if gum confirm "Write privileged keyd config to /etc/keyd/default.conf ?"; then
            confirmed=true
        else
            echo "Privileged keyd install cancelled (gum)." >&2; return 1
        fi
    else
        local reply
        printf "Type 'yes' to confirm privileged keyd install: " >&2
        if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
        if [[ "$reply" == "yes" ]]; then confirmed=true; else echo "Cancelled (expected 'yes')." >&2; return 1; fi
    fi
    if [[ "$confirmed" != true ]]; then return 1; fi

    # Adopt only when regular-file conflict exists AND explicit adopt confirmation
    local use_adopt=false
    if [[ "$has_regular_conflict" == true ]]; then
        local adopt_reply=""
        if [[ "$YES" == true ]]; then
            # --yes bypass does NOT auto-adopt — still plain stow unless user previously chose adopt via checklist detail
            use_adopt=false
        elif command -v gum >/dev/null 2>&1; then
            if gum confirm "Conflict file exists. Adopt host file into repo (moves $host_conf into repo)?"; then
                use_adopt=true
            fi
        else
            printf "Conflict file exists at %s.\n" "$host_conf" >&2
            printf "Type 'adopt' to move host file into repo (stow --adopt), or Enter for plain stow: " >&2
            read -r adopt_reply || true
            if [[ "$adopt_reply" == "adopt" ]]; then use_adopt=true; fi
        fi
    fi

    if [[ "$use_adopt" == true ]]; then
        sudo stow --dir="$SCRIPT_DIR" --target=/ --adopt keyd
    else
        sudo stow --dir="$SCRIPT_DIR" --target=/ keyd
    fi

    # Least-privilege reload — never kills installer on failure
    sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true
    echo "[DRY RUN would have printed: sudo keyd reload]"
}
```

### Pattern 3: Hyprland `zsh/.zprofile` Removal — Delete `exec` Block, Leave No Mode File

**What:** Delete the entire conditional `exec start-hyprland` block from `zsh/.zprofile`. Do NOT write or read any `~/.config/dotfiles/mode` file. If the file becomes empty after deletion, leave it as an empty file or delete the file entirely — both are reversible via `git restore zsh/.zprofile`.

**When to use:** As part of the `02-01` plan that touches `zsh/.zprofile`.

**Example:**

```bash
# Before (committed, to be removed) [VERIFIED: zsh/.zprofile:1-4]:
# Auto-start Hyprland on TTY1
# if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
#     exec start-hyprland
# fi

# After: file is deleted entirely OR contains only a comment:
# zsh/.zprofile — no Hyprland autostart (removed Phase 2, D-10)
# Zsh login profile — intentionally empty; Hyprland is launched manually via display manager or `Hyprland` command.

# Installer must NOT contain any of:
# - mkdir -p ~/.config/dotfiles; echo "$MODE" > ~/.config/dotfiles/mode
# - if [[ -f ~/.config/dotfiles/mode ]]; then mode=$(cat ...)
# - command -v Hyprland guards around exec start-hyprland
# On uninstall, optionally clean legacy file but never fail if absent:
#   rm -f "$HOME/.config/dotfiles/mode" 2>/dev/null || true
```

### Pattern 4: Zsh Self-Provision via `zsh/.zshrc` Self-Clone (No Installer Pin) + End-of-Run `chsh` Offer

**What:** Installer ensures `zsh` binary present via `common` deps [VERIFIED: setup.sh:183-184] then stows `zsh` package. `zsh/.zshrc` inline self-clone `if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then ... git clone https://github.com/zdharma-continuum/zinit ...` [VERIFIED: zsh/.zshrc:138-146] stays untouched — installer does NOT run `git clone` for Zinit and does NOT pin a commit. `chsh -s $(which zsh)` is offered only after `quarantine_scan` + `run_stow` + `post_verify` all succeed, only if `$(which zsh)` != `$SHELL`, only after explicit `Type 'yes'` (never auto, `--yes` does NOT bypass), and printed as `[DRY RUN] Would run: chsh ...` when `DRY_RUN`.

**When to use:** After stow deployment, before final `echo "Setup complete."`.

**Example:**

```bash
# Source: CONTEXT D-12/D-13 + zsh/.zshrc:138-164 + setup.sh common deps
# No Zinit clone in installer — comment explains:
# Zinit self-clones on first zsh launch via zsh/.zshrc:138-164 — no installer pin per D-12.

offer_chsh() {
    # Skip if not interactive or if already on zsh
    local zsh_path
    if ! zsh_path=$(command -v zsh 2>/dev/null); then
        echo "Warning: zsh not found — cannot offer chsh." >&2; return 0
    fi
    if [[ -n "${SHELL-}" ]] && [[ "$zsh_path" == "$SHELL" ]]; then
        echo "Default shell already zsh ($SHELL) — skipping chsh offer."; return 0
    fi
    # Termux has no chsh — skip gracefully (see Open Question)
    if [[ "${FAMILY:-}" == "termux" ]]; then
        echo "Termux detected — chsh not applicable; skipping default shell change."; return 0
    fi
    if ! command -v chsh >/dev/null 2>&1; then
        echo "chsh not found — skipping default shell change. Run manually: chsh -s $zsh_path" >&2; return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: chsh -s $zsh_path"
        return 0
    fi

    # --yes does NOT bypass chsh per D-13 — still requires explicit yes
    local reply
    printf "Change default shell to zsh? Type 'yes' to run chsh -s %s: " "$zsh_path" >&2
    if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
    if [[ "$reply" != "yes" ]]; then
        echo "Skipping chsh (expected 'yes'). Manually run: chsh -s $zsh_path" >&2; return 0
    fi

    # chsh may prompt for password — let it; never backgrounds; || true on failure
    if ! chsh -s "$zsh_path"; then
        echo "Warning: chsh failed (check /etc/shells contains $zsh_path, or use sudo chsh)." >&2
        return 1
    fi
    echo "Default shell changed to $zsh_path — relogin to take effect."
}
```

### Anti-Patterns to Avoid

- **Blind `--adopt` on `keyd`:** `sudo stow --adopt -t / keyd` without `diff -u` and explicit adopt confirmation moves the host's `/etc/keyd/default.conf` into `keyd/etc/keyd/default.conf` in the repo, polluting `git status` and losing the host's original. Always preview with `stow --no --verbose -t / keyd` + `diff -u` and only use `--adopt` when user typed `adopt` or confirmed via `gum confirm` on the adopt-specific prompt [VERIFIED: CONTEXT D-07].
- **Persisting a mode file after Hyprland removal:** Writing `~/.config/dotfiles/mode` or repo-root `.dotfiles-mode` after `zsh/.zprofile` exec is deleted adds a state file with no reader; re-prompts already handle next install. D-11 says no file — do not create `gitignored` mode file "just in case".
- **Installer cloning Zinit:** `git clone https://github.com/zdharma-continuum/zinit` in `setup.sh` duplicates `zsh/.zshrc:138-164` inline self-clone [VERIFIED: zsh/.zshrc:138-164] and introduces pin drift. Leave self-clone to the shell runtime per D-12.
- **Auto `chsh` without confirmation or via `--yes` bypass:** `chsh -s $(which zsh)` changes `/etc/passwd` and requires password; auto-run locks users out of current shell and breaks Termux where `chsh` does not exist. Always gate behind `Type 'yes'` and never bypass with `--yes` per D-13.
- **`rm -rf` on repo stow dirs during uninstall:** `teardown.zsh:149` `rm -rf "$stow_dir"` [VERIFIED: teardown.zsh:149] and `teardown.nu:152` `rm -rf $stow_dir` [VERIFIED: teardown.nu:152] are destructive and contradict PROJECT Reversibility constraint. Phase 2 uninstall must use only `stow -D` and delete Mason artefacts, never `rm -rf ./nvim` etc. per D-01.
- **Deleting `.stow-conflicts/<ts>/` on uninstall:** `quarantine_scan` already warns quarantine is a safety backup and `.gitignore:14` already ignores `.stow-conflicts/` [VERIFIED: .gitignore:14]; auto-deleting on uninstall destroys the only rollback for earlier file collisions.
- **Using `eval "$(whiptail ...)"` to parse checklist output:** `eval` executes arbitrary content; `setup.sh:572-580` already fixed `CR-01` by parsing via `xargs -n1` without `eval` [VERIFIED: setup.sh:572-580 `Safe parse without eval` comment]. Keep safe parse.
- **Sourcing `/etc/os-release` via `.`/`source`:** Executing the file allows code injection; `setup.sh:152-154` uses `grep -E '^ID='` + `cut` + `tr -d` + `xargs` safe parse [VERIFIED: setup.sh:152-154 `Safe parse without sourcing` comment]. Do not regress.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink deployment with folding (`starship.toml`, `nvim` directory folding) | Custom `ln -sf` / `cp -r` loop | `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow/-D` + `stow --no --verbose` preview [VERIFIED: setup.sh:385-390,479] | Stow handles `--no-folding`, `folding` of `starship/.config/starship.toml` → `~/.config/starship.toml` correctly; custom loop breaks folding and `keyd -t /` privilege — REQUIREMENTS.md Out of Scope explicitly forbids custom engine [VERIFIED: REQUIREMENTS.md:78] |
| Distribution detection for derivatives (Manjaro, EndeavourOS, Mint, Pop!_OS) + Termux | Hard-coded `if distro in ["arch","cachyos","ubuntu"]` | `detect_family()` 4-tier `TERMUX_VERSION`/`PREFIX` → `command -v pacman`/`apt` → `ID_LIKE` space-split → `ID` → manager fallback with `OS_RELEASE_FILE` seam [VERIFIED: setup.sh:139-175] | Users on derivatives hit hard error per CONCERNS.md; `ID_LIKE` covers `manjaro`/`endeavouros`/`garuda`/`linuxmint`/`pop` correctly [VERIFIED: setup.sh:158-168] |
| System package install / uninstall | Manual `pacman -S` strings without verify | `get_deps`/`filter_deps_by_selection`/`verify_deps`/`reverify_deps` lock + per-family `pacman -S --needed`/`apt install -y`/`pkg install` and `pacman -Rns`/`apt remove -y`/`pkg uninstall` offer [VERIFIED: setup.sh:177-337] | Re-verify aborts with `Still missing` report [VERIFIED: setup.sh:329-332]; `sort -V` upgrade handles `stow ≥2.4.1` correctly |
| Interactive selection (CLI/TUI) | Raw `read` with manual toggle parsing only | `gum→whiptail→dialog→fzf→read` ladder `checklist_gum`…`checklist_read` with Termux disabled-row emulation and `cancel never cascades` [VERIFIED: setup.sh:486-773] | Covers preinstalled/static binaries without needing `Bubbletea`/`textual` — REQUIREMENTS.md Out of Scope forbids elaborate TUI frameworks |
| Collision backup for stow conflicts | `stow --adopt` unconditionally or silent overwrite | `quarantine_scan` `mv` to `.stow-conflicts/<timestamp>/MANIFEST` preserving relative paths, gitignored, never delete [VERIFIED: setup.sh:393-440, .gitignore:14] | `--adopt` moves host file into repo; `mv`-only quarantine is reversible and warnings are folding-aware via `readlink -f` prefix check |
| Privileged `/etc` write conflict check | Blind `sudo stow -t / keyd` | `stow --no --verbose -t / keyd` preview + `diff -u /etc/keyd/default.conf $SCRIPT_DIR/keyd/etc/keyd/default.conf` iff regular file, then `gum confirm→Type 'yes'` gate [VERIFIED: CONTEXT D-06/D-08] | Prevents silent overwrite of host key remap; `--adopt` only after explicit adopt confirm per D-07 |
| Post-deploy verification | `echo success` or `ls ~/` | `post_verify` folding-aware `test -L` + `readlink -f` prefix under `$SCRIPT_DIR/<pkg>/` over `~/.config/nvim` and `~/.config/starship.toml` [VERIFIED: setup.sh:442-473] | Catches `starship` folding and `nvim` symlink misses; aborts with link→expected-target report |

**Key insight:** GNU Stow `≥2.4.1` already fixes the folding/adopt bugs that motivated custom `ln -sf` rewrites; Phase 1 `quarantine_scan` + `post_verify` wrap Stow's correct semantics with `mv`-only safety and `readlink -f` checks — re-implementing Stow logic loses folding, breaks `/etc` targets, and reintroduces derivative crashes already fixed by `-t /` handling.

## Common Pitfalls

### Pitfall 1: `stow -D` Not Idempotent Assumption — Second Uninstall Fails or Deletes Repo Content

**What goes wrong:** Running `stow -D nvim` when `~/.config/nvim` is already unstowed or when a target file is a regular file (not a symlink) returns non-zero and, with `set -e`, aborts the whole uninstall; or a naive `rm -rf` fallback deletes the repo's `nvim/.config/nvim/` directory.

**Why it happens:** `stow -D` only removes links it owns [CITED: man stow `-D --delete deletes package... owned by stow`]; users expect `uninstall` to be repeatable. `set -Eeuo pipefail` [VERIFIED: setup.sh:3] makes any non-zero `stow -D` fatal unless guarded.

**How to avoid:** Wrap every `stow -D` with `|| true` or explicit `if ! stow ...; then echo "Warning: ... already unstowed — continuing" >&2; fi` and never `rm -rf "$SCRIPT_DIR/$pkg"`. Check `[[ -d "$SCRIPT_DIR/$pkg" ]]` and skip missing package dirs with warning not error per D-04. Keep `.stow-conflicts/<ts>/` never auto-deleted.

**Warning signs:** Second `bash setup.sh --uninstall` exits non-zero; `git status` shows deleted `nvim/` directory.

### Pitfall 2: `--adopt` Silently Moves Host `/etc/keyd/default.conf` Into Repo

**What goes wrong:** `sudo stow --adopt -t / keyd` succeeds but `git status` shows `modified: keyd/etc/keyd/default.conf` — the host's keyd config (maybe with different `j+k = esc` mapping) has been moved into the repo and will be committed on next `git add`.

**Why it happens:** `--adopt` is defined to move conflicting host files into the stow directory [CITED: man stow `--adopt Warning! This behaviour is specifically intended to alter the contents of your stow directory`]; without `diff -u` preview the user never sees what was adopted.

**How to avoid:** Always run `stow --no --verbose -t / keyd` preview and `diff -u /etc/keyd/default.conf $SCRIPT_DIR/keyd/etc/keyd/default.conf` when `[[ -f /etc/keyd/default.conf && ! -L /etc/keyd/default.conf ]]` per D-06. Use plain `sudo stow -t / keyd` by default; only `--adopt` when user typed `adopt` or `gum confirm` on the dedicated adopt prompt per D-07. Document `git diff keyd/etc/keyd/default.conf` in uninstall success message.

**Warning signs:** `git status` shows `keyd/etc/keyd/default.conf` modified after keyd install.

### Pitfall 3: Dry-Run That Still Mutates the Filesystem

**What goes wrong:** `bash setup.sh --dry-run --uninstall` still runs `stow -D` or `rm -rf ~/.local/share/nvim/mason` or `pacman -Rns`, leaving system without keyd or Mason.

**Why it happens:** Forgetting `if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ..."; return 0; fi` before a mutation branch; Phase 1 pattern requires `DRY_RUN` early-return before every mutation [VERIFIED: setup.sh:273-277,300-301].

**How to avoid:** Gate every `stow -D`, `sudo stow -D -t /`, `rm -rf`, `pacman -Rns`/`apt remove`/`pkg uninstall`, `chsh`, `sudo keyd reload`, and legacy mode-file `rm -f` behind `DRY_RUN` check that prints `stow --no --verbose` preview instead. Treat `DRY_RUN` as the first condition in each `run_uninstall`/`install_keyd_privileged`/`offer_chsh` function.

**Warning signs:** `bash setup.sh --dry-run --uninstall` exits with `quarantine_scan` messages or `keyd unstowed` output.

### Pitfall 4: Server-Mode `tty1` Login Death From `zsh/.zprofile` `exec`

**What goes wrong:** User deploys in `server` mode (headless), logs in via `tty1` with Zsh as login shell, `zsh/.zprofile` runs `exec start-hyprland`, `Hyprland` binary missing or fails, `exec` replaces the shell and login session dies with no prompt.

**Why it happens:** `zsh/.zprofile:2-4` [VERIFIED: zsh/.zprofile:1-4] runs `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` unconditionally — `server` mode never installed `hyprland` via `gui_list` partitioning [VERIFIED: setup.sh:1081] but Zsh still `exec`s it.

**How to avoid:** Delete the entire `exec` block from `zsh/.zprofile` per D-10. Do NOT attempt to guard with `mode` file + `command -v Hyprland` + `|| true` — user explicitly rejected the guard (`redundent`) and D-11 says no persisted mode file. The fix is deletion, reversible via `git restore zsh/.zprofile`.

**Warning signs:** SSH works but `tty1` console login immediately returns to login prompt on server installs.

### Pitfall 5: `chsh` Prompts for Password Under `set -e` and Kills Installer, or Fails on Termux With No `/etc/shells`

**What goes wrong:** `chsh -s $(which zsh)` prompts for password in non-interactive CI, fails with `chsh: Shell not in /etc/shells`, or Termux has no `chsh` binary and installer exits non-zero; `set -e` aborts the whole script before `Setup complete` prints.

**Why it happens:** `chsh` is an OS account tool that reads `/etc/shells` [CITED: man chsh] and may require password; Termux `pkg` users have no `chsh` [ASSUMED — flagged in CONTEXT Research Flag] and `which zsh` may be `$PREFIX/bin/zsh` not in `/etc/shells`.

**How to avoid:** Gate `chsh` behind `if [[ "${FAMILY:-}" == "termux" ]] then skip` and `if ! command -v chsh; then echo "chsh not found — skipping"; return 0; fi`. Only offer when `$(which zsh) != $SHELL` and after explicit `Type 'yes'` (never `--yes` bypass). Wrap final call with `if ! chsh -s "$zsh_path"; then echo "Warning: chsh failed ..."; fi` without `set -e` kill — use `|| true` on the reload path but not on `chsh` itself so user sees the failure.

**Warning signs:** `chsh: PAM: Authentication failure` or `chsh: /data/data/com.termux/files/usr/bin/zsh not in /etc/shells`.

### Pitfall 6: `~/.config/dotfiles/mode` Ghost File Written After D-11 Forbids It

**What goes wrong:** Installer still runs `mkdir -p ~/.config/dotfiles && echo "$MODE" > ~/.config/dotfiles/mode` because `ROADMAP.md:58` still lists success criteria 3 as `zsh/.zprofile guarded by persisted ~/.config/dotfiles/mode` [VERIFIED: ROADMAP.md:58] — a pre-Phase-2 description that D-10/D-11 supersede.

**Why it happens:** Planner reads `ROADMAP.md` success criteria without cross-checking `02-CONTEXT.md D-11` which states `No persisted mode file is written or read` and `installer re-prompts mode on next install`.

**How to avoid:** Treat `02-CONTEXT.md D-11` as authoritative over `ROADMAP.md` and `REQUIREMENTS.md:28` `STOW-03` persisted-mode description. Planner must list `no-mode-file` as an explicit step and verify `grep -r "dotfiles/mode" setup.sh || echo "ok — no mode file"` in acceptance check. On uninstall, `rm -f ~/.config/dotfiles/mode` is allowed with `|| true` but must NEVER be paired with a write.

**Warning signs:** `ls ~/.config/dotfiles/mode` exists after install on `server` mode.

### Pitfall 7: Mason Artefact Path Hard-Coded Without Checking `stdpath("data")` Variant

**What goes wrong:** Installer runs `rm -rf ~/.local/share/nvim/mason` but on XDG-custom hosts `$XDG_DATA_HOME` re-routes Mason to `~/.local/share/nvim` vs `$XDG_DATA_HOME/nvim/mason`; leftover 200MB of `mason/packages` remains after uninstall and user thinks cleanup failed.

**Why it happens:** `mason-install-all.lua` uses `mr.refresh` with `stdpath("data")` implicitly [VERIFIED: nvim/.config/nvim/lua/utils/mason-install-all.lua:1-30]; `~/.local/share/nvim/mason` is the default but `XDG_DATA_HOME` override exists.

**How to avoid:** Remove via `nvim --headless -c 'echo stdpath("data")' -c qa 2>&1 | tr -d '\n'` when available, fallback to `$XDG_DATA_HOME/nvim/mason` and `~/.local/share/nvim/mason`, and also prune `$XDG_DATA_HOME/nvim/site`/`mason` with `rm -rf` only after `nvim` not in `SELECTED_PACKAGES`. Always print what was removed.

**Warning signs:** `du -sh ~/.local/share/nvim/mason` still shows size after `bash setup.sh --uninstall`.

## Code Examples

Verified patterns from official/host sources where noted; all preserve Phase 1 `set -Eeuo pipefail; shopt -s inherit_errexit` and `DRY_RUN` contracts.

### `stow -D` Reversible Uninstall (Idempotent, Repo-Preserving)

```bash
# Behavior per D-01/D-04: stow -D removes only links stow owns; repo stays intact for stow --restow recovery.
# Source: man stow -D/--delete; teardown guard teardown.zsh:165 teardown.nu:35

# Correct: directory-qualified, target-explicit, never rm -rf repo dirs
stow --dir="$SCRIPT_DIR" --target="$HOME" --delete nvim zsh starship
sudo stow --dir="$SCRIPT_DIR" --target=/ --delete keyd 2>&1 || echo "Warning: not owned — idempotent skip"

# Idempotent check before -D (avoids set -e abort on second uninstall)
if ! stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose --delete nvim 2>&1 | grep -q "would delete"; then
    echo "Note: nvim already unstowed — skipping stow -D"
else
    stow --dir="$SCRIPT_DIR" --target="$HOME" --delete nvim
fi

# NEVER:
# rm -rf "$SCRIPT_DIR/nvim"        # deletes repo package — forbidden per D-01
# rm -rf "$SCRIPT_DIR/keyd"         # same — destruction via unstow is wrong
# rm -rf ~/.local/share/nvim        # too broad — only mason subdir when nvim deselected per D-02
```

### `stow --no --verbose` Preview Before Any Mutation (Install + Privileged + Uninstall)

```bash
# Source: setup.sh:385-389 preview_selection + CONTEXT D-06 preview contract
# Preview respects folding; output goes to stderr so 2>&1 | sed is needed.

stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose nvim zsh starship 2>&1 | sed 's/^/  /'
stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd 2>&1 | sed 's/^/  /'
stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose --delete nvim 2>&1 | sed 's/^/  /'
sudo stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd 2>&1 | sed 's/^/  /' || true

# Installer must print as:
# [DRY RUN] Would run: stow --dir="$SCRIPT_DIR" --target="$HOME" --restow nvim zsh starship
# [DRY RUN] Would run: sudo stow --dir="$SCRIPT_DIR" --target=/ keyd
# [DRY RUN] Would run: sudo keyd reload
```

### Privileged `keyd` `diff -u` When Host File Is Regular File (Not Symlink)

```bash
# Source: CONTEXT D-06 regular-file check
host_conf="/etc/keyd/default.conf"
repo_conf="$SCRIPT_DIR/keyd/etc/keyd/default.conf"  # keyd/etc/keyd/default.conf → [ids]/* [main] j+k=esc [VERIFIED: keyd/etc/keyd/default.conf:1-6]

if [[ -f "$host_conf" ]] && [[ ! -L "$host_conf" ]]; then
    echo "Host $host_conf exists as regular file — diff:"
    diff -u "$host_conf" "$repo_conf" 2>&1 | head -n 100 || true  # diff exits 1 on difference — || true for set -e
elif [[ -L "$host_conf" ]]; then
    echo "Host $host_conf is already a symlink (owned by stow) — no diff needed"
else
    echo "No host $host_conf present — plain stow will create it"
fi
# Never diff when file missing — diff would print "No such file" and confuse preview.
```

### Typed `yes` Gate — Exact `yes` + `--yes` CI Bypass + `--dry-run` Preview (Ported From `teardown.zsh:165`)

```bash
# Source: teardown.zsh:165 read "REPLY?Are you sure you want to continue? Type 'yes' to confirm: " [VERIFIED: teardown.zsh:165]
#         teardown.nu:35 input "Are you sure you want to continue? Type 'yes' to confirm: " [VERIFIED: teardown.nu:35]
#         CONTEXT D-03 exact case-sensitive + --yes/dry-run semantics

require_uninstall_consent() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would prompt: Type 'yes' to confirm:"
        echo "[DRY RUN] Would run: stow -D ... + sudo stow -D -t / keyd"
        return 0  # dry-run never prompts — prints preview and returns
    fi
    if [[ "$YES" == true ]]; then
        # --yes bypasses only uninstall/privileged flows per D-03, not chsh per D-13
        return 0
    fi
    if command -v gum >/dev/null 2>&1; then
        if gum confirm "Run uninstall? This removes symlinks via stow -D."; then
            return 0
        else
            echo "Cancelled (gum)." >&2; return 1
        fi
    fi
    local reply
    printf "Type 'yes' to confirm: " >&2
    if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
    if [[ "$reply" != "yes" ]]; then
        echo "Uninstall cancelled (expected exact 'yes')." >&2; return 1
    fi
}
# Do NOT accept y/n, Y/yes, YES — only exact lowercase "yes" per D-03.
```

### `chsh` End-of-Run Offer (Explicit `yes`, Never Auto, Termux Skip)

```bash
# Source: CONTEXT D-13 07 chsh wording + zsh binary in common per setup.sh:183
# Manual pre-check: /etc/shells must contain $(which zsh) on most distros.

offer_chsh_if_needed() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: chsh -s $(command -v zsh 2>/dev/null || echo /usr/bin/zsh)"
        return 0
    fi
    # --yes does NOT bypass chsh — still prompt per D-13
    local zsh_bin shell_cur
    zsh_bin=$(command -v zsh 2>/dev/null || true)
    shell_cur="${SHELL-}"
    if [[ -z "$zsh_bin" ]]; then echo "Warning: zsh not in PATH — skipping chsh" >&2; return 0; fi
    if [[ "$zsh_bin" == "$shell_cur" ]]; then echo "Shell already $zsh_bin — skipping chsh"; return 0; fi
    if [[ "${FAMILY:-}" == "termux" ]]; then echo "Termux — chsh not applicable; skipping" >&2; return 0; fi
    if ! command -v chsh >/dev/null 2>&1; then echo "chsh not installed — skipping; run: chsh -s $zsh_bin" >&2; return 0; fi

    local reply
    printf "Change default shell to zsh? Type 'yes' to run chsh -s %s: " "$zsh_bin" >&2
    if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
    if [[ "$reply" != "yes" ]]; then echo "Skipping chsh — run manually: chsh -s $zsh_bin" >&2; return 0; fi
    if ! chsh -s "$zsh_bin"; then
        echo "Warning: chsh failed — is $zsh_bin in /etc/shells? Try: grep -q \"\$zsh_bin\" /etc/shells || echo \"\$zsh_bin\" | sudo tee -a /etc/shells" >&2
        return 1
    fi
}
```

### `keyd` Reload Least-Privilege (Never Kills Installer)

```bash
# Source: CONTEXT D-09 reload contract + keyd reload || systemctl fallback
# README.md currently shows broad sudoers shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd [VERIFIED: README.md:114]
# Phase 2 must replace with least-privilege: reload only.

# Install path:
sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || sudo systemctl restart keyd 2>/dev/null || echo "Warning: keyd reload failed — reload manually: sudo keyd reload" >&2

# Uninstall path:
sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true  # || true so failure never aborts uninstall

# README.md sudoers snippet to document (phase 2 D-09):
# shoyeb ALL=(ALL) NOPASSWD: /usr/bin/keyd reload, /usr/bin/systemctl reload keyd, /usr/bin/systemctl restart keyd
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate `teardown.zsh` + `teardown.nu` with `rm -rf "$stow_dir"` destructive directory delete [VERIFIED: teardown.zsh:149, teardown.nu:152] | Unified `bash setup.sh --uninstall` with `stow -D` + `sudo stow -D -t /` reversible, repo-preserving, idempotent | Phase 2 D-01 (this phase) | Repo stays intact; recovery via `stow --restow`; staged delete of `teardown.*` after `--uninstall` ships per D-15 |
| `zsh/.zprofile` unconditional `exec start-hyprland` on `tty1` [VERIFIED: zsh/.zprofile:1-4] killing server-mode logins | Delete the `exec` block entirely, no mode file, no guard — login never killed [VERIFIED: CONTEXT D-10/D-11] | Phase 2 D-10 (this phase) | `server` mode `tty1` login no longer dies; fix is reversible via `git restore zsh/.zprofile` |
| `README.md` `setup.zsh --stow-keyd y/n` + `keyd` manual `stow --adopt` with broad sudoers `start|stop` [VERIFIED: README.md:113-114] | `stow --no --verbose -t / keyd` + `diff -u` preview + `gum confirm→Type 'yes'` + `--adopt` only on explicit adopt confirm + `keyd reload` least-privilege `reload` sudoers [VERIFIED: CONTEXT D-06..D-09] | Phase 2 STOW-02 (this phase) | No silent host-file adoption; least-privilege `NOPASSWD: /usr/bin/keyd reload` not blanket `systemctl` |
| Installer cloning Zinit commit-pinned before `stow --restow zsh` | Zinit self-clone on first `zsh` launch via `zsh/.zshrc:138-164` inline; installer only ensures `zsh` binary before stow per D-12 [VERIFIED: zsh/.zshrc:138-164] | Phase 2 D-12 (this phase) | No duplicate clone/pin drift; shell runtime owns its plugin manager |
| Silent `chsh -s $(which zsh)` or no `chsh` at all | Offered once at very end after all writes succeed, only after explicit `Type 'yes'`; `--yes` does NOT bypass; skipped if already `zsh` or Termux per D-13 | Phase 2 D-13 (this phase) | User never locked out; Termux `chsh` absence handled gracefully |
| 4-tier `detect_family` existed in Phase 1 but `setup.sh:140-141` Termux check `if [[ -n "${TERMUX_VERSION-}" ]] || [[ "${PREFIX-}" == *"com.termux"* ]]` [VERIFIED: setup.sh:140-141] now also needs to skip `chsh` + privileged `keyd` explicitly | Reuse same 4-tier detection to gate `chsh` and `keyd`; extend docs to note `chsh` unavailable on Termux | Phase 2 + Termux research flag | Termux `local`/`server` installs remain safe and prompt-free for privileged steps |

**Deprecated/outdated:**

- `setup.nu` / `setup.zsh` deleted in Phase 1 (no shims) — do NOT reintroduce Nushell/Zsh bootstrap shims; `teardown.*` survive until Phase 2 `--uninstall` ships, then staged delete atomically with docs per D-15.
- `nvim/README.md` absent (deleted pre-Phase-1) — recreate only if it reappears per D-14; do NOT block Phase 2 on it.
- `~/.config/dotfiles/mode` persisted mode file — deprecated after `zsh/.zprofile` deletion per D-11; any `ROADMAP.md:58` success-criteria reference to it is superseded by CONTEXT.md D-10/D-11.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Termux has no `chsh` binary and `chsh -s $(which zsh)` would fail or `PREFIX`-zsh not in `/etc/shells` [ASSUMED — flagged for research in CONTEXT Research Flag, not verified this session on Termux device] | Architecture Patterns / Code Examples / Pitfall 5 | Installer would exit non-zero on Termux when offering `chsh`; mitigation is `FAMILY==termux` early skip with message — planner must add Termux `chsh` skip explicitly |
| A2 | Termux extra "login shell" prompt after `zsh/.zprofile` change is related to `zsh -l` / `login` flag or `proot`/`PREFIX` detection, not to `chsh` [ASSUMED — research flag candidate `$-` vs `$0` vs `login`, not verified on device] | Open Questions / Hyprland Removal | Extra prompt remains after `zsh/.zprofile` emptying; planner should timebox a 30-min spike probing `zsh/.zprofile` `login` detection and `TERMUX_VERSION` handling but not block `02-01` on it |
| A3 | `SELECTED_PACKAGES` vs `SELECTED_DEPS` split already tracks installed system packages for removal offer — `get_deps` filtered via `SELECTED_DEPS` [VERIFIED: setup.sh:177-242 `filter_deps_by_selection`] can be reused to enumerate removal candidates without persisting an install log | Uninstall / D-05 | If `SELECTED_DEPS` filtering misses non-toolchain GUI extras (`hyprland`/`waybar` etc. which bypass toolchain filter per `get_deps:200-221`), offer may omit GUI deps; planner should include both `SELECTED_PACKAGES`→keyd mapping and `SELECTED_DEPS` for toolchain removal |
| A4 | `sudo keyd reload` is available on Arch (keyd provides `keyd reload`) and `systemctl reload keyd` on Debian systemd [ASSUMED — not probed this session; systemctl present on Ubuntu host [VERIFIED: bash probe shows systemd], but keyd binary not installed] | Standard Stack / Code Examples | Reload might fail even via fallback; safe because `|| true` prevents installer abort — warning message suffices |

**If this table is empty:** N/A — 4 assumptions above need planner + review acknowledgement; A1/A2 are Termux-specific and safe to handle with skip guards.

## Open Questions

1. **Termux extra login-shell prompt — root cause and fix scope**
   - What we know: User flagged `termux asks an extra login shell prompt which needs to be researched`; `setup.sh:140-141` detects Termux via `TERMUX_VERSION`/`PREFIX` [VERIFIED: setup.sh:140-141]; `zsh/.zprofile` currently has only Hyprland `exec` [VERIFIED: zsh/.zprofile:1-4] and will be empty after Phase 2; `zsh/.zshrc:138-164` self-clones Zinit with `git clone` on first launch [VERIFIED: zsh/.zshrc:138-164].
   - What's unclear: Whether the extra prompt is `zsh` `login` shell detection (`$-` contains `l`, `$0` starts with `-`), `Termux` `$PREFIX/bin/login` invocation, `proot` environment, `chsh` on Termux being missing and falling back to `/system/bin/sh`, or `zsh/.zprofile` vs `zsh/.zshrc` ordering.
   - Recommendation: Timebox 30-min spike probing `zsh -l` vs `zsh -i`, `echo $- $0 $TERMUX_VERSION $PREFIX`, and `cat /etc/shells` on real Termux; add `FAMILY==termux` skip for `chsh` and privileged `keyd` regardless, and leave `zsh/.zprofile` deletion as Phase 2 ship — do not block `02-01` on Termux login-shell spike, file as follow-up research spike in `02-02` or backlog.

2. **Mason artefact removal breadth — `mason` only vs `mason` + `site` + `state` + `cache`**
   - What we know: `~/.local/share/nvim/mason` is the primary store [VERIFIED: bash probe `ls ~/.local/share/nvim/mason`]; `~/.local/share/nvim` also contains `lazy site telescope_history` [VERIFIED: bash probe `ls ~/.local/share/nvim`]; `nvim/.config/nvim/lua/utils/mason-install-all.lua` uses `mr.refresh` [VERIFIED: mason-install-all.lua:1-30].
   - What's unclear: Whether `site`/`state`/`cache` under `stdpath("data")` should also be pruned when `nvim` deselected, or only `mason`; D-02 says "`~/.local/share/nvim/mason` (and related state/cache if present)" — vague on which dirs qualify as "related".
   - Recommendation: Plan specifies `rm -rf ~/.local/share/nvim/mason` plus optional `rm -rf ~/.local/share/nvim/site` only when `nvim` not in `SELECTED_PACKAGES` and only after explicit confirmation; `state`/`cache` under `~/.local/state/nvim` should be left alone unless user opted full uninstall (`--uninstall` with no checklist filter).

3. **System package removal scope — do we offer to remove GUI deps (`hyprland`/`waybar`) that were never in `SELECTED_DEPS`?**
   - What we know: `get_deps` bypasses `SELECTED_DEPS` filter for non-toolchain GUI extras [VERIFIED: setup.sh:207-215]; `SELECTED_DEPS` only tracks 13 toolchain packages [VERIFIED: setup.sh:23 `ALL_TOOLCHAIN`] while GUI list is 7–8 packages [VERIFIED: setup.sh:185-189].
   - What's unclear: D-05 verbatim "offer to remove all the packages ... all the packages that were installed with setup" — does "all" include GUI deps auto-installed via `mode==local` even when not in `SELECTED_DEPS`?
   - Recommendation: Planner should offer both: `SELECTED_DEPS` candidates for toolchain (`make gcc fzf zsh stow ...`) and, when `MODE==local`, also list `gui_list` packages that were installed (reconstitute via `get_deps` with current `FAMILY`/`MODE` and `SELECTED_PACKAGES` containing `alacritty`/`wofi` etc.). Gate the whole offer behind the same `yes` guard and `DRY_RUN` preview; never auto-remove.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | Unified installer core | ✓ | `5.2.21(1)-release` [VERIFIED: bash --version] | — (required; abort with `if [ -z "${BASH_VERSION-}" ]` guidance [VERIFIED: setup.sh:2]) |
| `GNU Stow` | `stow --restow`/`-D`/`--no --verbose` deploy | ✓ | `2.3.1` [VERIFIED: stow --version] (need `≥2.4.1` — installer upgrades via `sort -V` [VERIFIED: setup.sh:1094]) | Installer queues `stow` via same family manager lock [VERIFIED: setup.sh:1106-1109] |
| `zsh` | `stow zsh` + `chsh -s $(which zsh)` | ✓ | `5.9` [VERIFIED: zsh --version] | `verify → install → re-verify` via `common` [VERIFIED: setup.sh:183] |
| `git` | Zinit self-clone in `zsh/.zshrc` [VERIFIED: zsh/.zshrc:144-146] | ✓ | host git present | — (zsh launch handles clone lazily) |
| `pacman` | Arch-family installs (`pacman -S --needed`, `pacman -Rns`) | ✗ (Ubuntu host) | — | `detect_family` maps to `apt` on this host [VERIFIED: setup.sh:169-170] |
| `apt` | Debian-family installs/removals | ✓ | `2.8.3` [VERIFIED: apt --version] | `pacman` vs `apt` vs `pkg` per `detect_family` |
| `pkg` | Termux installs (`pkg install`, `pkg uninstall`) | ✗ (not Termux) | — | Only on `FAMILY==termux` via `TERMUX_VERSION`/`PREFIX` [VERIFIED: setup.sh:140-141] |
| `gum` | `gum confirm` privileged/uninstall ladder primary | ✗ | — [VERIFIED: `which gum` not found] | `whiptail→dialog→fzf→read` then `Type 'yes'` fallback [VERIFIED: setup.sh:486-773] |
| `chsh` | `chsh -s $(which zsh)` offer | ✓ | `util-linux chsh` with `-s` [VERIFIED: chsh --help] | Skip with message when `FAMILY==termux` or `! command -v chsh` or `zsh == $SHELL` per D-13 |
| `keyd` / `sudo keyd reload` | Privileged `keyd` reload | ?/✓ (not probed; `keyd reload` not verified on this Ubuntu host) | — | `sudo systemctl reload keyd` / `restart keyd` with `|| true` per D-09 |
| `diff` | `diff -u` keyd preview | ✓ | GNU diffutils (present) | `diff` fallback: `stow --no` preview only, warn that diff unavailable |

**Missing dependencies with no fallback:**
- None — every Phase 2 dependency has a documented fallback (gum→yes, keyd reload→systemctl→warn, chsh→skip on Termux/missing).

**Missing dependencies with fallback:**
- `gum` missing → `Type 'yes'` fallback per D-08.
- `keyd` binary missing → `sudo systemctl reload keyd || true` and manual hint.
- `chsh` missing or Termux → skip with `run manually: chsh -s $(which zsh)` message per D-13.

## Security Domain

> `security_enforcement: true` [VERIFIED: .planning/config.json:47 `security_enforcement: true`], `security_asvs_level: 1` [VERIFIED: .planning/config.json:48], `security_block_on: high` [VERIFIED: .planning/config.json:49]. `workflow.nyquist_validation: false` so Validation Architecture section omitted [VERIFIED: .planning/config.json:24].

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (no user auth; `chsh` uses PAM but installer never stores credentials) |
| V3 Session Management | no | — (stateless dotfiles, no sessions) |
| V4 Access Control | yes | `sudo` least-privilege for `keyd reload` / `systemctl reload keyd` / `stow -t /` — document `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/keyd reload, /usr/bin/systemctl reload keyd` not blanket `start|stop` per D-09 |
| V5 Input Validation | yes | `${1-}` guards + `case --help` pre-scan before `set -u` [VERIFIED: setup.sh:52-58], safe `grep` parse of `/etc/os-release` without sourcing [VERIFIED: setup.sh:152-154], safe `xargs -n1` checklist parse without `eval` [VERIFIED: setup.sh:572-580] |
| V6 Cryptography | no | — |
| V7 Error Handling | yes | `set -Eeuo pipefail; shopt -s inherit_errexit` [VERIFIED: setup.sh:3-4] + `|| true` on `diff -u` (exits 1 on diff) and `keyd reload` so session never killed |
| V8 Data Protection | no | — (no secrets in Phase 2; `MISTRAL_API_KEY` hygiene deferred per scope) |
| V10 Malicious Code | yes | `keyd/etc/keyd/default.conf` integrity via `diff -u` preview before `/etc` write — never `--adopt` without explicit adopt confirm per D-07; `zsh/.zshrc:144-146` `git clone https://github.com/zdharma-continuum/zinit` is HTTPS but unverified — leave self-clone to shell runtime, do not add installer pin per D-12 |
| V14 Configuration | yes | Outside-repo-root guard `[[ -f "$SCRIPT_DIR/setup.sh" ]] && [[ -f ./setup.sh ]]` aborts `run-from-clone` before any write [VERIFIED: setup.sh:1038-1045]; `.stow-conflicts/` gitignored [VERIFIED: .gitignore:14]; `.gitignore` quarantine never auto-deleted per D-04 |

### Known Threat Patterns for Bash + Stow + Privileged keyd Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent `--adopt` moves host `/etc/keyd/default.conf` into repo → host key-remap lost, repo commit polluted | Tampering | `stow --no --verbose -t / keyd` + `diff -u` preview when `[[ -f ... && ! -L ... ]]` then `gum confirm→Type 'yes'` and only `--adopt` on explicit adopt prompt [VERIFIED: CONTEXT D-06/D-07/D-08] |
| `/etc/os-release` sourcing injects code via `ID="$(rm -rf ~)"` | Tampering | `grep -E '^ID='` + `cut -d= -f2-` + `tr -d '"'` + `xargs` safe parse without sourcing [VERIFIED: setup.sh:152-154] |
| Checklist output `eval "$(whiptail ...)"` executes arbitrary `"; rm -rf ~; "` | Tampering | `mapfile -t parsed < <(printf '%s' "$sel" \| xargs -n1)` without `eval` [VERIFIED: setup.sh:572-580] |
| `chsh` PAM bypass or auto-run locks user out of login shell | Elevation | Never auto-run; offer only after explicit `Type 'yes'` at end-of-run, skip if `which zsh == $SHELL` or `FAMILY==termux` or `! command -v chsh`, `--yes` does NOT bypass per D-13 |
| Broad sudoers `NOPASSWD: /usr/bin/systemctl start keyd, stop keyd` widens privilege | Elevation | Document least-privilege `NOPASSWD: /usr/bin/keyd reload, /usr/bin/systemctl reload keyd` (and `restart` only if needed) per D-09, not blanket `systemctl` |
| `keyd reload` failure kills installer under `set -e` and leaves session without input handling | Denial | `sudo keyd reload 2>/dev/null \|\| sudo systemctl reload keyd 2>/dev/null \|\| true` so failure never aborts installer per D-09 |
| Double uninstall `stow -D` on already-removed symlink aborts via `set -e` | Denial | Wrap `stow -D` with `if ! stow ...; then echo "Warning: already unstowed — continuing"` and treat as idempotent per D-04 |
| `diff -u` exits `1` on difference → `set -e` aborts before confirmation prompt | Denial | Pipe `diff ... || true` so non-zero diff does not kill script |

## Sources

### Primary (HIGH confidence)
- `setup.sh` (1162 lines) read this session — strict header [VERIFIED: setup.sh:3-4], `ALL_PACKAGES`/`ALL_TOOLCHAIN`/`TERMUX_DISABLED_PACKAGES` [VERIFIED: setup.sh:19-23], `detect_family` [VERIFIED: setup.sh:139-175], `get_deps`/`filter_deps_by_selection`/`verify_deps`/`install_deps`/`reverify_deps` [VERIFIED: setup.sh:177-337], `quarantine_scan` [VERIFIED: setup.sh:393-440], `post_verify`/`assert_linked` [VERIFIED: setup.sh:442-473], `run_stow` keyd skip [VERIFIED: setup.sh:385,475-482], `checklist_*` ladder [VERIFIED: setup.sh:486-773], `main` outside-root guard [VERIFIED: setup.sh:1038-1045], `--uninstall` deferred notice [VERIFIED: setup.sh:106-110]
- `zsh/.zprofile` [VERIFIED: zsh/.zprofile:1-4] — `exec start-hyprland` block to delete
- `zsh/.zshrc` [VERIFIED: zsh/.zshrc:138-164] — Zinit self-clone inline, no installer pin needed
- `teardown.zsh` [VERIFIED: teardown.zsh:165] — `Type 'yes' to confirm` exact wording + `rm -rf` destructive pattern to NOT replicate
- `teardown.nu` [VERIFIED: teardown.nu:35] — Nushell `Type 'yes'` guard
- `keyd/etc/keyd/default.conf` [VERIFIED: keyd/etc/keyd/default.conf:1-6] — `[ids]/*` `[main] j+k=esc`
- `.gitignore` [VERIFIED: .gitignore:14] — `.stow-conflicts/` gitignored
- `README.md` [VERIFIED: README.md:9-17,108-114] — Zsh default table, keyd preview/sudoers snippet placeholder
- `REQUIREMENTS.md` Phase 2 block [VERIFIED: REQUIREMENTS.md:14,27-28,32,47] — INST-03/STOW-02/STOW-03/SHEL-01/DOCS-01 definitions + Out of Scope no-custom-Stow/no-blind-adopt
- `ROADMAP.md` Phase 2 section [VERIFIED: ROADMAP.md:48-67] — 5 success criteria + 02-01/02-02 split
- Host probes this session: `bash 5.2.21`, `zsh 5.9`, `stow 2.3.1`, `apt 2.8.3`, `which gum` absent, `ls ~/.local/share/nvim/mason`, `chsh --help`, `man stow --no/--verbose/--adopt/-D`

### Secondary (MEDIUM confidence)
- `https://www.gnu.org/software/stow/manual/stow.html` — `stow --no/--verbose/--adopt/-D` semantics (stow installed host matches manual) [CITED: GNU Stow manual]
- `https://man7.org/linux/man-pages/man1/chsh.1.html` — `chsh -s/--shell SHELL` + `/etc/shells` requirement [CITED: man chsh via `chsh --help` host probe]
- `.planning/ROADMAP.md:58` vs `.planning/phases/02-safe-reversible-server-safe-deployment/02-CONTEXT.md:D-11` — mode-file criteria superseded (D-11 authoritative) [VERIFIED: both files read this session]

### Tertiary (LOW confidence)
- Termux `chsh` absence and `PREFIX` login-shell prompt behavior [ASSUMED] — not verified on Termux device; inferred from `setup.sh:140-141` Termux detection and CONTEXT research flag; planner must gate `chsh` on `FAMILY==termux` and timebox spike
- `sudo keyd reload` availability across distros [ASSUMED] — not probed on host without `keyd` installed; mitigated with `|| systemctl reload || true` fallback

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every core tool version probed this session (`bash`, `stow`, `zsh`, `apt`, `chsh`, `gum` absent) and in-repo `setup.sh`/`zsh/.zshrc`/`zsh/.zprofile`/`keyd` read line-exact
- Architecture: HIGH — 4-tier `detect_family`, `quarantine_scan`, `post_verify`, and `--help` pre-scan patterns reused verbatim from `setup.sh:52-58,139-175,393-473`
- Pitfalls: HIGH — 6 of 7 pitfalls anchored to in-repo `[VERIFIED: path:line]` citations; 1 Termux-related pitfall marked [ASSUMED] with explicit skip guard

**Research date:** 2026-09-11
**Valid until:** 2026-09-30 (Phase 2 is Bash/Stow/host-tooling stable; re-verify if `stow` upgrades to ≥2.4.1 or `zsh/.zshrc` Zinit path changes)
