# Phase 2: Safe, Reversible & Server-Safe Deployment - Context

**Gathered:** 2026-09-11
**Status:** Ready for planning

## Phase Boundary

Deployment is safely previewable, overridable, and cleanly reversible; privileged and server-mode writes never surprise the user. Phase 2 delivers `bash setup.sh --uninstall/--remove` (stow -D + privileged keyd cleanup + Mason/prune + system-deps offer, typed `yes` gated), a safe privileged `keyd` gate (`stow --no --verbose -t /` preview + `diff -u` + `--adopt` only after explicit confirm), removal of the `zsh/.zprofile` Hyprland tty1 auto-exec (no persisted mode file), Zsh self-provision via self-cloning Zinit (no installer pin) + end-of-run `chsh` offer, and docs flipped to `Default: Zsh | Backup: Nushell`. Phase 1's universal `setup.sh` spine, Termux-aware deps, and quarantine/post-verify patterns are locked and not re-asked. Shell fzf/PATH/local overrides (SHEL-02/03/04, THEM-01, EDIT-04) are Phase 3; Mason auto-install/which-key/self-test gates are Phase 4.

## Implementation Decisions

### Uninstall & cleanup scope (INST-03)

- **D-01:** `bash setup.sh --uninstall` / `--remove` does `stow -D <pkg>` for selected pkgs + `sudo stow -D -t / keyd` when keyd was selected; never `rm -rf` repo package directories. — **Reversibility:** reversible — repo stays intact (recoverable via `stow --restow`); mirrors Phase 1 D-03 no-shims via git history
- **D-02:** When `nvim` is not selected at uninstall time (previously stowed but now deselected, or full uninstall), remove Mason artefacts `~/.local/share/nvim/mason` (and related state/cache if present). Otherwise leave Mason intact — matches SUCCESS #1 "Mason artefacts are cleaned when Neovim was deselected"
- **D-03:** Typed guard is exact case-sensitive `Type 'yes' to confirm:`; `--yes` bypasses the prompt for CI only for uninstall/privileged flows; `--dry-run --uninstall` prints `[DRY RUN] Would run: stow -D ...` and `sudo stow -D -t / --no --verbose` without touching filesystem — consistent with Phase 1 D-08 `--help` wins and `DRY_RUN` early-return before every mutation
- **D-04:** Second `bash setup.sh --uninstall` and re-install after uninstall are idempotent safe no-ops (check `test -L` before `stow -D`; skip missing targets with warning, not error). `.stow-conflicts/<timestamp>/` quarantine is never auto-deleted on uninstall — remains as safety backup (Phase 1 D-13/D-14). No persisted mode file exists after Hyprland decision (D-10/D-11), so uninstall has no `~/.config/dotfiles/mode` to clear; if a legacy file exists from a pre-Phase-2 install, remove it on full uninstall with no error if absent
- **D-05:** Uninstall must offer to remove **all** system packages that `setup.sh` installed during the verify→install→re-verify lock — not only stow-config-related pkgs. User verbatim twice: "it should offer to remove all the packages not only stow config related ones, all the packages that were installed with setup". Implementation: list the `SELECTED_DEPS` / toolchain packages that were installed via `pacman -S --needed` / `apt install -y` / `pkg install` and offer `pacman -Rns` / `apt remove -y` / `pkg uninstall` only after the same `yes` guard (gum confirm → `Type 'yes'` fallback), with `--dry-run` preview `[DRY RUN] Would run: sudo pacman -Rns ...`. Never auto-remove without explicit confirmation

### Privileged keyd safety gate (STOW-02)

