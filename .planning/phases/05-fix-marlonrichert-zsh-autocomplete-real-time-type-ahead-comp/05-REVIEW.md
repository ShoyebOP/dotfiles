---
phase: 05-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp
reviewed: 2026-09-23T14:30:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - zsh/.zshrc
  - README.md
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-09-23T14:30:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the 05-03 gap-closure delta at standard depth: the one-shot precmd
`_fix_zasync_once` hook (`zsh/.zshrc:334-343`, commit `b4d4dd5`), the
menuselect Tab binding (`zsh/.zshrc:381-383`, commit `eec13ac`), and the README
stale-registration troubleshooting paragraph (`README.md:147-148`). Full file
reads plus cross-referencing (git history, `zsh -f` behavioral probes) were
used; no finding below relies on pattern-matching alone.

**Security:** clean — no secrets, no injection surface, no new network fetch
(the hook only re-points an autoload at a local cache file). All findings are
correctness/robustness defects in the new shell code, empirically verified
where claimed.

**Headline:** the hook fixes the live symptom but has no preconditions and
disarms unconditionally, so the offline/missing-file edge silently poisons
`zasync` with no retry (WR-01), and it unconditionally clobbers a healthy or
upstream-fixed registration on every fresh shell (WR-02). The new menuselect
bind assumes `zsh/complist` is already loaded with no guard (WR-03). A
same-phase (05-01) quoting defect in the atload ice it sits next to is benign
today only by accident of zsh auto-resolving `$terminfo` (WR-04).

## Warnings

### WR-01: Hook registers backend with no existence check, then disarms unconditionally

**File:** `zsh/.zshrc:338-342`
**Issue:** `_fix_zasync_once` runs `autoload -Uz <cache-path>` even when the
cache file does not exist (offline first prompt, failed clone, XDG mismatch),
and then always executes `add-zsh-hook -d precmd _fix_zasync_once`. Verified
with `zsh -f`: `autoload -Uz /nonexistent/path/zasync` exits 0 and registers a
broken autoload (`whence -v` reports it as the source). So on the exact edge
the README warns about (first prompt needs network), the hook deletes the
old stub, installs a broken registration, removes its only retry mechanism,
and every subsequent prompt in that shell uses the poisoned entry. The static
`hook-ok` gate (grep for the function name) cannot detect this — it checks
wiring, never the target's existence.
**Fix:**
```zsh
_fix_zasync_once() {
  local backend="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zasync/zasync"
  [[ -f "$backend" ]] || return 0   # clone not ready yet; stay armed, retry next precmd
  unfunction zasync 2>/dev/null
  autoload -Uz "$backend"
  add-zsh-hook -d precmd _fix_zasync_once
}
```

### WR-02: Unconditional `unfunction zasync` clobbers healthy state on every fresh shell

**File:** `zsh/.zshrc:339`
**Issue:** The hook is re-armed at every shell source (`zsh/.zshrc:343`) and
fires at the first precmd of every fresh shell, unconditionally deleting
whatever `zasync` definition exists — including a correct file-backed
registration or a future upstream-fixed implementation — and re-pointing it at
a hardcoded cache path. Until someone manually performs the README retire
step, this is a forward-compat landmine: if upstream moves the backend path,
this hook breaks every new shell until manually removed. There is no gate
checking the stub is actually stale (e.g. `whence -v zasync` showing a bare
directory) before destroying it.
**Fix:**
```zsh
_fix_zasync_once() {
  # Only touch the known-stale state: registered from its directory, not its file.
  [[ "$(whence -v zasync 2>/dev/null)" != *"from "*"/zasync/zasync"* ]] || return 0
  ...
}
```
At minimum, gate the `unfunction` on the directory-stub signature the README
itself documents (`whence -v zasync` printing a bare directory), so healthy
shells converge with zero mutation.

### WR-03: `bindkey -M menuselect` assumes `zsh/complist` is loaded, with no guard

