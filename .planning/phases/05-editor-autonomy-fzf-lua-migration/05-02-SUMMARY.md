---
phase: 05-editor-autonomy-fzf-lua-migration
plan: 02
subsystem: editor
tags: [neovim, fzf-lua, lazy-nvim, treesitter, blink-cmp, bash-installer, compiler-free]

# Dependency graph
requires:
  - phase: 05-01-headless-mason-which-key
    provides: [headless MasonInstallAll sync branch, which-key group spec assuming byte-identical leader keys]
provides:
  - fzf-lua picker spec with FzfLua cmd trigger + ui_select dressing (no build step)
  - Keymaps rewritten to fzf-lua builtins, keys and descs byte-identical, dead terms binding deleted
  - Legacy telescope spec deleted, zero legacy-name references, lockfile churned on disk
  - Compiler-free blink/treesitter configs + setup.sh make/gcc optional warn-if-missing policy
affects: [06-health-gates, installer-toolchain-docs]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 4802
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: [ibhagwan/fzf-lua (lazy spec, pin materialized on disk main@d5c12c6)]
  patterns: [cmd-lazy picker spec with ui-select dressing, guarded function-form build, optional-toolchain warn helper]

key-files:
  created: [nvim/.config/nvim/lua/plugins/fzf-lua.lua]
  modified: [nvim/.config/nvim/lua/base/keymaps.lua, nvim/.config/nvim/lua/plugins/nvim-tree.lua, nvim/.config/nvim/lua/plugins/alpha.lua, nvim/.config/nvim/lua/lang/markdown/plugins.lua, nvim/.config/nvim/lua/icons/lspkind.lua, nvim/.config/nvim/lua/plugins/blink-cmp.lua, nvim/.config/nvim/lua/plugins/treesitter.lua, setup.sh, README.md]

key-decisions:
  - "cmd-only fzf-lua spec kept (no VeryLazy fallback) — executor proved :FzfLua invocation loads the plugin (error surfaced from inside fzf-lua), require smoke passes, plugin not eager-loaded (A1 resolved as HIT)"
  - "lazy-lock.json churn verified on disk only, not committed — file is gitignored (.gitignore:22); project convention takes precedence over the plan's commit assumption (same as 05-01)"
  - "Stale lockfile pins pruned by hand + orphan plugin dirs via :Lazy clean — Lazy sync installs but does not auto-clean removed specs"
  - "Ticked make/gcc checklist rows stay offered but install nothing — absence warns; README documents the advisory semantic"

patterns-established:
  - "Picker spec shape: cmd trigger + explicit devicons dep + ui_select dressing, zero build keys, zero executable guards (D-11)"
  - "Guarded function-form build: return make command only when executable(make)==1, else nil — silently skips on compiler-free hosts"
  - "Optional-toolchain installer pattern: OPTIONAL_TOOLCHAIN array + _is_optional_dep case + warn_optional_toolchain probe returning 0 always, called on live and dry-run paths"

requirements-completed: [EDIT-03]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "fzf-lua picker end-to-end: spec loads unconditionally, all 15 picker bindings rewritten with identical keys/descs, dead terms binding deleted"
    requirement: "EDIT-03"
    verification:
      - kind: other
        ref: "headless require('fzf-lua') prints 'fzf-lua ok'"
        status: pass
      - kind: other
        ref: "command -v fzf + picker-smoke prints 'picker-smoke ok'"
        status: pass
      - kind: other
        ref: "source grep: leader-ff/fg/fb/fo present with identical desc, leader-pt absent"
        status: pass
    human_judgment: false
  - id: D2
    description: "Legacy picker fully removed: spec deleted, spurious deps pruned, zero legacy-name hits, lockfile churned with plenary kept"
    requirement: "EDIT-03"
    verification:
      - kind: other
        ref: "test ! -f telescope.lua + zero-hits grep over lua/ returns clean"
        status: pass
      - kind: other
        ref: "on-disk lockfile: 39 pins, plenary kept, zero legacy pins, fzf-lua + which-key present"
        status: pass
    human_judgment: false
  - id: D3
    description: "Compiler-free configs + installer demotion: guarded builds, TSUpdate-alone spec, make/gcc warn-if-missing never aborting"
    requirement: "EDIT-03"
    verification:
      - kind: other
        ref: "bash -n setup.sh exits 0 + demotion source assertions pass"
        status: pass
      - kind: other
        ref: "headless checkhealth reports zero error lines"
        status: pass
      - kind: integration
        ref: "headless Mason-list check vs require('lang').mason_packages → MASON-OK: 21 packages"
        status: pass
      - kind: other
        ref: "fresh-install-equivalent treesitter reinstall + Lazy build → 'All parsers are up-to-date', zero E492"
        status: pass
      - kind: other
        ref: "sterile-PATH warn_optional_toolchain prints cc/gcc/clang warnings, exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Interactive picker UX across all rebound keys feels right in a real session"
    verification: []
    human_judgment: true
    rationale: "Headless smoke proves loading and wiring, never rendering — a human must open pickers (files, grep, buffers, colorschemes) once in a live nvim session"