- **D-06:** Every `keyd` install shows preview before any `/etc` write: run `stow --no --verbose -t / keyd` (or `stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd`) and if `/etc/keyd/default.conf` exists and is a regular file (not a symlink), also print `diff -u /etc/keyd/default.conf $SCRIPT_DIR/keyd/etc/keyd/default.conf`. Shown in both normal runs (before the confirmation) and as `[DRY RUN] Would run: sudo stow ...` + diff preview when `--dry-run`
- **D-07:** Only use `sudo stow --adopt -t / keyd` when a conflict file exists as a regular file AND the user explicitly confirms the privileged adopt path; otherwise use plain `sudo stow -t / keyd`. Never force `--adopt` without confirmation; never silently move host file into repo — matches CONCERNS.md `keyd --adopt` risk (D-13 quarantine elsewhere is `mv` only, never `--adopt` unless confirmed)
- **D-08:** Confirmation ladder for privileged `/etc` writes is `gum confirm` primary → `Type 'yes'` fallback (case-sensitive `Type 'yes' to confirm privileged keyd install:`), same ladder as uninstall guard. `--yes` bypasses the prompt for CI (consistent with D-03). On plain `read` fallback, do not accept `y/n`
- **D-09:** After successful privileged stow, run `sudo keyd reload` (or `sudo systemctl reload keyd` / `restart keyd` with `|| true` so failure never kills session) and document least-privilege sudoers in `README.md` (e.g., `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload keyd, /usr/bin/keyd reload`), not blanket `systemctl start|stop`. Dry-run prints `[DRY RUN] Would run: sudo keyd reload`

### Hyprland server guard (STOW-03) — removed

- **D-10:** Remove the `exec start-hyprland` block from `zsh/.zprofile` entirely — no `tty1` auto-start. Current `zsh/.zprofile:2-4` `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` is deleted. User verbatim: "no need for that remove that i no longer use tty login so that is redundent" — session death on server-mode tty1 (CONCERNS.md) is fixed by deletion, not by guard. — **Reversibility:** reversible — block recoverable via git history; no migration needed
- **D-11:** No persisted mode file is written or read. Earlier SUCCESS criteria required `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true`; with the `exec` removed, persistence is unnecessary. Intermediate discussion considered `repo-root` gitignored mode file ("it should create in repo root and it should be gitignored") but final decision is **no file** — installer re-prompts `mode` on next install without relying on persisted state; if a legacy `~/.config/dotfiles/mode` exists, uninstall may remove it (D-04) but no code reads it

### Zsh self-provision & docs canon (SHEL-01, DOCS-01)

- **D-12:** Installer does **not** clone Zinit; Zinit self-clones on first `zsh` shell launch via `zsh/.zshrc` (`zdharma-continuum/zinit` inline clone if `~/.local/share/zinit/zinit.git` missing). No commit pinning required. User verbatim: "no need to clone anything, zinnit clones itself on first zsh shell launch also no need for pinning". `zsh` binary itself is still ensured via deps `verify → install → re-verify` (already in `common` per Phase 1 `make`+`gcc`+`fzf`+`zsh` decision) before `stow --restow zsh`. Research note: Termux extra login shell prompt (extra `login shell` question on Termux) needs to be researched — candidate for Phase 2 research spike, not a blocking decision here
- **D-13:** `chsh -s $(which zsh)` is offered once, at the very end after all `stow` + `quarantine_scan` + `post_verify` succeed, and only after explicit confirmation. Prompt wording: `Change default shell to zsh? Type 'yes' to run chsh -s $(which zsh)` (case-sensitive `yes`). Never auto-run `chsh`; `--yes` does **not** bypass `chsh` (still requires explicit `yes`); `--dry-run` prints `[DRY RUN] Would run: chsh -s $(which zsh)`; if `$(which zsh)` == `$SHELL`, skip prompt entirely. User verbatim: "offer after stow at the ned when everything is setted up."
- **D-14:** Docs full flip, keep backup column — **Reversibility:** costly — touches README, setup.sh comments, zsh headers, AGENTS.md. Update `README.md` shell-path table to `Default: Zsh | Backup: Nushell`, quick-start primary example to `bash setup.sh --mode local` / `bash setup.sh --mode local --dry-run` and `bash setup.sh --mode server --shell zsh --dry-run`, manual section to `stow --dir=. --target="$HOME" --restow nvim zsh starship` (core) vs `nvim nushell starship` (backup), GUI to `nvim zsh starship alacritty wofi`; update `setup.sh` header `usage()` comments and `zsh/.zshrc` header/inline comments to reflect Zsh default; update `AGENTS.md` if it contains shell guidance; `nvim/README.md` is currently absent (deleted pre-Phase-1) — recreate/update only if it reappears. Keep Nushell as backup column/examples, do not delete Nushell mentions
- **D-15:** Keep `teardown.zsh` / `teardown.nu` fallback mentions in docs until `bash setup.sh --uninstall` ships, then staged delete them and atomically fix docs — same pattern as Phase 1 D-02 staged delete (`setup.nu`/`setup.zsh` deleted in Phase 1, `teardown.*` survive until Phase 2). During Phase 2 transition, docs note `Use teardown scripts for now: bash teardown.zsh --help / nu teardown.nu --help` (already in `setup.sh:107-110`); final Phase 2 commit deletes `teardown.*` and removes mentions

