---
phase: 01-universal-installer-platform-foundations
reviewed: 2026-09-11T00:45:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - setup.sh
  - README.md
  - .gitignore
findings:
  critical: 2
  warning: 5
  info: 2
  total: 9
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-09-11T00:45:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the Phase 01 unified Bash installer (`setup.sh` 737 lines, `bash -n` clean, executable 775, `set -Eeuo pipefail` + `inherit_errexit`, `SCRIPT_DIR` via `BASH_SOURCE`), its docs (`README.md` 156 lines) and gitignore. Diff versus 6 commits earlier shows 778 insertions/1031 deletions, staged deletion of `setup.nu`/`setup.zsh`, addition of `.stow-conflicts/` quarantine. Verified mandatory safety ladders: strict header, Termux-first 4-tier `detect_family`, guarded `parse_args` (`${1-}` + arity checks), `OS_RELEASE_FILE` seam, `get_deps` per-family tables, `verify->install->re-verify` lock, `sort -V` stow upgrade, 5-backend `gum->whiptail->dialog->fzf->read` ladder with preset contract and Termux disabled-row emulation, `quarantine_scan` `mv`-only with `MANIFEST`, explicit `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow`, folding-aware `post_verify` via `readlink -f`, outside-root guard, keyd skip, source-guard, `DRY_RUN` preview, `--adopt` absence and `rm -rf` absence. Core flow is correct and meets INST-01/02/04/05 STOW-01 DEPS-01/02/03, but two Critical injection-class defects and five Warning correctness/robustness gaps must be fixed before Phase 2.

**Passing controls (verified):**
- Strict mode header present, `SCRIPT_DIR` resolved from `BASH_SOURCE[0]` (L5), source-guard `BASH_SOURCE[0]==$0` (L737) — sourcing for tests does not execute `main`.
- Guarded parsing: `case "${1-}"`, `[[ $# -lt 2 ]]` before consuming values, allowlist `local|server` / `zsh|nushell`, help-wins pre-scan, unknown flag abort before any write (L47-L133) — `bash setup.sh --bogus-flag` now correctly exits 1, `--help` exits 0.
- Termux-first detection (L137-L144) via `TERMUX_VERSION` / `PREFIX=*com.termux*` / `command -v pkg` before touching os-release; manager presence fallback after `ID_LIKE`/`ID` token-wise `case`; derivative fixtures `manjaro->arch`, `pop->debian` verified.
- Dep tables (L172-L196): `arch`/`debian` common includes `make gcc fzf zsh` + distinct GUI splits, `termux` `gui=()` and sudo-free `pkg install -y` loop with per-package `pkg search` hint (L230-L237).
- Checklist ladder order locked `gum->whiptail->dialog->fzf->read` (L629-L648), cancel `return 2` never cascades, `strip_termux_disabled` (L287) drops disabled with warning, `preview_selection` `stow --no --verbose` simulation and `[DRY RUN] Would run:` argv (L302-L313).
- Quarantine uses `mv` only (L347), preserves relative paths under `.stow-conflicts/<timestamp>/` (L318-L319), no `rm -rf` string in file, no `--adopt` flag.
- Post-verify folding-aware `readlink -f` prefix check `"$SCRIPT_DIR/$pkg/"*` (L368) covers folded `~/.config` dir-links.
- Outside-root guard checks both `SCRIPT_DIR/setup.sh` and `./setup.sh` (L652-L659) before any prompt/write.
- Version compare via `sort -V` (L698) correctly handles `2.10 > 2.4.1`, stow outdated auto-added to `missing`/`core_missing`.
- Docs: `README.md` canonical `bash setup.sh --mode/--shell [--dry-run]`, Zsh default/Nushell backup, 7-package list, ladder description, quarantine and post-verify safety notes, manual `stow --dir=. --target="$HOME"` one-liners, keyd deferred block — no `setup.nu`/`.zsh` references outside planning history; `.gitignore` quarantine entry present.

## Critical Issues

### CR-01: Command injection via `eval` in checklist backends

**File:** `setup.sh:480` and `setup.sh:521`
**Issue:** `checklist_whiptail` and `checklist_dialog` parse `whiptail`/`dialog` output with `eval "SELECTED_PACKAGES=($sel)"`. `eval` executes arbitrary shell code. Although normal output is quoted package names (`"nvim" "zsh"`), an attacker who can replace `whiptail`/`dialog` in `PATH` (common in CI, or via `PATH` injection) or a future TUI bug that emits shell metacharacters (e.g., `"; rm -rf $HOME; echo "`) would get immediate code execution inside the installer running with user privileges and later `sudo` for package installs. Even without malice, `eval` mis-parses package names containing spaces or quotes. The post-eval allowlist filter (L482-L488) runs *after* the injection already executed, so it does not mitigate. This is flagged by the dangerous-function pattern `eval\(` and violates the project's high-severity stride expectation.

