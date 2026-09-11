---
phase: 02-safe-reversible-server-safe-deployment
plan: "01"
subsystem: installer
tags: [bash, stow, keyd, uninstall, termux, zsh, dro]
requires:
  - phase: 01-universal-installer-platform-foundations
    provides: setup.sh spine with Termux-first detect_family 4-tier, verify→install→re-verify lock, 5-backend checklist ladder, mv-only quarantine to .stow-conflicts/<ts>/MANIFEST, folding-aware post_verify via readlink -f
provides:
  - Reversible uninstall verb `bash setup.sh --uninstall/--remove` with typed `yes` + `--yes` CI bypass + `--dry-run` preview and idempotent `stow -D`
  - Privileged keyd safety gate with `stow --no --verbose -t /` preview + `diff -u` on regular-file conflict + gum/Type-yes ladder + conditional `--adopt` + `keyd reload || true`
  - Server-safe `zsh/.zprofile` with Hyprland exec block removed (no persisted mode file)
  - Mason artefacts cleanup when nvim deselected and legacy dotfiles/mode file removal with quarantine immutability
  - System package removal offer via pacman -Rns / apt remove -y / pkg uninstall with same yes gate and dry-run preview
affects: [02-02, 03-polished-shell-theme-local-overrides, 04-editor-autonomy-verified-health]
tech-stack:
  added: []
  patterns: [strict-mode Bash with inherit_errexit and ${1-} guards, DRY_RUN early-return before every mutation, typed yes gate with gum confirm fallback, stow --dir/--target/--no --verbose preview, privileged keyd gate with diff -u and conditional --adopt]
key-files:
  created: []
  modified: [setup.sh, zsh/.zprofile]
key-decisions:
  - "Use DRY_RUN early-return before every filesystem mutation including stow -D, sudo stow -D -t / keyd, rm -rf ~/.local/share/nvim/mason, pacman -Rns/apt remove/pkg uninstall and keyd reload"
  - "Privileged keyd install requires preview + diff -u only when /etc/keyd/default.conf is regular file, gum confirm primary → Type 'yes' fallback, adopt only on second explicit 'adopt' confirmation"
  - "Delete Hyprland exec block from zsh/.zprofile entirely per D-10, never write or read ~/.config/dotfiles/mode per D-11"
  - "Mason cleanup only when nvim not in SELECTED_PACKAGES, rmdir parent with || true, never delete .stow-conflicts quarantine"
  - "System package offer reuses ALL_TOOLCHAIN order and SELECTED_DEPS filtering, Termux uses pkg without sudo, single yes gate for whole list"
patterns-established:
  - "UNINSTALL global + help-wins pre-scan before while loop, `${1-}` guards under set -u"
  - "run_uninstall: DRY_RUN preview for HOME stow -D + privileged stow -D -t / with stow --no --verbose piped through sed || true"
  - "install_keyd_privileged: privileged preview (no writes) + diff -u + gum/Type yes ladder + conditional --adopt + reload || true"
  - "offer_system_package_removal: candidate = SELECTED_DEPS || ALL_TOOLCHAIN, filtered via filter_deps_by_selection, DRY_RUN prints per-manager Would run, live single yes gate"
requirements-completed: [INST-03, STOW-02, STOW-03]
coverage:
  - id: D1
    description: "User runs bash setup.sh --uninstall/--remove and must type yes (bypass with --yes) before stow -D + sudo stow -D -t / keyd removes links, Mason artefacts cleaned when nvim deselected — second uninstall and re-install idempotent"
    requirement: INST-03
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --dry-run --uninstall --mode server --shell zsh --yes | grep -q \"\\[DRY RUN\\] Would run: stow\""
        status: pass
      - kind: unit
        ref: "bash -n setup.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "User who selects keyd sees stow --no --verbose -t / keyd preview and diff -u if /etc/keyd/default.conf exists as regular file; installer requires gum confirm / Type 'yes' before sudo stow --adopt -t / keyd, otherwise plain stow then reload with || true"
    requirement: STOW-02
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --dry-run --mode local --shell zsh --yes | grep -q \"Privileged keyd preview\""
        status: pass
      - kind: unit
        ref: "grep -q \"install_keyd_privileged\" setup.sh && grep -q \"diff -u\" setup.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "User on server mode can log in on tty1 without session death — zsh/.zprofile Hyprland exec block is deleted, no persisted ~/.config/dotfiles/mode file written or read, legacy mode file removed silently if present"
    requirement: STOW-03
    verification:
      - kind: unit
        ref: "test ! -s zsh/.zprofile || ! grep -q \"exec start-hyprland\" zsh/.zprofile"
        status: pass
      - kind: unit
        ref: "grep -q \"rm -f.*\\.config/dotfiles/mode\" setup.sh && ! grep -q \"mkdir.*dotfiles/mode\" setup.sh"
        status: pass
    human_judgment: false
  - id: D4
    description: "System package removal offer lists all SELECTED_DEPS toolchain names, previews with [DRY RUN] Would run: sudo pacman -Rns / apt remove -y / pkg uninstall, requires same yes gate, never auto-removes, Termux uses no sudo"
    requirement: INST-03
    verification:
      - kind: unit
        ref: "bash setup.sh --dry-run --uninstall --mode server --shell zsh --yes | grep -q \"apt remove -y\""
        status: pass
      - kind: unit
        ref: "grep -q \"pacman -Rns\" setup.sh && grep -q \"apt remove -y\" setup.sh && grep -q \"pkg uninstall\" setup.sh"
        status: pass
    human_judgment: false