### Agent's Discretion

None — every presented option was decided by the user (including two explicit overrides: uninstall to remove ALL installed deps, and Hyprland exec removal). No "You decide" selections.

### Research Flag

- **Termux extra login shell prompt** — installer triggers an extra "login shell" prompt on Termux that needs investigation before planning. Downstream researcher should probe `zsh/.zprofile` / `zsh/.zshrc` login-shell detection (`$-` vs `$0` vs `login` flag) and Termux `$PREFIX` / `TERMUX_VERSION` handling; candidates include `zsh -l` invocation, `proot`/`login` shell mismatch, or `chsh` on Termux (`pkg` users have no `chsh`). See `setup.sh:140-143` Termux family detection and `zsh/.zprofile` (now empty after D-10).

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + requirements (locked scope)
- `.planning/ROADMAP.md` Phase 2 section — goal "safely previewable, overridable, and cleanly reversible", 5 success criteria (uninstall `yes`+`stow -D`+Mason+idempotence, keyd preview+diff+adopt gate+reload, Hyprland guard, Zsh provision+Zinit+chsh, docs Zsh-default flip), and the two-plan split (02-01 reversible uninstall + privileged keyd gate + Hyprland guard, 02-02 Zsh self-provision + docs canon) that bounds this phase
- `.planning/REQUIREMENTS.md` §§ Installer (INST-03 unified Bash removal with `stow -D`+`sudo stow -D -t / keyd`+Mason cleanup when nvim deselected, `yes`+`--yes`), Stow (STOW-02 privileged keyd preview+diff+gum/Type-yes+adopt gating+least-privilege, STOW-03 Hyprland server guard), Shell (SHEL-01 Zsh provision before stow, Zinit commit-pinned, `chsh` explicit confirm only), Docs (DOCS-01 README+zsh/starship manual `stow --restow nvim zsh starship` vs `nvim nushell starship`, `nvim/README.md`, in-code comments, `AGENTS.md`) — the 5 Phase 2 requirements; Out-of-Scope table (no custom `ln -sf` engine, no blind `--adopt`, no chemoi/yadm) constrains solution space
- `.planning/PROJECT.md` — Core Value, Constraints (Bash, Zsh-default, `ID_LIKE` + manager probing, reversibility, safety, no destructive writes without preview/confirmation), and Key Decisions table (mode → shell → checklist flow, Unified Bash `setup.sh`, quarantine pattern)

### Prior context (carry-forward)
- `.planning/phases/01-universal-installer-platform-foundations/01-CONTEXT.md` — D-01..D-16 locked (canonical entry `setup.sh`, staged delete setups now/teardowns later D-02, no shims D-03, atomic docs fix D-04, TTY vs no-TTY invocation D-05..D-08 with `${1-}` guards, 7-package toggleable checklist D-09 with `gum→whiptail→dialog→fzf→read` ladder D-09..D-12 Termux disabled-row, quarantine to `.stow-conflicts/<timestamp>/`+`MANIFEST` D-13/D-14, auto-upgrade `stow <2.4.1` D-15, strict `test -L`+`readlink -f` post-verify D-16) — researcher must reuse these patterns verbatim for Phase 2 writes

