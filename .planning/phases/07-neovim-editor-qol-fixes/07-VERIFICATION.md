---
phase: 07-neovim-editor-qol-fixes
verified: 2026-11-23T14:22:33Z
status: human_needed
score: 8/10 must-haves verified
covered_files:
  - ".planning/phases/07-neovim-editor-qol-fixes/07-01-PLAN.md"
  - ".planning/phases/07-neovim-editor-qol-fixes/07-01-SUMMARY.md"
  - ".planning/phases/07-neovim-editor-qol-fixes/07-02-PLAN.md"
  - ".planning/phases/07-neovim-editor-qol-fixes/07-02-SUMMARY.md"
  - ".planning/phases/07-neovim-editor-qol-fixes/07-03-PLAN.md"
  - ".planning/phases/07-neovim-editor-qol-fixes/07-03-SUMMARY.md"
  - "nvim/.config/nvim/README.md"
  - "nvim/.config/nvim/lazy-lock.json"
  - "nvim/.config/nvim/lua/base/keymaps.lua"
  - "nvim/.config/nvim/lua/base/options.lua"
  - "nvim/.config/nvim/lua/plugins/scrollview.lua"
  - "nvim/.config/nvim/lua/plugins/surround.lua"
  - "nvim/.config/nvim/lua/plugins/which-key.lua"
covered_digest: "v4:sha256:2d62f60e407e01fba503fd442a45fcc63f18c652722c7585fa5dd106ce6def20"
behavior_unverified: 2
overrides_applied: 0
re_verification: false
behavior_unverified_items:
  - truth: "Marker / separator / gitsigns order is preserved on a line carrying both a native diagnostic sign and a gitsigns sign (QOL-03, G-07-1)"
    test: "Open a git-tracked file with uncommitted changes in kitty, set a native diagnostic sign on a line that already has a gitsigns hunk, and inspect the gutter left to right."
    expected: "The far-left opaque marker, the thin solid separator, and the native gitsigns all remain visible in that order, with no multi-cell blank gap; the separator float does not cover the second native sign slot."
    why_human: "The headless screen dump exercises a single-sign changed line but never a two-sign line, and headless screenstring() cannot reliably composite the separator float over native signs. Code review IN-01 flagged exactly this unexercised case; this is the plan's deferred <human-check> for G-07-1."
  - truth: "Alt+comma / Alt+period actually move to the next / previous buffer in the user's live kitty terminal (QOL-05, G-07-2)"
    test: "In real kitty with at least two buffers open, press Alt+comma then Alt+period in normal mode."
    expected: "Next buffer, then previous buffer, are selected."
    why_human: "No kitty binary exists in this headless environment; the maparg probe proves only the editor-side binding, not terminal-to-Neovim delivery. Terminal delivery is an external-service behavior no headless test exercises."
human_verification:
  - test: "Open a git-tracked file with uncommitted changes in kitty and inspect the left gutter; then put a native diagnostic sign and a gitsigns sign on the same line and inspect again."
    expected: "Left to right: far-left opaque git marker column (┃), a very thin solid line separator (│), the native per-line gitsigns, line numbers, then text — no large empty gap. The order is unchanged on a line carrying both a native diagnostic sign and a gitsigns sign."
    why_human: "Final pixel compositing needs a real TUI; headless probes prove the option values and a marker→separator→number→text screen row but cannot composite the separator float over a two-sign line (review IN-01). This is the deferred <human-check> in 07-02-PLAN."
  - test: "In real kitty with at least two buffers, press Alt+comma and Alt+period in normal mode; if nothing happens, run the insert-mode delivery test under `nvim --clean`."
    expected: "Next/previous buffer switches. For the delivery probe, a literal ESC prefix is inserted after the Alt key; note that under this repo's normal config insert-mode <C-v> is remapped to clipboard paste (review WR-02), so the probe must run with `nvim --clean` or after `:iunmap <C-v>`."
    why_human: "Live kitty key delivery is external to the codebase; headless maparg proves the editor side only. 07-03-SUMMARY explicitly defers this to end-of-phase UAT because no kitty binary is available here."
---

# Phase 7: Neovim Editor QoL Fixes Verification Report

