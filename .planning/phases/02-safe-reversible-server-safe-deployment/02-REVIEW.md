---
phase: 02-safe-reversible-server-safe-deployment
reviewed: 2026-09-12T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - setup.sh
  - zsh/.zprofile
  - zsh/.zshrc
  - README.md
  - AGENTS.md
findings:
  critical: 3
  warning: 7
  info: 3
  total: 13
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-09-12T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed unified installer delta for phase 02 (reversible uninstall, privileged keyd safety gate, Hyprland guard removal, Zsh self-provision + chsh offer, staged teardown deletion). Installer is 1558-line Bash with `set -Eeuo pipefail`, OS_RELEASE_FILE seam, and five-backend checklist ladder. Found 3 BLOCKER-class defects that violate the phase safety contract (dry-run privilege escalation, unguarded shell startup failure, and bulk destructive package removal gated only by --yes), plus 7 warnings (string SHELL check, quarantine timestamp collision, duplicated preview paths, stale docs) and 3 info items. No Nushell-only issues flagged per scope filter. `bash -n setup.sh` and `zsh -n zsh/.zshrc` pass, but runtime behavior defects remain.

## Critical Issues

### CR-01: Unguarded `apply_catppuccin` crashes Zsh startup when plugin missing

**File:** `zsh/.zshrc:330`
**Issue:** `apply_catppuccin classic mocha` is called unconditionally after `source ~/.p10k.zsh`. The function is provided by `tolkonepiu/catppuccin-powerlevel10k-themes` loaded via `zinit light` at line 218. If network/clone fails, or Zinit bootstrap fails (silent install path at lines 158-162 discards errors via `>/dev/null 2>&1`), the function is undefined and every new Zsh session fails with `zsh: command not found: apply_catppuccin`. This violates the D-12 contract "Zinit self-clones ... no installer pin" – installer assumes shell always self-heals, but .zshrc does not guard the call.
**Fix:**
```zsh
# After loading p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
if (( $+functions[apply_catppuccin] )); then
  apply_catppuccin classic mocha
else
  echo "warning: catppuccin-powerlevel10k-themes not loaded — skipping apply_catppuccin" >&2
fi
```

### CR-02: Dry-run privileged preview escalates via `sudo` and prompts for password

**File:** `setup.sh:748-751`
**Issue:** `run_uninstall()` DRY_RUN branch prints `[DRY RUN] Would run: sudo stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd` and then *executes* `sudo stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd 2>&1 | sed ...` (line 751). `sudo` prompts for password even in `--dry-run`, breaking the phase invariant "dry-run touches zero files, no writes, no privilege escalation" (02-CONTEXT D-03/D-06, verify requirement `bash setup.sh --dry-run --uninstall ... | grep Would run` with zero writes). In CI (`--yes`) this blocks or hangs. Same pattern exists for install preview at `setup.sh:396-398` and `509-511` where `stow --target=/ --no --verbose` is correct (no sudo) but uninstall preview incorrectly uses `sudo`.
**Fix:**
```bash
# Do not use sudo for simulation preview; stow --no does not write
echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose --delete keyd"
if command -v stow >/dev/null 2>&1; then
    stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd 2>&1 | sed 's/^/  /' || true
else
    echo "  (stow not found — would install via package manager first)"
fi
```
Remove `sudo` from both `run_uninstall` DRY_RUN preview and any other `--no --verbose` preview against `/`.

### CR-03: `--yes` auto-confirms bulk removal of all 13 toolchain packages

**File:** `setup.sh:628-692`
**Issue:** `offer_system_package_removal()` determines candidates as `SELECTED_DEPS` or `ALL_TOOLCHAIN` (13 entries: stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh) and when `YES==true` sets `confirmed=true` immediately (line 629), skipping the `gum confirm` / `Type 'yes'` gate. Combined with `run_uninstall()` being called with `--uninstall --yes`, a single `bash setup.sh --uninstall --yes` will attempt `sudo pacman -Rns --noconfirm` / `sudo apt remove -y` / `pkg uninstall -y` for *every* toolchain package, including `git`, `stow`, `zsh` itself, without a second explicit confirmation. This violates Safety constraint "No destructive writes without preview/confirmation" and D-05 "only after same yes guard" – the intent was per-package graceful failure, but auto-bypass turns `--yes` (CI bypass for uninstall) into a destructive mass-uninstall. Candidates also include packages never installed by setup.sh (fallback to ALL_TOOLCHAIN when SELECTED_DEPS empty), amplifying blast radius.
**Fix:**
```bash
# In offer_system_package_removal, never auto-confirm bulk removal even with --yes;
# require an explicit second gate or at least a DRY_RUN preview + separate flag.
if [[ "$DRY_RUN" == true ]]; then
  # preview only
elif [[ "$YES" == true ]]; then
  echo "Skipping system package removal under --yes (requires explicit confirmation)." >&2
  echo "Re-run without --yes or confirm interactively to remove: ${candidates[*]}" >&2
  return 0
elif command -v gum ...; then
  # existing gum confirm path
```
Alternatively introduce `--remove-packages` explicit flag; never chain `--yes` to mass `pacman -Rns`.