### Existing implementation to reuse (logic source, not to preserve)
- `setup.sh` (1162 lines, Phase 1 complete) — `parse_args` strict-mode header `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards, `detect_family` 4-tier (Termux env/pkg → manager → `ID_LIKE` tokens → `ID` → manager fallback) with `OS_RELEASE_FILE` seam, `verify_deps`/`reverify_deps` partition `core_missing` vs `gui_missing` + `sort -V` stow version check, `verify→install→re-verify` lock, `prompt_checklist`/`prompt_toolchain_checklist` 5-backend ladder, `quarantine_scan` `mv` to `.stow-conflicts/<ts>/MANIFEST`, `stow --dir="$SCRIPT_DIR" --target` + `--no --verbose` preview, folding-aware `post_verify`, outside-repo-root guard, current `keyd` skip notice `// Phase 2 — no /etc writes in Phase 1` at `setup.sh:385,404,460,478`
- `teardown.zsh` + `teardown.nu` — `Type 'yes'` confirmation guard (`read "REPLY?Type 'yes' to confirm: "` / `input "Type 'yes' to confirm: "`), `stow -D` + `sudo stow -D -t / keyd`, `delete_stow_directory` `rm -rf` (Phase 2 must NOT replicate deletion, use D-01), kept until Phase 2 ships `--uninstall` per D-02
- `zsh/.zprofile` — currently 4 lines unconditional `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` (Phase 2 deletes per D-10)
- `zsh/.zshrc` — Zinit bootstrap `if [[ ! -f ~/.local/share/zinit/zinit.git ]]; then git clone https://github.com/zdharma-continuum/zinit ...` inline (Phase 2 leaves self-clone per D-12, no pin), `fzf`/`zsh-autocomplete` conflict deferred to Phase 3
- `README.md` — current manual `stow --restow` sections and shell-path table `Zsh (Default) | Nushell (Backup)` already partially flipped in Phase 1 but needs Phase 2 full flip per D-14; keyd section `Phase 2` preview/sudoers snippet is placeholder for D-09
- `keyd/etc/keyd/default.conf` — privileged target for `stow -t / keyd`; single file `[ids]/*` + `[main] j+k=esc`