# Metrics
duration: 10min
completed: 2026-10-03
status: complete
---

# Phase 05 Plan 02: fzf-lua Migration + Compiler Demotion Summary

**Full picker migration to fzf-lua with zero legacy references, compiler-free blink/treesitter configs, and setup.sh make/gcc demoted to warn-only — every gate green including a fresh-install treesitter build proof**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-03T15:36:41Z
- **Completed:** 2026-10-03T15:46:12Z
- **Tasks:** 3
- **Files modified:** 11 (1 created, 1 deleted, 9 edited)

## Accomplishments

- fzf-lua spec + keymap/dashboard migration: new lazy spec (`cmd = "FzfLua"`, devicons dep, `ui_select = {}` dressing, no build key, no make guard); all 15 picker bindings rewritten per the RESEARCH 18-item map with keys and descs byte-identical; dead `<leader>pt` deleted; toggleterm `<C-\>` untouched; nvim-tree cwd-scoped `files`/`live_grep`; alpha `ColorschemeWithPreview` + ff/r/k buttons repointed (D-07/D-09/D-11)
- Legacy removal + dep prune: `git rm telescope.lua`; markdown live-preview dep block deleted (event kept, no invented picker flag); lspkind `Telescope` icon key dropped with Ripgrep/Grep neighbors byte-identical; plenary kept (todo-comments dep); lockfile churned on disk (39 pins: fzf-lua + which-key in, 3 legacy pins out, plenary kept); orphan plugin dirs removed via `:Lazy clean` (D-07/D-08)
- Compiler-free configs + demotion: blink LuaSnip `run=` replaced with guarded function-form `build`; treesitter rewritten to main-branch shape (`build = ":TSUpdate"`, dead `auto_install`/`ensure_installed`/`ignore_install` gone, parser list kept as documented on-demand set); setup.sh drops make/gcc from all three `common` lists, adds `OPTIONAL_TOOLCHAIN` + warn helpers naming `cc/gcc/clang` + degraded features, probe runs on live and dry-run paths with exit 0 always; README toolchain + editor sections updated atomically (D-10)
- Plan gates all green: zero legacy-name hits (lua/ + lockfile), headless fzf-lua smoke + fzf probe, checkhealth zero errors (telescope section gone, no fzf-lua section per Pitfall 5), MASON-OK 21 packages, `bash -n` clean, dry-run shows optional probe with zero writes and `--no-folding` intact, all six assumptions executor-verified

## Task Commits

Each task was committed atomically:

1. **Task 1: fzf-lua spec plus keymap and dashboard migration** - `cad785a` (feat)
2. **Task 2: Legacy spec deletion plus spurious dep prune plus lockfile churn** - `84e6326` (feat)
3. **Task 3: No-compromise compiler-free configs plus make-gcc demotion** - `73c28e0` (feat)

**Plan metadata:** pending SUMMARY commit (this file)

_Note: Task 2 commit also carries the one-line fzf-lua comment reword required by its zero-hits gate._

## Files Created/Modified

