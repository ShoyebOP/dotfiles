---
phase: 05-editor-autonomy-fzf-lua-migration
verified: 2026-10-03T16:15:00Z
status: human_needed
score: 12/13 must-haves verified
behavior_unverified: 1
overrides_applied: 0
behavior_unverified_items:
  - truth: "Uninstall with nvim deselected removes whole data dir behind existing typed-yes gate with updated dry-run preview, and reinstall restores everything"
    test: "On a disposable clone/VM (NEVER the daily driver): run `bash setup.sh --uninstall`, deselect nvim, type `yes`, confirm `~/.local/share/nvim` is gone; then reinstall and confirm LSPs restore via the headless trigger"
    expected: "Whole `~/.local/share/nvim` removed behind the typed-yes gate; reinstall restores plugins + Mason packages"
    why_human: "Live `rm -rf` deliberately never executed during verification (destructive); dry-run preview proves the gate + literal, not the actual deletion"
human_verification:
  - test: "Open nvim, press `<Space>` and then `f` / `s` / `g`"
    expected: "LazyVim-like which-key popup appears (preset modern, ~200ms delay) with group labels (find, search/todo, git, …) and nested leaf hints from keymap desc strings"
    why_human: "Headless proves spec registration + zero-error health, never visual popup rendering"
  - test: "In a live nvim session, invoke each rebound picker once: `<leader>ff fa fg fb fh fo ma cm gt f th st sT N`, `<C-f>`/`<C-fg>` in nvim-tree, dashboard `ff r k th`, `:ColorschemeWithPreview`"
    expected: "Every key opens the fzf-lua picker with correct scope; NOTE expected deviations under test: `<leader>sT` currently shows ALL todos (filter silently dropped, WR-01); first-ever `<leader>fa`/`<leader>f`/`<leader>th` before any `:FzfLua` command may fail module-not-found (WR-04); `<C-f>` outside the tree errors instead of falling back to cwd (WR-03)"
    why_human: "Headless smoke proves loading and wiring, never rendering, filtering semantics, or lazy-load ordering in a real session"
  - test: "On a disposable clone/VM (NEVER the daily driver): run `bash setup.sh --uninstall`, deselect nvim, type `yes`, confirm `~/.local/share/nvim` is gone; then reinstall and confirm LSPs restore via the headless trigger"
    expected: "Whole `~/.local/share/nvim` removed behind the typed-yes gate; reinstall restores plugins + Mason packages"
    why_human: "Live `rm -rf` deliberately never executed during verification (destructive); dry-run preview proves the gate + literal, not the actual deletion"
---

# Phase 05: Editor Autonomy & fzf-lua Migration Verification Report

