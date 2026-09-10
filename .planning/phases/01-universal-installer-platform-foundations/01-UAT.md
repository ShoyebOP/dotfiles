---
status: diagnosed
phase: 01-universal-installer-platform-foundations
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md]
started: 2026-09-10T18:57:15Z
updated: 2026-09-10T19:55:33Z
---

## Current Test

[testing complete]

## Tests

### 1. Strict-mode entry with guarded arg parsing, usage, and source-guard (INST-05)
expected: Strict-mode entry with guarded arg parsing, usage, and source-guard (INST-05)
result: pass
source: automated
coverage_id: D1
requirement: INST-05

### 2. Termux-first 4-tier family detection with derivative and Termux fixtures (DEPS-01)
expected: Termux-first 4-tier family detection with derivative and Termux fixtures (DEPS-01)
result: pass
source: automated
coverage_id: D2
requirement: DEPS-01

### 3. Per-family dep tables with toolchain/history/shell entries and Termux distinct list (DEPS-02)
expected: Per-family dep tables with toolchain/history/shell entries and Termux distinct list (DEPS-02)
result: pass
source: automated
coverage_id: D3
requirement: DEPS-02

### 4. Verify → install → re-verify lock with dry-run preview, partitioned reporting, stow upgrade via sort -V, idempotent second run (INST-02, DEPS-03)
expected: Verify → install → re-verify lock with dry-run preview, partitioned reporting, stow upgrade via sort -V, idempotent second run (INST-02, DEPS-03)
result: pass
source: automated
coverage_id: D4
requirement: DEPS-03

### 5. Invocation contract matrix: TTY gating, help-wins, unknown/value-less abort, fallible-capture guards (INST-01, INST-05)
expected: Invocation contract matrix: TTY gating, help-wins, unknown/value-less abort, fallible-capture guards (INST-01, INST-05)
result: pass
source: automated
coverage_id: D5
requirement: INST-01

### 6. Mode→shell→checklist ladder before any write with presets and Termux disabled emulation (INST-01, INST-04)
expected: Mode→shell→checklist ladder before any write with presets and Termux disabled emulation (INST-01, INST-04)
result: pass
source: automated
coverage_id: D1
requirement: INST-04

### 7. Dry-run previews exact manager argv plus stow simulation for final selection with zero writes (INST-02)
expected: Dry-run previews exact manager argv plus stow simulation for final selection with zero writes (INST-02)
result: pass
source: automated
coverage_id: D2
requirement: INST-02

### 8. Collision quarantine to timestamped gitignored dir preserving relative paths with MANIFEST and restore hint (STOW-01)
expected: Collision quarantine to timestamped gitignored dir preserving relative paths with MANIFEST and restore hint (STOW-01)
result: pass
source: automated
coverage_id: D3
requirement: STOW-01

### 9. Explicit-dir stow deploy with idempotent restow and Phase-1 keyd skip (STOW-01, DEPS-03)
expected: Explicit-dir stow deploy with idempotent restow and Phase-1 keyd skip (STOW-01, DEPS-03)
result: pass
source: automated
coverage_id: D4
requirement: DEPS-03

### 10. Folding-aware strict post-verify over linked set aborting with link→expected-target report
expected: Folding-aware strict post-verify over linked set aborting with link→expected-target report
result: pass
source: automated
coverage_id: D5
requirement: STOW-01

### 11. Staged delete of legacy bootstrappers with atomic docs repair and outside-root guard (D-02/D-03/D-04)
expected: Staged delete of legacy bootstrappers with atomic docs repair and outside-root guard (D-02/D-03/D-04)
result: pass
source: automated
coverage_id: D6
requirement: INST-01

### 12. Confirm auto-verified deliverables
expected: |
  All 11 Phase 1 deliverables were auto-verified via passing procedural checks (01-01 D1-D5 + 01-02 D1-D6) plus VERIFICATION.md 13/13 must-haves live. Confirm that reality matches — does bash setup.sh flow work as described?
result: issue
reported: "script does not work - ~/dotfiles $ sh setup.sh => setup.sh: 2: set: Illegal option -o pipefail"
severity: major

### 13. Checklist appears before dependency installation
expected: |
  User runs bash setup.sh and sees mode → shell → package checklist BEFORE any dependency installation begins (no apt/pacman writes before user confirms selection)
result: issue
reported: "it shows selection after installation is done not before"
severity: major

### 14. All 7 packages shown as toggleable
expected: |
  Package checklist shows all 7 packages (nvim, zsh, nushell, alacritty, starship, wofi, keyd) individually toggleable
result: issue
reported: "not all the package show as toggleable only 4-5 shows"
severity: major

### 15. Repo update before install (apt update / pacman -Sy)
expected: |
  Installer runs apt update (debian) or pacman -Sy (arch) before installing missing dependencies so fresh systems don't hit stale cache