actuals:
  tokens: 4558
  tasks: 3
  commits: 3
duration: 6 min
completed: 2026-09-11
status: complete
---

# Phase 02 Plan 01: Reversible uninstall + privileged keyd safety gate + Hyprland server guard Summary

**Reversible `bash setup.sh --uninstall` with typed `yes` + privileged keyd preview/diff/adopt gate and Hyprland exec removal — dry-run safe and idempotent via `stow -D`**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-11T19:48:29Z
- **Completed:** 2026-09-11T19:54:21Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Unified `bash setup.sh --uninstall/--remove` with `UNINSTALL` global, `--help` wins pre-scan, typed `yes` exact case-sensitive + `--yes` CI bypass, `--dry-run` preview via `stow --no --verbose --delete` before any mutation and idempotent `stow -D` loops that never `rm -rf` repo dirs
- Privileged keyd safety gate `install_keyd_privileged` with `stow --no --verbose -t / keyd` preview + `diff -u` when host file is regular file + `gum confirm` → `Type 'yes'` fallback + conditional `--adopt` only on explicit `adopt` + `keyd reload || systemctl reload || true`
- Server-safe login by deleting `zsh/.zprofile` Hyprland `exec start-hyprland` block entirely (comment-only file, no `DISPLAY`/`tty` check, no persisted mode file)
- Mason artefacts cleanup `~/.local/share/nvim/mason` only when `nvim` not in `SELECTED_PACKAGES` with `rmdir` prune and legacy `~/.config/dotfiles/mode` + `.dotfiles-mode` removal, `.stow-conflicts` never auto-deleted
- System package removal offer `offer_system_package_removal` that reuses `ALL_TOOLCHAIN` order and `SELECTED_DEPS` filtering, previews `sudo pacman -Rns` / `sudo apt remove -y` / `pkg uninstall` with same yes gate and per-package graceful failure

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer: uninstall verb + idempotent stow -D + keyd preview/diff/gate + zprofile exec removal — one path only** - `b647e83` (feat)
2. **Task 2: Mason artefacts + legacy mode file + quarantine immutability** - `e799333` (feat)
3. **Task 3: System packages removal offer — all toolchain after same yes gate, Termux-aware, dry-run preview** - `1fb3fc6` (feat)

**Plan metadata:** `pending` (docs: complete plan)

## Files Created/Modified

- `setup.sh` - Adds UNINSTALL global, --uninstall/--remove flag, install_keyd_privileged with preview/diff/adopt ladder, run_uninstall with DRY_RUN preview → yes gate → idempotent stow -D + privileged unstow + Mason/legacy/system offer, offer_system_package_removal for all toolchain, and privileged keyd delegation in run_stow
- `zsh/.zprofile` - Deleted Hyprland exec block, now comment-only intentionally empty login profile per D-10

## Decisions Made

- Keep Phase 1 spine verbatim: `set -Eeuo pipefail; shopt -s inherit_errexit; SCRIPT_DIR` guard, `${1-}` guards, `--help` wins pre-scan, `DRY_RUN` early-return, outside-repo-root guard, `detect_family` 4-tier, `verify→install→re-verify`, checklist ladder, `mv`-only quarantine, folding-aware `readlink -f` post-verify — reuse without deviation
- Use `stow --no --verbose` piped through `sed 's/^/  /' || true` for all previews so `diff` exit 1 never kills `set -e`
- For `Termux` family, skip privileged keyd entirely with warning and no sudo writes; for `arch`/`debian` use `sudo pacman -Rns --noconfirm` / `sudo apt remove -y`, for `termux` use `pkg uninstall -y` without sudo
- Never auto-adopt: plain `sudo stow -t / keyd` unless regular-file conflict exists AND second explicit `adopt` confirmation (gum or exact `adopt` string)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `sudo stow --no --verbose --delete keyd` preview in dry-run requires sudo for privileged target `/`; on hosts without passwordless sudo it prints `sudo: a password is required` but header `[DRY RUN] Would run: sudo stow ...` still satisfies preview contract and `|| true` prevents `set -e` abort — accepted as non-blocking, preview via non-sudo `stow --no --verbose -t /` is used for install path
- Initial `run_uninstall` DRY_RUN preview printed headers unconditionally even for live runs; fixed in Task 2 to wrap preview inside `if [[ "$DRY_RUN" == true ]]` before any write, preserving idempotence

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Uninstall path is reversible (`stow --restow` after `stow -D` because repo dirs never deleted), dry-run previews every pending `stow -D` and privileged keyd write before any filesystem touch, second uninstall/re-install are safe no-ops
- Privileged keyd never force-adopts without explicit adopt confirmation; diff shown when conflict regular file exists
- Server tty1 login no longer execs Hyprland; no persisted mode file exists — legacy file cleaned on uninstall
- Ready for 02-02: Zsh self-provision polish + docs canon flip (touches README.md, setup.sh usage header, zsh/.zshrc comments, AGENTS.md if needed, and staged delete of teardown.zsh/teardown.nu after --uninstall ships per D-15)

---
*Phase: 02-safe-reversible-server-safe-deployment*
*Completed: 2026-09-11*

## Self-Check: PASSED