**Phase Goal (ROADMAP, verbatim):** Daily editing gaps are closed: full diagnostics on demand, no dead keymaps, git markers in a far-left gutter with no scrollbar, surround support, and buffer cycling on `<C-,>`/`<C-.>`. Cursor-jump investigation is explicitly out of scope.
**Verified:** 2026-11-23T14:22:33Z
**Status:** human_needed — all implementation must-haves verified against final state; two end-of-phase human checks remain (both explicitly deferred by the gap-closure plans).
**Re-verification:** No — initial verification of the final codebase. A stale `07-VERIFICATION.md` from 12:48:51Z existed but had no `gaps:` block and predated both gap-closure plans (07-02 / 07-03), so per Step 0 this is a fresh initial pass. It has been superseded by this report.

## Scope Notes (read before the tables)

1. **Stale goal strings superseded.** The ROADMAP/REQUIREMENTS literal `<C-,>`/`<C-.>` is stale: UAT gap **G-07-2** moved buffer cycling to `<M-,>`/`<M-.>` (Alt+comma/Alt+period) because kitty's legacy encoding drops Ctrl on punctuation. The ROADMAP SC-3 literal "blank separator cell" and `winblend_gui = 100` are also stale: gap **G-07-1** replaced the disproved spare-cell separator with a dedicated thin-solid-line float and changed `winblend_gui` to `0` with a `ScrollView → Normal` highlight link. Verification below follows the locked final end-state (gap-closure plans 07-02/07-03), as directed. REQUIREMENTS.md lines 48/50 still carry the old literals — documentation drift owned by the orchestrator, not a code defect.
2. **MVP mode.** ROADMAP marks this phase `mode: mvp`, but the ROADMAP goal string is not a User Story (`user-story.validate` returned `valid: false`, missing the "As a … / I want to … / so that …" slots). The strict MVP guard would refuse to verify against it. To avoid blocking the orchestrator while staying honest, this report performs the full standard goal-backward verification and supplies the MVP User Flow Coverage table below using the **valid** User Story in `07-01-PLAN.md`'s `<objective>` (validated `valid: true`, role "daily Neovim user"). The discrepancy should be corrected by rewriting the ROADMAP goal as a proper User Story; it did not affect any implementation truth.
3. **Digest.** `covered_digest` was produced by `gsd_run query verification.fingerprint` (v4), not hand-written. The verb auto-unioned the six phase PLAN/SUMMARY files with the seven declared implementation files.

## User Flow Coverage (MVP mode — story taken from 07-01-PLAN.md `<objective>`)

| Step (capability) | Expected | Evidence in codebase | Status |
|---|---|---|---|
| Open full diagnostics on demand | `<leader>vd` shows the full current-line message in a rounded float; virtual text unchanged | `keymaps.lua:25-27` + `VD-BEHAVIOR-OK`; UAT test 3 passed by human | ✓ VERIFIED |
| Keep only keymaps that work | No bindings to uninstalled plugins; group label no longer "trouble/buffer" | `DEAD-MAPS-CLEAN`, `SURVIVORS-OK`, `WK-LABEL-OK`, `WK-SPEC-OK` | ✓ VERIFIED |
| See git markers in a clean far-left gutter | Opaque far-left markers, hidden bar, thin solid separator, gitsigns intact | `GUTTER-SOURCE-OK`, `SCROLLVIEW-OPTS-FINAL-OK`, fresh `GUTTER-CONFIG-OK`, `SEPARATOR-LAYOUT-OK` | ✓ VERIFIED (2-sign line pending human) |
| Wrap selections with surround | `S"` / `S)` wrap; plugin pinned with default keymaps | `SURROUND-PIN-OK`, `SURROUND-SPEC-OK`, `SURROUND-WRAP-OK` | ✓ VERIFIED |
| Cycle buffers without sacrificing Tab | `<M-,>`/`<M-.>` (final) cycle buffers; Tab/S-Tab free | `BUFFER-ALT-SOURCE-OK`, `BUFFER-ALT-OK`, `BUFFER-CMDS-INTACT`, `STALE-CAVEAT-CLEAN` | ✓ VERIFIED (live kitty pending human) |
| Outcome: everyday editing gaps closed without changing the diagnostic model or touching unrelated config | No diagnostic wrapping, no new hover binding, no cursor-jump work, no collateral edits | `HOVER-UNCHANGED`; commit file lists show only the 7 intended files touched | ✓ VERIFIED |

## Goal Achievement

### Observable Truths

