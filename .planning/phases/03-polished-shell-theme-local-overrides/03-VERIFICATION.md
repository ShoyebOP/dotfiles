---
phase: 03-polished-shell-theme-local-overrides
verified: 2026-09-17T07:57:11Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/6
  gaps_closed:
    - "T5 preview reachability: full `bash setup.sh --mode server --shell zsh --dry-run` now prints the local-file Would-run marker with zero writes (ensure_local_files called at setup.sh:1999 inside the DRY_RUN preview branch)"
  gaps_remaining: []
  regressions: []
gaps:
  - truth: "User types and the async completion list auto-shows below the prompt with no keypress; Tab only enters menu-select; ghost autosuggestion text still renders (SHEL-02 per D-04/D-05)"
    status: failed
    reason: "Code is present, substantive, and correctly wired (all greps pass, no zshrc change since prior verification), but the human live-shell check returned an explicit FAIL: typing 2-3 characters and pausing shows no auto completion list. User directive defers the fix to a separate future phase — no code was attempted here, so the must-have remains unmet in the codebase."
    artifacts:
      - path: "zsh/.zshrc"
        issue: "Plugin block (autosuggestions + autocomplete-last + single ^I binding) is wired but does not produce the auto-show behavior at runtime — root cause unknown, needs a dedicated diagnosis/fix phase"
    missing:
      - "A dedicated follow-up phase diagnosing why marlonrichert/zsh-autocomplete does not auto-show on this machine (load order vs atload vs terminal/widget conflict) and fixing typing auto-show + Tab menu-select + ghost text"
---

# Phase 03: Polished Shell, Theme & Local Overrides Verification Report

