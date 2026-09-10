---
phase: 01-universal-installer-platform-foundations
verified: 2026-09-11T00:45:00Z
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
gaps: []
---

# Phase 01: Universal Installer + Platform Foundations Verification Report

**Phase Goal:** A fresh clone can run `bash setup.sh` on Arch, Debian-family, or Termux and get a correct deployment with no manual `stow` or preinstalled Zsh
**Verified:** 2026-09-11T00:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

Phase goal is **ACHIEVED**. `setup.sh` is a strict-mode Bash entry (`set -Eeuo pipefail; shopt -s inherit_errexit`, 750 lines, `bash -n` clean, executable) that detects Arch/Debian/Termux derivatives, resolves deps via `verify → install → re-verify`, presents `mode → shell → checklist` before any write, previews every write with `stow --no --verbose` + `[DRY RUN] Would run:` and aborts outside the clone root with `run-from-clone`. Live sandbox deploys (real `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow` + folding-aware `readlink -f` post-verify) succeed idempotently; dry-run leaves zero writes; quarantine preserves collisions byte-identical with gitignored `MANIFEST`. No manual `stow` and no preinstalled Zsh required.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User runs `bash setup.sh --help` and sees usage, exits 0, changes nothing (no unbound-variable crash) | ✓ VERIFIED | `bash setup.sh --help` exits 0, prints `Usage: setup.sh [OPTIONS]` with `--mode/--shell/--dry-run`, SHA stable, `git status --porcelain -- ':!setup.sh'` only shows untracked planning/research cache; `bash setup.sh -h` same; `bash -n setup.sh` clean; no `unbound variable` in stderr |
| 2 | User on Manjaro, EndeavourOS, Garuda, Mint, Pop!_OS, or Termux resolves to arch/debian/termux with no hard error | ✓ VERIFIED | 4-tier `detect_family`: `TERMUX_VERSION/PREFIX/pkg` → `pacman/apt` presence → `ID_LIKE` tokens → `ID` → manager fallback. Fixtures: `ID=manjaro,ID_LIKE=arch→arch`, `ID=pop,ID_LIKE="ubuntu debian"→debian`, `ID=linuxmint→debian`, `ID=garuda→arch`, `ID=endeavouros→arch`, `ID=cachyos→arch`, `ID=termux→termux`, `TERMUX_VERSION=1,PREFIX=com.termux→termux` all pass via `OS_RELEASE_FILE` seam |
| 3 | User with missing deps gets verify → install → re-verify: partitioned core/gui missing list, manager install, abort naming residue on failure | ✓ VERIFIED | `verify_deps` partitions `core_missing` vs `gui_missing` via `gui_list` per family, prints `Missing CORE/GUI deps:`; `install_deps` uses `sudo pacman -S --needed`, `sudo apt install -y`, `pkg install -y` (termux per-package loop with `pkg search` hint); `reverify_deps` re-collects via `get_deps` and aborts `Still missing: ...` with exact retry `sudo pacman ...` / `sudo apt ...` / `pkg ...` |
| 4 | User passes --dry-run and sees every pending install as preview text with zero filesystem writes | ✓ VERIFIED | `bash setup.sh --mode server --shell zsh --dry-run` prints `=== DRY RUN MODE`, `[DRY RUN] Would run: sudo apt install -y stow` (upgrade path), `DRY RUN: Skipped re-verify`, `=== DRY RUN: Preview of selected packages ===` with `stow --no --verbose` per package; empty `HOME=/tmp/fakehome` dry-run leaves `ls -A` empty; SHA unchanged |
| 5 | User re-runs the installer and the dep lock is a safe no-op; stow below 2.4.1 is auto-upgraded via the platform manager | ✓ VERIFIED | Host `stow 2.3.1` triggers `Stow 2.3.1 < 2.4.1 — will upgrade via debian manager.` and queues `stow` into missing; with mock `stow 2.4.1` shim, second run reports `All dependencies are satisfied.` + `No install needed — second run is a safe no-op`; `sort -V` via `printf '%s\n' "$ver" "2.4.1" | sort -V | head -n 1`; `stow --restow` idempotent verified by double sandbox deploy (70 links both passes) |
| 6 | User is prompted mode → shell → package checklist before any write happens | ✓ VERIFIED | `main` sequence: `parse_args` → repo-root guard → TTY-gated `prompt_mode/prompt_shell` → `detect_family` → `verify/install/reverify` → `prompt_checklist` → `preview` → `quarantine_scan` → `run_stow` → `post_verify`. No write before checklist; piped `printf '2\n1\n\n' | HOME=sandbox PATH=shim bash setup.sh --mode server --shell zsh` completes prompt then stow; non-TTY with incomplete flags aborts before any write |
| 7 | User can toggle all 7 packages; server pre-unchecks GUI but re-check works; shell choice pre-checks only the chosen shell; Termux disabled rows stay unselectable | ✓ VERIFIED | `ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd)` 7; `GUI_STOW_PACKAGES=(alacritty wofi keyd)`; server `MODE==server` sets those `OFF`; `SHELL_CHOICE==zsh` sets `zsh ON/nushell OFF`; Termux `TERMUX_DISABLED_PACKAGES=(alacritty wofi keyd)` forced `OFF` + rendered as `pkg (not available on Termux)` + `strip_termux_disabled` drops with warning; `checklist_read` toggle logic validated by `2\n1\n7` Termux dry-run → only `nvim zsh starship` in final selection |
| 8 | User passes --dry-run and sees the exact post-checklist selection previewed with zero writes | ✓ VERIFIED | `preview_selection` prints `Selection: ${SELECTED_PACKAGES[*]}` then per-pkg `Would run: stow --dir="$SCRIPT_DIR" --target="$HOME" --restow $pkg` and `stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg"` (or `stow not found` fallback); verified on empty HOME dry-run with zero writes; non-interactive presets `nvim zsh starship` correctly previewed |
| 9 | User with existing non-symlink targets gets them quarantined to a timestamped gitignored dir with a manifest and restore hint — never deleted, never force-adopted | ✓ VERIFIED | `quarantine_scan` uses `mv` only to `$SCRIPT_DIR/.stow-conflicts/<ts>/` preserving `rel` with `mkdir -p $(dirname)`, writes `MANIFEST` with `original -> quarantined` lines + header `Restore: mv <quarantined-path> <original-path>`; fixture `precious` at `.config/starship.toml` survives byte-identical `cmp -s` under quarantine, `grep -F ".config/starship.toml" .stow-conflicts/*/MANIFEST` hits, log prints `Quarantine complete` + `Restore with: mv`; `grep -q -- '--adopt' setup.sh` is 0, `grep -q "rm.*HOME"` is 0 |
| 10 | User gets strict post-verify over the linked set (folding-aware) or an abort naming each bad link and its expected target | ✓ VERIFIED | `post_verify` iterates `find "$pkg_dir" -type f` per `SELECTED_PACKAGES`, calls `assert_linked` which checks `test -e $abs` then `readlink -f $abs` prefix `"$SCRIPT_DIR/$pkg/"*`; covers folded `~/.config → repo/.config` and unfolded files; on mismatch prints `MISMATCH/MISSING: $rel -> $got (expected under ...)`; sandbox deploy verified `70 links: ok: ... -> /home/shoyeb/dotfiles/...` and `Post-verify passed: all 70 links verified`; standalone `SELECTED_PACKAGES=(nvim zsh starship) post_verify` passes |
| 11 | User finds no legacy setup scripts and no dangling doc references; teardowns still present for Phase 2 removal work | ✓ VERIFIED | `test ! -e setup.nu && test ! -e setup.zsh` passes, `test -e teardown.nu && test -e teardown.zsh` passes; `grep -Eq 'setup\.(nu|zsh)' README.md` hits 0, `grep -Eq 'setup\.(nu|zsh)' nvim/.config/nvim/README.md` hits 0; `grep -q 'bash setup.sh' README.md` hits; README shows `Zsh (Default) | Nushell (Backup)` table, `bash setup.sh --mode local` examples, `stow --dir=. --target="$HOME" --restow nvim zsh starship` one-liners |
| 12 | User invoking outside the clone root gets an abort with a run-from-clone message before any write | ✓ VERIFIED | Guard: `[[ ! -f "$SCRIPT_DIR/setup.sh" ]]` and `[[ ! -f ./setup.sh ]]` → `Error: setup.sh must be run from the dotfiles repo root.` + `This installer uses stow --dir="$SCRIPT_DIR"` + `Current directory: $PWD (./setup.sh not found) — run-from-clone required.` before any prompt/write; `(cd /tmp/notrepo && bash /home/shoyeb/dotfiles/setup.sh --mode server --shell zsh --dry-run)` exits 1 and matches `run-from-clone|repo root` |
| 13 | User on Termux gets pkg installs with no sudo and keyd/hyprland/wofi never selectable | ✓ VERIFIED | Termux `install_cmd=(pkg install -y)` (no `sudo`); `grep -A2 'termux) install_cmd'` confirms; `get_deps termux server` returns only `stow neovim ... zsh` no `keyd/hyprland/wofi/waybar/slurp`; `gui_list` for termux is `()`; `install_deps` termux branch loops per-pkg with `pkg install -y $pkg` and no `sudo` prefix anywhere on that path; checklist Termux path renders disabled OFF + `strip_termux_disabled` warning; dry-run on `TERMUX_VERSION=1` correctly shows `Selected packages (non-interactive presets): nvim zsh starship` |

