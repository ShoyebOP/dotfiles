---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 3
current_phase_name: Polished Shell, Theme & Local Overrides
status: planning
stopped_at: Phase 2.1 context gathered
last_updated: "2026-09-14T11:08:44.568Z"
last_activity: 2026-09-14
last_activity_desc: Phase 02.1 execution started
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 10
  completed_plans: 10
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-10)

**Core value:** A fresh clone can go from `bash setup.sh` → working Zsh + Neovim + desktop environment on any supported distro/derivative with one interactive run, and cleanly reverse itself — no manual `stow` or `MasonInstallAll` required.
**Current focus:** Phase 02.1 — remove-hyperland-and-hyperland-related-configs-and-make-sure

## Current Position

Phase: 3 — Polished Shell, Theme & Local Overrides
Plan: Not started
Status: Ready to plan
Last activity: 2026-09-14 — Phase 02.1 complete, transitioned to Phase 3

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 10
- Average duration: -
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Universal Installer + Platform Foundations | 0/2 | - | - |
| 2. Safe, Reversible & Server-Safe Deployment | 0/2 | - | - |
| 3. Polished Shell, Theme & Local Overrides | 0/1 | - | - |
| 4. Editor Autonomy & Verified Health | 0/2 | - | - |
| 01 | 5 | - | - |
| 02 | 2 | - | - |
| 02.1 | 3 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P01 | 3 min | 3 tasks | 1 files |
| Phase 01 P02 | 5 min | 3 tasks | 5 files |
| Phase 01 P03 | 1 min | 1 tasks | 1 files |
| Phase 01 P04 | 4 min | 3 tasks | 1 files |
| Phase 01 P05 | 3 min | 2 tasks | 1 files |
| Phase 02-safe-reversible-server-safe-deployment P01 | 6 min | 3 tasks | 2 files |
| Phase 02-safe-reversible-server-safe-deployment P02 | 5 min | 3 tasks | 6 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Unified Bash `setup.sh` for install+remove (Bash 5.2 preinstalled, single entry)
- Distro detection via `ID_LIKE` + `pacman`/`apt`/`pkg` probe → families `arch`/`debian`/`termux` (Termux separate pkg list, no sudo/keyd)
- Flow: mode → shell (zsh default) → package checklist before any write, with gum→whiptail→dialog→fzf→read ladder
- Coarse granularity: 4 vertical MVP slices (Phase 1 spine installable, later phases polish fzf/Mason/health)
- [Phase ?]: Help-wins-anywhere via pre-scan — any --help/-h exits 0 before validation (D-08) — Ensures invocation contract holds under strict mode without crashes
- [Phase ?]: Termux-first 4-tier family detection with OS_RELEASE_FILE seam — Covers Manjaro/EndeavourOS/Garuda/Mint/Pop and Termux env fixtures via manager fallback
- [Phase ?]: Per-family install names mapped to binary probes (neovim->nvim etc) and Termux best-effort pkg table — Fixes donor defect where package names mismatched manager repos, keeps Termux sudo-free
- [Phase ?]: Stow version check via sort -V routed through same manager lock (D-15) — Version-sort semantics handle 2.10 > 2.4.1 correctly, never lexicographic
- [Phase ?]: Five-backend ladder gum→whiptail→dialog→fzf→read in locked order, cancel never cascades — selection contract unchanged regardless of backend — Ensures interactive checklist works with whatever TUI is preinstalled, Termux disabled emulation and preset contract stay consistent
- [Phase ?]: Quarantine via mv only to .stow-conflicts/<timestamp>/ preserving relative paths with MANIFEST and restore hint, gitignored — Never delete or force-adopt user files; quarantine is reversible and folded-link aware to avoid deleting repo content
- [Phase ?]: Folding-aware post-verify via readlink -f prefix under SCRIPT_DIR/<pkg>/ — Covers both folded directory-links and unfolded file-links; aborts with link→expected-target report on mismatch
- [Phase ?]: Outside-repo-root guard requires ./setup.sh in CWD alongside SCRIPT_DIR/setup.sh — Fixes donor CWD-relative stow defect and prevents privileged writes from wrong directory
- [Phase ?]: Staged delete of setup.nu/setup.zsh with atomic README/.gitignore repair; keyd Phase-2 skip — No shims, git history is recovery; docs now canonical Bash entry with Zsh default, Nushell backup, no --adopt in Phase 1
- [Phase 01]: POSIX guard via [ -z "${BASH_VERSION-}" ] before strict mode ensures sh fails fast with guidance — Preserves bash/shebang paths; uses POSIX [ and ${BASH_VERSION-} so dash executes guidance before pipefail crash
- [Phase 01]: Two-step checklist (7 stow + 13 toolchain) before any write with SELECTED_DEPS filtering — Honors user's explicit toggleable deps decision, closes G-01-14b
- [Phase ?]: Use DRY_RUN early-return before every filesystem mutation including stow -D and privileged writes — Ensures preview safety per D-03/D-06/D-09
 - [Phase ?]: Privileged keyd gate with preview + diff -u + conditional --adopt + reload || true — Prevents surprise /etc writes per STOW-02
 - [Phase 02-02]: Zsh provision via common deps before stow, Zinit self-clones on first zsh launch via zsh/.zshrc — no installer clone, no commit pin per D-12
 - [Phase 02-02]: chsh -s $(which zsh) offered only at very end after quarantine_scan+run_stow+post_verify succeed, explicit Type 'yes', --yes does NOT bypass, dry-run previews, Termux/already-zsh skipped per D-13
 - [Phase 02-02]: Docs flipped to Default: Zsh | Backup: Nushell — README shell-path table, quick-start, manual stow one-liners, keyd preview+sudoers reload, Zinit note per D-14
 - [Phase 02-02]: Staged delete teardown.zsh/teardown.nu with atomic doc fix, no shims, recoverable via git history per D-15

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

### Roadmap Evolution

- Phase 2.1 inserted after Phase 2: remove hyperland and hyperland related configs and make sure anything related to hyperland is not installed in local installation (URGENT)

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-09-14T09:04:29.139Z
Stopped at: Phase 2.1 context gathered
Resume file: /home/shoyeb/dotfiles/.planning/phases/02.1-remove-hyperland-and-hyperland-related-configs-and-make-sure/02.1-CONTEXT.md