### Codebase maps (scouted 2026-09-10, refreshed)
- `.planning/codebase/CONCERNS.md` — `keyd --adopt` risk (no explicit conflict check, widened sudoers), `zsh/.zprofile` unconditional Hyprland exec killing server login, `setup.sh` keyd skip Phase 1 (no /etc writes), and test gaps (stow symlink correctness, privileged path) Phase 2 directly answers
- `.planning/codebase/ARCHITECTURE.md` — Stow data-flow `get-distro → get-deps → verify → install → run-stow`, stow-package bounded contexts (`nvim/` `zsh/` `keyd/`), `keyd -t /` privilege note
- `.planning/codebase/STACK.md` — core dep set (`stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `node`/`npm`) + GUI extras, `make`+`gcc` toolchain requirement, `stow ≥2.4.1` expectation vs installed 2.3.1
- `.planning/codebase/CONVENTIONS.md` / `STRUCTURE.md` / `TESTING.md` — naming, session patterns, and test seams (reuse `OS_RELEASE_FILE`, `DRY_RUN` early-return before every mutation)

### User-referenced / verbatim specifics needing file checks
- User verbatim uninstall: "it should also delete the packages it installed" + "it should offer to remove all the packages not only stow config related ones, all the packages that were installed with setup" — D-05 above
- User verbatim Hyprland: "no need for that remove that i no longer use tty login so that is redundent" — D-10/D-11
- User verbatim Zinit: "no need to clone anything, zinnit clones itself on first zsh shell launch also no need for pinning" — D-12
- User verbatim chsh: "offer after stow at the ned when everything is setted up." — D-13

## Existing Code Insights

### Reusable Assets
- `setup.sh:detect_family` (Termux env/pkg → manager → `ID_LIKE` space-split → `ID` → manager fallback) + `get_deps`/`filter_deps_by_selection`/`verify_deps`/`reverify_deps` partition + `install_deps` per-family `pacman -S --needed`/`apt install -y`/`pkg install` (no sudo on Termux) — extend to offer `pacman -Rns`/`apt remove -y`/`pkg uninstall` on `--uninstall` (D-05) reusing same family tables and `SELECTED_DEPS` filtering
- `setup.sh:quarantine_scan` (`mv` to `.stow-conflicts/<ts>/` preserving relative paths, `MANIFEST`, gitignored, never delete per D-13) — reuse unwrapped; uninstall `stow -D` already idempotent so no quarantine needed on removal, but keep warning on conflict
- `setup.sh:run_stow`/`post_verify` (`stow --dir="$SCRIPT_DIR" --restow` + `stow --dir="$SCRIPT_DIR" --target=/ --no --verbose` preview + `test -L` + `readlink -f` folding-aware prefix check over `~/.config/nvim` and `~/.config/starship.toml`) — reuse for both install and `stow -D --no --verbose` preview on uninstall/dry-run (D-03/D-06)
- `teardown.zsh:main` + `teardown.nu:main` typed `Type 'yes' to confirm` guard with `--dry-run` early `print "=== DRY RUN MODE ==="` — port exact wording/casing to `setup.sh --uninstall` (D-03/D-08) and `gum confirm` → fallback ladder
- `setup.sh` checklist ladder `gum→whiptail→dialog→fzf→read` with Termux disabled-row emulation and `cancel never cascades` contract (Phase 1 D-09..D-12) — reuse for privileged keyd `gum confirm` prompt (D-08)

### Established Patterns
- `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards + pre-scan `for arg in "$@"; do case "$arg" in --help)` wins (Phase 1 D-08) — mandatory for new `--uninstall`/`--remove` parsing; `main` must `parse_args` before `SCRIPT_DIR` guards so `--help` never triggers `unbound variable`
- `DRY_RUN` early-return before every filesystem mutation, including `pacman`/`apt`/`pkg` installs, `stow`, privileged `sudo stow -t /`, `keyd reload`, and `chsh` — preview prefix `[DRY RUN] Would run:` + `stow --no --verbose` (Phase 1 pattern) must cover uninstall and keyd flows per D-03/D-06/D-09/D-13
- Outside-repo-root guard `[[ -f "$SCRIPT_DIR/setup.sh" ]] && [[ -f ./setup.sh ]]` else abort `run-from-clone` before any prompt or write — applies to both install and uninstall

### Integration Points
- `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow nvim zsh starship ...` and `stow --dir="$SCRIPT_DIR" --target=/ --restow keyd` (privileged) / `stow -D` / `stow --no --verbose` preview — installer toggles via `SELECTED_PACKAGES` (7 individually toggleable, Termux disabled rows for `keyd`/`alacritty`/`wofi` per Phase 1 D-12)
- Platform package managers: `pacman -S --needed`/`apt install -y`/`pkg install` for install, `pacman -Rns`/`apt remove -y`/`pkg uninstall` for uninstall offer (D-05); `stow` self-upgrade via same `sort -V` lock before any stow
- Interactive ladder `gum→whiptail→dialog→fzf→read` for mode/shell/checklist prompts; `--dry-run` prints `stow --no --verbose` output for the exact post-checklist selection; privileged keyd prompt reuses `gum confirm` → `Type 'yes'` fallback per D-08
- `zsh/.zprofile` — Phase 2 deletes the Hyprland exec block entirely; no `~/.config/dotfiles/mode` file is read or written (D-10/D-11)
- `zsh/.zshrc` — Phase 2 leaves Zinit inline self-clone untouched; installer only ensures `zsh` binary present before stow

## Specific Ideas

- Uninstall verbatim (user): "it should also delete the packages it installed" + "it should offer to remove all the packages not only stow config related ones, all the packages that were installed with setup" — captured as D-05 offer to remove ALL `pacman`/`apt`/`pkg` deps, gated by same `yes` guard + dry-run preview
- Hyprland verbatim (user): "no need for that remove that i no longer use tty login so that is redundent" — captured as D-10 delete `zsh/.zprofile` exec block
- Zinit verbatim (user): "no need to clone anything, zinnit clones itself on first zsh shell launch also no need for pinning" — captured as D-12 no installer clone/pin
- chsh verbatim (user): "offer after stow at the ned when everything is setted up." — captured as D-13 end-of-run `chsh` offer
- Termux extra login shell prompt — user flagged "termux asks an extra login shell prompt which needs to be researched." No decision made; downstream researcher should investigate `zsh` login-shell detection on Termux (`TERMUX_VERSION`/`PREFIX` handling, `chsh` availability, `zsh/.zprofile` login-shell guards) before planning

## Deferred Ideas

None — discussion stayed within Phase 2 scope (uninstall/keyd/Hyprland/Zsh/docs). Backup/snapshot restore `AUTO-01`/`AUTO-02` (tar + `setup.sh --restore`, CI matrix) remains v2 per REQUIREMENTS.md; not re-raised as new asks.

---

*Phase: 2-Safe, Reversible & Server-Safe Deployment*
*Context gathered: 2026-09-11*