**Reproduce:** `sel='"; echo pwned >&2; echo "'` -> `eval "SELECTED_PACKAGES=($sel)"` prints `pwned`.
**Fix:** Remove `eval`. Parse quoted output safely without shell evaluation:

```bash
# BEFORE (L480):
eval "SELECTED_PACKAGES=($sel)"
local -a filtered=()
local s
for s in "${SELECTED_PACKAGES[@]}"; do
    s="${s//\"/}"
    for pkg in "${ALL_PACKAGES[@]}"; do if [[ "$s" == "$pkg" ]]; then filtered+=("$s"); break; fi; done
done

# AFTER — safe, no eval:
local -a raw=()
# whiptail/dialog return space-separated quoted tags: "nvim" "zsh"
# Use xargs to split respecting quotes, then allowlist filter directly
local -a parsed=()
if ! read -ra parsed < <(xargs -n1 <<< "$sel" 2>/dev/null); then parsed=(); fi
# xargs output is one token per line; alternatively:
# while IFS= read -r tok; do parsed+=("$tok"); done < <(printf '%s' "$sel" | xargs -n1)
local -a filtered=()
local tok clean
for tok in "${parsed[@]}"; do
    clean="${tok#\"}"; clean="${clean%\"}"
    clean="${clean#\'}"; clean="${clean%\'}"
    for pkg in "${ALL_PACKAGES[@]}"; do
        if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi
    done
done
SELECTED_PACKAGES=("${filtered[@]}")
```

Alternatively use `eval` replacement with safe array assignment:

```bash
# Minimal safe fix — interpret sel as bash array literal without eval via declare:
declare -a SELECTED_PACKAGES="($sel)"  # still eval-like — NOT safe
# Prefer explicit parsing above
```

Apply to both `checklist_whiptail` and `checklist_dialog`. Keep the subsequent `strip_termux_disabled` call unchanged.

---

### CR-02: Arbitrary code execution via sourced `OS_RELEASE_FILE` override

**File:** `setup.sh:149`
**Issue:** `detect_family` sources the file named by `OS_RELEASE_FILE` with `. "$os_file" 2>/dev/null`. `OS_RELEASE_FILE` is an env-controlled override seam (L12 `OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"`, L147 `local os_file="${OS_RELEASE_FILE:-/etc/os-release}"`). An operator (or a compromised parent process, CI env, or wrapper script) can set `OS_RELEASE_FILE=/tmp/malicious_os` containing arbitrary shell code which is then sourced and executed with the installer's privileges before any validation. The threat model (T-01-02) mitigates sourcing the *vendor* root-owned file by token comparison, but the override seam breaks that: demonstrated exploit prints `pwned` and controls `arch`/`debian`/`termux` detection to bypass Termux `sudo`-free path or force wrong manager.

**Reproduce:**
```bash
echo 'echo pwned; ID=arch' > /tmp/malicious_os
OS_RELEASE_FILE=/tmp/malicious_os bash -c 'source ./setup.sh; detect_family'
# prints pwned
```

**Fix:** Do not source the file. Parse it with safe text tools and never execute its contents. Validate the path first (optional root-owned check), then extract `ID`/`ID_LIKE` via grep:

```bash
# BEFORE (L148-L149):
local os_file="${OS_RELEASE_FILE:-/etc/os-release}"
if [[ -f "$os_file" ]]; then
    if ! . "$os_file" 2>/dev/null; then id=""; id_like=""; else id="${ID:-}"; id_like="${ID_LIKE:-}"; fi
fi

# AFTER — safe parsing, no execution:
local os_file="${OS_RELEASE_FILE:-/etc/os-release}"
local id="" id_like=""
if [[ -f "$os_file" ]]; then
    # Optional: warn if file is not root-owned / world-writable
    # if [[ ! -O "$os_file" ]] && [[ "$(stat -c %U "$os_file" 2>/dev/null)" != "root" ]]; then
    #     echo "Warning: OS_RELEASE_FILE not root-owned: $os_file" >&2
    # fi
    id="$(grep -m1 -E '^ID=' "$os_file" 2>/dev/null | cut -d= -f2- | tr -d '"'\'' ' | head -n1 || true)"
    id_like="$(grep -m1 -E '^ID_LIKE=' "$os_file" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'" || true)"
    # ID_LIKE is space-separated, keep internal spaces but strip quotes
    id_like="$(echo "$id_like" | tr -d '"'\')"
fi
```

