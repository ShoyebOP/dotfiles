---
gsd_state_version: "1.0"
milestone: v1.0
current_phase: 6
current_phase_name: Neovim Editor QoL Fixes
status: complete
stopped_at: All phases complete — Phase 5 marked complete; former Phase 7 renumbered to Phase 6
last_updated: "2026-11-23T16:54:08.000Z"
last_activity: 2026-11-23
last_activity_desc: Phase 5 marked complete; Phase 6 self-test removed and former Phase 7 renumbered to 6
state_head: 5db534050a60351ea14041fe5f86bfedf64c21e3
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 21
  completed_plans: 21
  percent: 100
milestone_name: milestone
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-23)

**Core value:** A fresh clone can go from `bash setup.sh` → working Zsh + Neovim + desktop environment on any supported distro/derivative with one interactive run, and cleanly reverse itself — no manual `stow` or `MasonInstallAll` required.
**Current focus:** All phases complete — v1.0 milestone ready to close

## Current Position

Phase: 6 — Neovim Editor QoL Fixes (final phase)
Plan: 4/4
Status: Complete — Phase 5 marked complete at user direction; all phases done
Last activity: 2026-11-23 — Phase 5 marked complete; self-test phase removed, former Phase 7 renumbered to 6

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 21
- Average duration: -
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Universal Installer + Platform Foundations | 0/2 | - | - |
| 2. Safe, Reversible & Server-Safe Deployment | 0/2 | - | - |
| 3. Polished Shell, Theme & Local Overrides | 2/2 | - | - |
| 5. Editor Autonomy & fzf-lua Migration | 2/2 | - | - |
| 01 | 5 | - | - |
| 02 | 2 | - | - |
| 02.1 | 3 | - | - |
| 04 (old 05) | 3 | - | - |
| 06 | 4 | - | - |

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
| Phase 03-polished-shell-theme-local-overrides P01 | 9 min | 3 tasks | 7 files |
| Phase 03-polished-shell-theme-local-overrides P02 | 5 min | 2 tasks | 1 files |
| Phase 03-polished-shell-theme-local-overrides P02 | 5 min | 2 tasks | 1 files |
| Phase 05-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp P03 | 12 min | 3 tasks | 2 files |
| Phase 06 P02 | 15 min | 3 tasks | 3 files |
| Phase 06 P03 | 2min | 2 tasks | 2 files |
| Phase 06 P04 | 5min | 3 tasks | 8 files |

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
- [Phase 03-polished-shell-theme-local-overrides]: Tail PATH re-assertion via array self-assignment: scalar export bypasses typeset -U at assignment time on zsh 5.9 — Array form keeps the plan first-match awk verify green with identical retro-dedupe semantics
- [Phase 03-polished-shell-theme-local-overrides]: Debian legacy fzf rung added: doc/examples key-bindings path is the only legacy location for distro fzf 0.44.1 — Without it Ctrl+R warns despite fzf installed; plan single legacy path absent on Debian-family
- [Phase 03-polished-shell-theme-local-overrides]: Check-1 typing auto-show failure deferred to a separate future phase per user directive; phase 03 completes with the partial human verdict recorded verbatim (1 failed/deferred, 1 passed, 1 untested) — Human verdict was partial-fail; fixing the typing auto-show failure here would violate MVP_MODE no-scope-expansion, so it is deferred to a user-owned future phase
- [Phase 05-03]: Keep the one-shot precmd zasync hook as the shipped path while upstream PRs #903/#905 and issue #907 stay open; release-tag pin is fallback-only on observed live hook failure, never pre-pinned — a future upstream merge retires the hook via the manager update path per the README `Retire after` condition
- [Phase 06 — SUPERSEDED by G-07-4]: G-07-1: far-left opaque scrollview markers with the bar hidden by a ScrollView->Normal highlight link — layout abandoned, plugin removed by 07-04
- [Phase 06 — SUPERSEDED by G-07-4]: G-07-1: dedicated │ separator float with a widened signcolumn — Neovim left-aligns signs so spare cells formed the empty gap; abandoned, native per-line gitsigns are now the only git indicator
- [Phase 06]: Buffer cycling rebound to <M-,>/<M-.> (Alt+comma/period): kitty legacy Alt ESC-prefix is the only user-offered pair delivered reliably; supersedes 06-CONTEXT.md scope item 5 per UAT acceptance
- [Phase 06]: README now documents kitty as the primary terminal for key delivery, with Alacritty retained only as a secondary case
- [Phase 06-04]: G-07-4 abandoned the far-left marker + divider gutter entirely as unachievable with the pinned nvim-scrollview and Neovim signcolumn model; removed the scrollview spec, its lazy-lock pin and the widened signcolumn so native per-line gitsigns are the only git indicator (supersedes both G-07-1 decisions above)

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 05 RESOLVED 2026-09-23]: SHEL-02 auto-show half + D-29 Tab-vs-ghost ownership closed by 04-03 gap-closure (renumbered from 05) slice (R-3 one-shot precmd hook + R-7 menuselect Tab line) with an overall-PASS blocking-human live verdict ("perfect fully fixed and everything is working as intended"). Upstream re-check: PR #903 open, PR #905 open, issue #907 open — hook kept as shipped path, release-tag pin fallback-only. Static gates all green. See 04-03-SUMMARY.md (renumbered from 05).
- Follow-up (out of scope, routed): setup.sh post_verify will report `~/.config/nvim/.gitignore` MISSING on next live run (Stow default-ignores `.gitignore`, 65/66 leaf links) — owner: setup.sh follow-up or Phase 6 self-test scope.

