---
phase: 03-polished-shell-theme-local-overrides
plan: 01
subsystem: shell
tags: [zsh, zinit, fzf, autocomplete, path, machine-local, nvim, installer, gitignore]

# Dependency graph
requires:
  - phase: 02-safe-reversible-server-safe-deployment
    provides: [canonical setup.sh spine, DRY_RUN preview idiom, Zinit self-clone, chsh end-of-run offer]
  - phase: 02.1-remove-hyperland-and-hyperland-related-configs-and-make-sure
    provides: [unified single-page checklist, Debian keyd notice, run-from-clone guard]
provides:
  - Repaired zsh plugin block (fzf-history-search loads, autocomplete stays last, split ^R/^I ownership)
  - Best-effort fzf degrade ladder (sort -V version branch, warn-and-continue, never breaks autocomplete)
  - Duplicate-free PATH across reloads (top guard plus convergent tail re-assertion)
  - HOME-only machine-local overrides (zsh tail guard, nvim pcall tail, gitignored, installer-bootstrapped, templated, documented)
  - Untracked shell history with working-tree file preserved
affects: [04-editor-autonomy-verified-health, verify-work-human-check]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 20486
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns: [split-ownership keybindings, degrade-ladder init, silent-absent loud-broken local overrides, convergent PATH re-assertion]

key-files:
  created: [zsh/.zshrc.local.example, nvim/.config/nvim/lua/local.lua.example]
  modified: [zsh/.zshrc, nvim/.config/nvim/init.lua, .gitignore, setup.sh, README.md]

key-decisions:
  - "Tail PATH re-assertion via array self-assignment (scalar export bypasses typeset -U at assignment time on zsh 5.9)"
  - "Debian legacy fzf rung added (doc/examples path is the only legacy key-bindings location for fzf 0.44.1)"
  - "History cached-untrack committed with Task-2 commit due to shared staging; full purge stays deferred SECR-02"
  - "Full setup.sh --dry-run does not invoke ensure_local_files (DRY_RUN branch untouched per plan); preview covered at function level"

patterns-established:
  - "Convergent PATH guard: top-of-file typeset -U path plus tail path=( $path ) re-assertion so every source pass ends duplicate-free"
  - "HOME-only local sourcing: tail guard after tool inits, before prompt apply; templates are docs-only under *.example"

requirements-completed: [SHEL-02, SHEL-03, SHEL-04, THEM-01, EDIT-04]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Polished shell spine in zsh/.zshrc: repaired plugin block, fzf degrade ladder, unconditional Ctrl+R bind with WARN, PATH dedup guard, HOME local tail guard, portable bun source"
    requirement: "SHEL-02"
    verification:
      - kind: other
        ref: "zsh -n zsh/.zshrc (syntax-ok) + guard/order/wiring/probe greps + hermetic triple-source reload-ok"
        status: pass
    human_judgment: true
    rationale: "Wiring is proven automatically, but interactive feel (async auto-show while typing, Ctrl+R fuzzy UI, prompt render) needs human eyes — the plan's end-of-phase human check"
  - id: D2
    description: "PATH survives triple sourcing with zero duplicates while shell still loads"
    requirement: "SHEL-03"
    verification:
      - kind: other
        ref: "hermetic triple-source PATH-dedup check (reload-ok)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Editor machine-local override (pcall require local tail) plus gitignore section plus two documented templates"
    requirement: "EDIT-04"
    verification:
      - kind: other
        ref: "nvim --headless clean start exit 0 + check-ignore gates (locals ignored, templates committable)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Installer ensure_local_files bootstrap plus README Machine-local docs plus history untrack, zero theme code"
    requirement: "SHEL-04"
    verification:
      - kind: other
        ref: "bash -n + bootstrap-wired greps + sourced DRY_RUN no-write proof + live create/no-truncate/idempotent + docs greps + ls-files history gate"
        status: pass
    human_judgment: false
  - id: D5
    description: "THEM-01 closed as intended-drift with zero theme code (no per-app appearance file touched)"
    requirement: "THEM-01"
    verification:
      - kind: other
        ref: "change-set gate: only the seven plan paths plus intended history index removal"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: 2026-09-17
status: complete
---

# Phase 03 Plan 01: Polished Shell Spine plus Local Overrides Summary