If sourcing must be retained for fixture test ergonomics, at minimum restrict to a static allowlist and disable `OS_RELEASE_FILE` override outside tests, or validate that the file contains only `ID`/`ID_LIKE` assignments via `grep -Ev '^\s*(ID|ID_LIKE|VERSION_ID|PRETTY_NAME)='`.

---

## Warnings

### WR-01: Broken quarantine restore hint — `cut -d'>'` corrupts `->` manifest lines

**File:** `setup.sh:342`
**Issue:** The manifest restore hint writes:
```bash
echo "# Or: cat $manifest | while read line; do src=\$(echo \"\$line\" | cut -d'>' -f1); dst=\$(echo \"\$line\" | cut -d'>' -f2); mv \"\$dst\" \"\$src\"; done"
```
Manifest lines are `$home_target -> $q_target` (L347 `echo "$home_target -> $q_target" >> "$manifest"`). `cut -d'>' -f1` splits on the `>` character, not the `->` token, producing `src="/home/user/.config/foo -"` (trailing space + dash) and `dst=" /repo/.stow-conflicts/ts/foo"` (leading space). The subsequent `mv "$dst" "$src"` fails due to the stray ` -` and leading spaces, leaving the user unable to restore quarantined files by following the documented procedure. This is a data-recovery defect after a safety-critical `mv`.

**Fix:**
```bash
# BEFORE:
echo "# Or: cat $manifest | while read line; do src=\$(echo \"\$line\" | cut -d'>' -f1); dst=\$(echo \"\$line\" | cut -d'>' -f2); mv \"\$dst\" \"\$src\"; done"

# AFTER — split on ' -> ' and trim:
echo "# Or: while IFS=' -> ' read -r src dst; do [[ -z \"\$src\" || -z \"\$dst\" ]] && continue; mv \"\$dst\" \"\$src\"; done < \"$manifest\""
# Or more robustly:
echo "# Or: awk -F' -> ' 'NF==2 {system(\"mv -- \\\"\" \$2 \"\\\" \\\"\" \$1 \"\\\"\")}' \"$manifest\""
```
Also consider writing the manifest with a safer delimiter (tab or `|`) and documenting `mv -- "$q_target" "$home_target"`.

---

### WR-02: Quarantine timestamp collision and manifest truncation

**File:** `setup.sh:317-344`
**Issue:** `ts=$(date +%Y%m%d-%H%M%S 2>/dev/null)` has one-second granularity. Two concurrent or rapid re-runs within the same second share `qdir="$SCRIPT_DIR/.stow-conflicts/$ts"`. First collision creates `mkdir -p "$qdir"` and `> "$manifest"` (truncate). Second run's first collision re-enters `if [[ "$quarantined_count" -eq 0 ]]` and re-creates `mkdir -p` (no-op) but overwrites the manifest with `>`, losing the first run's entries. Subsequent `q_target` duplicate check (`[[ -e "$q_target" ]]`) may skip files that failed to be recorded. Mixed quarantines become unrecoverable.

**Fix:**
```bash
# BEFORE:
if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then ts="$(date +%s)"; fi
local qdir="$SCRIPT_DIR/.stow-conflicts/$ts"

# AFTER — nanosecond + PID + mktemp for uniqueness:
local ts
if ! ts=$(date +%Y%m%d-%H%M%S-%N 2>/dev/null); then ts="$(date +%s)-$$"; else ts="${ts}-$$"; fi
local qdir
if ! qdir=$(mktemp -d "$SCRIPT_DIR/.stow-conflicts/$ts.XXXXXX" 2>/dev/null); then
    qdir="$SCRIPT_DIR/.stow-conflicts/$ts-$$"
    mkdir -p "$qdir"
fi
local manifest="$qdir/MANIFEST"
# Also guard manifest creation with >> or test -f before truncating:
if [[ ! -f "$manifest" ]]; then
    {
        echo "# Stow quarantine manifest"
        # ...
    } > "$manifest"
fi
```
Or append `$$` and use `date +%s%N` on hosts where `%N` is supported.

---

### WR-03: Broken symlink not quarantined — leads to `stow --restow` collision

**File:** `setup.sh:329-330`
**Issue:** `if [[ ! -e "$home_target" ]]; then continue; fi` uses `-e` which returns false for broken symlinks (dangling). A broken symlink at `$HOME/.config/nvim` (e.g., leftover from previous manual stow) is thus skipped, never moved to quarantine. On `run_stow`, `stow --restow` then fails with `existing target is not owned by stow` or similar because the path already exists as a symlink, even though broken. `post_verify` then reports `MISSING` (since `! -e` true) rather than the clearer stash-and-retry path.