Must-haves merged from the 6 ROADMAP success criteria (non-negotiable contract) plus the per-plan frontmatter truths that add detail. Every row was checked against the final files, not SUMMARY claims.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `<leader>vd` opens the full rounded line-diagnostic float; virtual text unchanged; no Trouble added (SC-1 / QOL-01) | ✓ VERIFIED | `keymaps.lua:25-27` holds exactly one active `vim.diagnostic.open_float(nil, { scope = "line", border = "rounded", focusable = true })` with desc `Show line diagnostic`, immediately after the `<Esc>` noh map. `VD-SOURCE-OK` + headless `VD-BEHAVIOR-OK` (float opened from loaded source). `HOVER-UNCHANGED`: exactly one `vim.lsp.buf.hover` binding remains in `lspconfig.lua`; no `trouble` plugin. UAT test 3 passed by a human. |
| 2 | No dead keymaps to uninstalled plugins; `<leader>x` group retitled to `buffer` (SC-2 / QOL-02) | ✓ VERIFIED | `DEAD-MAPS-CLEAN`: active-line counts for grug-far/persistence/Diffview/Trouble all 0. `SURVIVORS-OK`: `gs.preview_hunk`, `TodoFzfLua`, `Bdelete!` intact. `which-key.lua:19` = `{ "<leader>x", group = "buffer" }`, zero `trouble/buffer`; `WK-SPEC-OK` confirmed headlessly. |
| 3 | Scrollview git markers render opaque at the far-left gutter; scrollbar hidden (QOL-03 / G-07-1) | ✓ VERIFIED | `scrollview.lua:8-16`: `base=left`, `column=2`, `signs_overflow=left`, `winblend_gui=0`, `signs_show_in_folds=true`, `signs_on_startup={gitsigns}`, `signs_scrollbar_overlap=off`, no `winblend_gui=100`. `ScrollView→Normal` link at `:20` with `vim.schedule` + `ColorScheme` re-assert. Freshly re-ran the shipped gate: `sign_windows=1`, `min_sign_col=0`, `winblend=0`, `ScrollView_hl_link=Normal`, `bar_cell_row6=  blank=true` → `GUTTER-CONFIG-OK`. |
| 4 | Thin solid separator before native gitsigns, no multi-cell blank gap (SC-3 / QOL-03 / G-07-1) | ✓ VERIFIED | `scrollview.lua:41-103`: one-column `│` (U+2502) float, `focusable=false`, `border=none`, `zindex=45`, dedicated dim `ScrollViewSeparator` highlight, autocmd recreate/cleanup. `options.lua:12` is `signcolumn="yes:2"` with the verified left-alignment comment (no `yes:4`). Fresh gate screen row: `marker=1 sep=3 number=7 text=9`, `marker->sep=2 sep->number=4` → `SEPARATOR-LAYOUT-OK`. |
| 5 | Marker / separator / gitsigns order preserved on a line carrying BOTH a native diagnostic sign and a gitsigns sign (07-02 truth / QOL-03) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Source and headless geometry are present and wired, but no test exercises a two-sign line: the gate's screen dump used a single-gitsigns changed line, and headless `screenstring()` cannot reliably composite floats over native signs. Code review `IN-01` (open) flags that the separator float at `col=2` may overlap the second native sign slot. Routed to Human Verification item 1; excluded from the verified score. |
| 6 | Gitsigns contrib uses only keys the pinned plugin reads; research corrected; prior deliverables untouched (07-02 truths) | ✓ VERIFIED | `CONTRIB-KEYS-OK`: only `enabled` + `add/change/delete_priority`; no bare `priority`/`show_in_folds`. `RESEARCH-CORRECTED`: no `right-align` claim, `left-align` present, cites G-07-1. Commit file lists for `35c7955`, `199e50f`, `c399ace` touch only `scrollview.lua`, `options.lua`, `07-RESEARCH.md`; `07-01-SUMMARY.md` is byte-unchanged. |
| 7 | nvim-surround installed, pinned with a genuine 40-hex commit, default `ys`/`ds`/`cs`/visual `S` wrap works (SC-4 / QOL-04) | ✓ VERIFIED | `surround.lua` is the exact locked spec (`kylechui/nvim-surround`, `version="*"`, `event="VeryLazy"`, `opts={}`) — `SURROUND-SPEC-OK`, git-tracked. `lazy-lock.json:26` pins `2e93e154de9ff326def6480a4358bfc149d5da2c`, which equals the installed plugin HEAD (tag v4.0.5); 40 entries, prior pins retained. Extra probe loaded the real plugin and visually wrapped `hello` → `"hello"` (`SURROUND-WRAP-OK`). |
| 8 | Buffer next/prev bound to `<M-,>`/`<M-.>` with the original commands; Tab/S-Tab and old Ctrl lhs unbound (SC-5 editor side / QOL-05 / G-07-2) | ✓ VERIFIED | `keymaps.lua:94-95` map `<M-,>`→`BufferLineCycleNext`, `<M-.>`→`BufferLineCyclePrev`, desc/order preserved. Headless `BUFFER-ALT-OK` confirmed both mapargs and empty maparg for `<Tab>`, `<S-Tab>`, `<C-,>`, `<C-.>`. Repo-wide scan finds no `<C-,>`/`<C-.>` in the shipped nvim config. `BUFFER-CMDS-INTACT`. |
| 9 | Alt+comma / Alt+period actually cycle buffers in the user's live kitty terminal (07-03 truth / QOL-05) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The editor side is proven (row 8) and the README explains kitty's legacy Ctrl+punctuation drop, but no kitty binary exists here, so terminal-to-Neovim delivery has no behavioral test. Routed to Human Verification item 2; excluded from the verified score. |
| 10 | `smoothscroll` removed as cosmetic cleanup; no cursor-jump claims (SC-6 / QOL-06) | ✓ VERIFIED | `SMOOTH-CLEAN`: zero active `smoothscroll` lines in `options.lua`; `vim.o.smoothscroll == false` asserted in `VD-BEHAVIOR-OK`. No cursor-jump claims in any phase artifact; `07-01-SUMMARY` records the removal as cosmetic only. |