**End-to-end polished Zsh spine (fzf ladder, convergent PATH dedup, HOME local guard) plus gitignored editor overrides, installer bootstrap, and history untrack — zero theme code**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-17T07:09:15Z
- **Completed:** 2026-09-17T07:17:49Z
- **Tasks:** 3
- **Files modified:** 7 (5 edited, 2 created, plus 1 intended index removal)

## Accomplishments

- Tracer shell spine in `zsh/.zshrc`: fzf-history-search gets its own `zi light` (bare `zi ice` was silently loading nothing — plugin dir absent), autocomplete stays last with byte-identical atload, `sort -V` fzf ladder with warn-and-continue, unconditional Ctrl+R bind with yellow WARN, top `typeset -U path` guard, HOME-only `.zshrc.local` tail guard, portable bun source
- Convergent PATH hygiene: triple-source reload leaves zero duplicates (required inventing the tail re-assertion — scalar exports bypass `-U`)
- Editor half: `pcall(require, "local")` tail in `init.lua` (silent-absent, WARN-on-broken), `.gitignore` machine-local section, two documented `*.example` templates that stay committable while real files stay ignored
- Installer plus docs: `ensure_local_files` (DRY_RUN preview, create-only-when-absent, HOME-derived, called post-verify pre-chsh), README Machine-local subsection, `zsh/.zsh_history` untracked with working-tree file preserved, no appearance file touched (THEM-01 intended-drift closure)

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer: end-to-end polished shell spine in zshrc** - `15c1a9b` (feat)
2. **Task 2: Expansion: nvim local override plus gitignore plus documented templates** - `4466643` (feat)
3. **Task 3: Expansion: installer bootstrap plus README docs plus history untrack plus theme closure** - `250aceb` (feat)

**Plan metadata:** pending final docs commit (this SUMMARY plus STATE/ROADMAP updates)

## Files Created/Modified

- `zsh/.zshrc` - Plugin-block repair, fzf ladder, Ctrl+R bind plus WARN, PATH guards, HOME local tail guard, portable bun source
- `nvim/.config/nvim/init.lua` - Machine-local `pcall(require, "local")` tail block after colorscheme schedule
- `.gitignore` - Phase 3 machine-local section (`*.local`, deployed `local.lua`, shell history)
- `setup.sh` - `ensure_local_files` function plus live-path call after `post_verify`, before chsh offer
- `README.md` - Machine-local overrides subsection (destinations, copy commands, silent-absent, git-clean)
- `zsh/.zshrc.local.example` - Documented shell template (PATH prepend, prompt tweak, alias), docs-only
- `nvim/.config/nvim/lua/local.lua.example` - Documented editor template (option tweak, keymap), docs-only
- `zsh/.zsh_history` - Untracked from index only (working-tree file intact, 68894 bytes); full purge deferred to SECR-02

## Decisions Made

- Tail PATH re-assertion spelled as array self-assignment `path=( $path )` rather than a second `typeset -U path` line, preserving the plan's first-match awk verify while achieving identical retro-dedupe semantics (verified empirically)
- Debian legacy fzf rung (`/usr/share/doc/fzf/examples/key-bindings.zsh`) added alongside the plan's `/usr/share/fzf/` path — the latter does not exist for distro fzf 0.44.1, so without the extra rung Ctrl+R would warn despite fzf being installed
- History cached-removal (Task-3 action) physically committed inside the Task-2 commit `4466643` due to shared index staging; Task-3 commit `250aceb` holds `setup.sh` plus `README.md`
- Full `setup.sh --dry-run` does not call `ensure_local_files` (DRY_RUN early-return branch left untouched per explicit plan instruction); Would-run preview is proven via sourced `DRY_RUN=true` invocation plus existing dry-run markers

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added Debian legacy fzf key-bindings rung**
- **Found during:** Task 1 (tracer shell spine)
- **Issue:** Plan's legacy branch sources only `/usr/share/fzf/key-bindings.zsh`, which does not exist on this Debian host (distro fzf 0.44.1 ships scripts under `/usr/share/doc/fzf/examples/`); Ctrl+R ladder would fall to WARN even with fzf installed
- **Fix:** Added file-guarded `elif` rung for `/usr/share/doc/fzf/examples/key-bindings.zsh` with why-comment
- **Files modified:** zsh/.zshrc
- **Verification:** Ladder sources successfully in interactive shell; wiring-ok greps still pass
- **Committed in:** 15c1a9b (part of task commit)