**Phase Goal:** Daily Zsh feels finished — history search just works, PATH is stable, machine-local tweaks stay gitignored, theme is consistent
**Verified:** 2026-09-17T07:57:11Z
**Status:** gaps_found
**Re-verification:** Yes — gaps-only re-verification after gap-closure plan 03-02 (prior 03-VERIFICATION.md: gaps_found, 3/6, 1 gap T5 + 2 behavior-unverified)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ------- | ---------- | -------------- |
| 1 | User presses Ctrl+R and gets fzf history search, or a visible warning telling them to install fzf — never a silent dead key (SHEL-02 per D-03) | ✓ VERIFIED | Present + wired as before (`zi light joshskidmore/zsh-fzf-history-search` :308 < autocomplete-last :314; unconditional `bindkey '^R' fzf-history-widget` :341 + `zle -l` yellow WARN guard :342-344; 3-rung `sort -V` 0.48 ladder :324-335 incl. Debian `doc/examples` rung). Behavior now exercised: human live-shell check **PASSED** (history-search UI works — verbatim verdict in 03-02-SUMMARY.md, confirmed by orchestrator context). |
| 2 | User types and the async completion list auto-shows below the prompt with no keypress; Tab only enters menu-select; ghost autosuggestion text still renders (SHEL-02 per D-04/D-05) | ✗ FAILED | Present + wired (autosuggestions atload `_zsh_autosuggest_start` :291-296 untouched; fast-syntax-highlighting untouched; autocomplete last with byte-identical `^I menu-select` atload :311-314; exactly one `^I` binding repo-wide), but the human live-shell check **FAILED**: typing 2-3 characters and pausing shows no auto-show list. No code change attempted per user directive (deferred to a separate future phase). See Gaps Summary. |
| 3 | User reloads the shell repeatedly and PATH has zero duplicates while z, zi, zoxide, completions, and the p10k prompt still work (SHEL-03 per D-09) | ✓ VERIFIED | Unregressed (03-02 touched only setup.sh — `git show 62557f7 --stat` confirms setup.sh +2 lines). `typeset -U path` :38 < first `export PATH` :40; tail `path=( $path )` :445. Verifier re-ran the hermetic triple-source check: `reload-ok` (zero dupes after 3 sources). |
| 4 | User drops personal tweaks in HOME ~/.zshrc.local and the deployed nvim local.lua and they take effect without dirtying git; a fresh clone works with both files absent (SHEL-04, EDIT-04 per D-10/D-11) | ✓ VERIFIED | Unregressed. Tail guard :370 after zoxide init :58, before p10k apply :371; `pcall(require, "local")` init.lua:91-94 silent-absent + WARN-only-broken; `nvim --headless -c 'qa!'` exit 0 re-confirmed; `check-ignore` succeeds for all 3 local/history paths, fails (correctly) for both `*.example` templates. |
| 5 | User runs setup.sh --dry-run and sees the local-file preview with zero writes; a live run creates empty HOME files without truncating existing ones (SHEL-04, EDIT-04 per D-12) | ✓ VERIFIED | **Gap T5 CLOSED and re-proven by verifier:** `ensure_local_files` now called at setup.sh:1999 inside the DRY_RUN preview branch (after chsh preview block, before `DRY RUN complete` + `return 0`), inheriting `DRY_RUN=true`. Full `bash setup.sh --mode server --shell zsh --dry-run` output contains `[DRY RUN] Would run: touch HOME ~/.zshrc.local (if absent) and deployed nvim lua/local.lua (if absent)` (full-preview-ok). Sourced `DRY_RUN=true` run creates nothing and preserves seeded `keepme` (sourced-preview-clean). Stub-HOME live run creates the deployed lua file, second run is a no-op, seeded content survives (live-idempotent-no-truncate — all re-run by verifier). |
| 6 | No per-app appearance file is modified and no theme token, installer theme function, or mismatch warning is added anywhere (THEM-01 closed as intended-drift per D-13) | ✓ VERIFIED | Unregressed. 03-02 diff is setup.sh only (+2 lines: why-comment + bare call). Appearance-routine absence probe returns 0; zero `alacritty/` / `starship/` / `colorschemes/` / `p10k` touches across all 4 task commits. All 3 prohibitions hold. |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `zsh/.zshrc` | PATH dedup guard, repaired plugin block, version-branched fzf init, unconditional Ctrl+R bind with warning, HOME-only local tail guard, portable bun source | ✓ VERIFIED | Unchanged since 03-01 (no 03-02 diff). 445 lines; all prior greps re-pass; `zsh -n` passes |
| `nvim/.config/nvim/init.lua` | Machine-local override load as last startup step, silent when absent, warning when broken | ✓ VERIFIED | Unchanged; `pcall(require, "local")` :91-94; headless exit 0 re-confirmed |
| `.gitignore` | Machine-local gitignore section covering local overrides and shell history | ✓ VERIFIED | Unchanged; lines 17-20; all 5 check-ignore gates re-pass |
| `setup.sh` | DRY_RUN-safe post-stow bootstrap creating empty HOME local files only when absent, **surfaced in the dry-run preview path** | ✓ VERIFIED | `ensure_local_files` :779-793 unchanged; **new call :1999 inside DRY_RUN branch** (the T5 fix); live call :2021 untouched; `bash -n` passes; full-preview + live-idempotent probes re-pass |
| `zsh/.zshrc.local.example` | Documented shell template | ✓ VERIFIED | Unchanged; committable, docs-only |
| `nvim/.config/nvim/lua/local.lua.example` | Documented editor template | ✓ VERIFIED | Unchanged; committable, docs-only |
| `README.md` | Machine-local overrides docs with HOME-only paths and copy-from-template commands | ✓ VERIFIED | Unchanged; `## Machine-local overrides` :140 + template filename greps pass |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| zsh/.zshrc plugin load order (fzf-history-search own light, autocomplete last) | bindkey Ctrl+R target widget | Repaired load above the unconditional bind | ✓ WIRED | :308 < :314; bind :341; unchanged |
| typeset -U path position near top | All later PATH exports | Forward-looking unique attribute + tail re-assertion | ✓ WIRED | :38 < :40; tail :445; reload-ok re-passes |
| HOME local guard position (after tool inits, before p10k apply) | User prompt and alias overrides rendering | Load-bearing tail slot | ✓ WIRED | :58 < :370 < :371; unchanged |
| setup.sh ensure_local_files HOME-derived paths | Deployed ~/.zshrc.local and ~/.config/nvim/lua/local.lua | HOME at runtime, never repo dir | ✓ WIRED | `$HOME`-derived :780-782; zero repo-dir refs |
| main DRY_RUN preview branch (preview_selection + chsh preview + return 0) | ensure_local_files bootstrap | **NEW 03-02 link:** bare call inherits DRY_RUN=true, hits early preview return before any write | ✓ WIRED | Call at :1999 strictly between `preview_selection` line and `DRY RUN complete` line (ordering probe passes); full dry-run prints the marker |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| zsh/.zshrc local guard | `$HOME/.zshrc.local` → shell env | HOME-owned file at tail | ✓ FLOWING (unchanged, prior marker proof stands) | ✓ FLOWING |
| nvim init.lua local tail | `require("local")` → editor state | Deployed lua file | ✓ FLOWING (unchanged; absent exit 0 re-confirmed) | ✓ FLOWING |
| setup.sh ensure_local_files | `$HOME` → two deployed files | Runtime `$HOME` | ✓ FLOWING (live create + idempotent + no-truncate re-proven; **preview path now flows the Would-run marker to stdout with zero writes**) | ✓ FLOWING |
| fzf ladder | `fzf --version` → branch | System fzf binary | ✓ FLOWING (unchanged) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| zsh syntax | `zsh -n zsh/.zshrc` | `syntax-ok` | ✓ PASS |
| PATH triple-source convergence | hermetic ZDOTDIR triple-source pipe | `reload-ok` (re-run) | ✓ PASS |
| nvim silent-absent start | `nvim --headless -c 'qa!'` | exit 0 | ✓ PASS |
| Locals ignored, templates committable | `git check-ignore` (3 must-ignore, 2 must-not) | all 5 as expected | ✓ PASS |
| setup.sh syntax | `bash -n setup.sh` | `setup-syntax-ok` | ✓ PASS |
| **Full --dry-run shows local-file preview** | `bash setup.sh --mode server --shell zsh --dry-run` grep marker | `[DRY RUN] Would run: touch HOME ~/.zshrc.local ...` present | ✓ PASS (was ✗ FAIL — **T5 closed**) |
| Sourced preview zero-write + seed preservation | `DRY_RUN=true ensure_local_files` under stub HOME | marker printed, nothing created, `keepme` intact | ✓ PASS |
| Live create + idempotent + no-truncate | stub-HOME live run ×2 with `keepme` seed | created, preserved across rerun | ✓ PASS |
| Ctrl+R history UI (human) | live interactive shell, press Ctrl+R | works per verbatim verdict | ✓ PASS (human) |
| Typing auto-show (human) | live interactive shell, type 2-3 chars + pause | **did NOT work** per verbatim verdict | ✗ FAIL (human) |
| Dry-run preview readability (human) | eyeball full dry-run output | **NOT TESTED** — user will test later | ? SKIP (human) |
| README docs | greps `Machine-local` + `zshrc.local.example` | `docs-ok` | ✓ PASS |
| History untracked, working file intact | `git ls-files` + prior size check | `history-untracked` | ✓ PASS |

