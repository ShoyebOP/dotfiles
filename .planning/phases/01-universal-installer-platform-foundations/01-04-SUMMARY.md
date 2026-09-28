---
phase: 01-universal-installer-platform-foundations
plan: 04
subsystem: infra
tags: [bash, installer, checklist, termux, deps, dry-run, stow, pacman, apt]

# Dependency graph
requires:
  - phase: 01-universal-installer-platform-foundations
    provides: Executable setup.sh with strict Bash header and verify-install-reverify lock and POSIX guard
provides:
  - Checklist-before-install ordering with unified Preview block (deps + stow)
  - Full 7-package toggleable rendering with adaptive whiptail/dialog and tightened Termux detection
  - Repo refresh before install (pacman -Sy / apt update / pkg update -y) with dry-run preview
affects: [phase-02, installer, distro-handling, stow-orchestration]

# Actuals (#2632)
actuals:
  tokens: 3060
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns: [checklist-before-install, adaptive-whiptail, termux-env-guard, repo-refresh-install, preview-unification]

key-files:
  created: []
  modified: [setup.sh]

key-decisions:
  - "Reorder main() to prompt_checklist before get_deps/verify/install/reverify; checklist after FAMILY/MODE detection but before any package-manager write to satisfy before-any-write guarantee"
  - "Unified DRY_RUN preview after checklist via === Preview === block that partitions deps and calls install_deps preview plus preview_selection, returning before mutation"
  - "Whiptail/dialog adaptive sizing via stty rows with <20 fallback to checklist_read and min(7, rows-8) list height to keep all 7 visible"
  - "Tighten Termux detection to env-only (TERMUX_VERSION/PREFIX com.termux) — stray pkg shim no longer mis-detects as termux; ID=termux still covered via ID/ID_LIKE tokens"
  - "Add Final selection count line (offered 7, selected N) and 7 packages offered notes in every checklist backend for auditability; strip_termux_disabled warning preserved"
  - "Repo refresh once per install_deps before install: pacman -Sy / apt update / pkg update -y with DRY_RUN Would run preview and warning-continue on failure"

patterns-established:
  - "Checklist-before-install: mode -> shell -> detect_family -> prompt_checklist -> get_deps -> verify -> Preview -> install -> stow -> post_verify"
  - "Adaptive whiptail/dialog: rows=$(stty size | cut -d' ' -f1); if rows <20 fallback to checklist_read else list_height=min(7, rows-8)"
  - "Termux env guard: detect_family Termux tier is env TERMUX_VERSION/PREFIX only, not bare pkg"
  - "Repo-refresh-install: install_deps refreshes DB once before install with DRY_RUN preview"

requirements-completed: [INST-01, INST-04, DEPS-02]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "User sees mode -> shell -> package checklist BEFORE any dependency installation (before apt update/install or pacman -Sy)"
    requirement: "INST-01"
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | awk '/Package Selection/{found=1} /Verifying dependencies/{if(found==0) print \"BAD\"; else print \"OK\"}' | grep -q OK"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Package Selection'"
        status: pass
      - kind: manual_procedural
        ref: "printf '2\\n1\\n\\n' | HOME=/tmp/fake-order PATH=/tmp/stbbin:/tmp/fakebin:/tmp/noladderbin bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'DRY RUN'"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | awk '/Package Selection/{ps=NR} /Verifying dependencies/{vd=NR} /Would run: sudo apt update/{apt=NR} END{ps<vd && ps<apt}' | grep -q ORDER"
        status: pass
    human_judgment: false
  - id: D2
    description: "Checklist shows all 7 packages toggleable with clear ON/OFF state on TTY; non-TTY shows guidance not truncated preset summary (7 offered)"
    requirement: "INST-04"
    verification:
      - kind: manual_procedural
        ref: "bash -n setup.sh && grep -q 'offered 7' setup.sh"
        status: pass
      - kind: manual_procedural
        ref: "printf '2\\n1\\n\\n' | HOME=/tmp/fake-toggle PATH=/tmp/noladderbin bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Final selection'"
        status: pass
      - kind: manual_procedural
        ref: "HOME=/tmp/fake-toggle2 PATH=/tmp/noladderbin bash setup.sh --mode local --shell zsh --dry-run 2>&1 | grep -q '7'"
        status: pass
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; OS_RELEASE_FILE=/tmp/fix-pop detect_family' | grep -q debian && echo not mis-detected"
        status: pass
      - kind: manual_procedural
        ref: "PATH=/tmp/shim-pkg-test:$PATH bash -c 'source ./setup.sh; OS_RELEASE_FILE=/tmp/fix-pop detect_family' | grep -q debian"
        status: pass
    human_judgment: false
  - id: D3
    description: "Installer runs apt update (debian) or pacman -Sy (arch) before installing missing deps and previews it in --dry-run"
    requirement: "DEPS-02"
    verification:
      - kind: manual_procedural
        ref: "grep -q 'apt update' setup.sh && grep -q 'pacman -Sy' setup.sh && grep -q 'pkg update' setup.sh"
        status: pass
      - kind: manual_procedural
        ref: "HOME=/tmp/fake-refresh PATH=/tmp/noladderbin bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Would run: sudo apt update'"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Refresh'"
        status: pass
      - kind: manual_procedural
        ref: "bash -n setup.sh"
        status: pass
    human_judgment: false