result: issue
reported: "it should update the repos in corresponding os like apt update/ pacman -Sy"
severity: major

### 16. Shell actually changes after selection
expected: |
  After selecting zsh (default) and completing install, user's login shell is changed via chsh or at least offered with confirmation
result: skipped
reason: "Deferred follow-up: also shell doesnt change after all the changes — deferred to Phase 2 per user (SHEL-01)"

## Summary

total: 16
passed: 11
issues: 4
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-01-12
  truth: "All 11 Phase 1 deliverables were auto-verified via passing procedural checks (01-01 D1-D5 + 01-02 D1-D6) plus VERIFICATION.md 13/13 must-haves live. Confirm that reality matches — does bash setup.sh flow work as described?"
  status: failed
  reason: "User reported: script does not work - ~/dotfiles $ sh setup.sh => setup.sh: 2: set: Illegal option -o pipefail"
  severity: major
  test: 12
  root_cause: "setup.sh lines 2-3 execute Bash-only strict mode (set -Eeuo pipefail; shopt -s inherit_errexit) without first verifying the running shell is Bash. When invoked as sh setup.sh, dash fails at 'set: Illegal option -o pipefail' before any error handling can run."
  artifacts:
    - path: "setup.sh"
      issue: "Lines 2-3 use Bash-only pipefail/shopt with no prior BASH_VERSION guard; sh invocation aborts with Illegal option before usage"
  missing:
    - "Add POSIX-safe Bash detection guard before strict mode: if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash. Use: bash setup.sh [OPTIONS]" >&2; exit 1; fi"
    - "Guard must be POSIX-safe (no [[, arrays, BASH_SOURCE) and precede set -Eeuo pipefail"
  debug_session: ".planning/debug/sh-pipefail-guard.md
- gap_id: G-01-13
  truth: "User sees interactive flow mode → shell → package checklist BEFORE any write (including dependency installation)"
  status: failed
  reason: "User reported: it shows selection after installation is done not before"
  severity: major
  test: 13
  root_cause: "main() ordering bug: verify/install/re-verify (setup.sh:688-730) executes before prompt_checklist (setup.sh:738). Checklist must precede any write per ROADMAP criterion 5, but current flow writes before user finalizes selection."
  artifacts:
    - path: "setup.sh"
      issue: "Lines 688-730 verify/install block precedes checklist at 738; install_deps writes before user selection"
  missing:
    - "Move prompt_checklist immediately after detect_family and mode/shell resolution, before get_deps/verify/install"
    - "Ensure DRY_RUN previews deps+stow together after checklist"
  debug_session: ".planning/debug/checklist-order-guard.md

- gap_id: G-01-14
  truth: "Package checklist shows all 7 packages (nvim, zsh, nushell, alacritty, starship, wofi, keyd) individually toggleable"
  status: failed
  reason: "User reported: not all the package show as toggleable only 4-5 shows"
  severity: major
  test: 14
  root_cause: "checklist_read non-TTY fast path (setup.sh:585) shows only ON presets (nvim zsh starship =3 for server) instead of 7 toggleable entries; whiptail 20x10 may clip on small terminals; Termux mis-detection via command -v pkg can disable 3 leaving 4 selectable"
  artifacts:
    - path: "setup.sh"
      issue: "checklist_read non-TTY branch prints preset summary not full list; whiptail window 20 78 10 may clip; detect_family pkg probe overly broad"
  missing:
    - "Ensure TTY checklist always shows all 7 with ON/OFF state; fix non-TTY to error or show 7"
    - "Make whiptail/dialog sizing adaptive or fallback to read; tighten Termux detection"
  debug_session: ".planning/debug/package-toggle-count.md

- gap_id: G-01-15
  truth: "Installer runs apt update (debian) or pacman -Sy (arch) before installing missing dependencies"
  status: failed
  reason: "User reported: it should update the repos in corresponding os like apt update/ pacman -Sy"
  severity: major
  test: 15
  root_cause: "install_deps() (setup.sh:216-244) never refreshes package manager metadata; debian branch uses sudo apt install -y without apt update, arch uses pacman -S --needed without pacman -Sy, so fresh systems hit stale cache"
  artifacts:
    - path: "setup.sh"
      issue: "install_deps debian/arch branches omit repo refresh; no apt update or pacman -Sy before install"
  missing:
    - "Add repo refresh before install: sudo apt update (debian), sudo pacman -Sy (arch), pkg update -y (termux)"
    - "Preview update in DRY_RUN alongside install"
  debug_session: ".planning/debug/repo-update-missing.md

## Deferred Follow-Ups

- test: 16
  idea: "also shell doesnt change after all the changes — deferred to Phase 2 per user (SHEL-01)"
  deferred_at: 2026-09-10