**File:** `zsh/.zshrc:383` (new 05-03 line; same latent pattern in the atload ice at `zsh/.zshrc:331`)
**Issue:** The menuselect keymap only exists after `zsh/complist` loads.
Verified with `zsh -f`: `bindkey -M menuselect "^I" menu-complete` without the
module fails with `no such keymap 'menuselect'`, exit 1. In the current file
this happens to work because the OMZ `completion` snippet (line 206-208) loads
before it — an implicit, uncommented ordering dependency. Any reorder,
snippet failure, or minimal-server deviation turns every shell startup into an
error, and the `menuselect-ok` grep gate would still pass because it never
executes the bind.
**Fix:**
```zsh
zmodload -i zsh/complist 2>/dev/null
bindkey -M menuselect '^I' menu-complete
```
Apply the same guard thinking to the atload-embedded kcbt bind, which runs
even earlier in a deferred context.

### WR-04: Atload ice double quotes expand `$terminfo[kcbt]` at definition time; comment claims a `\$` escape that is absent

**File:** `zsh/.zshrc:326-331`
**Issue:** Commit `11d85aa` (same phase, 05-01) converted the ice from
single-quoted to double-quoted for greppability, with a comment stating "the
`\$` and `\"` escapes keep the ice value byte-identical to the old
single-quoted form." The code contains `\"` but no `\$` — `$terminfo[kcbt]`
is unescaped inside double quotes, so it expands when `zi ice` runs, not when
the atload fires. Probed with `zsh -f`: `$terminfo[kcbt]` auto-resolves even
with no rc, so this is benign today (Shift-Tab works while TERM/terminfo db
are sane) — but it bakes a TERM-specific escape into the ice at source time,
breaks under `TERM=dumb`/missing terminfo with no re-evaluation, and the
comment actively misleads the next editor into believing the expansion is
deferred.
**Fix:**
```zsh
bindkey -M menuselect \"\$terminfo[kcbt]\" reverse-menu-complete"
```
(one-character fix: escape the `$`), or correct the comment if early
expansion is intentional.

## Info

### IN-01: Dead `_fix_zasync_once` function persists after self-disarm

**File:** `zsh/.zshrc:338-342`
**Issue:** `add-zsh-hook -d` removes the hook but leaves the globally-defined
`_fix_zasync_once` in the function namespace for the rest of the session —
dead code in every shell, and a (low-risk) name-collision surface with future
plugin helpers.
**Fix:** `add-zsh-hook -d precmd _fix_zasync_once; unfunction _fix_zasync_once 2>/dev/null` — or document that it is intentionally kept for re-source idempotence.

### IN-02: Backend cache path hardcoded in two places with inconsistent XDG treatment

**File:** `zsh/.zshrc:340`, `README.md:148`
**Issue:** The rc uses `${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zasync/zasync`
(unquoted — see WR-01 fix) while the README cites an ellipsis path
(`.../.cache/zsh/zasync/zasync`) and a hardcoded `~/.local/state/` log dir,
ignoring `$XDG_STATE_HOME`. A user with non-default XDG dirs cannot map the
doc to their system, and future path changes must be edited in both places.
**Fix:** Quote the rc expansion; in README, show the XDG-aware form
(`${XDG_CACHE_HOME:-~/.cache}/zsh/zasync/zasync`) alongside the default.

### IN-03: SUMMARY claims a "HOME-cache fallback" the code does not implement

**File:** `zsh/.zshrc:340` vs `05-03-SUMMARY.md` ("registers the cached backend file under the XDG cache path with HOME-cache fallback")
**Issue:** `${XDG_CACHE_HOME:-$HOME/.cache}` is a single-path default
expansion, not a two-location fallback: if `XDG_CACHE_HOME` is set but the
plugin wrote under `~/.cache` (or vice versa), the hook registers the wrong
path with no second attempt. Either implement a real fallback (`[[ -f ]]`
probe of both locations) or correct the SUMMARY wording so no false
confidence in fallback coverage persists.
**Fix:** Probe both locations, first hit wins; else stay armed per WR-01.

---

_Reviewed: 2026-09-23T14:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
