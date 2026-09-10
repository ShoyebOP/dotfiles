---
phase: 01-universal-installer-platform-foundations
reviewed: 2026-09-11T00:55:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - setup.sh
  - README.md
  - .gitignore
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 01: Code Review Report — Re-review after fixes (867e602)

**Reviewed:** 2026-09-11T00:55:00Z
**Depth:** standard
**Files Reviewed:** 3 (setup.sh, README.md, .gitignore)
**Status:** issues_found — no Critical remaining; 1 low Warning + 3 Info (non-blocking, Phase 2 backlog)
**Diff Base:** 867e602 (fix) vs c85933e (prior review) — 1 file changed, 31 insertions/18 deletions in setup.sh
**Verifier:** bash -n clean, --help exits 0, --dry-run zero writes, outside-root abort, fixture detect_family all re-verified

## Summary

Re-reviewed Phase 01 after commit `867e602 fix(01-02): address code review CR-01/C-02 and WR-01/02/03`. All 2 Critical and 2 of 5 Warnings are now **verified fixed** via code inspection + live reproduction. One Warning (WR-02 timestamp) is **partially fixed** with a low-severity residual. Two prior Warnings (WR-04/WR-05) remain intentionally deferred and are **downgraded to Info** — they are low-risk quality/maintainability notes, not correctness or security blockers for Phase 2.

**Scope:** `setup.sh` (750 lines, bash 5.2.21, `set -Eeuo pipefail` + `inherit_errexit`, `SCRIPT_DIR` via `BASH_SOURCE`, executable 775), `README.md` (156 lines, canonical `bash setup.sh` docs, Zsh default/Nushell backup, 7-package ladder, quarantine/post-verify notes, manual `stow --dir=. --target="$HOME"`), `.gitignore` (14 lines, `.stow-conflicts/` gitignored). Previous scope files `setup.nu`/`setup.zsh` correctly deleted with no shim, no dangling doc refs, `teardown.nu`/`teardown.zsh` retained.

**Verified fixes (must close):**
- **CR-01 eval injection** — `grep -n eval setup.sh` now 0 executable evals (only 2 comment lines `mitigates CR-01` at 483/528). Both `checklist_whiptail` and `checklist_dialog` now use safe `xargs -n1` parsing (L485, L530) + allowlist filter `ALL_PACKAGES`, no code execution path.
- **CR-02 OS_RELEASE_FILE sourcing** — `grep -n '^\s*\.\s*"\$os_file"'` = 0. Lines 150-151 now use `grep -E '^ID=' / '^ID_LIKE=' | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs`. Reproduction `OS_RELEASE_FILE=/tmp/malicious_os bash -c 'source ./setup.sh; detect_family'` no longer prints `pwned`; fixture `manjaro->arch` and `pop->debian` still pass.
- **WR-01 manifest hint** — L347 now `awk -F' -> ' '{print $1}' / '{print $2}'`, correctly splitting `original -> quarantined` instead of `cut -d'>'` which produced trailing ` -` / leading space. Dry-run reconstruction `mv "$dst" "$src"` now succeeds.
- **WR-03 broken symlink** — L334 now `[[ ! -e "$home_target" && ! -L "$home_target" ]]` so dangling `~/.config/nvim` symlink is quarantined, not skipped, preventing `stow --restow` collision + false `MISSING`.
- No new secrets, no `eval`, no `innerHTML`, no `console.log`/`TODO`, no `rm -rf`, no `--adopt` string (`grep -- --adopt` 0 hits).

**Passing controls re-verified (unchanged):**
- Strict header, `SCRIPT_DIR`, source-guard `BASH_SOURCE[0]==$0`, guarded `parse_args` `${1-}` + arity checks, allowlist `local|server` / `zsh|nushell`, help-wins pre-scan, unknown-flag abort before write.
- Termux-first `detect_family` (L137 TERMUX_VERSION/PREFIX/pkg) → `ID_LIKE` tokens → `ID` → manager fallback; derivative fixtures proven.
- Dep tables (L174) `common` includes `make gcc fzf zsh` (unlocks telescope-fzf-native), `termux gui=()` sudo-free `pkg install -y` loop with `pkg search` hint.
- Ladder `gum→whiptail→dialog→fzf→read` locked order, `return 2` cancel never cascades, `strip_termux_disabled` (L289) warn+drop.
- Quarantine `mv` only (L352), relative paths, `MANIFEST` with restore hint, no `rm`.
- Post-verify folding-aware `readlink -f` prefix `"$SCRIPT_DIR/$pkg/"*` (L374) covers folded `~/.config`.
- Outside-root guard (L665-672) both `SCRIPT_DIR/setup.sh` and `./setup.sh`, aborts before prompt/write.
- `sort -V` version compare (L711) correct for `2.10 > 2.4.1`, stow outdated auto-queued to `missing`.
- Docs `.gitignore` quarantine entry, `README.md` no `setup.nu/.zsh` refs, `bash setup.sh --help` and `--mode server --shell zsh --dry-run` verified zero writes.