**Phase Goal:** Neovim works out-of-box with auto-installed LSPs, discoverable keys, and an fzf-lua picker with no compiled telescope dependency
**Verified:** 2026-10-03T16:15:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Merged must_haves from 05-01-PLAN.md (6 truths) + 05-02-PLAN.md (7 truths).
Roadmap SCs cross-checked: all three SCs are covered by these truths with two
documented wording drifts (see Notes under the table).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Fresh-clone user gets LSPs/formatters without manual MasonInstallAll because setup.sh triggers headless MasonInstallAll post-stow and it blocks to completion | ✓ VERIFIED | `mason-install-all.lua:15-16` headless branch (`nvim_list_uis()==0` → sync `mr.refresh()`); `setup.sh:2091-2097` post-stow trigger gated on nvim-selected + `command -v nvim`; headless require smoke `MASON-SMOKE-OK` passes; live blocking proven during execution (build hook blocked ~268s installing, per 05-01-SUMMARY) + `MASON-OK: 21 packages` re-confirmed this session |
| 2 | Headless Mason failure never fails the install; user sees warning plus exact retry command and setup continues | ✓ VERIFIED | `setup.sh:2094-2096` negated `elif ! nvim …` guard prints `Warning: headless Mason install failed — retry with: nvim --headless -c "MasonInstallAll" (or :MasonInstallAll inside nvim)` to stderr, exit stays 0; `set -Eeuo pipefail` cannot abort through the negation |
| 3 | Manual repair path unchanged: interactive MasonInstallAll refreshes registry then installs missing with notify, mason.lua build hook preserved | ✓ VERIFIED | Interactive `mr.refresh(callback)` body byte-identical (`mason-install-all.lua:43-67`); `mason.lua:3` keeps `build = ":MasonInstallAll"`; user-command name + desc unchanged (`:70-74`); aggregator single source kept (`require("lang")`, never duplicated) |
| 4 | Uninstall with nvim deselected removes whole data dir behind existing typed-yes gate with updated dry-run preview, and reinstall restores everything | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Present + wired: preview + live blocks both reference whole `~/.local/share/nvim` (`setup.sh:917-922,977-980`); zero `mason`-only suffix hits; typed-yes gate precedes live `rm -rf`; sourced `run_uninstall` dry-run prints `[DRY RUN] Would run: rm -rf "~/.local/share/nvim"` with zero writes. Live deletion deliberately never executed (destructive) — see Human Verification |
| 5 | User presses Space leader and sees LazyVim-like which-key popup with preset modern delay 200 and nested group hints from desc strings | ✓ VERIFIED | `which-key.lua` sets `preset="modern"`, `delay=200`, table-form `triggers={{"<auto>",mode="nxso"}}` (byte-matches upstream default, Pitfall 2 avoided), 8 group-only entries, zero `register()` calls; headless `require('which-key')` prints `which-key ok`; `checkhealth` zero error lines. Visual rendering needs live eyes — see Human Verification |
| 6 | Headless checkhealth is zero-errors and Mason package list matches lang aggregator; no TAP harness added | ✓ VERIFIED | `nvim --headless -c "checkhealth"` → 0 error lines; `MASON-OK: 21 packages`; no `scripts/` dir, no TAP files, `mason-tool-installer` zero hits in code (rejected by D-01, by design) |
| 7 | User picker is fzf-lua for files/grep/buffers/help/git/colorschemes/keymaps/Todo/Noice with zero legacy picker references remaining | ✓ VERIFIED | `fzf-lua.lua` spec (`cmd=FzfLua`, devicons dep, `ui_select={}`, no build/cond); all 15 picker bindings rewritten per RESEARCH 18-item map; `telescope.lua` deleted (`git rm`, absent from tree); case-insensitive `telescope` grep over `lua/` + `setup.sh` + `README.md` → zero hits; lockfile on disk 39 pins, zero legacy pins; `fzf` binary present (`/usr/bin/fzf`); headless `require('fzf-lua')` prints `fzf-lua ok` |
| 8 | Plenary stays for todo-comments and devicons survives via explicit dep; cosmetic icon key dropped so file-wide search is clean | ✓ VERIFIED | Lockfile keeps `plenary` pin (todo-comments dep intact); fzf-lua spec declares `nvim-web-devicons`; `lspkind.lua` Telescope key gone, Ripgrep/Grep neighbors byte-identical — the zero-hits gate in Truth 7 depends on this and passes |
| 9 | Every non-picker keymap byte-identical with desc strings preserved; picker keys reuse current leader keys with fzf-lua builtins and dead terms binding deleted | ✓ VERIFIED | `ff fa fg fb fh fo ma cm gt f th st sT N` all present with identical keys + descs, RHS swapped to fzf builtins (`helptags` canonical, `blines`, `TodoFzfLua`, `Noice pick`); `<leader>pt` absent; toggleterm `open_mapping=<C-\>` untouched; KNOWN CAVEAT (not a literal-truth failure): `<leader>sT` `keywords=` filter is silently discarded upstream (WR-01) — flagged for the live picker pass |
| 10 | Picker needs no make/gcc build step and loads unconditionally with no silent fallback guard | ✓ VERIFIED | fzf-lua spec has no `build` key and no `executable("make")` cond/guard (grep clean); `cmd=FzfLua` proven to lazy-load (`:FzfLua` invocation loads plugin per 05-02-SUMMARY A1). Narrow-window caveat: lua-function RHS bindings bypass `cmd`-loading (WR-04) — folded into the live picker pass |
| 11 | make plus gcc demoted from common to optional warn-if-missing across arch/debian/termux with no-compromise treesitter/blink config so demotion costs nothing | ✓ VERIFIED | All three `common=(…)` lists (`setup.sh:198,202,206`) contain no make/gcc; `OPTIONAL_TOOLCHAIN=(make gcc)` + warn helpers naming `cc/gcc/clang` (`setup.sh:28,273-296`); `bash -n` clean; warn probe exit 0; treesitter `build=":TSUpdate"` alone, dead `auto_install`/`ensure_installed`/`ignore_install`/`TSInstallAll` gone; blink dead packer `run=` replaced (function-form `build`; note WR-02: return value discarded by lazy so jsregexp never compiles — identical to the old dead-key behavior, no regression, but the code reads as if the compiler path works) |
| 12 | Picker health proven by headless fzf-lua smoke plus fzf binary probe because no health section exists, and checkhealth overall is zero errors | ✓ VERIFIED | `fzf-lua ok` smoke + `/usr/bin/fzf` probe both pass (Pitfall 5 substitution for the nonexistent `:checkhealth fzf-lua`); overall checkhealth 0 error lines (telescope section gone as expected) |
| 13 | Lightweight headless gates only with Mason list matching lang aggregator; no TAP harness added | ✓ VERIFIED | `MASON-OK: 21 packages` this session; no TAP/`scripts/` artifacts; Phase 6 HLTH-01 separation intact |

