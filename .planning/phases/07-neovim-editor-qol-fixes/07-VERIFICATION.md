---
phase: 07-neovim-editor-qol-fixes
verified: 2026-11-23T12:48:51Z
status: human_needed
score: 6/6 must-haves verified (implementation + headless behavior)
covered_files:
  - .planning/phases/07-neovim-editor-qol-fixes/07-01-PLAN.md
  - .planning/phases/07-neovim-editor-qol-fixes/07-01-SUMMARY.md
  - .planning/phases/07-neovim-editor-qol-fixes/07-CONTEXT.md
  - .planning/phases/07-neovim-editor-qol-fixes/07-RESEARCH.md
  - nvim/.config/nvim/lua/base/keymaps.lua
  - nvim/.config/nvim/lua/base/options.lua
  - nvim/.config/nvim/lua/plugins/scrollview.lua
  - nvim/.config/nvim/lua/plugins/which-key.lua
  - nvim/.config/nvim/lua/plugins/surround.lua
  - nvim/.config/nvim/lazy-lock.json
  - nvim/.config/nvim/README.md
covered_digest: "unavailable — gsd_run tooling not installed in this environment; digest not fabricated"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
requirements_coverage:
  QOL-01: SATISFIED
  QOL-02: SATISFIED
  QOL-03: SATISFIED
  QOL-04: SATISFIED
  QOL-05: SATISFIED
  QOL-06: SATISFIED
human_verification:
  - test: "Open a git-tracked file with uncommitted changes in Alacritty and inspect the left gutter"
    expected: "scrollview git markers render in the far-left gutter (column 1), the scrollbar itself is invisible (winblend_gui=100), a blank separator cell sits before gitsigns' native per-line signs, and the separator survives on a line carrying both a native diagnostic sign and a gitsigns sign (signcolumn=yes:4)"
    why_human: "visual / window-layout rendering — headless probes prove the exact options passed to scrollview.setup() and signcolumn=yes:4, but cannot observe the rendered gutter"
  - test: "In a real Alacritty terminal with nvim open on >=2 buffers, press <C-,> and <C-.> in normal mode; if nothing happens, press <C-v><C-,> in insert mode to test delivery"
    expected: "next/previous buffer switches; if the sequence is swallowed, a literal control char fails to appear in insert mode, indicating Alacritty needs a custom key_bindings entry for Ctrl+comma/Ctrl+period"
    why_human: "external terminal key delivery — Alacritty uses TERM=xterm-256color with no custom key_bindings; headless maparg proves the bindings exist but cannot prove the terminal emits the sequences"
  - test: "Trigger <leader>vd on a line carrying a diagnostic"
    expected: "a rounded-border floating window shows the full current-line message; virtual-text rendering is unchanged"
    why_human: "visual confirmation — headless probe proved a float window opens with border=rounded configured and the diagnostic set, so this is a quick visual sanity check rather than a blocking unknown"
---

# Phase 7: Neovim Editor QoL Fixes Verification Report