**Fix:**
```bash
# BEFORE:
if [[ ! -e "$home_target" ]]; then continue; fi
local canon=""
if canon=$(readlink -f "$home_target" 2>/dev/null); then
    if [[ "$canon" == "$pkg_dir/"* ]] || [[ "$canon" == "$pkg_dir" ]]; then continue; fi
fi

# AFTER — treat broken symlink as collision:
if [[ ! -e "$home_target" && ! -L "$home_target" ]]; then continue; fi
local canon=""
# readlink -m canonicalizes even if leaf is missing/broken
if canon=$(readlink -m "$home_target" 2>/dev/null); then
    if [[ "$canon" == "$pkg_dir/"* ]] || [[ "$canon" == "$pkg_dir" ]]; then
        # Also verify the symlink actually points correctly, not just its resolved path prefix
        # If it's a broken symlink whose -m still matches pkg_dir but -e is false, we still skip
        # only if it's already a symlink to the right target:
        if [[ -L "$home_target" ]] && [[ "$(readlink -f "$home_target" 2>/dev/null)" == "$pkg_dir"* ]]; then
            continue
        elif [[ ! -L "$home_target" ]]; then
            continue
        fi
    fi
fi
# For broken symlink, still quarantine the link itself:
if [[ -L "$home_target" ]]; then
    # mv will move the link, not its target — correct
    :
fi
```
Simpler minimal fix: change `[[ ! -e ]]` to `[[ ! -e && ! -L ]]`.

---

### WR-04: `mapfile < <(get_deps ...)` silently hides `get_deps` failures

**File:** `setup.sh:248` and `setup.sh:675`
**Issue:** `if ! mapfile -t deps < <(get_deps "$family" "$mode"); then` does not reliably propagate `get_deps` exit status under `set -Euo pipefail` + `inherit_errexit`. Process substitution's exit is not the `mapfile` exit; a failed `get_deps` (e.g., unknown family `get_deps` returns 1) can still leave `mapfile` succeeding with empty `deps`, causing `verify_deps` to report `All dependencies are satisfied` incorrectly and skipping the install lock.

**Fix:**
```bash
# BEFORE:
if ! mapfile -t deps < <(get_deps "$family" "$mode"); then echo "Error: failed to get deps for re-verify" >&2; return 1; fi

# AFTER — capture exit explicitly:
local -a deps=()
local get_deps_status=0
mapfile -t deps < <(get_deps "$family" "$mode") || get_deps_status=$?
if [[ $get_deps_status -ne 0 ]] || [[ ${#deps[@]} -eq 0 && "$family" != "termux" ]]; then
    # For termux empty gui is valid; check deps non-empty for common at least
    if [[ $get_deps_status -ne 0 ]]; then
        echo "Error: failed to get deps for $family/$mode" >&2
        return 1
    fi
fi
# Or avoid process substitution entirely:
local deps_str
if ! deps_str=$(get_deps "$family" "$mode"); then
    echo "Error: failed to get deps for $family/$mode" >&2; return 1
fi
mapfile -t deps <<< "$deps_str"
```
Apply to both `reverify_deps` and `main`'s deps loading.

---

### WR-05: Near-duplicate `checklist_whiptail` / `checklist_dialog` implementations

**File:** `setup.sh:452-532` (80 lines each, ~90% identical)
**Issue:** Two 50+ line functions differ only in the binary name (`whiptail` vs `dialog`) and the cancel message string yet duplicate preset computation, `TERMUX_DISABLED_PACKAGES` handling, fd-swap `3>&1 1>&2 2>&3`, `xargs` trimming, `eval` parsing, and `strip_termux_disabled` post-filter. Duplication increases maintenance cost (fixing CR-01 requires patching two places, already diverged) and obscures that the `dialog` path was never tested with the `TERMUX_DISABLED_PACKAGES` OFF suffix.

**Fix:** Extract a shared helper:

