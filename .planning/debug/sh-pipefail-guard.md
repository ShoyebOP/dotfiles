# Debug Session: sh setup.sh pipefail guard

**Phase:** 01-universal-installer-platform-foundations
**Gap:** G-01-12
**Symptom:** `sh setup.sh` fails with `setup.sh: 2: set: Illegal option -o pipefail`
**Severity:** major
**Test:** 12

## Symptoms

- User ran `sh setup.sh` (or `sh setup.sh --help`) from repo root
- Immediate error: `setup.sh: 2: set: Illegal option -o pipefail`
- Exit code 2
- No usage shown, no friendly guidance

- Verified: `sh setup.sh` on this host reproduces: exit 2, same message
- `bash setup.sh --help` works (exit 0, shows usage)
- `dash -c 'set -o pipefail'` similarly fails: `Illegal option -o pipefail`
- `bash -c 'set -o pipefail; echo ok'` succeeds

## Investigation

- Read `setup.sh:1-10`
  - Line 1: `#!/usr/bin/env bash` — correct shebang for `./setup.sh` direct execution
  - Line 2: `set -Eeuo pipefail` — bash-specific (pipefail not POSIX)
  - Line 3: `shopt -s inherit_errexit` — bash-specific
  - Lines 5+: uses `BASH_SOURCE`, arrays `declare -a`, `[[`, `mapfile`, etc — all bash-only

- Root mechanism: POSIX shell spec does not define `pipefail` or `shopt`. Dash (Ubuntu `sh`) aborts at line 2 before any application code runs. There is no guard earlier that can emit a friendly message.

- Checked docs: `README.md` says `bash setup.sh` everywhere after 01-02 rewrite (verified `grep -q 'bash setup.sh' README.md` pass, no `sh setup.sh`). But users commonly try `sh <script>` out of habit, especially when migrating from `sh setup.zsh` mental model or following generic shell instructions.

- Checked prior verification: `01-VERIFICATION.md` tested only `bash setup.sh --help` and `bash -n setup.sh`, never `sh setup.sh`. So this path was never exercised.

- Checked other scripts: `teardown.zsh` etc are zsh, not relevant. `setup.sh` is executable (`-rwxrwxr-x`) so `./setup.sh` would also invoke bash via shebang — that path already works. Only `sh setup.sh` bypasses shebang.

## Root Cause

**setup.sh lines 2-3 execute Bash-only strict mode unconditionally without first verifying the running shell is Bash.** When invoked as `sh setup.sh`, dash parses `set -Eeuo pipefail` and fails with `Illegal option -o pipefail` before any error handling or usage can run.

- File: `setup.sh:2` — `set -Eeuo pipefail`
- File: `setup.sh:3` — `shopt -s inherit_errexit`
- Missing: early Bash detection guard (e.g., `if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash..." >&2; exit 1; fi`)

## Evidence Summary

- `sh setup.sh 2>&1` → `setup.sh: 2: set: Illegal option -o pipefail` (reproduced)
- `dash -c 'set -o pipefail'` → same Illegal option (confirms POSIX sh limitation)
- `bash -n setup.sh` clean, `bash setup.sh --help` exit 0 (confirms script is valid bash)
- No code before line 2 can intercept the error — guard must precede `set`
- `BASH_VERSION` is the canonical detector (`[ -z "${BASH_VERSION-}" ]` works in both sh and bash without triggering unbound variable)

## Files Involved

- `setup.sh:1-5` — needs guard inserted before strict mode
- `README.md` — already says `bash setup.sh`, no change required but guard message should echo same invocation hint
- `.planning/phases/01-universal-installer-platform-foundations/01-VERIFICATION.md` — never tested `sh` invocation path

## Suggested Fix Direction

- Insert at top of `setup.sh` (line 2, before `set -Eeuo pipefail`):

```bash
if [ -z "${BASH_VERSION-}" ]; then
  echo "Error: This installer must be run with Bash." >&2
  echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2
  echo "See: bash setup.sh --help" >&2
  exit 1
fi
```

- This is POSIX-safe (no bashisms before guard), prints friendly guidance, and preserves existing behavior for correct `bash setup.sh` invocation.
- Optionally also check for bash version >= 4? Not needed — `inherit_errexit` requires 4.4+, but existing host check uses that; guard's primary job is to redirect `sh` users.

## Reproduction Steps

1. `sh setup.sh` → error Illegal option -o pipefail (before fix)
2. `sh setup.sh` → friendly "must be run with Bash" (after fix)
3. `bash setup.sh --help` → still 0 and shows usage (no regression)
4. `./setup.sh --help` → via shebang, still 0 (no regression)
5. `bash -n setup.sh` → clean (no syntax error from guard)