**2. [Rule 1 - Bug] Scalar PATH exports bypass typeset -U — added convergent tail re-assertion**
- **Found during:** Task 1 (hermetic triple-source reload check failed with dupes despite guard)
- **Issue:** Research assumed tied `path`/`PATH` dedupes scalar assignments; verified on zsh 5.9 that `export PATH=...` does NOT dedupe at assignment time (only re-asserting the attribute retro-dedupes), so the top guard alone never converges
- **Fix:** Appended tail `path=( $path )` array self-assignment (dedupes under the still-set unique attribute) with why-comment, positioned as the last PATH-relevant line
- **Files modified:** zsh/.zshrc
- **Verification:** Hermetic triple-source check now prints reload-ok; guard-on-top awk still passes (no second literal match)
- **Committed in:** 15c1a9b (part of task commit)

**3. [Rule 1 - Bug] Why-comment tripped the guard-position awk**
- **Found during:** Task 1 (guard-on-top probe failed)
- **Issue:** My rationale comment contained the literal string `export PATH=`, which the plan's first-match awk counted as the first PATH export (preceding the guard)
- **Fix:** Reworded comment to "later PATH exports" with identical meaning
- **Files modified:** zsh/.zshrc
- **Verification:** guard-on-top prints
- **Committed in:** 15c1a9b (part of task commit)

**4. [Rule 3 - Blocking] Live bootstrap failed when parent dirs absent**
- **Found during:** Task 3 (live-path test with stub HOME)
- **Issue:** `touch $HOME/.zshrc.local` fails if `$HOME` itself does not exist; `touch` on the lua file fails without its parent dir (only the lua side had `mkdir -p`)
- **Fix:** Added `[[ -d "$HOME" ]] || mkdir -p "$HOME"` guard; hoisted lua parent dir into a declared local
- **Files modified:** setup.sh
- **Verification:** Live stub-HOME run creates both files, second run is a no-op, pre-existing content never truncated, DRY_RUN run creates nothing
- **Committed in:** 250aceb (part of task commit)

---

**Total deviations:** 4 auto-fixed (1 missing critical, 2 bugs, 1 blocking)
**Impact on plan:** All auto-fixes necessary for the plan's own done-criteria (reload-ok convergence, live bootstrap) or its verification probes. No scope creep — zero theme code, no new packages, seven-path change set preserved.

## Issues Encountered

- Task-2 `git check-ignore zsh/.zsh_history` gate cannot pass while the file is tracked (check-ignore exempts indexed files) — sequencing artifact, not a defect: resolved by the planned Task-3 cached untrack, gate re-run to PASS afterward
- Plan's `test "${PIPESTATUS[0]}" = '0'` probe is a bash-ism that fails under the zsh harness shell; nvim headless exit verified 0 via `$?` instead
- A no-op Edit call briefly merged `offer_chsh() {` with its next line; repaired immediately and verified via `bash -n` plus empty diff before proceeding
- Change-set gate shows two `.planning/` entries (pre-existing `STATE.md` modification from the orchestrator before execution began, plus planning-created `03-PATTERNS.md`); production change set is exactly the seven plan paths plus the intended history index removal
- Note for later: full `setup.sh --dry-run` output does not name the local files (DRY_RUN branch untouched per plan); consider invoking `ensure_local_files` from the dry-run preview path in a future pass so users see the Would-run lines in a real preview

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Shell spine ready for the plan's end-of-phase human check: open one interactive shell, confirm completions auto-show while typing, press Ctrl+R for history search, confirm the prompt renders
- Phase complete (single-plan phase) — ready for Phase 04 planning; `zsh/.zsh_history` full purge plus secret handling remain deferred to the SECR-02 hygiene phase, never attempted here

---
*Phase: 03-polished-shell-theme-local-overrides*
*Completed: 2026-09-17*

## Self-Check: PASSED

- All 7 plan paths plus SUMMARY.md exist on disk; all 3 task commits (`15c1a9b`, `4466643`, `250aceb`) present in git log
- Working-tree `zsh/.zsh_history` preserved after cached untrack; no per-app appearance file in the change set
