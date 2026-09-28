---
phase: 01-universal-installer-platform-foundations
plan: 01
subsystem: infra
tags: [bash, installer, distro-detection, termux, stow, verify-install-reverify]

# Dependency graph
requires: []
provides:
  - Executable setup.sh with strict Bash header, arg parsing, and source-guard
  - Termux-first 4-tier family detection (env/pkg → manager → ID_LIKE → ID) with OS_RELEASE_FILE seam
  - Per-family dep tables (arch/debian/termux) with binary-probe map and toolchain entries
  - Verify → install → re-verify lock with dry-run preview, partitioned reporting, stow 2.4.1 upgrade, and idempotency
  - TTY-gated invocation contract (help-wins-anywhere, unknown/value-less abort, no-TTY handling, fallible-capture guards)
affects: [01-02, phase-02-uninstall, stow-orchestration, distro-handling]

# Actuals (#2632)
actuals:
  tokens: 4563
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns: [strict-mode-bash, inherit_errexit, SCRIPT_DIR-from-BASH_SOURCE, guarded-parse_args, termux-first-detection, binary-probe-map, sort-V-version-compare, verify-install-reverify, TTY-gated-prompts]

key-files:
  created: [setup.sh]
  modified: []

key-decisions:
  - "Help-wins-anywhere via pre-scan — any --help/-h exits 0 before validation (D-08)"
  - "Termux-first detection with OS_RELEASE_FILE seam for fixture tests (DEPS-01, T-01-02 mitigate)"
  - "Per-family install names (neovim/ripgrep/nodejs) mapped to binary probes (nvim/rg/node) for correct verify"
  - "Termux distinct pkg table with best-effort names (A2/A3) and per-package graceful failure messages, sudo-free (T-01-04)"
  - "Stow version check via sort -V (never lexicographic) routed through same manager lock (D-15)"
  - "Core/gui partitioned missing reporting and Still-missing residue abort with exact retry command (T-01-05)"

patterns-established:
  - "Strict header: set -Eeuo pipefail; shopt -s inherit_errexit; SCRIPT_DIR from BASH_SOURCE; repo-root guard on setup.sh presence"
  - "Guarded parsing: case ${1-} with arity check [[ $# -ge 2 ]] before consuming flag values, allowlist validation, unknown abort before any write"
  - "4-tier detect_family: TERMUX_VERSION/PREFIX/pkg → pacman/apt presence → ID_LIKE tokens → ID → manager fallback"
  - "Binary-probe map: install names neovim/ripgrep/nodejs probed via nvim/rg/node"
  - "Version compare: printf '%s\n' \"$ver\" \"2.4.1\" | sort -V | head -1 (version-sort semantics)"
  - "Verify/install/reverify: collect missing, partition core/gui, dry-run early return with [DRY RUN] Would run: argv preview, re-verify abort naming residue"