**Score:** 12/13 truths verified (1 present, behavior-unverified)

**Roadmap wording drifts (documented, not hidden):**
- SC1's `mason-tool-installer ensure_installed backstop` clause was explicitly
  REJECTED by locked user decision D-01 (05-CONTEXT.md) — installer-trigger-only
  won. Zero `mason-tool-installer` occurrences in code is by design, and the
  user-stated phase goal for this verification omits the backstop.
- SC3's "`checkhealth` reports picker healthy" is literally unsatisfiable:
  fzf-lua ships no `health.lua` (RESEARCH Pitfall 5). The D-11/D-12 substitution
  (headless require smoke + fzf binary probe, overall checkhealth zero-error) is
  implemented and green.

### Deferred Items

None. Step 9b filter: no later milestone phase covers Phase-5 picker/keymap
semantics (Phase 6 is HLTH-01 TAP harness). The orphaned
`~/.local/share/nvim/telescope_history` runtime artifact is noted for Phase 6
self-test scope as an optional cleanup, not a deferred must-have.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `nvim/.config/nvim/lua/utils/mason-install-all.lua` | Headless sync-refresh branch | ✓ VERIFIED | Substantive (76 lines, both branches), wired (user-command + setup.sh trigger + smoke OK) |
| `nvim/.config/nvim/lua/plugins/which-key.lua` | v3 group-only spec | ✓ VERIFIED | Substantive, wired (VeryLazy event, require OK, checkhealth clean) |
| `nvim/.config/nvim/lua/plugins/fzf-lua.lua` | Spec + ui_select dressing | ✓ VERIFIED | Substantive, wired (cmd trigger proven, require OK) |
| `nvim/.config/nvim/lua/base/keymaps.lua` | Picker RHS rewritten | ✓ VERIFIED | 78 `map(` calls; picker block verified; non-picker keys intact by inspection |
| `nvim/.config/nvim/lua/plugins/nvim-tree.lua` | cwd-scoped fzf-lua calls | ✓ VERIFIED | `basedir` logic kept, telescope attach block gone, `<c-f>`/`<c-fg>` call `FzfLua files/live_grep` with cwd |
| `nvim/.config/nvim/lua/plugins/alpha.lua` | Colorscheme cmd + buttons | ✓ VERIFIED | `ColorschemeWithPreview` body → `fzf-lua.colorschemes()`; ff/r/k → FzfLua; n/l/q untouched |
| `nvim/.config/nvim/lua/plugins/telescope.lua` | DELETED | ✓ VERIFIED | Absent from tree; deleted via `git rm` |
| `nvim/.config/nvim/lua/lang/markdown/plugins.lua` | Dep block removed | ✓ VERIFIED | live-preview entry keeps event, no dependencies block, no invented picker flag |
| `nvim/.config/nvim/lua/icons/lspkind.lua` | Telescope key dropped | ✓ VERIFIED | Neighbors byte-identical; blink consumer has glyph fallback |
| `nvim/.config/nvim/lua/plugins/blink-cmp.lua` | Guarded build | ✓ VERIFIED | `run=` gone; function-form `build` present (see WR-02 note); prebuilt fuzzy pin untouched |
| `nvim/.config/nvim/lua/plugins/treesitter.lua` | Main-branch spec | ✓ VERIFIED | `build=":TSUpdate"` alone; dead keys gone; parser list retained as documented on-demand set |
| `setup.sh` | Trigger + wipe + demotion | ✓ VERIFIED | Trigger block, widened wipe, OPTIONAL_TOOLCHAIN, `bash -n` clean, dry-runs green |
| `nvim/.config/nvim/lazy-lock.json` | Pin churn | ✓ VERIFIED | On-disk only (gitignored, correctly uncommitted): 39 pins, fzf-lua + which-key in, 3 legacy out, plenary kept |
| `README.md` | Atomic docs | ✓ VERIFIED | Mason auto-install section, widened-wipe bullet, optional-toolchain section all present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| setup.sh post-stow trigger | MasonInstallAll headless sync path | `nvim --headless -c "MasonInstallAll" -c "qall"` gated on nvim-selected + `command -v nvim` | WIRED | Async no-op breakage (Pitfall 1) fixed by sync branch; negated guard = warn-and-continue |
| mason-install-all.lua | lang aggregator mason_packages | `require("lang")` single source | WIRED | `MASON-OK: 21 packages` live this session |
| which-key spec triggers | popup visibility | Table-form `{ {"<auto>", mode="nxso"} }` | WIRED | Matches upstream default; bare-string pitfall avoided; visual pending human |
| widened wipe literal | typed-yes gate + dry-run preview | Fixed `$HOME`-anchored literal | WIRED | Gate precedes live `rm -rf`; preview proven; live path code-read only |
| keymaps RHS | fzf-lua builtins | `:FzfLua …` / `TodoFzfLua` / `:Noice pick` / lua-function calls | WIRED | All 11 builtins probed to exist (REVIEW); smoke green |
| fzf-lua ui_select flag | vim.ui.select dressing | `ui_select = {}` replacing ui-select plugin | WIRED | Generic coverage; live `vim.ui.select` path pending human session use |
| Noice pick | fzf-lua integration | Snacks-disabled → telescope-absent → fzf-lua fallback chain | WIRED | Verified against noice source in REVIEW; snacks stays `opts={}` disabled |
| treesitter build string | fresh-clone install | `build = ":TSUpdate"` alone | WIRED | Fresh-install-equivalent reinstall proven in 05-02-SUMMARY (zero E492) |
| setup.sh optional marking | verify_deps abort policy | make/gcc absent from `common`, warn-only probe | WIRED | No family aborts; probe exit 0; Termux clang-only safe |