- `nvim/.config/nvim/lua/plugins/fzf-lua.lua` - New lazy spec: fzf-lua with devicons dep, FzfLua cmd trigger, ui_select dressing
- `nvim/.config/nvim/lua/base/keymaps.lua` - Picker RHS rewritten to fzf-lua builtins/TodoFzfLua/Noice pick; keys+descs identical; pt deleted
- `nvim/.config/nvim/lua/plugins/nvim-tree.lua` - Dropped telescope attach block + pcall guard; cwd-scoped fzf-lua files/live_grep on `<c-f>`/`<c-fg>`
- `nvim/.config/nvim/lua/plugins/alpha.lua` - Colorscheme command + ff/r/k dashboard buttons on fzf-lua
- `nvim/.config/nvim/lua/plugins/telescope.lua` - DELETED via git rm
- `nvim/.config/nvim/lua/lang/markdown/plugins.lua` - Spurious telescope dep block removed from live-preview entry
- `nvim/.config/nvim/lua/icons/lspkind.lua` - Unreachable Telescope icon key dropped
- `nvim/.config/nvim/lua/plugins/blink-cmp.lua` - Dead packer `run=` replaced with guarded function-form `build`
- `nvim/.config/nvim/lua/plugins/treesitter.lua` - Main-branch spec: TSUpdate-alone build, dead opts deleted, on-demand comment
- `setup.sh` - make/gcc demoted to OPTIONAL_TOOLCHAIN warn-if-missing across arch/debian/termux
- `README.md` - Toolchain optional status + new optional-toolchain editor section (TSInstall flow, jsregexp note)
- `nvim/.config/nvim/lazy-lock.json` - Churned ON DISK ONLY (gitignored): +fzf-lua pin, -3 legacy pins, plenary kept

## Decisions Made

- cmd-only fzf-lua spec kept, no VeryLazy fallback (A1 resolved as HIT): headless probe showed the plugin NOT loaded at startup (`_.loaded == nil`), the `FzfLua` cmd trigger registered, and invoking `:FzfLua --help` loaded the plugin (error text came from inside fzf-lua: `[Fzf-lua] invalid command`). The plan's fallback condition ("if executor proves command loading misses") never triggered — adding VeryLazy unprompted would have deviated from the plan's conditional.
- lazy-lock.json verified on disk, not committed: `.gitignore:22` excludes it and AGENTS.md directives take precedence over plan instructions (same ruling as 05-01). Stale pins pruned by hand (Lazy sync installs but never auto-cleans removed specs) and orphan dirs removed with `:Lazy clean` (plugin-manager-native, no raw rm).
- Ticked make/gcc checklist rows stay offered but install nothing: the plan asks for offered-rows + warn-on-absence + never-abort, with no selection-to-install wiring; README now documents the advisory semantic so the "tick installs" line is not a lie for those two rows.
- Bare deletion for the markdown live-preview dep (no `picker = "fzflua"` pin): RESEARCH verifies the default backend is already telescope-free, and PATTERNS.md names bare deletion the minimal correct edit — no invented config keys.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Own fzf-lua comment broke the zero-hits gate**
- **Found during:** Task 2 (legacy-name search)
- **Issue:** The Task-1 spec comment named `telescope-ui-select.nvim`, so the case-insensitive `grep -rqi 'telescope' lua/` gate failed on the new file itself
- **Fix:** Reworded to "replaces the legacy select-dressing plugin" (no legacy name in any case)
- **Files modified:** nvim/.config/nvim/lua/plugins/fzf-lua.lua
- **Verification:** Zero-hits grep passes
- **Committed in:** 84e6326 (part of Task 2 commit)