**Phase Goal:** Daily editing gaps are closed: full diagnostics on demand, no dead keymaps, git markers in a far-left gutter with no scrollbar, surround support, and buffer cycling on `<C-,>`/`<C-.>`. Cursor-jump investigation is explicitly out of scope.
**Verified:** 2026-11-23T12:48:51Z
**Status:** human_needed (all implementation must-haves verified; 3 visual/live items require a human terminal)
**Re-verification:** No — initial verification
**Verification approach:** Goal-backward against the 6 PLAN frontmatter truths (one per QOL requirement), cross-referenced to the ROADMAP Phase 7 success criteria. `gsd_run` CLI tooling is not installed; all evidence was gathered by direct file reads, `git`, and re-running the plan's 13 headless gates with `nvim v0.12.2` + `jq 1.7`.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `<leader>vd` opens full rounded line-diagnostic float; virtual text untouched; no extra plugin (QOL-01) | ✓ VERIFIED | `keymaps.lua:25-27` holds exactly one active `vim.diagnostic.open_float(nil, {scope="line", border="rounded", focusable=true})` with desc `Show line diagnostic`, inserted immediately after the `<Esc>` noh map. Gate `VD-SOURCE-OK` passed. Headless `VD-BEHAVIOR-OK` loaded real keymaps/options, set a line diagnostic, invoked the callback and confirmed a float window opened. `HOVER-UNCHANGED` passed (`K`→`vim.lsp.buf.hover` still exactly once at `lspconfig.lua:103`). virtual_text config intact at `lspconfig.lua:38`. No `trouble` plugin anywhere. |
| 2 | No dead keymaps; stale `<leader>x` group label retitled (QOL-02) | ✓ VERIFIED | Active-line greps for `grug-far`/`persistence`/`Diffview`/`Trouble` in `keymaps.lua` all return 0 (`DEAD-MAPS-CLEAN`). Survivors preserved (`SURVIVORS-OK`): `gs.preview_hunk`, `TodoFzfLua`, `Bdelete!`. `which-key.lua:19` is `{ "<leader>x", group = "buffer" }`, zero `trouble/buffer` (`WK-LABEL-OK`); headless `WK-SPEC-OK` confirms label `buffer` and table-form triggers. |
| 3 | Scrollview git markers in far-left gutter, hidden scrollbar, blank separator via `signcolumn=yes:4` (QOL-03) | ✓ VERIFIED | `scrollview.lua:8-12` sets `base="left"`, `column=1`, `winblend_gui=100`, `signs_on_startup={"gitsigns"}`, `signs_scrollbar_overlap="off"`; gitsigns contrib block byte-intact. Headless `SCROLLVIEW-OPTS-OK` loaded the spec with a stubbed module and asserted every option plus `current_only=true`, contrib setup called, `excluded_filetypes[1]="nerdtree"`. `options.lua:12` sets `signcolumn="yes:4"` with the four-cell comment. Visual rendering itself remains a human item (below). |
| 4 | Surround selected text with `S"`/`S)`; nvim-surround pinned (QOL-04) | ✓ VERIFIED | `surround.lua` is exactly the locked spec (`kylechui/nvim-surround`, `version="*"`, `event="VeryLazy"`, `opts={}`) — headless `SURROUND-SPEC-OK`. `git ls-files` confirms it is tracked; `lazy-lock.json:26` pins `2e93e154de9ff326def6480a4358bfc149d5da2c` (`SURROUND-PIN-OK`). Pin is genuine: installed plugin HEAD is that exact commit, tagged `v4.0.5`. All 40 lockfile pins match installed plugin HEADs (39 prior pins retained). Beyond the plan's gates, an extra headless probe loaded the real v4.0.5 plugin and confirmed default keymaps register (`ys`/`ds`/`cs`/visual `S`) and that visual `S"` actually wraps `hello` → `"hello"` (`SURROUND-WRAP-OK`). |
| 5 | Buffer cycling on `<C-,>`/`<C-.>`, Tab freed, caveat documented (QOL-05) | ✓ VERIFIED | `keymaps.lua:94-95` map `<C-,>`→`BufferLineCycleNext`, `<C-.>`→`BufferLineCyclePrev`. Headless `BUFFER-MAPS-OK` confirmed maparg for both and that `<Tab>`/`<S-Tab>` maparg is empty; Tab/S-Tab remain only in `blink-cmp.lua` completion. `README.md:24-30` documents the insert-mode `<C-v><C-,>` delivery test and the Alacritty `key_bindings` caveat (`CAVEAT-DOC-OK`). Live terminal delivery remains a human item (below). |
| 6 | `smoothscroll` removed as cosmetic cleanup (QOL-06) | ✓ VERIFIED | `SMOOTH-CLEAN` passed: zero active `smoothscroll` lines in `options.lua`; repo-wide scan of `*.lua` found no active assignment. No cursor-jump claims appear in any phase artifact. |

**Score:** 6/6 truths verified (0 present-but-behavior-unverified; 0 overrides). All 6 have behavioral/grep evidence from re-run gates, not just file existence.

### Probe Execution (13 plan gates + 2 extra behavioral checks)

All commands run from repo root with `nvim --headless --clean -u NONE` and rtp prepended to `nvim/.config/nvim` exactly as specified in the plan.

| # | Gate marker | Command type | Result |
|---|-------------|--------------|--------|
| 1 | VD-SOURCE-OK | grep/test source assertions | PASS |
| 2 | VD-BEHAVIOR-OK | headless float-open + options probe | PASS |
| 3 | HOVER-UNCHANGED | grep/test source assertions | PASS |
| 4 | SMOOTH-CLEAN | grep/test source assertions | PASS |
| 5 | DEAD-MAPS-CLEAN | grep/test source assertions | PASS |
| 6 | SURVIVORS-OK | grep source assertions | PASS |
| 7 | WK-LABEL-OK | grep/test source assertions | PASS |
| 8 | SCROLLVIEW-OPTS-OK | headless stubbed-module option probe | PASS |
| 9 | WK-SPEC-OK | headless which-key spec load | PASS |
| 10 | SURROUND-PIN-OK | file/git/grep lockfile pin | PASS |
| 11 | SURROUND-SPEC-OK | headless surround spec load | PASS |
| 12 | BUFFER-MAPS-OK | headless maparg probe | PASS |
| 13 | CAVEAT-DOC-OK | grep README | PASS |
| E1 | SURROUND-KEYMAPS-OK | extra: load real v4.0.5 plugin, assert default keymaps | PASS |
| E2 | SURROUND-WRAP-OK | extra: visual `S"` actually wraps `hello` → `"hello"` | PASS |