requirements-completed: [INST-01, INST-02, INST-05, DEPS-01, DEPS-02, DEPS-03]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Strict-mode entry with guarded arg parsing, usage, and source-guard (INST-05)"
    requirement: "INST-05"
    verification:
      - kind: manual_procedural
        ref: "bash -n setup.sh && bash setup.sh --help"
        status: pass
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; echo sourced-ok'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Termux-first 4-tier family detection with derivative and Termux fixtures (DEPS-01)"
    requirement: "DEPS-01"
    verification:
      - kind: manual_procedural
        ref: "OS_RELEASE_FILE=/tmp/fix-manjaro PATH=/usr/bin:/bin bash -c 'source ./setup.sh; detect_family' -> arch"
        status: pass
      - kind: manual_procedural
        ref: "OS_RELEASE_FILE=/tmp/fix-pop PATH=/usr/bin:/bin bash -c 'source ./setup.sh; detect_family' -> debian"
        status: pass
      - kind: manual_procedural
        ref: "TERMUX_VERSION=1 PREFIX=com.termux OS_RELEASE_FILE=/tmp/fix-manjaro bash -c 'source ./setup.sh; detect_family' -> termux"
        status: pass
    human_judgment: false
  - id: D3
    description: "Per-family dep tables with toolchain/history/shell entries and Termux distinct list (DEPS-02)"
    requirement: "DEPS-02"
    verification:
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; get_deps arch server' contains make gcc fzf zsh"
        status: pass
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; get_deps termux server' has no sudo/keyd/hyprland"
        status: pass
    human_judgment: false
  - id: D4
    description: "Verify → install → re-verify lock with dry-run preview, partitioned reporting, stow upgrade via sort -V, idempotent second run (INST-02, DEPS-03)"
    requirement: "DEPS-03"
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run | grep -qE 'DRY RUN|Would run'"
        status: pass
      - kind: manual_procedural
        ref: "PATH=/tmp/mock-bin:$PATH bash setup.sh --mode server --shell zsh --dry-run -> No install needed (second run no-op) with mock stow 2.4.1"
        status: pass
      - kind: manual_procedural
        ref: "grep -q 'sort -V' setup.sh"
        status: pass
    human_judgment: false
  - id: D5
    description: "Invocation contract matrix: TTY gating, help-wins, unknown/value-less abort, fallible-capture guards (INST-01, INST-05)"
    requirement: "INST-01"
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --mode 2>&1; test $? -ne 0"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --bogus-flag 2>&1; test $? -ne 0"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --dry-run --help; test $? -eq 0"
        status: pass
      - kind: manual_procedural
        ref: "printf '' | bash setup.sh --mode server </dev/null 2>&1; test $? -ne 0"
        status: pass
    human_judgment: false

# Metrics
duration: 3 min
completed: 2026-09-10
status: complete
---

# Phase 01 Plan 01: Strict-mode entry, arg parsing, and Termux-aware deps resolver Summary

**Bash strict-mode installer entry with Termux-first distro detection, per-family dep lock via verify→install→re-verify, and TTY-gated invocation contract**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-10T18:18:21Z
- **Completed:** 2026-09-10T18:21:24Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Created canonical `setup.sh` with `#!/usr/bin/env bash`, `set -Eeuo pipefail; shopt -s inherit_errexit`, `SCRIPT_DIR` from `BASH_SOURCE`, repo-root guard, and source-guard for test sourcing (INST-01, INST-05)
- Implemented guarded `parse_args` with `${1-}` defaults, arity checks before consuming values, allowlist-validated `--mode`/`--shell`, help-wins-anywhere pre-scan, unknown-flag abort before any write, and deferred `--uninstall`/`--remove`/`--yes` stubs (D-08, T-01-03)
- Built Termux-first 4-tier `detect_family` (env/pkg → manager presence → ID_LIKE tokens → ID) with `OS_RELEASE_FILE` seam, token-wise `case` matching, and manager fallback covering Manjaro/EndeavourOS/Garuda/Mint/Pop and Termux env fixtures (DEPS-01, T-01-02)
- Delivered per-family `get_deps` tables: arch/debian `common` includes `make`+`gcc`+`fzf`+`zsh` (unlocking `telescope-fzf-native` and fzf history), arch vs debian GUI splits match donors, Termux distinct `pkg` table with best-effort names (A2/A3) and per-package graceful failure messages, no `sudo` and no `keyd`/`hyprland`/`wofi` on Termux (DEPS-02, T-01-04)
- Wired binary-probe map (`neovim`→`nvim`, `ripgrep`→`rg`, `nodejs`→`node`) and `verify_deps` with per-dep `+`/`-` status lines, partitioned `core_missing` vs `gui_missing` reporting, `install_deps` 3-branch manager arrays with exact-argv `[DRY RUN] Would run:` preview and early return, `stow` `<2.4.1` auto-upgrade via `sort -V` routed through same lock, and `reverify` abort naming residue with exact retry command; second run via `--needed` is a safe no-op (INST-02, DEPS-02, DEPS-03, T-01-05)
- Hardened invocation contract: bare TTY prompts for mode→shell, no-TTY incomplete aborts with usage nonzero and zero writes, partial flags keep given values and only gaps prompt/abort, help wins with zero writes, value-less/bogus values abort with usage not strict-mode crashes, every fallible capture wrapped in `if ! VAR=$(cmd)` with split `local` declarations (D-05..D-08, Pitfalls 2-3)

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — end-to-end strict entry plus resolver dry-run on one family** - `1b4e724` (feat)
2. **Task 2: Expansion — full three-family dep lock with upgrade and idempotency** - `f867d35` (feat)
3. **Task 3: Expansion — invocation contract matrix (TTY gating and flag precedence)** - `a7f9fb7` (feat)

