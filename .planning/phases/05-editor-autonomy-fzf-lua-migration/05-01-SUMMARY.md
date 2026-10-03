---
phase: 05-editor-autonomy-fzf-lua-migration
plan: 01
subsystem: editor
tags: [neovim, mason, which-key, lazy-nvim, bash-installer, headless]

# Dependency graph
requires:
  - phase: 04-autocomplete-gap-closure
    provides: [stable shell/stow baseline installer must not regress]
provides:
  - Headless-safe MasonInstallAll with sync-refresh branch (installer-triggerable, blocks to completion)
  - setup.sh post-stow headless Mason trigger with warn-and-continue retry
  - which-key v3 group-only spec (preset modern, delay 200, table-form triggers)
  - Widened uninstall wipe to whole ~/.local/share/nvim behind typed-yes gate
affects: [05-02-fzf-lua-migration, 06-health-gates]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 2262
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: [folke/which-key.nvim v3 (lazy spec, pin materialized on disk)]
  patterns: [headless sync-refresh branch via nvim_list_uis, DRY_RUN preview mirrors live marker, group-only which-key spec]

key-files:
  created: [nvim/.config/nvim/lua/plugins/which-key.lua]
  modified: [nvim/.config/nvim/lua/utils/mason-install-all.lua, setup.sh, README.md]

key-decisions:
  - "lazy-lock.json pin verified on disk, not committed — file is gitignored (.gitignore:22) and project convention takes precedence over the plan's commit assumption"
  - "DRY_RUN Mason preview surfaced in the dry-run preview section — the live-path DRY_RUN branch is unreachable from main (early return), so the marker must be echoed in the preview path per repo convention"
  - "Preview rm path quoted as \"~/.local/share/nvim\" — matches file preview conventions and the plan's trailing-quote grep assertion"

patterns-established:
  - "Headless branch pattern: `#vim.api.nvim_list_uis() == 0` selects sync `mr.refresh()` (no callback, run_blocking); interactive keeps async callback body byte-identical"
  - "Installer preview-mirrors-live: every live-path marker gets a `[DRY RUN] Would run:` echo in the dry-run preview section (existing convention at setup.sh preview path)"
  - "Group-only which-key spec: leader group entries only, leaf hints from existing keymap `desc` strings, table-form triggers `{ { \"<auto>\", mode = \"nxso\" } }`"

requirements-completed: [EDIT-01, EDIT-02]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Headless MasonInstallAll blocks to completion; setup.sh triggers it post-stow and warns with exact retry on failure"
    requirement: "EDIT-01"
    verification:
      - kind: other
        ref: "bash -n setup.sh exits 0"
        status: pass
      - kind: other
        ref: "bash setup.sh --dry-run --mode server --shell zsh --yes | grep 'DRY RUN.*MasonInstallAll'"
        status: pass
      - kind: integration
        ref: "headless Mason-list check vs require('lang').mason_packages → MASON-OK: 21 packages"
        status: pass
    human_judgment: false
  - id: D2
    description: "Space leader shows grouped which-key popup (preset modern, delay 200) with nested hints from desc strings"
    requirement: "EDIT-02"
    verification:
      - kind: other
        ref: "headless require('which-key') prints 'which-key ok'"
        status: pass
      - kind: other
        ref: "checkhealth which-key reports zero errors"
        status: pass
    human_judgment: true
    rationale: "Automated checks prove spec registration and clean health; actual popup rendering on <Space> needs human eyes in a real nvim session"
  - id: D3
    description: "Uninstall wipe covers whole ~/.local/share/nvim behind typed-yes gate with updated dry-run preview; README updated atomically"
    requirement: "EDIT-01"
    verification:
      - kind: other
        ref: "sourced run_uninstall dry-run previews quoted whole-data-dir path, zero writes"
        status: pass
      - kind: other
        ref: "bash -n setup.sh exits 0; no mason-only suffix remains uncommented; stow/mkdir lines untouched"
        status: pass
    human_judgment: true
    rationale: "Live rm -rf deliberately never executed here (destructive); proven via dry-run preview only — human confirms on a real uninstall or accepts preview evidence"

# Metrics
duration: 9min
completed: 2026-10-03
status: complete
---

# Phase 05 Plan 01: Headless Mason + which-key + Widened Wipe Summary