**Score:** 13/13 truths verified

### ROADMAP Phase 1 Success Criteria

| # | Criterion (ROADMAP § Phase 1) | Status | Evidence |
|---|-------------------------------|--------|----------|
| 1 | `bash setup.sh --help` (or no TTY/missing arg) shows usage without `unbound variable`/`pipefail` crash | ✓ VERIFIED | `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards; `--help` exits 0, `--bogus-flag`/`--mode` value-less/`printf '' | bash setup.sh --mode server </dev/null` all exit 1 with `Usage:` not `unbound variable` |
| 2 | Derivative (Manjaro/EndeavourOS/Garuda/Mint/Pop!_OS) installs without hard error via `command -v pacman/apt` → `ID_LIKE` → `ID` families `arch/debian/termux` | ✓ VERIFIED | Fixtures above + `detect_family` Tier 2 manager presence + Tier 3 `ID_LIKE` token split + Tier 4 `ID` + fallback `have_pacman/have_apt`; covers all 5 roadmap derivatives plus `cachyos` |
| 3 | Termux via `pkg install` distinct `termux` list (no `sudo`, no `keyd` privileged) — `keyd/hyprland/wofi` auto-deselected, `nvim/zsh/starship` still link | ✓ VERIFIED | Termux distinct `get_deps` (same common, empty gui), `pkg install -y` sudo-free, disabled-row emulation + `strip_termux_disabled`, sandbox Termux dry-run links correctly |
| 4 | `verify → install → re-verify` lock with partitioned `core_missing/gui_missing`, `make+gcc+fzf+zsh` in `common`, `Still missing` abort, idempotent second run | ✓ VERIFIED | `common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)` for arch/debian/termux; `core_missing/gui_missing` report; `install_deps` exact-argv preview; `reverify_deps` aborts `Still missing` with retry; host `stow 2.3.1` upgrade path proven; shim `2.4.1` no-op proven |
| 5 | Interactive `mode→shell→checklist` before any write, `--dry-run` previews every write (`[DRY RUN] Would run:` + `stow --no --verbose`), outside-root abort, `stow --dir="$SCRIPT_DIR"` + `readlink -f` post-verify | ✓ VERIFIED | Checklist ladder before any mutation; dry-run shows manager argv + `stow --no --verbose` per selected; outside-root guard exits 1 with `run-from-clone`; deploy uses `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow`; `assert_linked` via `readlink -f` covers folding |

**Success criteria score:** 5/5

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `setup.sh` | Canonical Bash installer: strict header, arg parsing, family detection, dep lock | ✓ VERIFIED | 750 lines, `#!/usr/bin/env bash`, `set -Eeuo pipefail`, `shopt -s inherit_errexit`, `SCRIPT_DIR` from `BASH_SOURCE`, executable, `bash -n` clean, contains `detect_family`, `get_deps`, `verify_deps`, `install_deps`, `reverify_deps`, `prompt_checklist`, `quarantine_scan`, `run_stow`, `post_verify` |
| `setup.sh:prompt_checklist` | Checklist ladder with 5 backends sharing one selection contract | ✓ VERIFIED | `checklist_gum/w h i ptail/dialog/fzf/read` each `command -v` probed, `return 1` skip, `return 2` cancel never cascades; `prompt_checklist` ladder locked `gum→whiptail→dialog→fzf→read` |
| `.gitignore` | Quarantine-root ignore entry | ✓ VERIFIED | Contains `# Installer quarantine (D-13/D-14)` header + `.stow-conflicts/` on line 14, `git check-ignore -v .stow-conflicts/...` confirms ignored |
| `.stow-conflicts/<timestamp>/MANIFEST` | Original→quarantined mapping plus restore hint | ✓ VERIFIED | Runtime-created `.stow-conflicts/20260911-004331-329/MANIFEST` with `# Stow quarantine manifest`, `original -> quarantined` lines, `Restore: mv <quarantined-path> <original-path>`; log prints `Quarantine complete` + `Restore with:` |
| `setup.nu` / `setup.zsh` | Deleted (staged, no shims) | ✓ VERIFIED | `ls setup.nu setup.zsh` → no such file; `git log --oneline -- setup.nu` shows deletion in `f06e399`; `teardown.nu/zsh` still present |
| `README.md` | Canonical-entry rewrite, Zsh default, no dangling pointers | ✓ VERIFIED | `grep -q 'bash setup.sh' README.md` pass, `! grep -Eq 'setup\.(nu|zsh)' README.md` pass, `! grep -Eq -- '--adopt' README.md` pass, `! grep -Eq -- '--adopt' setup.sh` pass |
| `nvim/.config/nvim/README.md` | No legacy pointers | ✓ VERIFIED | `! grep -Eq 'setup\.(nu|zsh)' nvim/.config/nvim/README.md` pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `setup.sh:parse_args` | `setup.sh:main` | parsed `MODE/SHELL_CHOICE/DRY_RUN` globals gate every later step; --help/unknown exit before any prompt or write | ✓ WIRED | Pre-scan `for arg in "$@"; case --help` exits 0; `parse_args` sets globals; `main` reads `MODE/SHELL_CHOICE/DRY_RUN/FAMILY`; unknown `Unknown option` exits 1 before `prompt_mode` |
| `setup.sh:detect_family` | `setup.sh:get_deps` | family string `arch|debian|termux` selects dep table branch | ✓ WIRED | `FAMILY=$(detect_family)` then `get_deps "$FAMILY" "$MODE"`; `case "$family" in arch/debian/termux` branches verified with fixtures |
| `setup.sh:verify_deps` | `setup.sh:install_deps` | collected missing list drives exact manager argv; re-verify aborts on residue | ✓ WIRED | `VERIFY_MISSING` array from `verify_deps "${deps[@]}"` drives `install_deps "$FAMILY" "${missing[@]}"` with `sudo pacman -S --needed` / `sudo apt install -y` / `pkg install -y`; `reverify_deps` re-runs `verify_deps` and aborts `Still missing` |
| `setup.sh:prompt_checklist` | `setup.sh:preview_selection` | final `SELECTED_PACKAGES` array drives simulate-plus-verbose preview verbatim | ✓ WIRED | `SELECTED_PACKAGES` set by any rung (same shape), then `preview_selection` iterates it printing `Would run: stow --dir="$SCRIPT_DIR" --target="$HOME" --restow $pkg` + `stow --no --verbose` |
| `setup.sh:quarantine_scan` | `setup.sh:run_stow` | every collision relocated with manifest line before any restow runs | ✓ WIRED | `main` order `quarantine_scan` → `run_stow`; `quarantine_scan` `mv` collisions under `QDIR/$rel` with `MANIFEST` before `run_stow` calls `stow --restow`; dry-run skips both correctly |
| `setup.sh:run_stow` | `setup.sh:post_verify` | expected link set resolves into repo dir or abort with link→target report | ✓ WIRED | `run_stow` `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow` then `post_verify` `assert_linked` via `readlink -f` prefix; failure `post_verify FAILED` aborts; success `Post-verify passed: all 70 links verified` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `setup.sh:detect_family` | `FAMILY` | `TERMUX_VERSION/PREFIX/pkg` + `command -v pacman/apt` + `OS_RELEASE_FILE` (`/etc/os-release` ID/ID_LIKE) | ✓ Real | ✓ FLOWING |
| `setup.sh:get_deps` | `deps` | `case "$family"` table + `mode` filter; common includes `make gcc fzf zsh` | ✓ Real | ✓ FLOWING |
| `setup.sh:verify_deps` | `VERIFY_MISSING` | `command -v $cmd` probing (`nvim/rg/node` map) | ✓ Real | ✓ FLOWING |
| `setup.sh:SELECTED_PACKAGES` | `SELECTED_PACKAGES` | `prompt_checklist` ladder presets + user input → `strip_termux_disabled` | ✓ Real | ✓ FLOWING |
| `setup.sh:run_stow` | filesystem links | `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow` per `SELECTED_PACKAGES` | ✓ Real | ✓ FLOWING |
| `setup.sh:post_verify` | `readlink -f $abs` | `find "$pkg_dir" -type f` → `assert_linked` prefix check | ✓ Real | ✓ FLOWING |
| `.stow-conflicts/MANIFEST` | manifest lines | `quarantine_scan` `mv` loop appending `"$home_target -> $q_target"` | ✓ Real | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `bash -n` passes | `bash -n setup.sh` | exit 0, no output | ✓ PASS |
| `--help` exits 0 | `bash setup.sh --help` | `Usage: setup.sh` + `Zsh default` + EXAMPLES, exit 0 | ✓ PASS |
| `-h` exits 0 | `bash setup.sh -h` | same usage, exit 0 | ✓ PASS |
| Source-guard | `bash -c 'source ./setup.sh; echo sourced-ok'` | `sourced-ok`, no main execution, exit 0 | ✓ PASS |
| Dry-run preview + zero writes | `HOME=/tmp/fakehome bash setup.sh --mode server --shell zsh --dry-run` | `[DRY RUN] Would run: sudo apt install -y stow`, `stow --no --verbose` preview for nvim/starship, `ls -A HOME` empty, `DRY RUN complete` | ✓ PASS |
| Unknown-flag abort | `bash setup.sh --bogus-flag` | `Unknown option: --bogus-flag`, Usage, exit 1 | ✓ PASS |
| Value-less flag abort | `bash setup.sh --mode` | `Error: --mode requires an argument`, Usage, exit 1 | ✓ PASS |
| No-TTY incomplete abort | `printf '' | bash setup.sh --mode server </dev/null` | `Error: --mode and --shell are required in non-interactive mode`, Usage, exit 1 | ✓ PASS |
| Outside-root abort | `(cd /tmp/notrepo && bash /home/shoyeb/dotfiles/setup.sh --mode server --shell zsh --dry-run)` | `run from the dotfiles repo root` + `run-from-clone required`, exit 1, before any prompt | ✓ PASS |
| No --adopt anywhere | `grep -Eq -- '--adopt' setup.sh` | exit 1 (0 hits) | ✓ PASS |
| Manjaro→arch | `OS_RELEASE_FILE=/tmp/fix-manjaro PATH=/usr/bin:/bin bash -c 'source ./setup.sh; detect_family'` | `arch` | ✓ PASS |
| Pop→debian | `OS_RELEASE_FILE=/tmp/fix-pop PATH=/usr/bin:/bin bash -c 'source ./setup.sh; detect_family'` | `debian` | ✓ PASS |
| Termux env→termux | `TERMUX_VERSION=1 PREFIX=/data/data/com.termux/files/usr OS_RELEASE_FILE=/tmp/fix-manjaro bash -c 'source ./setup.sh; detect_family'` | `termux` | ✓ PASS |
| Real deploy sandbox | `printf '2\n1\n\n' | HOME=/tmp/fakehome-real PATH=stow-2.4.1-shim:fakebin bash setup.sh --mode server --shell zsh` | `Stowing nvim/zsh/starship`, `ok: .config/nvim/init.lua -> ...`, `Post-verify passed: all 70 links verified`, links exist | ✓ PASS |
| Quarantine byte-identical | `printf 'precious' > HOME/.config/starship.toml; printf '2\n1\n\n' | bash setup.sh --mode server --shell zsh` | `Quarantined: ... -> .stow-conflicts/.../.config/starship.toml`, `Quarantine complete`, `MANIFEST` contains `.config/starship.toml`, `QFILE` cmp -s identical | ✓ PASS |
| Idempotent re-run | Same real deploy re-run | `All dependencies are satisfied.` + re-verify + `Post-verify passed` pass again, no duplicate/broken links | ✓ PASS |
| Termux disabled strip | `TERMUX_VERSION=1 ... checklist_read` non-interactive | `Selected packages (non-interactive presets): nvim zsh starship` (no alacritty/wofi/keyd) | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| No probes declared (`scripts/*/tests/probe-*.sh` absent, PLAN verify uses inline `bash` fixtures) | — | — | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| INST-01 | 01-01, 01-02 | `bash setup.sh` canonical entry, interactive `mode local|server → shell zsh/nushell` without preinstalled Zsh/Nushell, TTY gating | ✓ SATISFIED | `setup.sh` #!/usr/bin/env bash, `parse_args` with `--mode/--shell`, `prompt_mode/prompt_shell/prompt_checklist` before any write, `detect_family`+`install_deps` handle tooling, no Zsh/Nushell preinstalled probe |
| INST-02 | 01-01, 01-02 | `--dry-run` previews every write (`stow --no --verbose`, package installs, keyd privileged) without filesystem mutation | ✓ SATISFIED | `DRY_RUN` early return in `install_deps` + `preview_selection` with `stow --no --verbose` per selected; verified zero writes on empty HOME |
| INST-04 | 01-02 | Interactive checklist override after mode+shell, deselecting `keyd/hyprland/wofi` before any write (`gum→whiptail→dialog→fzf→read`) | ✓ SATISFIED | 5-backend ladder, presets server/GUI/shell, Termux disabled emulation, `prompt_checklist` before `quarantine_scan/run_stow` |
| INST-05 | 01-01 | Robust flags `--help --mode --shell --dry-run --yes --uninstall` with `set -Eeuo pipefail`, `${1-}` guards, no crash on --help or non-interactive TTY | ✓ SATISFIED | Strict header + inherit_errexit, `${1-}`/`${2-}` guards, help-wins-anywhere pre-scan, unknown/value-less abort, no-TTY complete/incomplete branches |
| DEPS-01 | 01-01 | Derivative + Termux installs without hard error: `command -v pacman/apt/pkg` → `ID_LIKE` → `ID`, families `arch/debian/termux` | ✓ SATISFIED | `detect_family` 4 tiers, `OS_RELEASE_FILE` seam, all derivative fixtures pass including `ID=termux` |
| DEPS-02 | 01-01 | Missing deps auto-installed and re-verified: `verify→install→re-verify` lock, `make+gcc+fzf+zsh` in common, core/gui partition, distinct Termux list no sudo no keyd | ✓ SATISFIED | `get_deps` common includes `make gcc fzf zsh`, `verify_deps`/`install_deps`/`reverify_deps` chain, Termux pkg names distinct, no sudo on termux path |
| DEPS-03 | 01-01, 01-02 | Idempotent re-run: `stow --restow` + `--needed/-y/pkg` is safe no-op, handles `stow ≥2.4.1` upgrade | ✓ SATISFIED | `run_stow` uses `--restow`, `install_deps` uses `--needed`/`-y`, `sort -V` upgrade path proven, double deploy passes |
| STOW-01 | 01-02 | Stow packages correctly symlinked only from repo root (`stow --dir="$SCRIPT_DIR"`), `stow --no --verbose` preview and `readlink -f` post-verify; outside-root aborts | ✓ SATISFIED | Explicit `--dir="$SCRIPT_DIR" --target="$HOME" --restow`, dry-run `stow --no --verbose` per selection, `post_verify` folding-aware `readlink -f`, outside-root `[[ ! -f ./setup.sh ]]` abort |