**2. [Rule 3 - Blocking] Lazy sync neither cleans stale pins nor orphan plugin dirs**
- **Found during:** Task 2 (lockfile verification)
- **Issue:** After spec deletion + `Lazy! sync`, the 3 legacy pins lingered in lazy-lock.json and the 3 plugin checkouts lingered in `~/.local/share/nvim/lazy/` — the plan's "lockfile drops the three legacy pins" assertion could never pass on sync alone
- **Fix:** Pruned the 3 pin lines in the gitignored lockfile by script (format-preserving line removal) and ran headless `Lazy! clean`, which removed exactly the 3 orphan dirs via the plugin manager
- **Files modified:** nvim/.config/nvim/lazy-lock.json (on disk only, uncommitted by design)
- **Verification:** Lockfile shows 39 pins with zero legacy hits; `ls` shows no telescope dirs
- **Committed in:** n/a (gitignored file — same ruling as 05-01 deviation #2)

**3. [Rule 3 - Blocking] Lockfile commit impossible without violating .gitignore**
- **Found during:** Task 2 (pin commit)
- **Issue:** Plan says "commit the lockfile diff in the same commit", but the file is gitignored and untracked — committing requires `git add -f`, contradicting project convention
- **Fix:** Verified churn on disk (plenary kept, legacy out, fzf-lua + which-key in), committed only tracked spec/config files
- **Files modified:** (lockfile verified, uncommitted by design)
- **Verification:** python lockfile read asserts all three pin conditions
- **Committed in:** 84e6326 (spec/config side only)

---

**Total deviations:** 3 auto-fixed (1 bug-pattern conformance, 2 blocking)
**Impact on plan:** All three required for the plan's own acceptance assertions to hold. No scope creep: no behavior beyond must-haves, no new dependencies, no touched stow/checklist/arg-parsing code.

## Issues Encountered

- Bare `nvim --headless -c "TSUpdate"` reports `E492: Not an editor command` — expected, not a bug: the event-lazy treesitter plugin is not loaded in a buffer-less headless session. The assumption that matters (A3) is the install-time build path, which was proven separately by deleting the plugin dir and re-running sync + `Lazy! build` → "All parsers are up-to-date", zero E492.
- `nvim --headless -c "checkhealth"` no longer lists a telescope section and lists no fzf-lua section either (Pitfall 5: fzf-lua ships no health.lua) — picker health is covered by the require smoke + fzf binary probe instead. Zero error lines both before and after the change.
- `shellcheck` not installed on this host — `bash -n` clean substituted (same as 05-01).

## Known Stubs

None — scanned all created/modified files: the only TODO/FIXME hits are functional todo-comments keyword strings (`TodoFzfLua keywords=TODO,FIX,FIXME`, Trouble filter tags), which are picker arguments, not placeholders.

## Threat Flags

None — no new security surface beyond the plan's threat model: T-05-05 mitigated (high-reputation upstream, pin materialized `main@d5c12c6` on disk, no `build` key in new spec — verified by grep); T-05-06 mitigated (build fixed to `:TSUpdate` alone, proven clean on a fresh-install-equivalent reinstall with zero E492); T-05-07 mitigated (warn-only probe proven exit-0 on sterile PATH, `reverify_deps` can no longer see optionals so no family aborts); T-05-08 accepted (picker shows only already-visible content); T-05-SC clean (zero registry packages installed, no `postinstall` risk).

## Assumption Evidence (A1-A6)

- **A1 command-loading:** HIT — cmd trigger registered, `:FzfLua` invocation loads plugin, require smoke passes, no eager load. No VeryLazy fallback.
- **A2 fzf floor:** `fzf 0.44.1 (debian)` + picker smoke passes — floor holds for files/grep/buffers flows.
- **A3 TSUpdate-noargs:** SAFE at install time — fresh reinstall + `Lazy! build` prints "All parsers are up-to-date" with no errors (bare-headless E492 is the not-loaded case, not the build case).
- **A4 blink offline:** prebuilt fuzzy `force_version = "v1.8.0"` untouched; no blink health section exists to regress; jsregexp now skips cleanly without a compiler (guarded build).
- **A5 ui-select:** `ui_select = {}` in spec + headless require OK; covers all `vim.ui.select` callers generically.
- **A6 wipe-dir:** `~/.local/share/nvim/` holds `lazy/ mason/ site/ telescope_history/` (regenerable state only). `telescope_history/` is now orphaned by the picker swap — deliberately left on disk (uninstall wipe removes the whole dir anyway); note for Phase 6 self-test scope, not actioned here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Phase 06 (Verified Health & Self-Test Gates, HLTH-01): picker surface is fzf-lua end-to-end, checkhealth is zero-error, Mason list matches the aggregator — Phase 6 can absorb these headless probes into its TAP gates (D-12 separation intact; no TAP harness added here).
- Heads-up for Phase 6: `lazy-lock.json` is gitignored, so any gate asserting pin state must read the on-disk file (as this plan did), not git history. `~/.local/share/nvim/telescope_history` is orphaned picker history — Phase 6 may note or clean it.
- Interactive note: headless proves loading and wiring only (coverage D4) — one live-session pass over the rebound picker keys is the remaining human judgment before calling the migration fully bedded-in.

---
*Phase: 05-editor-autonomy-fzf-lua-migration*
*Completed: 2026-10-03*

## Self-Check: PASSED