**Result:** Phase 01 meets INST-01/02/04/05 STOW-01 DEPS-01/02/03 for Phase 2 entry. No Critical open. Remaining 1 Warning is low-severity uniqueness, 3 Info are polish/backlog — do not block promotion.

## Fixed Issues — Verified Closed (audit trail)

### CR-01 FIXED — Command injection via `eval` in checklist backends (was setup.sh:480/521)

**File:** `setup.sh:483` / `setup.sh:528` (was 480/521) — `checklist_whiptail` / `checklist_dialog`
**Prior issue:** `eval "SELECTED_PACKAGES=($sel)"` executed attacker-controlled `whiptail`/`dialog` output.
**Fix verified:** Both functions now comment `Safe parse without eval` and use:
```bash
local -a parsed=()
if ! mapfile -t parsed < <(printf '%s' "$sel" | xargs -n1 2>/dev/null); then parsed=(); fi
local -a filtered=()
local tok clean
for tok in "${parsed[@]}"; do
    clean="${tok#\"}"; clean="${clean%\"}"
    clean="${clean#\'}"; clean="${clean%\'}"
    clean="$(echo "$clean" | xargs 2>/dev/null || echo "$clean")"
    [[ -z "$clean" ]] && continue
    for pkg in "${ALL_PACKAGES[@]}"; do if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi; done
done
SELECTED_PACKAGES=("${filtered[@]}")
```
`grep -c eval` = 2 comments only, 0 executable evals. `xargs -n1` respects quotes without code execution; subsequent allowlist (`ALL_PACKAGES` 7 names) drops anything else. `strip_termux_disabled` retained.
**Reproduce fixed:** `sel='"; echo pwned >&2; echo "'` → `xargs -n1` → parsed tokens `;`, `echo`, `pwned` … none match allowlist → `SELECTED_PACKAGES` empty → no execution.

---

### CR-02 FIXED — Arbitrary code execution via sourced `OS_RELEASE_FILE` (was setup.sh:149)

**File:** `setup.sh:150-151` (was 149)
**Prior issue:** `. "$os_file"` sourced env-controlled file.
**Fix verified:**
```bash
id="$(grep -E '^ID=' "$os_file" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")"
id_like="$(grep -E '^ID_LIKE=' "$os_file" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")"
```
Never executes file content. `grep -E '^ID='` correctly excludes `ID_LIKE=` (verified `ID_LIKE="ubuntu debian"` not matched). Verified:
- `echo 'echo pwned; ID=arch' > /tmp/malicious_os; OS_RELEASE_FILE=/tmp/malicious_os bash -c 'source ./setup.sh; detect_family'` → output `debian` (fallback), no `pwned`.
- `manjaro ID_LIKE=arch` → `arch`, `pop ID="ubuntu" ID_LIKE="ubuntu debian"` → `debian`, `ID="ubuntu" ID_LIKE="debian"` quoted → `debian`.

---

### WR-01 FIXED — Broken quarantine restore hint (was setup.sh:342)

**File:** `setup.sh:347`
**Prior issue:** `cut -d'>' -f1/-f2` split on `>` not ` -> `, yielding `src="… -"` / `dst=" …"` with stray dash/space, `mv` fails.
**Fix verified:**
```bash
echo "# Or: cat $manifest | while IFS= read -r line; do src=\$(echo \"\$line\" | awk -F' -> ' '{print \$1}'); dst=\$(echo \"\$line\" | awk -F' -> ' '{print \$2}'); mv \"\$dst\" \"\$src\"; done"
```
`awk -F' -> '` correctly reconstructs both sides. Manifest lines `"$home_target -> $q_target"` (L352) now round-trip.

---

### WR-03 FIXED — Broken symlink not quarantined (was setup.sh:329)

