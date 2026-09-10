# Phase 1: Universal Installer + Platform Foundations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-10
**Phase:** 1-Universal Installer + Platform Foundations
**Areas discussed:** Old scripts fate, Missing-flag behavior, Checklist shape, Conflict policy

---

## Old scripts fate

| Question | Options presented | Selected |
|----------|-------------------|----------|
| Canonical installer filename: setup.sh or install.sh? | setup.sh (Recommended) / install.sh / You decide | setup.sh (Recommended) ✓ |
| What happens to setup.nu/zsh + teardown.nu/zsh in Phase 1? | Thin shims (Recommended) / Delete outright / Keep as-is | Delete outright (→ refined to staged delete next) |
| --uninstall ships in Phase 2, but you chose delete outright. Delete setups now + teardowns later, or all 4 now? | Staged delete (Recommended) / Delete all now | Staged delete (Recommended) ✓ |
| Delete leaves README/comments pointing at gone files. Fix references atomically in Phase 1 or defer to Phase 2 docs? | Atomic docs fix (Recommended) / Defer docs to Phase 2 | Atomic docs fix (Recommended) ✓ |

**User's choice:** `setup.sh`; staged delete (setups in Phase 1, teardowns after Phase 2 `--uninstall`); atomic README/comment fix in the Phase 1 commit.
**Notes:** Initial pick was "delete outright" for all 4; user accepted the staged refinement when told `--uninstall` (INST-03) only lands in Phase 2 — deleting teardowns now would remove reversibility with no replacement.

---

## Missing-flag behavior

| Question | Options presented | Selected |
|----------|-------------------|----------|
| User runs bare `bash setup.sh` on a terminal with no flags. Prompt interactively or show usage? | Interactive prompts (Recommended) / Usage and exit / You decide | Interactive prompts ✓ |
| Same command with no TTY (CI pipe, no flags). Abort with usage or run defaults? | Abort with usage (Recommended) / Run with defaults | Abort with usage ✓ |
| Partial flags, e.g. `--mode server` with no --shell. Prompt for the rest, default it, or abort? | Prompt for rest (Recommended) / Default the rest / Abort unless full | Prompt for rest ✓ |
| `--help` mixed with other flags, or an unknown flag. Which precedence? | --help wins (Recommended) / Abort on unknown | --help wins ✓ |

**User's choice:** All recommended options. TTY → prompt (bare or partial); no TTY without full flags → usage + non-zero exit, zero writes; `--help` anywhere wins (exit 0, no changes).
**Notes:** Resolves the success-criteria ambiguity ("--help or no TTY / missing arg shows usage"): usage-applies-to-no-TTY and unknown-flag cases, not to bare TTY runs.

---

## Checklist shape

| Question | Options presented | Selected |
|----------|-------------------|----------|
| Checklist granularity: all 7 packages individually toggleable, or core-locked with GUI-only toggles? | All 7 toggleable (Recommended) / Core-locked + GUI toggle | All 7 toggleable ✓ |
| Mode=server preselection: GUI packages pre-unchecked, or same defaults as local? | Server unchecks GUI (Recommended) / Same as local | Server unchecks GUI ✓ |
| Shell preselection: only the chosen shell pre-checked, or both shells pre-checked? | Only chosen shell (Recommended) / Both shells | Only chosen shell ✓ |
| Termux: hide keyd/hyprland/wofi from the checklist, or show them disabled? | Hide + note (Recommended) / Show disabled | Show disabled (override) |

**User's choice:** All 7 individually toggleable; server pre-unchecks GUI; only chosen shell pre-checked; Termux shows keyd/hyprland/wofi visibly disabled with reason text.
**Notes:** Only explicit override of a recommendation in the session (hide+note → show disabled). Checklist ladder `gum → whiptail → dialog → fzf → read` was pre-locked by ROADMAP and not re-asked.

---

## Conflict policy

| Question | Options presented | Selected |
|----------|-------------------|----------|
| Target exists and is not a stow symlink (e.g. ~/.config/nvim/). Abort, backup, or prompt? | Abort with fix-it (Recommended) / Backup to *.bak / Prompt each | Other (freeform) — quarantine to repo-root gitignored timestamped dir |
| Repo-root quarantine confirmed (.stow-conflicts/<timestamp>/, gitignored). Include a manifest + restore hint? | Manifest + restore (Recommended) / Move only | Manifest + restore ✓ |
| Host stow is 2.3.1 (< 2.4.1). Auto-upgrade, warn-and-continue, or abort? | Warn and continue (Recommended) / Auto-upgrade stow / Abort until 2.4.1 | Auto-upgrade stow (override) |
| Post-stow verify (test -L + readlink -f) finds a bad link. Abort with report or warn-and-pass? | Abort with report (Recommended) / Warn and pass | Abort with report ✓ |

**User's choice:** Freeform quarantine ("create a gitignored conflicts directory and move all the conflicting folders in a separate timestamped folder", location follow-up: repo root) + manifest/restore hint; auto-upgrade stow below 2.4.1; strict abort-with-report on post-verify failure.
**Notes:** Two overrides here: quarantine replaces the abort/backup/prompt trio; auto-upgrade beats warn-and-continue (host runs stow 2.3.1, so the upgrade path will execute for real). Freeform answer handled per default-mode rule: plain-text follow-up (location + manifest), reflected back, then resumed questions.

---

## the agent's Discretion

None — user decided every question; "You decide" was never selected.

## Deferred Ideas

None — discussion stayed within Phase 1 scope. Phase 2 items (`--uninstall`, keyd `--adopt` gate, Hyprland guard) and v2 `AUTO-01` snapshot/restore were referenced as boundaries, not new asks.