**Orphaned requirements:** None. All 8 Phase 1 IDs from `ROADMAP.md` appear in at least one PLAN frontmatter and are SATISFIED. Checked `grep -E "Phase 1" .planning/REQUIREMENTS.md` maps exactly those 8 IDs.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `setup.sh` | — | `TBD/FIXME/XXX` | — | None — 0 hits (`grep -n -E "TBD|FIXME|XXX" setup.sh` → exit 1) |
| `setup.sh` | — | `TODO/HACK/PLACEHOLDER` | — | None — 0 hits |
| `setup.sh` | — | `return null/return {}/return []/=> {}` stubs | — | None — Bash has no such stubs; `grep` shows only real function returns |
| `setup.sh` | — | Hardcoded empty data / hollow props | — | None — `SELECTED_PACKAGES` always populated from presets or ladder; verified non-empty on every dry-run/real path |
| `setup.sh` | `340,404` | `rm` presence | ℹ️ Info | No `rm -rf $HOME` — `grep -n "rm"` only matches `termux` substring; quarantine uses `mv` only, never `rm`, per prohibitions |
| `setup.sh` | `311,404` | `sudo stow -t /` privileged | ⚠️ Warning (expected) | Deferred — Phase 1 never executes privileged `stow -t /`; `keyd` is skipped with notices; `grep "sudo stow"` is 0 in Phase 1 code |