**Headless-blocking MasonInstallAll with setup.sh post-stow trigger, which-key v3 leader popup, and whole-data-dir uninstall wipe — tracer proven end-to-end (MASON-OK: 21 packages)**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-03T15:24:27Z
- **Completed:** 2026-10-03T15:33:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Tracer: `mason-install-all.lua` gains a headless sync-refresh branch (`#nvim_list_uis() == 0` → `mr.refresh()` with no callback, then the identical collect-missing loop and blocking `MasonInstall`); interactive `mr.refresh(callback)` body byte-identical; `setup.sh` triggers `nvim --headless -c "MasonInstallAll" -c "qall"` post-stow gated on nvim-selected + `command -v nvim`, with DRY RUN preview and warn-and-continue retry (D-01/D-02/D-03)
- which-key v3 popup: new lazy spec (`preset = "modern"`, `delay = 200`, table-form `triggers = { { "<auto>", mode = "nxso" } }`, 8 group-only entries), zero `register()` calls, headless require OK, `checkhealth which-key` zero errors (D-05/D-06)
- Widened wipe: `~/.local/share/nvim/mason` → whole `~/.local/share/nvim` in preview + live blocks, typed-yes gate unchanged, redundant `rmdir` tail removed, README uninstall bullet + new Mason auto-install section in the same commit (D-04 + atomic-docs rule)
- Plan gates all green: `bash -n` clean, dry-run previews both markers with zero writes, `MASON-OK: 21 packages` headless, no `mason-tool-installer` in code, no TAP harness added (D-12)

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer: headless-safe MasonInstallAll plus setup.sh post-stow trigger** - `176826c` (feat)
2. **Task 2: which-key v3 popup with group-only spec** - `ed6a465` (feat)
3. **Task 3: Widened uninstall wipe plus atomic docs** - `79f6978` (feat)

**Plan metadata:** pending SUMMARY commit (this file)

## Files Created/Modified

- `nvim/.config/nvim/lua/plugins/which-key.lua` - New lazy spec: which-key v3 popup, group-only spec fed by keymap desc strings
- `nvim/.config/nvim/lua/utils/mason-install-all.lua` - Headless sync-refresh branch; interactive semantics unchanged; user-command name/desc unchanged; no startup autocmd, no new plugin dep
- `setup.sh` - Post-stow headless Mason trigger (live path + dry-run preview marker); widened wipe literal + updated preview text
- `README.md` - Uninstall bullet states whole-data-dir path with typed-yes + preview; new Mason auto-install section with trigger command and retry wording

## Decisions Made

- lazy-lock.json pin verified on disk, not committed — `.gitignore:22` explicitly excludes it (Phase-3 machine-local policy); project convention takes precedence over the plan's "commit it" assumption. `Lazy! sync` materialized the `which-key.nvim` pin (`main @ 3aab214`) in the working-tree lockfile.
- DRY_RUN Mason preview echoed in the dry-run preview section — main returns early under `--dry-run` before the live path, so the live-path `DRY_RUN` branch alone could never print; the repo's own "preview path must surface the same marker" convention required the extra echo.
- Preview rm path quoted (`rm -rf "~/.local/share/nvim"`) — matches the file's quoted-path preview style and satisfies the plan's trailing-quote grep assertion, which the unquoted form could never match.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Dry-run preview marker unreachable from live-path block alone**
- **Found during:** Task 1 (tracer trigger insertion)
- **Issue:** Main returns early under `DRY_RUN=true` (~line 2026) before reaching the post-stow slot, so the plan-literal `DRY_RUN` branch inside the live trigger block is dead code via `main` — the acceptance CLI assertion (`--dry-run` prints a `DRY RUN` line naming `MasonInstallAll`) could never pass with only the live-path insertion
- **Fix:** Added the same preview echo to the dry-run preview section next to `ensure_local_files`, following the file's existing "preview path must surface the same marker" convention; live-path `DRY_RUN` branch kept verbatim for plan fidelity
- **Files modified:** setup.sh
- **Verification:** `bash setup.sh --dry-run --mode server --shell zsh --yes | grep 'DRY RUN.*MasonInstallAll'` passes; `git status` shows zero dry-run writes
- **Committed in:** 176826c (part of task commit)

