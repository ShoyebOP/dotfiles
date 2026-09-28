# Debug Session: only 4-5 packages toggleable (G-01-14)

**Phase:** 01-universal-installer-platform-foundations
**Gap:** G-01-14
**Symptom:** `not all the package show as toggleable only 4-5 shows`
**Severity:** major
**Test:** 14

## Symptoms
- User runs `bash setup.sh` on TTY and sees checklist, but only 4-5 entries appear toggleable instead of expected 7 (nvim, zsh, nushell, alacritty, starship, wofi, keyd)
- Expected: all 7 individually toggleable per INST-04 and D-09
- Observed: 4-5 visible/interactive

## Investigation
- Read `setup.sh:18-20` ALL_PACKAGES definition
  - `ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd)` = 7 — correct source
  - `GUI_STOW_PACKAGES=(alacritty wofi keyd)` = 3
  - `TERMUX_DISABLED_PACKAGES=(alacritty wofi keyd)` = 3

- Read `setup.sh:577-641` checklist_read (fallback when gum/whiptail/dialog/fzf absent)
  - TTY path loops `for pkg in "${ALL_PACKAGES[@]}"` and prints `printf " %2d %s %s%s\n" "$i" "$marker" "$pkg"` for each pkg
  - Correctly iterates 7 and increments `i`, should show 7 lines with `[x]/[ ]` markers
  - Non-TTY fast path (lines 585-591) skips display and prints `Selected packages (non-interactive presets): ...` with only ON presets — for `server + zsh` this is `nvim zsh starship` = 3, not 7. If user ran in a piped/non-TTY context or with stdin not a tty, they'd see only presets, not the toggle UI.

- Read `setup.sh:457-500` checklist_whiptail / `502-545` checklist_dialog
  - whiptail args: `whiptail --title "Packages" --checklist "Space to toggle (before any write):" 20 78 10 "${args[@]}"`
  - `20 78 10` = window 20x78, list height 10. With 7 items, should fit. But if terminal is small (e.g., 24x80), whiptail may clip or require scrolling; user sees only 4-5 without scrolling
  - dialog same 20 78 10
  - Both set `preset_state` ON/OFF then build `args` with `"$pkg" "$desc" "$state"` triples. For server mode, GUI OFF, so 3 appear unchecked but still visible and toggleable — but user may interpret unchecked as not toggleable?

- Read `setup.sh:410-455` checklist_gum / `547-575` checklist_fzf
  - `gum choose --no-limit` and `fzf -m` both render full `ALL_PACKAGES` list, but gum/fzf may not be installed. If absent, ladder falls through to whiptail/dialog/read. If terminal emulator lacks sufficient height, gum/fzf may truncate visible rows.

- Read `setup.sh:642-661` prompt_checklist ladder order
  - Ladder probes `gum → whiptail → dialog → fzf → read` in locked order
  - Each rung returns 1 if binary absent, 2 if cancelled, 0 if success
  - If `gum` is present but misconfigured, or whiptail/dialog fail to render due to TERM, fallback to fzf/read should still show all 7
  - However, reported "only 4-5 shows" matches two plausible failure modes:
    1. User's environment had `TERMUX_VERSION` or `FAMILY=termux` mis-detected, causing TERMUX_DISABLED to render 3 as OFF with "(not available)" suffix and then `strip_termux_disabled` drops them — visible 7 but only 4 selectable
    2. User's terminal height truncated whiptail/dialog list (20 rows window may exceed terminal, only 4-5 rows visible without scrolling)

- Checked `detect_family` Termux detection (setup.sh:136-172)
  - Tier 1: `if [[ -n "${TERMUX_VERSION-}" ]] || [[ "${PREFIX-}" == *"com.termux"* ]] || command -v pkg` → on Debian with `pkg` installed via unrelated package (e.g., `pkg` shim), would mis-detect as termux
  - Tier 2-4: pacman/apt presence then ID_LIKE/ID. If host has both pacman and apt (e.g., CachyOS with debtap), still correctly picks via ID_LIKE
  - If mis-detected as termux, 3 packages become disabled and list shows 7 but only 4 toggleable — exactly matches report

- Checked reproduction on current host (debian, no pkg)
  - `bash setup.sh --mode server --dry-run` with `PATH` hiding gum/whiptail/dialog/fzf falls to `checklist_read` TTY branch: prints 7 lines with markers `[x]` / `[ ]` correctly
  - `TERMUX_VERSION=1 bash setup.sh --mode server --dry-run` shows `alacritty/wofi/keyd` as `[ ] (not available on Termux — never selectable)` — still 7 lines, but 3 disabled
  - `printf '2\n1\n\n' | HOME=/tmp/fake PATH=/tmp/noladderbin bash setup.sh --dry-run` (non-TTY) prints `Selected packages (non-interactive presets): nvim zsh starship` — only 3 shown, which user could perceive as "only 4-5 toggleable" if they expected interactive checklist but got preset summary

## Root Cause
**Two contributing causes, both in checklist presentation:**

1. **Primary — ordering/preset confusion compounded by non-TTY fallback:** When run without a proper TTY or when piped, `checklist_read` non-TTY fast path (setup.sh:585-591) prints only the ON presets (`nvim zsh starship` = 3, or 4-5 for local mode with `nushell` etc.) instead of the full 7 toggleable list. User may have run via `sh setup.sh` or in a terminal where `[[ -t 0 ]]` was false, seeing only preset summary and interpreting as "only 4-5 toggleable."

2. **Secondary — Termux mis-detection or whiptail viewport clipping:** If `command -v pkg` exists or terminal height < 20 rows, whiptail/dialog list height 10 with window 20 may clip, showing 4-5 rows in viewport requiring scroll. If mis-detected as termux, 3 entries render disabled and are then stripped, leaving 4 selectable.

- Files:
  - `setup.sh:578-640` — checklist_read TTY vs non-TTY branch
  - `setup.sh:457-500` — whiptail/dialog window sizing `20 78 10` may clip
  - `setup.sh:136-145` — detect_family Tier 1 `command -v pkg` overly broad

## Evidence Summary
- `ALL_PACKAGES` is 7, but non-TTY preset for `server+zsh` yields 3; `local+zsh` yields 7 but server presets deselect 3 GUI → leaves 4-5 ON depending on shell — matches "4-5 shows" if user conflated ON presets with total list
- `setup.sh:585` `if [[ ! -t 0 ]]` triggers preset-only path when stdin not a tty
- `TERMUX_VERSION` / `pkg` detection can force 3 disabled → 4 selectable
- whiptail `20 78 10` may clip on small terminals

## Files Involved
- `setup.sh:18` ALL_PACKAGES
- `setup.sh:577-640` checklist_read
- `setup.sh:457-500` checklist_whiptail/dialog
- `setup.sh:136-172` detect_family pkg probe

## Suggested Fix Direction
- Ensure TTY detection is robust and interactive checklist always shows all 7 with clear ON/OFF state, even when presets start OFF — never render preset summary as the only output on TTY
- Increase whiptail/dialog list height or make it adaptive: use `$(stty size)` or fallback to `read` if terminal height < 20
- Tighten Termux detection: require BOTH `TERMUX_VERSION` and `PREFIX` or `pkg` + `ID=termux`, not just `command -v pkg` alone; or at least require `pkg` + no apt/pacman
- Add explicit post-checklist echo: `Final selection: ... (7 packages offered, N selected)` so user sees total offered count
- In non-TTY + no `--mode`/`--shell` abort case, error message should state checklist requires TTY and show presets, not silently show only 3
