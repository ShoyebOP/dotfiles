# Debug Session: repo update missing (G-01-15)

**Phase:** 01-universal-installer-platform-foundations
**Gap:** G-01-15
**Symptom:** `it should update the repos in corresponding os like apt update/ pacman -Sy`
**Severity:** major
**Test:** 15

## Symptoms
- User on debian/arch runs installer on fresh system (or after long idle)
- `sudo apt install -y stow neovim ...` fails with `Unable to locate package` or old version because `apt` cache stale
- `sudo pacman -S --needed` fails with `failed to retrieve` or `404` because sync DB out of date
- Expected: installer runs `apt update` / `pacman -Sy` before trying to install missing deps

## Investigation
- Read `setup.sh:216-244` install_deps()
  - arch: `install_cmd=(sudo pacman -S --needed --noconfirm)` then `"${install_cmd[@]}" "${missing[@]}"` — no prior `pacman -Sy` or `-Syu`
  - debian: `install_cmd=(sudo apt install -y)` — no prior `apt update`
  - termux: `install_cmd=(pkg install -y)` loop per-pkg — no `pkg update` either, but pkg handles own update
  - No branch runs update command, even though fresh VMs / containers often have empty or stale lists
  - DRY_RUN correctly previews `Would run: sudo apt install -y ...` but does not mention update step (so not previewed either)

- Checked `get_deps` and verify flow
  - `verify_deps` partitions missing, `install_deps` consumes `missing` array verbatim — there is no hook to refresh repo metadata first
  - `reverify_deps` would detect still-missing and report `Still missing: ...` with exact retry command, but user expected automatic refresh instead of manual retry

- Checked REQUIREMENTS DEPS-02/DEPS-03
  - Specifies `pacman -S --needed` / `apt install -y` / `pkg install` but does not explicitly mention `apt update` / `pacman -Sy`. However, real-world fresh installs (e.g., new Ubuntu cloud image) require `apt update` first, otherwise `apt install` fails.
  - Prior verification on host had warm apt cache, so not caught. On fresh host, would fail.

- Checked prior host behavior
  - `sudo apt install -y stow` without `apt update` succeeded on this host because cache warm (last update recent). On fresh `docker run ubuntu:24.04`, `apt install -y stow` without update fails with `Unable to locate package stow`.

- Checked Termux
  - Termux `pkg install` usually warns if `pkg update` not run, but `pkg` auto-updates on some wrappers. Still, `pkg update -y` or `pkg upgrade` would be analogous, but spec says Termux no sudo and pkg path is sudo-free; adding `pkg update -y` there is lower priority. Primary need is arch/debian.

- Checked idempotency concerns
  - Running `apt update` every time is safe (idempotent) but slow; should run once per invocation when there is at least one missing dep, not on every re-verify
  - `pacman -Sy` should similarly run once before first install, not on each missing pkg loop
  - DRY_RUN should preview the update command alongside the install command

## Root Cause
**install_deps() never refreshes package manager metadata before installing missing dependencies. On fresh or stale systems, `apt install` / `pacman -S` fails because sync DB is outdated.**

- File: `setup.sh:216-244` — install_deps case branches set install_cmd but omit update step
- Missing:
  - `debian: sudo apt update` before `sudo apt install -y`
  - `arch: sudo pacman -Sy` before `sudo pacman -S --needed`
  - DRY_RUN preview of those update commands
  - For termux: optionally `pkg update -y` before loop (less critical)

## Evidence Summary
- `grep -n "apt update\|pacman -Sy\|pkg update" setup.sh` → 0 hits
- `install_deps` debian branch: `install_cmd=(sudo apt install -y)` with no preceding `apt update`
- arch branch: `sudo pacman -S --needed` with no `pacman -Sy`
- Fresh container test: `apt install` without update → `Unable to locate package` (known behavior, not reproduced on warm host but well-documented)
- ROADMAP does not explicitly require update, but user expectation + real-world fresh install failure makes it a gap

## Files Involved
- `setup.sh:216-244` install_deps()

## Suggested Fix Direction
- Insert repo refresh before first install, guarded by missing count >0 and DRY_RUN preview:

```bash
case "$family" in
  arch) echo "Refreshing pacman DB..."; if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: sudo pacman -Sy"; else sudo pacman -Sy || { echo "Warning: pacman -Sy failed" >&2; }; fi ;;
  debian) echo "Refreshing apt lists..."; if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: sudo apt update"; else sudo apt update || { echo "Warning: apt update failed" >&2; }; fi ;;
  termux) if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: pkg update -y"; else pkg update -y 2>/dev/null || true; fi ;;
esac
```

- Run once per install_deps invocation, before the actual install loop/array, not per-package
- Surface failure as warning, not fatal, so install can still try (some mirrors fail but install may still succeed from cache)
- Ensure DRY_RUN previews update alongside install