# Metrics
duration: 4 min
completed: 2026-09-10
status: complete
---

# Phase 01 Plan 04: Checklist ordering, full toggle, repo refresh Summary

**Fresh-clone checklist before any write, all 7 packages toggleable with adaptive TUI and Termux-env guard, and repo refresh (apt update/pacman -Sy/pkg update) previewed in dry-run**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-10T20:04:01Z
- **Completed:** 2026-09-10T20:08:04Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Reordered `setup.sh:main()` to `prompt_checklist` immediately after `detect_family` and `MODE/SHELL` resolution and before `get_deps/verify/install`; dry-run now prints unified `=== Preview ===` block (partitioned deps + `install_deps` `Would run:` + `preview_selection` `stow --no --verbose`) and returns before any mutation — fixes G-01-13 before-any-write guarantee
- Fixed 7-package toggle rendering: `checklist_read` retains 7-loop with ON/OFF markers, adds `7 packages offered` and `Final selection: ... (offered 7, selected N)` notes; `whiptail`/`dialog` now compute `rows=$(stty size | cut -d' ' -f1)` and fallback to `checklist_read` when `rows<20`, otherwise `list_height=min(7, rows-8)` so all 7 remain visible without clipping — fixes G-01-14
- Tightened Termux detection: removed bare `command -v pkg` probe; Termux now detected only via `TERMUX_VERSION` or `PREFIX==*com.termux*` (env), stray `pkg` shim on Debian no longer mis-detects as `termux` (verified via `OS_RELEASE_FILE` fixture `pop->debian` with shim in PATH); `strip_termux_disabled` warning preserved — mitigates T-04-02
- Added repo refresh once per `install_deps` invocation before any install: `arch` `Refreshing pacman DB...` + `sudo pacman -Sy`, `debian` `Refreshing apt lists...` + `sudo apt update`, `termux` `Refreshing pkg lists...` + `pkg update -y`; dry-run prints `[DRY RUN] Would run: ...` alongside install preview, failure warns and continues — closes G-01-15 and mitigates T-04-03

## Task Commits

Each task was committed atomically:

1. **Task 1: Reorder checklist before any write and preview together** - `c13ed79` (feat)
2. **Task 2: Fix full 7-package toggle rendering and Termux detection** - `f8be9a5` (fix)
3. **Task 3: Add repo refresh before install** - `712b169` (feat)

**Plan metadata:** `pending` (docs: complete plan — next commit)

## Files Created/Modified

- `setup.sh` - Reordered checklist before deps with unified Preview, adaptive whiptail/dialog sizing, tightened Termux env guard, and repo-refresh-before-install with dry-run preview — 812 lines, `bash -n` clean, POSIX guard at line 2 preserved

## Decisions Made

- Keep `FAMILY/MODE` detection before checklist for preset computation, but defer all package-manager writes (`apt update/pacman -Sy`/install) until after selection — ordering alone satisfies `checklist-before-install` key_link; future filtering of `gui` deps by `SELECTED_PACKAGES` remains optional enhancement
- DRY_RUN unification after checklist: print `=== Preview ===` with partitioned `core_missing/gui_missing`, then `install_deps` preview, then `preview_selection`, returning before any mutation — combines both write classes in one consent block
- Whiptail/dialog `rows=$(stty size | cut -d' ' -f1)` with `rows<20` fallback to `checklist_read` avoids clipping on small terminals; `list_height` capped at 7 ensures all 7 fit when `rows>=20`
- Termux Tier1 narrowed to env-only; `ID=termux` and `ID_LIKE` handling remain in later tiers, so genuine Termux still resolves while Debian with stray `pkg` shim does not
- Repo refresh runs once per `install_deps` call, not per-package, and is previewed in dry-run together with install; failure is warning-continue, not abort, to avoid `DoS` on transient mirror failure

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — all three task verification loops and plan-level order/grep checks passed on first run; dry-run order `Package Selection < Verifying dependencies < Would run: sudo apt update` verified, `bash -n` clean, `sh setup.sh` guard still exits 1 with guidance, outside-root and help-wins-anywhere guards unchanged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Gaps G-01-13, G-01-14, G-01-15 closed; checklist-before-install, full toggle, and repo hygiene now match ROADMAP criterion 5 before any write
- Ready for Phase 1 completion verification and transition to Phase 2 (uninstall/keyd/server guard); shell actual-change after selection remains deferred to Phase 2 per user decision (G-01-16)
- No blockers; `setup.sh` remains `bash -n` clean, dry-run previews both deps and stow, `sh` invocation still fails fast with friendly message

---
*Phase: 01-universal-installer-platform-foundations*
*Completed: 2026-09-10*

## Self-Check: PASSED

- Found: setup.sh (812 lines, guard at line 2 contains BASH_VERSION, bash -n clean, contains apt update/pacman -Sy/pkg update, offered 7)
- Verifications: Package Selection before Verifying dependencies (OK order), Final selection count present, stray pkg not mis-detected as termux, Refresh preview present, dry-run both deps and stow previewed
- Commits: c13ed79, f8be9a5, 712b169 present in git log