```bash
_checklist_ncurses() {
    local bin="$1"  # whiptail or dialog
    if ! command -v "$bin" >/dev/null 2>&1; then return 1; fi
    declare -A preset_state
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do preset_state["$pkg"]="ON"; done
    if [[ "$MODE" == "server" ]]; then for pkg in "${GUI_STOW_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then preset_state["zsh"]="ON"; preset_state["nushell"]="OFF"
    elif [[ "$SHELL_CHOICE" == "nushell" ]]; then preset_state["zsh"]="OFF"; preset_state["nushell"]="ON"; fi
    if [[ "${FAMILY:-}" == "termux" ]]; then for pkg in "${TERMUX_DISABLED_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    local -a args=()
    for pkg in "${ALL_PACKAGES[@]}"; do
        local desc="" state="${preset_state[$pkg]}" is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]] && [[ "${FAMILY:-}" == "termux" ]]; then is_disabled=true; break; fi
        done
        if [[ "$is_disabled" == true ]]; then desc="(not available on Termux)"; state="OFF"; fi
        args+=("$pkg" "$desc" "$state")
    done
    local sel status=0
    sel=$("$bin" --title "Packages" --checklist "Space to toggle (before any write):" 20 78 10 "${args[@]}" 3>&1 1>&2 2>&3) || status=$?
    if [[ $status -ne 0 ]]; then echo "Checklist cancelled ($bin)." >&2; return 2; fi
    sel="$(echo "$sel" | xargs 2>/dev/null || echo "$sel")"
    if [[ -z "$sel" ]]; then echo "Checklist cancelled (empty selection via $bin)." >&2; return 2; fi
    # ... safe parsing (see CR-01 fix) then strip_termux_disabled ...
}
checklist_whiptail() { _checklist_ncurses whiptail; }
checklist_dialog()   { _checklist_ncurses dialog; }
```

---

## Info

### IN-01: Unused `YES` global (reserved stub)

**File:** `setup.sh:10,99-101`
**Issue:** `YES=false` is set via `parse_args --yes` but never read after parsing. Grep shows `YES` appears only in declaration and assignment. The plan documents `--yes` as deferred to Phase 2 (`--yes` stored stub for Phase 2), so this is intentional but triggers static-analysis unused-variable warnings and `bash -n` reviewers may flag dead code. No runtime impact, but consider documenting with `readonly` or `_` prefix.

**Fix:**
```bash
# Option A — mark as intentionally unused:
YES=false  # Phase 2: --yes stub (CI bypass) — currently stored but not consumed
# shellcheck disable=SC2034
# Or prefix to silence: _YES

# Option B — actually consume it where checklist prompting would be skipped:
# In prompt_checklist, if [[ "$YES" == true ]]; then use presets non-interactively
```

---

### IN-02: Magic geometry numbers for ncurses checklists

**File:** `setup.sh:474,517`
**Issue:** `whiptail --title "Packages" --checklist "Space to toggle (before any write):" 20 78 10` hard-codes rows 20, cols 78, menu-height 10. These are magic numbers repeated in two functions, not named. Low risk, but inconsistent with the project's explicit `2.4.1` constant centralisation and `min line length=off` convention.

**Fix:**
```bash
readonly NCURSES_HEIGHT=20 NCURSES_WIDTH=78 NCURSES_MENU_HEIGHT=10
# then:
sel=$(whiptail --title "Packages" --checklist "..." "$NCURSES_HEIGHT" "$NCURSES_WIDTH" "$NCURSES_MENU_HEIGHT" "${args[@]}" ...)
```

---

## Verification

Commands executed:

```bash
bash -n setup.sh && echo "syntax PASS"
bash setup.sh --help | grep -q "Usage:" && echo "help wins"
bash setup.sh --bogus-flag 2>&1; test $? -eq 1 && echo "unknown abort PASS"
bash setup.sh --mode 2>&1; test $? -ne 0 && echo "value-less abort PASS"
OS_RELEASE_FILE=/tmp/malicious_os bash -c 'source ./setup.sh; detect_family' | grep -q "pwned" && echo "source injection CONFIRMED"
grep -n 'eval "SELECTED_PACKAGES' setup.sh && echo "eval FOUND"
! grep -Eq -- '--adopt' setup.sh && echo "no --adopt PASS"
! grep -Eq 'rm -rf' setup.sh && echo "no rm -rf PASS"
grep -q 'inherit_errexit' setup.sh && echo "strict header PASS"
grep -q 'BASH_SOURCE\[0\] ==.*\$0' setup.sh && echo "source-guard PASS"
grep -q 'sort -V' setup.sh && echo "sort -V PASS"
grep -q 'stow --dir="\$SCRIPT_DIR" --target="\$HOME" --restow' setup.sh && echo "explicit stow PASS"
grep -q 'readlink -f' setup.sh && echo "folding-aware verify PASS"
grep -q '.stow-conflicts/' .gitignore && echo "gitignore PASS"
grep -q 'bash setup.sh' README.md && ! grep -Eq 'setup\.(nu|zsh)' README.md && echo "docs atomic PASS"
```

All passing controls verified; Critical findings proven by exploit fixture.

---

_Reviewed: 2026-09-11T00:45:00Z_
_Reviewer: gsd-code-reviewer (standard depth)_
_Depth: standard_