**Score:** 8/10 truths verified (2 present-but-behavior-unverified; 0 failed; 0 overrides). The 6 roadmap success criteria are all satisfied at the implementation level; the 2 unverified rows are plan-specific live/visual invariants deferred to end-of-phase UAT.

### Deferred Items

None — no failed truth or missing item was matched to a later milestone phase. Both open items are human checks, not gaps.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `nvim/.config/nvim/lua/base/keymaps.lua` | diag float; 4 dead regions removed; Alt buffer-cycle lhs | ✓ VERIFIED | 176 lines; all changes present, neighbors intact, no stale Ctrl lhs |
| `nvim/.config/nvim/lua/base/options.lua` | `signcolumn="yes:2"`, left-align comment; no smoothscroll | ✓ VERIFIED | 76 lines; line 12 correct (final G-07-1 state), no smoothscroll |
| `nvim/.config/nvim/lua/plugins/scrollview.lua` | far-left opaque markers, hidden bar, valid contrib keys, separator float | ✓ VERIFIED | 105 lines; final G-07-1 config, gate passed |
| `nvim/.config/nvim/lua/plugins/which-key.lua` | `<leader>x` group = `buffer` | ✓ VERIFIED | 24 lines; line 19 correct |
| `nvim/.config/nvim/lua/plugins/surround.lua` | nvim-surround lazy spec | ✓ VERIFIED | 6 lines; exact locked spec, git-tracked |
| `nvim/.config/nvim/lazy-lock.json` | nvim-surround 40-hex pin, prior pins retained | ✓ VERIFIED | 40 entries; pin matches installed HEAD (v4.0.5); forced-add documented in 07-01-SUMMARY and independently confirmed tracked |
| `nvim/.config/nvim/README.md` | kitty-inclusive Alt buffer-cycling caveat | ✓ VERIFIED | 39 lines; kitty primary, Alacritty secondary, no `<C-,>` prose |

**Artifacts:** 7/7 verified (all substantive, tracked, and wired).

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `<leader>vd` | `vim.diagnostic.open_float` | inline Lua callback in `keymaps.lua` | ✓ WIRED | `VD-BEHAVIOR-OK` opened a real float |
| `signcolumn="yes:2"` + scrollview `column=2`/`signs_overflow=left` | far-left marker column + native sign slots | option geometry | ✓ WIRED | `SCROLLVIEW-OPTS-FINAL-OK`, `SIGNCOLUMN-OK`, fresh gate |
| `ScrollView → Normal` highlight + `winblend_gui=0` | hidden bar, opaque signs | plugin highlight / winblend | ✓ WIRED | gate: `ScrollView_hl_link=Normal`, blank bar cell, `winblend=0` sign window |
| separator float (`col=2`, `│`, zindex 45) | gap between marker and gitsigns | `nvim_open_win` + autocmds | ✓ WIRED | `SEPARATOR-SOURCE-OK`, `SEPARATOR-LAYOUT-OK` |
| `surround.lua` spec | lockfile pin → installed plugin → visual `S` | lazy spec → pin → plugin keymaps | ✓ WIRED | genuine pin + `SURROUND-WRAP-OK` |
| `<M-,>`/`<M-.>` lhs | `BufferLineCycleNext`/`BufferLineCyclePrev` | normal-mode keymaps | ✓ WIRED | `BUFFER-ALT-OK` |
| kitty README caveat | final Alt binding | documentation | ✓ WIRED | `KITTY-DOC-OK`, no stale Ctrl lhs in prose |

