# Debug Session: checklist-after-install ordering (G-01-13)

**Phase:** 01-universal-installer-platform-foundations
**Gap:** G-01-13
**Symptom:** `it shows selection after installation is done not before`
**Severity:** major
**Test:** 13

## Symptoms
- User runs `bash setup.sh` (TTY, interactive)
- Sees `Verifying dependencies...` / `Installing via sudo apt install -y ...` / `Re-verify` scrolling first
- Only afterwards sees `=== Package Selection ===` and checklist
- Expects checklist BEFORE any writes (deps install is a write)
- ROADMAP success criteria 5 explicitly: `mode → shell → package checklist BEFORE any write`

## Investigation
- Read `setup.sh:663-850` main()
  - Order: `parse_args → repo guard → prompt_mode/prompt_shell (20-23) → detect_family (20) → get_deps/verify/install/reverify (25-73) → prompt_checklist (76) → quarantine/run_stow/post_verify`
  - Checklist is at line 75-78, AFTER install block lines 62-73 which already performed `sudo pacman -S` / `sudo apt install -y` / `pkg install`
  - Verify/install is NOT dry-run guarded beyond preview: `install_deps` does early return only if DRY_RUN, otherwise it mutates filesystem and may require sudo
  - Checklist position violates `before any write` guarantee: user cannot deselect packages before deps are installed, defeating override intent of INST-04

- Checked REQUIREMENTS and ROADMAP
  - ROADMAP Phase 1 criterion 5: `User sees interactive flow mode → shell → package checklist BEFORE any write and can preview every write with --dry-run`
  - 01-02 PLAN also claims checklist before any write, but implementation deferred install before checklist for technical convenience (deps needed before stow, but should still be after selection)
  - Current `get_deps` is keyed by `FAMILY` + `MODE`, not by `SELECTED_PACKAGES`, so moving checklist earlier does not change dep set yet, but future fix could filter gui deps by selection; at minimum ordering must respect preview-before-write

- Checked DRY_RUN handling
  - Dry-run currently previews deps install via `[DRY RUN] Would run: ...` BEFORE checklist, then checklist preview after — user cannot consent to the combined plan upfront
  - Expected: dry-run should show SINGLE preview of deps + stow after checklist, or preview checklist selection then deps

- Reproduction
  - `bash setup.sh --mode server --dry-run` on host with stow 2.3.1 shows: `Verifying dependencies...` → `Stow 2.3.1 < 2.4.1 — will upgrade` → `[DRY RUN] Would run: sudo apt install -y stow` → BEFORE `Package Selection` → violates expectation
  - Piped real run with `printf '2\n1\n\n' | HOME=/tmp/fake bash setup.sh` shows same ordering

## Root Cause
**main() ordering bug: dependency verify/install/re-verify (lines 25-73) executes BEFORE `prompt_checklist` (line 75). Checklist should precede any write (install_deps), but current flow writes before user finalizes selection.**

- File: `setup.sh:688-740` — verify/install block precedes checklist
- Missing: checklist before install, with deps filtered or at least previewed after selection

## Evidence Summary
- `sed -n '663,750p' setup.sh` shows checklist at 75, install at 64
- `bash setup.sh --dry-run` log shows `Missing CORE` before `Package Selection`
- ROADMAP criterion 5 requires checklist before any write — current implementation fails this
- No technical blocker: `FAMILY` and `MODE` are known before checklist; `SELECTED_PACKAGES` not needed for common deps, but reordering is safe

## Files Involved
- `setup.sh:663-790` — main() ordering, needs reorder

## Suggested Fix Direction
- Move `prompt_checklist` immediately after `detect_family` / mode/shell resolution and BEFORE `get_deps`/`verify_deps`/`install_deps`
- Keep `FAMILY/MODE` detection first (needed for both deps and checklist presets), but defer any `install_deps` until AFTER selection
- Ensure DRY_RUN previews BOTH deps and stow together after checklist (single `preview_selection` + deps preview)
- Optionally filter `gui` deps by final `SELECTED_PACKAGES` (if user deselected wofi, skip its deps) — at minimum, just move ordering to satisfy before-any-write guarantee