### Data-Flow Trace (Level 4)

Config repo — no DB/API/rendered-data pipeline. Picker data path spot-traced:
`live_grep` ← `rg` (14.1.0 present), `files` ← `fzf` binary (`/usr/bin/fzf`,
`fd` absent → documented `rg --files` fallback), git pickers ← `git`.
No hollow props, no static fallbacks in the picker path.

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| fzf-lua pickers | files/grep/buffers output | `fzf` + `rg` binaries on PATH | Yes (both probed) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Installer parses | `bash -n setup.sh` | exit 0 | ✓ PASS |
| Mason trigger previews, zero writes | `bash setup.sh --dry-run --mode server --shell zsh --yes \| grep MasonInstallAll` | `[DRY RUN] Would run: nvim --headless …` | ✓ PASS |
| Wipe previews whole data dir, zero writes | sourced `run_uninstall` with nvim deselected + `DRY_RUN=true` | `Removing Neovim data dir: …` + `[DRY RUN] Would run: rm -rf "~/.local/share/nvim"` | ✓ PASS |
| Mason module loads headless | `nvim --headless --clean -u NONE … require('utils.mason-install-all')` | `MASON-SMOKE-OK` | ✓ PASS |
| fzf-lua loads headless | `nvim --headless -c "lua assert(pcall(require,'fzf-lua'))"` | `fzf-lua ok` | ✓ PASS |
| which-key loads headless | `nvim --headless -c "lua assert(pcall(require,'which-key'))"` | `which-key ok` | ✓ PASS |
| checkhealth zero errors | `nvim --headless -c "checkhealth"` | 0 error lines | ✓ PASS |
| Mason list matches aggregator | D-12 one-liner | `MASON-OK: 21 packages` | ✓ PASS |
| Optional probe never aborts | sourced `warn_optional_toolchain` | exit 0 | ✓ PASS |