**2. [Rule 3 - Blocking] lazy-lock.json commit impossible without violating .gitignore**
- **Found during:** Task 2 (which-key pin commit)
- **Issue:** Plan says "commit [lazy-lock.json] in the same commit", but the file is gitignored (`.gitignore:22`) and untracked — committing requires `git add -f`, contradicting project convention (AGENTS.md directives take precedence over plan instructions)
- **Fix:** Ran headless `Lazy! sync` (installed which-key, materialized pin on disk), verified pin present, committed only the spec file; no force-add
- **Files modified:** nvim/.config/nvim/lua/plugins/which-key.lua (lockfile verified on disk, uncommitted by design)
- **Verification:** `python3` lockfile read shows `which-key.nvim: main @ 3aab214`, 41 pins; `git status` clean of lockfile
- **Committed in:** ed6a465 (part of task commit)

**3. [Rule 1 - Bug] Plan's uninstall-preview grep pattern unsatisfiable with unquoted echo**
- **Found during:** Task 3 (wipe preview verification)
- **Issue:** Plan asserts `... run_uninstall ... | grep -Eq 'DRY RUN.*local/share/nvim"'` (trailing literal `"`), but the preview echo printed a bare path with no quote — the assertion failed on first run even though behavior was correct (pre-existing pattern style, not a behavior bug)
- **Fix:** Quoted the preview path (`rm -rf "~/.local/share/nvim"`), consistent with the file's quoted-path preview style (`stow --dir="$SCRIPT_DIR" ...`)
- **Files modified:** setup.sh (preview echoes only; live `rm -rf "$HOME/..."` already quoted)
- **Verification:** Sourced `run_uninstall` dry-run re-run passes the exact plan grep; `bash -n` clean
- **Committed in:** 79f6978 (part of task commit)

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 bug-pattern conformance)
**Impact on plan:** All three required for the plan's own acceptance assertions to hold. No scope creep: no behavior beyond the plan's must-haves, no new dependencies, no touched stow/checklist/arg-parsing code.

## Issues Encountered

- Headless `Lazy! sync` executed the `mason.nvim` `build = ":MasonInstallAll"` hook through the NEW sync branch and blocked ~268s installing missing packages before exiting 0 — this was an unplanned but welcome live proof of the tracer path (Pitfall 1 fixed: the run blocked to completion instead of silently no-op'ing). No action needed; `MASON-OK: 21 packages` confirmed afterwards.
- Tracer gate: plan is `autonomous: true` with fully automated tracer `<verify>` steps and the orchestrator ordered full-plan execution; a mid-plan halt would create an illegal partial-plan state (production commits without SUMMARY). Tracer `<verify>` was re-run green post-commit and execution continued with all automated evidence logged here.
- `mason-tool-installer` appears only in `.planning/` decision prose (explicitly rejected by D-01); zero occurrences in code (`nvim/`, `setup.sh`, `README.md`). No action.
- `shellcheck` not installed on this host — `bash -n` clean substituted. No action.

## Known Stubs

None — scanned created/modified files for empty values, placeholder text, and TODO/FIXME: the single `todo` hit is the which-key group label `"search/todo"` (intentional UI string, feeds the `<leader>s` popup group).

## Threat Flags

None — no new security surface beyond the plan's threat model: no new network endpoints, auth paths, or file-access patterns. The widened `rm -rf` is the plan-specified T-05-01 surface, mitigated per register (fixed `$HOME`-anchored literal, typed-yes gate unchanged, preview updated; no live wipe executed — A6 dir listing recorded: `lazy/ mason/ site/ telescope_history/`, regenerable state only). The which-key spec carries no `build` key (T-05-SC clean). No secrets echoed (T-05-04 clean).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 05-02 (fzf-lua migration + make/gcc demotion): headless Mason path proven, which-key groups assume byte-identical leader keys per D-09 (05-02 must preserve them so group names keep matching).
- Note for 05-02: `lazy-lock.json` is gitignored — 05-02's expected pin churn (add `fzf-lua`, drop `telescope*`, keep `plenary`) will likewise materialize on disk only; do not plan a lockfile commit without revisiting `.gitignore`.
- `~/.local/share/nvim/telescope_history` exists in the data dir — 05-02's picker swap may leave it orphaned; consider cleanup note when fzf-lua lands.

---
*Phase: 05-editor-autonomy-fzf-lua-migration*
*Completed: 2026-10-03*

## Self-Check: PASSED