**File:** `setup.sh:334`
**Prior issue:** `[[ ! -e "$home_target" ]]` false for dangling symlink → skip quarantine → `stow --restow` fails.
**Fix verified:**
```bash
if [[ ! -e "$home_target" && ! -L "$home_target" ]]; then continue; fi
```
Now both regular files and broken symlinks are detected. `readlink -f` failure leaves empty `canon`, not matching `pkg_dir` prefix, so broken link is correctly `mv`'d to `qdir`.

---

## Critical Issues

*No open Critical Issues.*

Both prior Critical findings (CR-01 eval, CR-02 sourcing) are verified fixed above with reproduction tests and code inspection. No new injection, hardcoded secret, auth bypass, or data-loss risks found in `setup.sh`/`README.md`/`.gitignore`. `nushell/.config/nushell/env.nu` still contains a committed `MISTRAL_API_KEY` secret but is **out of scope** for this phase (not in `files_reviewed_list`); track separately if secret rotation is desired — not counted here.

## Warnings

### WR-01: Quarantine timestamp collision window remains (narrow) — nanosecond truncated, PID only on fallback

**File:** `setup.sh:317-322`
**Issue:** `quarantine_scan` now uses `date +%Y%m%d-%H%M%S-%N | cut -c1-19`. Format `+%N` is 9-digit nanoseconds, total string 25 chars (`20260911-004004-354406140`), but `cut -c1-19` keeps only first 19 (`20260911-004004-353`) — i.e., 8+1+6+1+3 = 3 of 9 ns digits (millisecond precision, not nanosecond). More importantly PID (`$$`) is appended **only** in the failure branch (`if ! ts=$(date ...); then ts="${ts}-$$"; fi`), not on success. Two concurrent installer runs in the same millisecond on the same host would share `qdir="$SCRIPT_DIR/.stow-conflicts/$ts"` and the second's first quarantine would `> "$manifest"` truncate the first's manifest (second `mkdir -p` is no-op). `q_target` duplicate check `[[ -e "$q_target" ]]` mitigates file clobber but manifest entries are still lost — quarantined files become unrecoverable via manifest alone.

Probability is very low (requires same millisecond + same host + same repo), and the original 1-second window is now 1000× smaller, so this is **low severity** and not a blocker. But Phase 01 spec requested `timestamp + N + $$` uniqueness.

**Fix (recommended before Phase 2, low priority):**
```bash
# BEFORE (L318-322):
if ! ts=$(date +%Y%m%d-%H%M%S-%N 2>/dev/null | cut -c1-19 2>/dev/null); then
    if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then ts="$(date +%s)"; fi
    ts="${ts}-$$"
fi
local qdir="$SCRIPT_DIR/.stow-conflicts/$ts"

# AFTER — always append PID, keep full nanoseconds or truncate less, and guard manifest:
local ts
if ts=$(date +%Y%m%d-%H%M%S-%N 2>/dev/null); then
    ts="${ts}-$$"
else
    if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then ts="$(date +%s)"; fi
    ts="${ts}-$$"
fi
local qdir="$SCRIPT_DIR/.stow-conflicts/$ts"
# Or keep cut but append PID:
# ts="$(date +%Y%m%d-%H%M%S-%N 2>/dev/null | cut -c1-22)-$$"  # 22 keeps 6 of 9 digits + PID
# And make manifest append-safe:
if [[ ! -f "$manifest" ]]; then
    { echo "# Stow quarantine manifest"; ... } > "$manifest"
else
    # if qdir already existed (collision), append rather than truncate
    :
fi
```
Alternatively use `mktemp -d "$SCRIPT_DIR/.stow-conflicts/$(date +%Y%m%d-%H%M%S)-$$-XXXXXX"` for guaranteed uniqueness.

---

## Info

### IN-01: `mapfile < <(get_deps ...)` does not reliably propagate `get_deps` exit under `inherit_errexit`

**File:** `setup.sh:250` and `setup.sh:688`
**Issue:** `if ! mapfile -t deps < <(get_deps "$family" "$mode"); then` — process substitution's exit is not reliably the `mapfile` exit under `set -Eeuo pipefail` + `inherit_errexit`. If `get_deps` returns 1 (unknown family), `mapfile` can succeed with empty `deps`, leading `verify_deps` to report `All dependencies are satisfied` incorrectly. In practice unreachable: `detect_family` validates `family` before `get_deps` is called, and unknown `mode` still returns `common` list, so this never triggers in normal flow. Downgraded from prior WR-04 to Info.
**Fix (backlog, optional robustness):**
```bash
# BEFORE:
if ! mapfile -t deps < <(get_deps "$family" "$mode"); then echo "Error: failed to get deps for re-verify" >&2; return 1; fi

# AFTER — capture deps via command substitution to propagate exit:
local deps_str
if ! deps_str=$(get_deps "$family" "$mode"); then
    echo "Error: failed to get deps for $family/$mode" >&2; return 1
fi
mapfile -t deps <<< "$deps_str"
```
Apply to both `reverify_deps` (L250) and `main` (L688). No behavior change, just correctness hardening.