## Warnings

### WR-01: String `SHELL` comparison misses symlink/canonicalization

**File:** `setup.sh:700-701`
**Issue:** `offer_chsh` skips via `[[ "$zsh_path" == "$SHELL" ]]`. `$SHELL` is the login shell recorded at account creation, often `/bin/zsh` vs `/usr/bin/zsh` or symlink, so string equality fails even when same inode, causing redundant chsh prompt. Conversely, `which zsh` vs `command -v zsh` inconsistency (`offer_chsh` uses `command -v` but preview block at 1520 uses `command -v`, OK) but still not canonicalized. Existing handler already has correct `readlink -f` pattern at `assert_linked` line 475, not reused here.
**Fix:**
```bash
local real_zsh real_shell
real_zsh=$(readlink -f "$zsh_path" 2>/dev/null || echo "$zsh_path")
real_shell=$(readlink -f "${SHELL-}" 2>/dev/null || echo "${SHELL-}")
if [[ -n "${SHELL-}" ]] && [[ "$real_zsh" == "$real_shell" ]]; then
  echo "Default shell already zsh ($SHELL) — skipping chsh offer." >&2
  return 0
fi
```

### WR-02: `source` of Zinit without existence check after silent failure

**File:** `zsh/.zshrc:140-166`
**Issue:** Silent branch (inside `if [[ -n "$P9K_INSTANT_PROMPT" ]]`) does `command git clone ... >/dev/null 2>&1` without testing exit status (line 161). Next line `source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"` (166) runs unconditionally, erroring on every shell launch if clone failed offline. Non-silent branch correctly checks `if command git clone ...; then ... else return 1; fi`. The silent path should mirror it.
**Fix:**
```zsh
command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
if ! command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" >/dev/null 2>&1; then
  echo "warning: Zinit clone failed — offline? Skipping Zinit load" >&2
  return 0
fi
...
[[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]] || return 0
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
```

### WR-03: Quarantine timestamp collision – PID only on failure path

**File:** `setup.sh:420-426`
**Issue:** `ts=$(date +%Y%m%d-%H%M%S-%N | cut -c1-19)` yields `20260912-014930-123` (seconds + 3 ns chars) without PID. PID suffix `-${ts}-$$` is appended only in the fallback `date +%s` branch (line 424). Two `bash setup.sh` invocations in the same millisecond (CI, rapid re-run) collide on `qdir="$SCRIPT_DIR/.stow-conflicts/$ts"` and then warn `quarantine target already exists — skipping duplicate` (line 443), losing conflict backup for second run. Earlier phase fixed nanoseconds with `$$` suffix always.
**Fix:**
```bash
if ! ts=$(date +%Y%m%d-%H%M%S-%N 2>/dev/null | cut -c1-19 2>/dev/null); then
  if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then ts="$(date +%s)"; fi
fi
ts="${ts}-$$"
# or use mktemp -d "$SCRIPT_DIR/.stow-conflicts/$(date +%Y%m%d-%H%M%S)-$$-XXXX"
```

### WR-04: `offer_system_package_removal` fallback to `ALL_TOOLCHAIN` over-offers

**File:** `setup.sh:593-607`
**Issue:** When `SELECTED_DEPS` empty (common for `--uninstall` path where `prompt_toolchain_checklist` never runs), candidates becomes `ALL_TOOLCHAIN` (13). DRY_RUN then prints 13 `sudo pacman -Rns`/`apt remove` previews even though most were preinstalled, not installed by setup.sh. User verbatim D-05 "all packages that were installed with setup" implies intersection of missing+installed, not unconditional all. Filtering via `filter_deps_by_selection` when `SELECTED_DEPS` empty is bypassed, so preview is misleading and live removal is overbroad.
**Fix:** Track actually installed-by-setup list (e.g., write `$HOME/.cache/dotfiles-installed` on install) or at least filter candidates to `verify_deps` missing+installed delta, not blind `ALL_TOOLCHAIN`. Minimum: warn `Offering removal for ALL_TOOLCHAIN — only packages previously verified missing were installed by setup.sh`.

### WR-05: Stale `AGENTS.md` still references deleted bootstrappers

**File:** `AGENTS.md:30-32, 101, 117, 194, 215, 262`
**Issue:** After Phase 1 staged delete of `setup.nu`/`setup.zsh` and Phase 2 deletion of `teardown.*`, `AGENTS.md` still documents `setup.nu`/`setup.zsh` as active bootstrappers ("Shell (Bash/POSIX) — subshell fragments inside setup/setup.sh --uninstall scripts" line 32 even repeats `setup.sh --uninstall` twice) and lists `Nushell required for setup.nu/setup.sh --uninstall`. The canonical entry is `bash setup.sh` per PROJECT.md Constraints, but AGENTS contradicts it, causing downstream agents to read wrong entry points. `Location: setup.nu, setup.zsh, setup.sh --uninstall, setup.sh --uninstall (repo root)` duplicates `setup.sh --uninstall`.
**Fix:** Scrub `AGENTS.md` to unified installer only:
```markdown
- Languages: Shell (Bash) — unified installer `setup.sh` (Nushell `setup.nu` and Zsh `setup.zsh` were deleted Phase 1)
- Runtime: GNU Stow — `setup.sh` uses `stow --restow` / `stow -D`; `teardown.*` deleted Phase 2
- Location: `setup.sh` (repo root) — validates host, stow orchestration, privileged keyd
```
Regenerate via `codebase/STACK.md` if needed.