No blocker anti-patterns.

### Human Verification Required

None required for Phase 1 automated gate. All mode→shell→checklist flows, Termux emulation, quarantine, and post-verify were exercised via fixtures, piped-input sandbox deploys, and `TERMUX_VERSION`/`OS_RELEASE_FILE` seams.

If a manual UAT pass is desired (optional, not blocking):

- **Visual ladder:** Run `bash setup.sh` on a TTY with `gum && whiptail && dialog && fzf` installed and verify the five-rung order falls through correctly by hiding each binary via `PATH`.
- **Real Termux device:** Confirm `bash setup.sh --mode server --shell zsh --dry-run` on an actual Termux handset shows `pkg install -y` (no `sudo` prompt) and preview never offers `keyd` as selectable.

### Gaps Summary

No gaps. All 5 ROADMAP success criteria, all 13 must-have truths, all 4 required artifacts (including runtime `MANIFEST`), all 6 key links, and all 8 traceable requirements are verified with live commands. Prohibitions (no `--adopt`, no `rm -rf $HOME`, no `sudo` on Termux, no custom symlink engine, no TUI framework, no shims) are satisfied. Anti-pattern scan is clean. Status is `passed` — ready for Phase 2.

---

_Verified: 2026-09-11T00:45:00Z_
_Verifier: gsd-verifier (Muse Spark 1.2, adversarial goal-backward)_