**Plan metadata:** `pending` (docs: complete plan — next commit)

_Note: All three tasks were feat commits with production-quality implementation and verification._

## Files Created/Modified

- `setup.sh` - Canonical Bash installer entry: strict header, SCRIPT_DIR, usage, parse_args, detect_family, get_deps, verify_command/verify_deps, install_deps, reverify_deps, prompt_mode/prompt_shell, main with TTY gating, source-guard — 582 lines, executable, `bash -n` clean

## Decisions Made

- Help-wins-anywhere via pre-scan loop over `"$@"` before any other parsing — ensures `bash setup.sh --bogus-flag --help` exits 0 with usage (D-08)
- Termux detection Tier 1 checks `TERMUX_VERSION`/`PREFIX`/`command -v pkg` before touching os-release — avoids misclassifying Termux as debian/arch (Pitfall 5, T-01-04)
- `OS_RELEASE_FILE` override seam defaults to `/etc/os-release` but is read dynamically inside `detect_family` for fixture tests
- Per-family install names use distro-correct package names (`neovim` not `nvim`, `ripgrep` not `rg`, `nodejs` not `node`) with probe map in `verify_deps` — fixes donor defect where `nvim`/`rg` package names would fail on apt/pacman
- Termux common includes `uv` as best-effort (A3) with per-package `pkg install -y $pkg` loop and `pkg search` hint on failure — partial failure doesn't abort whole Termux install
- Stow version comparison uses `sort -V` (version-sort) never lexicographic — correctly handles `2.10` > `2.4.1` (RESEARCH Don't Hand-Roll)
- Core/gui partition via `gui_list` case per family — matches donor `install_deps_interactive` `case "$dep" in stow|nvim|...` shape for consistent reporting

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Pre-existing dirty planning state (`M .planning/STATE.md`, `M .planning/config.json`, `?? .planning/phases/.../01-PATTERNS.md`, `?? .planning/research/.cache/`) caused absolute `git status --porcelain -- ':!setup.sh'` zero-writes check to report non-zero; verified zero writes via setup.sh SHA stability and before/after status delta instead — no writes from dry-run/help/unknown-flag paths.
- Host `stow 2.3.1` is outdated per D-15; dry-run correctly shows `Stow 2.3.1 < 2.4.1 — will upgrade` and previews `sudo apt install -y stow`; mock stow 2.4.1 verifies second-run no-op path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Installer spine is complete and testable: `bash setup.sh --help`, `bash setup.sh --mode server --shell zsh --dry-run`, and fixture-based `detect_family` tests all pass on this host.
- Ready for 01-02: stow orchestration core + dry-run + checklist ladder (`gum→whiptail→dialog→fzf→read`) before any write — builds directly on `setup.sh`'s strict entry and dep lock.
- No blockers; Termux fixture coverage is via env/pkg probes and os-release fixtures (no Termux device needed), version-sort and idempotency proven via mock stow.

---
*Phase: 01-universal-installer-platform-foundations*
*Completed: 2026-09-10*

## Self-Check: PASSED

- Found: setup.sh (582 lines, executable, bash -n clean)
- Commits: 1b4e724, f867d35, a7f9fb7 all present in git log
- Verifications: all <verification> commands re-run and pass (help/dry-run/fixtures/version-sort)