### Probe Execution

SKIPPED — no probes declared or implied for this phase (same as prior verification; no `scripts/*/tests/probe-*.sh` exist).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| SHEL-02 | 03-01 | Fuzzy history via fzf without conflicts | ⚠️ PARTIAL | Ctrl+R half SATISFIED (wired + human PASS). Typing auto-show half BLOCKED (human FAIL, gap below) |
| SHEL-03 | 03-01 | PATH deduped and stable | ✓ SATISFIED | reload-ok re-passes; guard position verified |
| SHEL-04 | 03-01 + 03-02 | Machine-local Zsh overrides, gitignored + bootstrapped + previewed | ✓ SATISFIED | Guard + templates + live bootstrap + **preview reachability now proven at the documented command** |
| EDIT-04 | 03-01 + 03-02 | Machine-local Neovim overrides via gitignored local.lua | ✓ SATISFIED | pcall tail + silent-absent exit 0; preview half shared with SHEL-04 via the same marker |
| THEM-01 | 03-01 | Theme consistency | ✓ SATISFIED as intended-drift closure | Zero theme code (absence probe 0); 03-02 diff is setup.sh-only |

Orphaned requirements check: REQUIREMENTS.md maps exactly SHEL-02, SHEL-03, SHEL-04, EDIT-04, THEM-01 to Phase 3 — 03-01-PLAN.md frontmatter `requirements:` carries all five; 03-02-PLAN.md frontmatter carries the gap requirements SHEL-04 + EDIT-04. SUMMARies report `requirements-completed: [SHEL-02, SHEL-03, SHEL-04, THEM-01, EDIT-04]` (03-01) and `[SHEL-04, EDIT-04]` (03-02). Zero orphaned. Every phase requirement ID is accounted for.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No `TBD`/`FIXME`/`XXX` in any phase-touched file (grep exit 1) | — | None — clean |
| — | — | No `TODO`/`HACK`/`PLACEHOLDER` in phase files or templates (grep exit 1) | — | None — clean |
| — | — | No stub returns, empty handlers, or hardcoded-empty renders | — | None — absent local files are guarded-source/pcall by design, not stubs |