### Probe Execution

SKIPPED — no probes declared. Neither PLAN mentions `probe-*.sh`, and no
`scripts/*/tests/probe-*.sh` exists in the repo. (Headless CLI assertions above
serve as the executable evidence instead.)

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| EDIT-01 | 05-01 | Headless MasonInstallAll post-stow; uninstall removes artefacts when nvim deselected | ✓ SATISFIED (wipe live path behavior-unverified) | Trigger + warn-and-continue + manual path + widened wipe all wired; backstop clause superseded by locked D-01 |
| EDIT-02 | 05-01 | which-key popup on `<Space>` (v3 preset modern delay 200) | ✓ SATISFIED (visual pending human) | Spec shape byte-matches upstream default; require + checkhealth green |
| EDIT-03 | 05-02 | fzf-lua replaces telescope; make/gcc out of the picker path (demoted) | ✓ SATISFIED | Zero legacy refs; no build step; demotion warn-only; no silent fallback; no TAP harness |

Orphaned requirements: none — all three Phase-5 IDs (EDIT-01/02/03) appear in
plan frontmatter (`requirements: [EDIT-01, EDIT-02]` in 05-01, `[EDIT-03]` in
05-02) and are accounted for above.

### Anti-Patterns Found

Debt-marker scan: the only TODO/FIXME hits are functional todo-keyword strings
(`TodoFzfLua keywords=…`, Trouble filter tags) — picker arguments, not
placeholders. No `TBD`/`XXX`, no `return null/{}/[]` stubs, no `console.log`
handlers, no hardcoded empty data flowing to output. No blockers.

Advisory findings carried from 05-REVIEW.md (reviewer-declared non-blocking,
none gates Phase 06 — recorded here so they are not lost):

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `base/keymaps.lua` | 165 | `TodoFzfLua keywords=…` filter silently discarded (WR-01) | ⚠️ Warning | Functional regression vs old `TodoTelescope` form: shows all todos; stray globals set. Fix documented in REVIEW (lua-function RHS with `opts.keywords`) |
| `plugins/blink-cmp.lua` | 10-14 | Guarded `build` function return value discarded by lazy (WR-02) | ⚠️ Warning | jsregexp never compiles even with a compiler; identical to old dead `run=` behavior (no regression) but reads as if the compiler path works |
| `plugins/nvim-tree.lua` | 65-69 | `basedir_from_node()` nil-index when tree not focused; bindings global (WR-03) | ⚠️ Warning | `<C-f>` in a normal buffer errors instead of opening the picker (pre-existing hazard shape, kept through rewrite) |
| `base/keymaps.lua`, `nvim-tree.lua`, `alpha.lua` | — | lua-function RHS bypasses lazy `cmd` loading (WR-04) | ⚠️ Warning | First-ever picker via `fa`/`f`/`th`/`<C-f>`/`<C-fg>`/command before any `:FzfLua` may fail module-not-found; narrow window, covered in live picker pass |
| `setup.sh` | 276-296,1987 | Optional probe warns on clang-only hosts + warns when unselected (WR-05) | ℹ️ Info | Noisy/misleading, exit 0 always, never aborts |
| `setup.sh` | 24,246-267 | Ticked make/gcc rows install nothing (WR-06) | ℹ️ Info | UI implies install-on-tick; README documents advisory semantic |
| `setup.sh` + `README.md` | 977-980 | Wipe destroys undo history/shada beyond README "regenerable" claim (WR-07) | ⚠️ Warning | Bounded, gated, previewed — disclosure gap, not a safety-mechanism failure |
| `utils/mason-install-all.lua` | 17-40,44-67 | Duplicated collect-missing/install block (WR-08) | ℹ️ Info | Future skew risk headless-vs-interactive; extract `install_missing()` helper |
| `setup.sh` | 2092-2093 | Unreachable DRY_RUN branch in live trigger (IN-01) | ℹ️ Info | Dead duplicate; working preview lives at line 2065 |
| `plugins/treesitter.lua` | 22-33 | `parsers` computed but never consumed; `incremental_selection` ignored on main (IN-02) | ℹ️ Info | Net effect correct; file implies active config that is not |
| `which-key.lua` | 13-22 | Group spec covers subset of leader prefixes (IN-04) | ℹ️ Info | Cosmetic; `q l n d /` leaders render ungrouped |