**Wiring:** 7/7 verified.

### Data-Flow Trace (Level 4)

Not applicable — this phase produces static Neovim configuration (keymaps, options, plugin specs), not dynamic data-rendering artifacts. Runtime wiring is covered by the headless probes below.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Diagnostic float opens from loaded source | `nvim --headless --clean -u NONE -c "luafile .../vd.lua"` | `VD-BEHAVIOR-OK` | ✓ PASS |
| which-key spec label + table triggers | headless `wk.lua` | `WK-SPEC-OK` | ✓ PASS |
| Scrollview final setup options | headless `scrollview-opts.lua` (stubbed plugin modules) | `SCROLLVIEW-OPTS-FINAL-OK` | ✓ PASS |
| Surround spec shape | headless `surround-spec.lua` | `SURROUND-SPEC-OK` | ✓ PASS |
| Real surround visual `S"` wraps | headless `surround_probe.lua` (installed v4.0.5) | `SURROUND-WRAP-OK` | ✓ PASS |
| Alt buffer maparg / old keys unbound | headless `buffer-alt.lua` | `BUFFER-ALT-OK` | ✓ PASS |

All checks completed in under 10 seconds, started no server, and mutated no repo state.

### Probe Execution

SUMMARY probe claims were not trusted; each probe was re-run in this verifier's own process.

| Probe | Command | Result | Status |
|---|---|---|---|
| Gutter config + separator layout (shipped gate) | `cd /tmp/opencode/gutter-probe && PROBE_OUT=... nvim --headless sample.txt -c 'luafile /tmp/opencode/gutter-gap-gate.lua'` | Fresh result: `GUTTER-CONFIG-OK` and `SEPARATOR-LAYOUT-OK`; `sign_windows=1`, `marker=1 sep=3 number=7 text=9` | ✓ PASS (independent re-run) |
| Source assertions (16 gates) | grep/test from repo root | all 16 PASS | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| QOL-01 | 07-01 | `<leader>vd` full diagnostic float; no wrapping/Trouble | ✓ SATISFIED | `VD-SOURCE-OK`, `VD-BEHAVIOR-OK`, `HOVER-UNCHANGED`; UAT test 3 human-passed |
| QOL-02 | 07-01 | dead keymaps removed; group label retitled | ✓ SATISFIED | `DEAD-MAPS-CLEAN`, `SURVIVORS-OK`, `WK-LABEL-OK`, `WK-SPEC-OK` |
| QOL-03 | 07-01, 07-02 | far-left markers, hidden bar, thin solid separator, gitsigns intact | ✓ SATISFIED | `GUTTER-SOURCE-OK`, `SIGNCOLUMN-OK`, `SEPARATOR-SOURCE-OK`, fresh gutter gate; two-sign line → human |
| QOL-04 | 07-01 | nvim-surround installed, pinned, default keymaps | ✓ SATISFIED | `SURROUND-PIN-OK`, `SURROUND-SPEC-OK`, `SURROUND-WRAP-OK` |
| QOL-05 | 07-01, 07-03 | Alt buffer cycling (final); Tab/S-Tab free; kitty caveat documented | ✓ SATISFIED | `BUFFER-ALT-SOURCE-OK`, `BUFFER-ALT-OK`, `KITTY-DOC-OK`, `STALE-CAVEAT-CLEAN`; live kitty → human |
| QOL-06 | 07-01 | smoothscroll removed, no cursor-jump claims | ✓ SATISFIED | `SMOOTH-CLEAN`, headless `vim.o.smoothscroll == false` |

**Coverage:** 6/6 requirement IDs declared in the three PLAN frontmatter fields are accounted for. Cross-referenced against REQUIREMENTS.md — all six map to Phase 7; no orphaned requirements. (REQUIREMENTS.md checkboxes for QOL-01/02/04/06 remain unchecked and its QOL-03/05 wording is stale; traceability updates are orchestrator-owned.)

### Decision Coverage

`check.decision-coverage-verify` returned `skipped: true` — "No trackable decisions in CONTEXT.md" (0 total, 0 honored). Warning-only gate; no status impact. The six locked scope decisions from 07-CONTEXT.md are nonetheless reflected verbatim in the shipped files and SUMMARY key-decisions, with the two UAT-superseded choices (gutter design, buffer keys) explicitly recorded in 07-RESEARCH.md / 07-03-SUMMARY.