### Roadmap Evolution

- Phase 6 added (formerly Phase 7, renumbered 2026-11-23 after the self-test phase was removed): Neovim Editor QoL Fixes (diagnostic float keybind, stale keymap removal, native per-line gitsigns only after G-07-4 abandoned the far-left marker + separator layout and removed the scrollview plugin, nvim-surround install, Alt+comma/Alt+period buffer cycling; smoothscroll option removal noted as cosmetic; cursor-jump investigation explicitly out of scope)
- Phase 2.1 inserted after Phase 2: remove hyperland and hyperland related configs and make sure anything related to hyperland is not installed in local installation (URGENT)
- Phase 5 added: fix marlonrichert/zsh-autocomplete Real-time type-ahead completion for Zsh doesn't work and needs to press tab to show.
- Phase 5 planned 2026-09-22: 2 plans (tracer 04-01 + expansion 04-02 (renumbered from 05)), plan-checker passed with 0 blockers/0 warnings. Decision-coverage gate override: 30/33 decisions cited in must_haves; D-08 (SUPERSEDED by D-27/D-28), D-18 (EXPANDED by D-33), D-23 (research directive, executed via Context7-first) intentionally uncited — verify-phase may re-surface. RESEARCH.md INFO: three "seven" shorthands vs nine measured stow sites — plans target nine; optional word fix alongside execution.
- Phase reswap 2026-10-01: old Phase 5 (autocomplete, complete) → new Phase 4 (dir + 12 files 05-* → 04-*); old Phase 4 (Editor+Health, pending) split into new Phase 5 Editor Autonomy & fzf-lua Migration (EDIT-01/02 unchanged, EDIT-03 = telescope* removal + fzf-lua + make/gcc dep removal, Depends on Phase 4) and new Phase 6 Verified Health & Self-Test Gates (HLTH-01 moved, Depends on Phase 5).
- Phase 6 (Verified Health & Self-Test Gates) removed 2026-11-23: unstarted phase (no directory, 0 plans); former Phase 7 (Neovim Editor QoL Fixes) renumbered to Phase 6 — dir + 14 files 07-* → 06-*, ROADMAP/state.json updated via `phase remove`.
- Phase 5 marked complete 2026-11-23 at user direction: both plans have SUMMARY.md records (2/2 executed) but 05-VERIFICATION.md remains `human_needed` (12/13 must-haves, 1 behavior unverified; 05-UAT.md 3 pending). Status flipped without fabricating verification/UAT results; `phase complete` was gated by the non-PASSED verification status.

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Phase 03 gap | Typing auto-show feel (SHEL-02 half): typing 2–3 chars + pause shows no completion list despite correct zsh-autocomplete wiring; Tab menu-select + ghost text unverified. User deferred to a dedicated future phase — no code attempted in 03-02. VERIFICATION.md 5/6, phase completed with debt. | Deferred — needs dedicated diagnosis/fix phase | 2026-09-17 |
| Phase 05 carry-forward | SHEL-02 auto-show half + D-29 Tab-vs-ghost ownership STILL OPEN after Phase 05 tracer attempt: live verdict 2/6 FAIL (typing shows no menu at all; Tab glitches ghost text — bolds-as-real then vanishes on typing). Static slice committed + green (min-input 1, delay 0, list-lines 300, ladder, preset, re-assert, zshenv guard). STOW-01 containment shipped. Needs researcher-led re-investigation (D-34 freedom), not a keybind-only fix. Verbatim verdict in 04-02-SUMMARY.md (renumbered from 05); gaps in 04-VERIFICATION.md (renumbered from 05). | Closed 2026-09-23 by 04-03 gap-closure slice (renumbered from 05) — overall-PASS live verdict, see 04-03-SUMMARY.md (renumbered from 05) | 2026-09-22 |

## Session Continuity

Last session: 2026-11-23T15:57:32.288Z
Stopped at: All phases complete — Phase 5 marked complete; former Phase 7 renumbered to Phase 6 (self-test phase removed)
Resume file: None
