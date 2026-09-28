---
phase: 01-universal-installer-platform-foundations
plan: 03
subsystem: infra
tags: [bash, installer, posix-guard, sh-compat]

# Dependency graph
requires:
  - phase: 01-universal-installer-platform-foundations
    provides: Executable setup.sh with strict Bash header and verify-install-reverify lock
provides:
  - POSIX-safe Bash detection guard before strict mode with friendly guidance for sh invocation
affects: [phase-02, installer, distro-handling]

# Actuals (#2632)
actuals:
  tokens: 95
  tasks: 1
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns: [posix-bash-guard, BASH_VERSION-check, early-exit-guidance]

key-files:
  created: []
  modified: [setup.sh]

key-decisions:
  - "POSIX guard via [ -z \"${BASH_VERSION-}\" ] before set -Eeuo pipefail ensures dash/sh fails fast with guidance instead of Illegal option -o pipefail"
  - "Single-line guard preserves existing strict header order: shebang -> guard -> set -Eeuo pipefail -> shopt -s inherit_errexit"
  - "No bashisms before guard (no [[, arrays, BASH_SOURCE) to remain executable under POSIX sh"

patterns-established:
  - "Bash guard: if [ -z \"${BASH_VERSION-}\" ]; then echo \"Error: This installer must be run with Bash.\" >&2; echo \"Use: bash setup.sh [OPTIONS]  (not sh setup.sh)\" >&2; echo \"See: bash setup.sh --help\" >&2; exit 1; fi placed immediately after shebang"

requirements-completed: [INST-01, INST-05]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "POSIX-safe Bash guard: sh setup.sh prints friendly 'must be run with Bash' and exits 1, bash and shebang paths unchanged"
    requirement: "INST-01"
    verification:
      - kind: manual_procedural
        ref: "bash -n setup.sh && echo ok"
        status: pass
      - kind: manual_procedural
        ref: "sh setup.sh 2>&1 | grep -q 'must be run with Bash' && test sh_exit -ne 0"
        status: pass
      - kind: manual_procedural
        ref: "sh setup.sh --help 2>&1 | grep -q 'must be run with Bash'"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --help 2>&1 | grep -q 'Usage:' && test bash_exit -eq 0"
        status: pass
      - kind: manual_procedural
        ref: "./setup.sh --help 2>&1 | grep -q 'Usage:' && test shebang_exit -eq 0"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'DRY RUN'"
        status: pass
    human_judgment: false

# Metrics
duration: 1 min
completed: 2026-09-10
status: complete
---

# Phase 01 Plan 03: Bash guard for sh invocation Summary

**POSIX-safe Bash detection guard before strict mode so `sh setup.sh` fails fast with friendly guidance instead of `Illegal option -o pipefail`, preserving `bash` and shebang paths**

## Performance

- **Duration:** 1 min
- **Started:** 2026-09-10T20:00:00Z
- **Completed:** 2026-09-10T20:00:13Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Inserted POSIX-safe Bash guard at `setup.sh:2` before `set -Eeuo pipefail`: `if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi` — executes under `dash`/`sh` without `unbound variable` or `Illegal option` and guides user to correct invocation (G-01-12)
- Preserved all verified `bash` paths: `bash -n setup.sh` clean, `bash setup.sh --help` exits 0 with `Usage:`, `./setup.sh --help` via shebang exits 0 with `Usage:`, `bash setup.sh --mode server --shell zsh --dry-run` still prints `DRY RUN` and zero writes

## Task Commits

Each task was committed atomically:

1. **Task 1: Insert POSIX-safe Bash guard before strict mode** - `b396f4a` (fix)

**Plan metadata:** `pending` (docs: complete plan — next commit)

## Files Created/Modified

- `setup.sh` - Added POSIX Bash guard at line 2 before strict mode; retains `set -Eeuo pipefail` and `shopt -s inherit_errexit` immediately after guard — 751 lines, `bash -n` clean, `chmod +x` preserved

## Decisions Made

- POSIX guard via `[ -z "${BASH_VERSION-}" ]` before any Bash-only syntax — using `${BASH_VERSION-}` (parameter expansion with default) avoids `unbound variable` under `set -u` in `dash`, and `[` is POSIX while `[[` is Bash-only (per `sh-pipefail-guard.md` evidence: `dash -c 'set -o pipefail'` fails but `[ -z "${BASH_VERSION-}" ]` succeeds in both shells)
- Single-line guard with `;` separators placed immediately after `#!/usr/bin/env bash` and before `set -Eeuo pipefail` — satisfies plan's `bash-guard` key_link (guard precedes strict mode and aborts with guidance) and prohibition (no bashisms before guard)
- Message wording exactly `"Error: This installer must be run with Bash."` + `"Use: bash setup.sh [OPTIONS]  (not sh setup.sh)"` + `"See: bash setup.sh --help"` as specified in plan critical rules — matches README's canonical `bash setup.sh` invocation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — all verification commands passed on first run; `sh`/`dash` now returns guidance with exit 1, `bash` paths show no regression.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Gap G-01-12 closed: `sh setup.sh` UAT trap now provides deterministic guidance, restoring trust in `VERIFICATION.md` 13/13 must-haves
- Ready for remaining gap closures: `01-04` (G-01-13..15 checklist ordering, toggle count, repo refresh) and Phase 2 work
- No blockers; `setup.sh` remains `bash -n` clean and dry-run verified

---
*Phase: 01-universal-installer-platform-foundations*
*Completed: 2026-09-10*

## Self-Check: PASSED

- Found: setup.sh (751 lines, guard at line 2 contains BASH_VERSION, bash -n clean)
- Verifications: sh setup.sh exits 1 with "must be run with Bash", sh --help same, bash --help exits 0 with Usage, ./setup.sh --help exits 0 with Usage, dry-run prints DRY RUN
- Commit: b396f4a present in git log