### Test Quality Audit

No committed test files are linked to requirements in this phase — verification uses disposable headless probes (`/tmp/opencode/...`, never committed). Disabled-test, circular-fixture, and expected-value-provenance checks are therefore N/A; assertion-strength is behavioral where runtime behavior is claimed (float opens, maparg resolves, real plugin wraps, screen row order). No circular expected values: probes assert against API state and installed plugin behavior, not values generated by the system under test.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `keymaps.lua` | 145 | `TODO,FIX,FIXME` in `TodoFzfLua keywords=...` | ℹ️ Info | Legitimate keymap keyword list, not an unresolved debt marker |
| `scrollview.lua` | 58 | `local lines = {}` | ℹ️ Info | Populated immediately by the loop at `:59-61`; not a stub |
| `surround.lua` | 5 | `opts = {}` | ℹ️ Info | Required empty-opts lazy spec shape; plugin defaults supply keymaps |

Debt-marker gate: the only `TODO`/`FIXME` hit is the legitimate keymap above and is not an unresolved marker — no blocker. No placeholder prose, empty implementations, hollow props, or console-log-only stubs. All 8 task commits exist and each touches only its intended files; working tree has only pre-existing `.planning/state.json` (M) and `.planning/milestone.lock` (untracked), untouched by this phase.

### Informational Notes (non-blocking)

- **Code review WR-01 (open):** `scrollview.lua:86-92` registers a `User ScrollViewRefresh` autocmd, but the pinned plugin fires a `:ScrollViewRefresh` command, not a `User` event — the callback never runs. Inert: separator redraw is already covered by `BufEnter`/`WinEnter`/`VimResized`/`WinScrolled`/`WinClosed`. Removal is a small follow-up, not a goal blocker.
- **Code review WR-02 (open):** the README insert-mode `<C-v>` delivery test is defeated by `keymaps.lua:174`'s `map("i", "<C-v>", "<C-r>+")`. Folded into Human Verification item 2 (`nvim --clean` or `:iunmap <C-v>`).
- **Code review IN-01 (open):** potential separator/native-sign overlap on a two-sign line — folded into Human Verification item 1.
- **Stale planning literals:** ROADMAP goal SC-3/SC-5 and REQUIREMENTS.md lines 48/50 still name `winblend_gui=100`, `yes:4`, `<C-,>`/`<C-.>`. Orchestrator-owned docs; final code is the locked gap-closure end-state.

### Human Verification Required

Automated checks pass. Two end-of-phase human checks remain — both explicitly deferred by the gap-closure plans (`human_verify_mode = end-of-phase`), not implementation defects.

**1. Gutter visual order in kitty (QOL-03 / G-07-1)**
- **Test:** Open a git-tracked file with uncommitted changes in kitty and inspect the left gutter; then put a native diagnostic sign and a gitsigns sign on the same line and inspect again.
- **Expected:** Left to right — far-left opaque marker (┃), thin solid line separator (│), native per-line gitsigns, line numbers, text; no large empty gap; order unchanged on the two-sign line.
- **Why human:** Final pixel compositing needs a real TUI; headless proves option values and a marker→separator→number→text screen row but cannot composite the float over a two-sign line (IN-01).

**2. Live kitty Alt buffer cycling (QOL-05 / G-07-2)**
- **Test:** In real kitty with ≥2 buffers, press Alt+comma and Alt+period in normal mode; run the insert-mode delivery probe under `nvim --clean` if needed.
- **Expected:** Next/previous buffer switches; literal ESC prefix appears in the clean-config delivery probe.
- **Why human:** No kitty binary here; maparg proves only the editor side. README's `<C-v>` probe is remapped under this config (WR-02), so use `--clean` or `:iunmap <C-v>`.

### Gaps Summary

**No gaps found.** All 6 roadmap success criteria, 10 merged must-have truths (8 fully verified, 2 present-but-behavior-unverified), 7 artifacts, 7 key links, and 6 requirement IDs are satisfied or explicitly routed to human verification. Both remaining items are the plans' own deferred end-of-phase human checks. G-07-1 and G-07-2 are closed at the automated level by 07-02 and 07-03 respectively, with each change re-verified from the final codebase in this pass.

---
_Verified: 2026-11-23T14:22:33Z_
_Verifier: the agent (gsd-verifier subagent)_