**Result: 15/15 PASS, 0 FAIL.**

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `nvim/.config/nvim/lua/base/keymaps.lua` | diag float mapping, 4 dead regions removed, buffer-cycle lhs changed | ✓ VERIFIED | 176 lines; all changes present, neighbors intact |
| `nvim/.config/nvim/lua/base/options.lua` | `signcolumn=yes:4`, smoothscroll removed | ✓ VERIFIED | 76 lines; line 12 correct, no smoothscroll |
| `nvim/.config/nvim/lua/plugins/scrollview.lua` | far-left gutter options, hidden bar, gitsigns-only signs | ✓ VERIFIED | 21 lines; all 5 options correct, contrib block intact |
| `nvim/.config/nvim/lua/plugins/which-key.lua` | `<leader>x` group = `buffer` | ✓ VERIFIED | 24 lines; line 19 correct |
| `nvim/.config/nvim/lua/plugins/surround.lua` | nvim-surround lazy spec | ✓ VERIFIED | 6 lines; exact locked spec, git-tracked |
| `nvim/.config/nvim/lazy-lock.json` | nvim-surround 40-hex pin, prior pins retained | ✓ VERIFIED | 40 entries, all match installed HEADs; pin genuine (v4.0.5) |
| `nvim/.config/nvim/README.md` | buffer-cycle caveat | ✓ VERIFIED | 35 lines; `## Keymaps` subsection with both caveats |

**Artifacts:** 7/7 verified.

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `<leader>vd` | `vim.diagnostic.open_float` | inline Lua callback in keymaps.lua | ✓ WIRED | VD-BEHAVIOR-OK opened a real float |
| `signcolumn=yes:4` | scrollview gutter / gitsigns signs | four-cell layout | ✓ WIRED | options + scrollview options verified together |
| `winblend_gui=100` | hidden scrollbar | scrollview.setup options | ✓ WIRED | SCROLLVIEW-OPTS-OK |
| surround.lua spec | lockfile pin → installed plugin → visual `S` | lazy spec → pin → plugin keymaps | ✓ WIRED | pin genuine + SURROUND-WRAP-OK |
| `<C-,>`/`<C-.>` lhs | BufferLine next/prev commands | normal-mode keymaps | ✓ WIRED | BUFFER-MAPS-OK |

**Wiring:** 5/5 verified.

### Data-Flow Trace (Level 4)

Not applicable — this phase produces static Neovim configuration (keymaps/options/plugin specs), not dynamic data-rendering artifacts. The relevant runtime wiring is covered by the headless probes above.

### Requirements Coverage

| Requirement | Source | Description | Status | Evidence |
|-------------|--------|-------------|--------|----------|
| QOL-01 | REQUIREMENTS.md:46 | `<leader>vd` full diagnostic float, no wrapping/Trouble | ✓ SATISFIED | VD-SOURCE-OK, VD-BEHAVIOR-OK, HOVER-UNCHANGED, no trouble/wrapping changes |
| QOL-02 | REQUIREMENTS.md:47 | dead keymaps removed, group label retitled | ✓ SATISFIED | DEAD-MAPS-CLEAN, SURVIVORS-OK, WK-LABEL-OK, WK-SPEC-OK |
| QOL-03 | REQUIREMENTS.md:48 | scrollview far-left gutter, hidden bar, blank separator | ✓ SATISFIED | SCROLLVIEW-OPTS-OK, signcolumn=yes:4 (visual confirm delegated to human) |
| QOL-04 | REQUIREMENTS.md:49 | nvim-surround installed, default keymaps, pinned | ✓ SATISFIED | SURROUND-PIN-OK, SURROUND-SPEC-OK, SURROUND-KEYMAPS-OK, SURROUND-WRAP-OK |
| QOL-05 | REQUIREMENTS.md:50 | `<C-,>`/`<C-.>` cycle buffers, Tab freed, caveat documented | ✓ SATISFIED | BUFFER-MAPS-OK, CAVEAT-DOC-OK (live terminal delivery delegated to human) |
| QOL-06 | REQUIREMENTS.md:51 | smoothscroll removed, no cursor-jump claims | ✓ SATISFIED | SMOOTH-CLEAN, repo-wide scan |