### WR-06: Unquoted `$pkg` in echo preview (low severity)

**File:** `setup.sh:741`
**Issue:** `echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"$HOME\" --delete $pkg"` interpolates `$pkg` unquoted in log line. While not executed, if `SELECTED_PACKAGES` ever contained spaces (future package names with dash, not space, so low risk) the preview is misleading. More importantly, the same file correctly quotes `"$pkg"` in the actual `stow ... "$pkg"` call (line 743), showing inconsistency.
**Fix:** `echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"$HOME\" --delete $pkg"` → include quotes in preview: `echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"$HOME\" --delete \"$pkg\""` or use `printf '%q'`.

### WR-07: `rm -rf` Mason path without `HOME` guard

**File:** `setup.sh:821, 758-763`
**Issue:** `rm -rf "$HOME/.local/share/nvim/mason"` is correctly quoted, but `HOME` is not validated non-empty and not `/`. With `set -u`, unbound `HOME` would already abort before, but if `HOME=""` (empty string, not unbound) or `HOME=/`, the command becomes `rm -rf "/.local/share/nvim/mason"` or `rm -rf "//.local/share/nvim/mason"` – still scoped, but `rmdir "$HOME/.local/share/nvim"` next line could attempt to remove `/` parent. Check `[[ -n "${HOME-}" && "$HOME" != "/" ]]` before destructive rm.
**Fix:**
```bash
if [[ -z "${HOME-}" || "$HOME" == "/" ]]; then
  echo "Refusing to rm Mason: HOME invalid ($HOME)" >&2
  return 1
fi
if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
  rm -rf "$HOME/.local/share/nvim/mason"
  rmdir "$HOME/.local/share/nvim" 2>/dev/null || true
fi
```

## Info

### IN-01: Duplicated checklist ladder (7× `TERMUX_DISABLED` loops, 5 backends × 2 checklists)

**File:** `setup.sh:853-1402`
**Issue:** `checklist_gum`/`whiptail`/`dialog`/`fzf`/`read` and `toolchain_gum`/`whiptail`/`dialog`/`fzf`/`read` each re-implement identical `preset_state` + Termux disabled-row filtering + `xargs` parsing. 10 functions, ~400 lines, copy-paste of `for d in "${TERMUX_DISABLED_PACKAGES[@]}"` and `args+=("$pkg" "$desc" "$state")`. Violates DRY, increases drift risk (already diverged: toolchain `stow (required)` note vs package ladder Termux suffix). No functional bug, but maintainability debt.
**Fix:** Extract `build_checklist_args()` and `parse_xargs_selection()` helpers; or keep but add comment `NOTE: keep in sync with toolchain_*` and deduplicate disabled check into `is_termux_disabled() { [[ "${FAMILY:-}" == "termux" ]] && printf '%s\n' "${TERMUX_DISABLED_PACKAGES[@]}" | grep -qx "$1"; }`.

### IN-02: Hard-coded counts in user-visible messages

**File:** `setup.sh:898-899, 956-957, 1014-1015, 1046-1047, 1194, 1242, 1290, 1317, 1452-1453`
**Issue:** Messages `echo "7 packages offered"` and `echo "13 toolchain offered"` are literal strings, while `ALL_PACKAGES` and `ALL_TOOLCHAIN` are arrays that could change. If a package is added/removed, count drifts. Already uses `${#SELECTED_PACKAGES[@]}` for selected count but not offered.
**Fix:** `echo "${#ALL_PACKAGES[@]} packages offered"` and `echo "${#ALL_TOOLCHAIN[@]} toolchain offered"`.

### IN-03: `zsh/.zprofile` UTF-8 header and dead comment noise

**File:** `zsh/.zprofile:1`
**Issue:** File is intentionally empty per D-10, but header `# zsh/.zprofile — no Hyprland autostart (removed Phase 2, D-10)` uses em dash `—` (UTF-8 342 200 224) and repeats decision log that belongs in git history, not login profile. Not harmful, but inconsistent with repo `.editorconfig` `charset=utf-8` is okay, but login profile is sourced on every login – keep minimal to avoid parse overhead. Comment references `Hyprland` command that does not need backticks.
**Fix:** Keep 2-line comment minimal or trim to `# No Hyprland autostart — see setup.sh and git history (D-10)` – no functional change.

---

_Reviewed: 2026-09-12T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