Commits verified present: `15c1a9b` (tracer), `4466643` (editor+gitignore+templates), `250aceb` (installer+docs), `62557f7` (03-02 preview-path call, setup.sh +2 lines). Working tree clean (`git status --short` empty).

### Human Verification Required

Status is `gaps_found`, so no blocking human-verification gate is emitted. One residual non-blocking human item is recorded here for the record (does not affect the truth table — Truth 5's functional assertion "preview appears with zero writes" is proven automatically; only the readability judgment is pending):

- **Dry-run preview readability — NOT TESTED.** Re-run `bash setup.sh --mode server --shell zsh --dry-run` and confirm the `[DRY RUN] Would run: touch HOME ~/.zshrc.local (if absent) and deployed nvim lua/local.lua (if absent)` lines read clearly alongside the existing selection and chsh previews. User will test on their own schedule per 03-02-SUMMARY.md.

### Gaps Summary

One gap blocks a clean pass. The 03-02 closure finished its code job completely, and the phase goal is otherwise met:

1. **Typing auto-show feel (Truth 2, SHEL-02 half) — the remaining gap:** the plugin block is present, substantive, and correctly wired (including the genuine bug-fixes 03-01 found: own `zi light` for the silently-never-loading plugin, tail `path=( $path )` for scalar-export bypass, Debian legacy fzf rung). But the runtime behavior fails — a human typing 2-3 characters and pausing sees no auto-show list. Root cause is undiagnosed (load order vs atload vs widget/terminal conflict). Per explicit user directive ("keep it here, complete the phase; they will add a different phase to fix issue 1 specifically"), no fix was attempted and no scope was added here — honestly recorded as FAILED, not waived.
2. **T5 preview reachability — CLOSED:** verified fixed at the exact documented command with zero writes; live idempotence and no-truncate re-proven. Removed from gaps.
3. **Ctrl+R feel — CLOSED by human PASS.** Dry-run readability — untested nicety, non-blocking (see above).

No deferred items against the current milestone: Phase 4 (EDIT-01/02/03, HLTH-01) covers Neovim autonomy and headless health gates — nothing in its goal or success criteria covers zsh-autocomplete interactive feel, so the Truth-2 gap is a real gap, not future roadmap work. (The user-promised dedicated fix phase does not exist in the roadmap yet; it must be planned as new scope. The full history/secret purge stays deferred to v2 SECR-02 by design.)

**Suggested next step:** `/gsd-plan-phase --gaps` against this report will produce the minimal follow-up plan (diagnose + fix typing auto-show), or the user may add the promised separate phase manually.

---
_Verified: 2026-09-17T07:57:11Z_
_Verifier: the agent (gsd-verifier)_
