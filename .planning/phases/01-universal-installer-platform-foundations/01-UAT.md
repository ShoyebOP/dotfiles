---
status: diagnosed
phase: 01-universal-installer-platform-foundations
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md]
started: 2026-09-10T18:57:15Z
updated: 2026-09-11T12:11:53Z
---

## Current Test

[testing complete — 1 issue outstanding (G-01-14b expansion of checklist to deps), 1 deferred (G-01-16 shell change)]

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
result: pass
re-tested: 2026-09-11 — sh setup.sh now shows friendly Bash guard (was Illegal option), bash --help exit 0 — verified live, user confirmed
resolved_by: 01-03-PLAN.md

### 13. Checklist appears before dependency installation
expected: |
  User runs bash setup.sh and sees mode → shell → package checklist BEFORE any dependency installation begins (no apt/pacman writes before user confirms selection)
result: pass
re-tested: 2026-09-11 — checklist now before verify/install with unified Preview, zero writes before selection — verified live, user confirmed
resolved_by: 01-04-PLAN.md

### 14. All 7 packages shown as toggleable
expected: |
  Package checklist shows all 7 packages (nvim, zsh, nushell, alacritty, starship, wofi, keyd) individually toggleable
result: issue
reported: "there is a issue, actually i need all the apps to be toggleable not just the one that has configs to stow - Verifying dependencies...  - stow (missing, need 'stow')  - neovim (missing, need 'nvim')  - starship (missing, need 'starship')  + git (installed)  - zoxide (missing, need 'zoxide')  - uv (missing, need 'uv')  - ripgrep (missing, need 'rg')  - nodejs (missing, need 'node')  - npm (missing, need 'npm')  - make (missing, need 'make')  - gcc (missing, need 'gcc')  - fzf (missing, need 'fzf')  - zsh (missing, need 'zsh')"
severity: major

### 15. Repo update before install (apt update / pacman -Sy)
expected: |
  Installer runs apt update (debian) or pacman -Sy (arch) before installing missing dependencies so fresh systems don't hit stale cache
result: pass
re-tested: 2026-09-11 — dry-run now shows Refreshing apt lists + Would run: sudo apt update before install, previewed alongside stow — verified live, user confirmed
resolved_by: 01-04-PLAN.md

### 16. Shell actually changes after selection
expected: |
  After selecting zsh (default) and completing install, user's login shell is changed via chsh or at least offered with confirmation
result: skipped
reason: "Deferred follow-up: also shell doesnt change after all the changes — deferred to Phase 2 per user (SHEL-01)"

## Summary

total: 16
passed: 14
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-01-12
  truth: "All 11 Phase 1 deliverables were auto-verified via passing procedural checks (01-01 D1-D5 + 01-02 D1-D6) plus VERIFICATION.md 13/13 must-haves live. Confirm that reality matches — does bash setup.sh flow work as described?"
  status: resolved
  reason: "User reported: script does not work - ~/dotfiles $ sh setup.sh => setup.sh: 2: set: Illegal option -o pipefail"
  severity: major
  test: 12
  root_cause: "setup.sh lines 2-3 execute Bash-only strict mode (set -Eeuo pipefail; shopt -s inherit_errexit) without first verifying the running shell is Bash. When invoked as sh setup.sh, dash fails at 'set: Illegal option -o pipefail' before any error handling can run."
  artifacts:
    - path: "setup.sh"
      issue: "Lines 2-3 use Bash-only pipefail/shopt with no prior BASH_VERSION guard; sh invocation aborts with Illegal option before usage"
  missing:
    - "Add POSIX-safe Bash detection guard before strict mode: if [ -z \"${BASH_VERSION-}\" ]; then echo \"Error: This installer must be run with Bash. Use: bash setup.sh [OPTIONS]\" >&2; exit 1; fi"
    - "Guard must be POSIX-safe (no [[, arrays, BASH_SOURCE) and precede set -Eeuo pipefail"
  debug_session: ".planning/debug/sh-pipefail-guard.md"
  resolved_by: 01-03-PLAN.md
  resolved_at: 2026-09-11
- gap_id: G-01-13
  truth: "User sees interactive flow mode → shell → package checklist BEFORE any write (including dependency installation)"
  status: resolved
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
  debug_session: ".planning/debug/checklist-order-guard.md"
  resolved_by: 01-04-PLAN.md
  resolved_at: 2026-09-11
- gap_id: G-01-14
  truth: "Package checklist shows all 7 packages (nvim, zsh, nushell, alacritty, starship, wofi, keyd) individually toggleable"
  status: resolved
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
  debug_session: ".planning/debug/package-toggle-count.md"
  resolved_by: 01-04-PLAN.md
  resolved_at: 2026-09-11
- gap_id: G-01-15
  truth: "Installer runs apt update (debian) or pacman -Sy (arch) before installing missing dependencies"
  status: resolved
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
  debug_session: ".planning/debug/repo-update-missing.md"
  resolved_by: 01-04-PLAN.md
  resolved_at: 2026-09-11


- gap_id: G-01-14b
  truth: "Package checklist shows all 7 packages (nvim, zsh, nushell, alacritty, starship, wofi, keyd) individually toggleable — user now expects dependencies (stow, neovim, starship, zoxide, uv, ripgrep, nodejs, npm, make, gcc, fzf, zsh, git) to also be individually toggleable, not just stow packages"
  status: failed
  reason: "User reported: there is a issue, actually i need all the apps to be toggleable not just the one that has configs to stow - Verifying dependencies lists stow/nvim/starship/zoxide/uv/rg/node/npm/make/gcc/fzf/zsh as non-toggleable deps"
  severity: major
  test: 14
  root_cause: "checklist (setup.sh:705 prompt_checklist via ALL_PACKAGES) only offers 7 stow-dirs as toggleable; get_deps()/verify_deps()/install_deps() (setup.sh:175/203/217) resolve 13 toolchain binaries unconditionally by family/mode, with no SELECTED_PACKAGES filter and no UI. User saw 'Verifying dependencies...' list of 13 binaries and expected them in checklist. Original ROADMAP criterion scoped checklist to 7 stow packages, but deps are presented identically as 'apps' causing confusion — no mapping from deps to toggle state."
  artifacts:
    - path: "setup.sh"
      issue: "ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd) hardcodes 7 toggleable; get_deps never filtered by SELECTED_PACKAGES, verify/install run unconditionally — deps never appear in prompt_checklist"
    - path: "setup.sh"
      issue: "verify_deps prints 'Verifying dependencies...' with same bullet style as package selection, implying same toggle level but checklist is separate"
  missing:
    - "Decide scope: either (A) map each dep to owning package and filter get_deps by SELECTED_PACKAGES (e.g., deselect nvim → skip neovim/node/npm/py deps), or (B) keep deps non-toggleable but add explicit UI: show deps as auto-installed toolchain with separate 'Core toolchain (always installed)' notice and preview, clarifying that only 7 stow packages are toggleable"
    - "If (A): add DEP_OWNERS associative map and checklist second step for deps or expand ALL_PACKAGES to include deps with ON/OFF; ensure dry-run previews both stow and deps under same Preview block"
    - "If (B): add pre-verify echo 'Core deps (auto-installed): stow, git, zoxide, uv, rg, node, npm, make, gcc, fzf, zsh' and checklist header 'Toggle deployable configs (7)' to disambiguate"
  debug_session: ".planning/debug/deps-toggle-scope.md"


## Deferred Follow-Ups

- test: 16
  idea: "also shell doesnt change after all the changes — deferred to Phase 2 per user (SHEL-01)"
  deferred_at: 2026-09-10