**Coverage:** 6/6 requirements satisfied. All 6 IDs declared in the PLAN frontmatter `requirements` field and all 6 mapped to Phase 7 in REQUIREMENTS.md traceability — no orphaned requirements.

### Decision Coverage

CONTEXT.md locked decisions D-1..D-6 (diagnostics built-in/no Trouble; stale keymap removal; scrollview far-left + signcolumn; nvim-surround install+pin; buffer rebind; smoothscroll removal cosmetic-only) all appear in the SUMMARY `key-decisions` and are reflected verbatim in the shipped files. Cursor-jump investigation remained out of scope in every artifact. Coverage: 6/6 honored. (Warning-only gate; CONTEXT.md `<decisions>` block checked manually since `gsd_run` is unavailable.)

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none | — | Debt-marker scan found no TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER in changed files (the sole `TODO` hit at `keymaps.lua:145` is a legitimate `TodoFzfLua keywords=TODO,FIX,FIXME` keymap, not a marker). No stub/empty implementations. Working tree clean. |

**Anti-patterns:** 0 blockers, 0 warnings.

### Documented Deviation — Lockfile Force-Add

The SUMMARY records that `lazy-lock.json` is gitignored (`.gitignore:5` and `:22`) and was force-added (`git add -f`) so the required committed pin would land — committed in `a986fca`. Independently verified:
- `git ls-files` lists `nvim/.config/nvim/lazy-lock.json` — it is tracked.
- Pin at line 26 is `2e93e154de9ff326def6480a4358bfc149d5da2c`, which equals the installed plugin's HEAD (tag `v4.0.5`) — genuine, not fabricated.
- The lockfile has 40 entries (39 prior + nvim-surround); **every** entry's commit matches its installed plugin HEAD, confirming all prior pins were retained. Deployed `~/.config/nvim/lazy-lock.json` is byte-identical in keys to the repo copy.
- All three task commits (`5e4f704`, `68514df`, `a986fca`) exist and are reachable; working tree is clean.

Deviation is acceptable and necessary to satisfy the plan's explicit "committed 40-hex pin" requirement. No override needed.

### Human Verification Required

All implementation and headless-behavior checks pass. Three items are visual/live and genuinely require a human terminal:

**1. Scrollview gutter rendering (QOL-03)**
- **Test:** Open a git-tracked file with uncommitted changes in Alacritty and inspect the left gutter.
- **Expected:** git markers in the far-left gutter (col 1), invisible scrollbar, blank separator before gitsigns' native per-line signs, separator intact even when a native diagnostic sign and a gitsigns sign share a line.
- **Why human:** visual/window-layout rendering — headless proves the options passed to `scrollview.setup()` and `signcolumn=yes:4`, not the rendered pixels.

**2. Terminal delivery of `<C-,>`/`<C-.>` in Alacritty (QOL-05)**
- **Test:** With ≥2 buffers open in a real Alacritty terminal, press `<C-,>`/`<C-.>` in normal mode; if nothing happens, test `<C-v><C-,>` in insert mode.
- **Expected:** next/previous buffer switch; if the sequence is swallowed, add an Alacritty `key_bindings` entry for Ctrl+comma/Ctrl+period.
- **Why human:** external terminal key delivery — Alacritty uses `TERM=xterm-256color` with no custom `key_bindings`; headless `maparg` proves the bindings exist but cannot prove the terminal emits the sequences. This is the caveat the plan itself flagged.

**3. Diagnostic float visual (QOL-01) — confirmatory**
- **Test:** Trigger `<leader>vd` on a line carrying a diagnostic.
- **Expected:** rounded-border float shows the full current-line message; virtual text unchanged.
- **Why human:** visual appearance; headless already proved a float opens with `border=rounded` configured, so this is a quick sanity check, not a blocking unknown.

### Gaps Summary

**No gaps found.** All 6 must-haves, 7 artifacts, 5 key links, and 6 requirements are satisfied by direct codebase evidence and re-run behavioral probes. The only outstanding work is human confirmation of three visual/live items, which are inherent to a terminal-config phase and were explicitly called out by the plan (not defects). Status `human_needed` reflects that, not an implementation shortfall.

---
*Verified: 2026-11-23T12:48:51Z*
*Verifier: the agent (gsd-verifier subagent)*