Regression check vs earlier phases: Phase-5 commits touch only
`nvim/`, `setup.sh`, `README.md` (per both SUMMARYs' key-files + task commits
`176826c ed6a465 79f6978 cad785a 84e6326 73c28e0`); no `zsh/`/shell-path files
modified. Installer guards intact: `set -Eeuo pipefail` header, stow
`--no-folding` on all stow calls, `mkdir -p "$HOME/.config"`, checklist/arg-parsing
untouched. Prior VERIFICATIONs: Phase 4 `passed` (6/6), Phase 3 `gaps_found`
(pre-existing, out of Phase-5 scope — not regressed by this phase).

### Human Verification Required

### 1. which-key popup visual

**Test:** Open nvim, press `<Space>` and then `f` / `s` / `g`
**Expected:** LazyVim-like popup appears (preset modern, ~200ms delay) with group labels and nested leaf hints from desc strings
**Why human:** Headless proves registration + health, never visual rendering

### 2. Interactive picker pass (all rebound keys)

**Test:** Invoke each picker once: `<leader>ff fa fg fb fh fo ma cm gt f th st sT N`, `<C-f>`/`<C-fg>` in nvim-tree, dashboard `ff r k th`, `:ColorschemeWithPreview`
**Expected:** Every key opens the fzf-lua picker with correct scope; EXPECTED DEVIATIONS under test: `<leader>sT` shows ALL todos (WR-01); first-ever `fa`/`f`/`th` before any `:FzfLua` may fail (WR-04); `<C-f>` outside the tree errors (WR-03)
**Why human:** Headless proves loading/wiring, never rendering, filter semantics, or lazy-load ordering

### 3. Live destructive wipe (disposable host only)

**Test:** On a disposable clone/VM — NEVER the daily driver — run `bash setup.sh --uninstall`, deselect nvim, type `yes`, confirm `~/.local/share/nvim` is gone; reinstall and confirm LSPs restore
**Expected:** Whole data dir removed behind typed-yes; reinstall restores everything
**Why human:** Live `rm -rf` deliberately never executed during verification; cannot be proven without destruction

### Gaps Summary

No must-have truth FAILED — there are no actionable gaps for
`/gsd-plan-phase --gaps`. One truth (wipe live deletion) is present and wired
but its destructive behavior is unexercised by design, and three live-session
checks (popup visual, picker feel incl. three known WR deviations, live wipe)
require human eyes. The eight 05-REVIEW.md warnings are real but reviewer-ruled
advisory/non-blocking; the four with user-visible impact (WR-01, WR-02, WR-03,
WR-04, plus disclosure WR-07) are recorded above and folded into the live
picker pass rather than silently dropped.

---

_Verified: 2026-10-03T16:15:00Z_
_Verifier: the agent (gsd-verifier)_