---

### IN-02: Near-duplicate `checklist_whiptail` / `checklist_dialog` implementations (~45 lines, ~90% identical)

**File:** `setup.sh:457-501` and `setup.sh:502-546`
**Issue:** Both functions duplicate preset computation (`preset_state`, `GUI_STOW_PACKAGES`, `TERMUX_DISABLED_PACKAGES`), `TERMUX_DISABLED` description suffix, `TERMUX_DISABLED` OFF force, fd-swap `3>&1 1>&2 2>&3`, `xargs` trimming, safe `xargs -n1` parsing, allowlist filter, and `strip_termux_disabled`. Fixing CR-01 required patching two places — evidence of duplication cost. Prior WR-05 downgraded to Info: no correctness impact, but increases maintenance and obscures that `dialog` path's `TERMUX_DISABLED` suffix was never exercised separately.
**Fix (backlog, Phase 2 polish):**
```bash
_checklist_ncurses() {
    local bin="$1"  # whiptail or dialog
    if ! command -v "$bin" >/dev/null 2>&1; then return 1; fi
    declare -A preset_state
    local pkg; for pkg in "${ALL_PACKAGES[@]}"; do preset_state["$pkg"]="ON"; done
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
    local -a parsed=()
    if ! mapfile -t parsed < <(printf '%s' "$sel" | xargs -n1 2>/dev/null); then parsed=(); fi
    local -a filtered=() tok clean
    for tok in "${parsed[@]}"; do clean="${tok#\"}"; clean="${clean%\"}"; clean="${clean#\'}"; clean="${clean%\'}"; clean="$(echo "$clean" | xargs 2>/dev/null || echo "$clean")"; [[ -z "$clean" ]] && continue; for pkg in "${ALL_PACKAGES[@]}"; do if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi; done; done
    SELECTED_PACKAGES=("${filtered[@]}")
    strip_termux_disabled
    echo "Selected via $bin: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    return 0
}
checklist_whiptail() { _checklist_ncurses whiptail; }
checklist_dialog()   { _checklist_ncurses dialog; }
```

---

### IN-03: Quarantine restore hint does not filter comment lines; `stow --version` parsing is brittle on localized output

**File:** `setup.sh:342-348` and `setup.sh:708`
**Issue:** Manifest hint `cat $manifest | while IFS= read -r line; do src=$(echo "$line" | awk -F' -> ' '{print $1}'); dst=$(echo "$line" | awk -F' -> ' '{print $2}'); mv "$dst" "$src"; done` will also attempt to parse the 4 header comment lines (`# Stow quarantine manifest`, `# Created:`, `# Restore:`, `# Or:`), producing empty `src`/`dst` and noisy `mv` errors. Harmless but confusing. Similarly `stow --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1` assumes English `--version` output and picks first dotted number — works on GNU Stow but could pick unrelated numbers if distro patches version string (e.g., `stow (GNU Stow) version 2.3.1 [with Perl 5.38]` still picks `2.3.1`, but edge case).
**Fix (minor polish, optional):**
```bash
# Hint — skip comments/empties and use -- for mv:
echo "# Or: grep -v '^#' \"$manifest\" | grep -v '^\$' | while IFS= read -r line; do src=\$(echo \"\$line\" | awk -F' -> ' '{print \$1}'); dst=\$(echo \"\$line\" | awk -F' -> ' '{print \$2}'); [[ -z \"\$src\" || -z \"\$dst\" ]] && continue; mv -- \"\$dst\" \"\$src\"; done"

# Stow version — anchor to 'stow' token:
stow_ver=$(printf '%s' "$stow_ver_str" | grep -oE 'stow[^0-9]*\K[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
# or keep current grep but add comment that first match is stow version on GNU Stow
```
No data loss; info only.

---

_Reviewed: 2026-09-11T00:55:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
_Files reviewed: setup.sh (750 lines), README.md (156 lines), .gitignore (14 lines) — commit 867e602 verified_
