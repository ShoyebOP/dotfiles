---
phase: 03-polished-shell-theme-local-overrides
verified: 2026-09-17T13:30:00Z
status: gaps_found
score: 3/6 must-haves verified
behavior_unverified: 2
overrides_applied: 0
gaps:
  - truth: "User runs setup.sh --dry-run and sees the local-file preview with zero writes; a live run creates empty HOME files without truncating existing ones (SHEL-04, EDIT-04 per D-12)"
    status: partial
    reason: "Live half fully proven (creates both empty HOME files, idempotent, never truncates). Preview half fails at the documented user command: full `bash setup.sh --mode server --shell zsh --dry-run` never prints the local-file Would-run lines because main's DRY_RUN branch returns before reaching ensure_local_files (line ~2019, live path only). The Would-run preview exists only at function level (sourced DRY_RUN=true invocation). SUMMARY.md admits this exact limitation and defers it as a future pass."
    artifacts:
      - path: "setup.sh"
        issue: "ensure_local_files is called only in the live path after post_verify; the DRY_RUN preview path (preview_selection + chsh preview + return 0) never invokes it, so users previewing with --dry-run never see the local-file lines"
    missing:
      - "Invoke ensure_local_files (already DRY_RUN-safe: prints Would-run and returns before any write) from the DRY_RUN preview path in main before `return 0`, or emit the equivalent Would-run lines from preview_selection — then re-run full --dry-run and grep for zshrc.local"
behavior_unverified_items:
  - truth: "User presses Ctrl+R and gets fzf history search, or a visible warning telling them to install fzf — never a silent dead key (SHEL-02 per D-03)"
    test: "Open one interactive Zsh (fresh login shell on this machine), then press Ctrl+R and type a fragment of a previous command"
    expected: "An fzf fuzzy history UI appears with matching entries (fzf installed here, ladder should take the live branch); on a machine without fzf, a yellow WARN naming the install action appears instead of a dead key — either outcome, never silence"
    why_human: "Presence + wiring (unconditional bind, zle-list WARN guard, 3-rung version ladder) are proven by grep, but the keypress-to-UI transition cannot be exercised headlessly — the widget only exists after Zinit loads the plugin in a live interactive shell"
  - truth: "User types and the async completion list auto-shows below the prompt with no keypress; Tab only enters menu-select; ghost autosuggestion text still renders (SHEL-02 per D-04/D-05)"
    test: "In the same interactive shell, type 2-3 characters of a known command/path and pause without pressing Tab; then press Tab; also confirm the p10k prompt renders normally"
    expected: "A completion list appears automatically below the prompt (no keypress); Tab moves into menu-select; faint ghost autosuggestion text still renders alongside; prompt renders with no errors"
    why_human: "Load order (fzf-history-search before autocomplete-last), single ^I binding, and all three plugins coexisting are proven by grep, but typing-to-list-appears is a runtime async transition no headless test exercises — it needs human eyes per the plan's own end-of-phase human check"
---

# Phase 03: Polished Shell, Theme & Local Overrides Verification Report

**Phase Goal:** Polished Shell, Theme & Local Overrides — daily Zsh feels finished (history search, stable PATH, machine-local overrides, theme closure)
**Verified:** 2026-09-17T13:30:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification (no prior VERIFICATION.md found)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ------- | ---------- | -------------- |
| 1 | User presses Ctrl+R and gets fzf history search, or a visible warning telling them to install fzf — never a silent dead key (SHEL-02 per D-03) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Present + wired: `zi light joshskidmore/zsh-fzf-history-search` (zsh/.zshrc:308) precedes autocomplete-last (:314, order-ok proven); unconditional `bindkey '^R' fzf-history-widget` (:341) + `zle -l` guard printing yellow WARN install-fzf message (:342-344); `sort -V` 0.48 branch + 2 legacy rungs incl. Debian `doc/examples` path (:324-335). Keypress→UI transition unexercised headlessly — see behavior item 1. |
| 2 | User types and the async completion list auto-shows below the prompt with no keypress; Tab only enters menu-select; ghost autosuggestion text still renders (SHEL-02 per D-04/D-05) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Present + wired: autosuggestions with `_zsh_autosuggest_start` atload (:291-296) untouched, fast-syntax-highlighting untouched (:299-300), autocomplete last with byte-identical `^I menu-select` atload (:311-314), exactly one `^I` binding repo-wide, no `^I` rebind in fzf branch. Typing→auto-show transition unexercised headlessly — see behavior item 2. |
| 3 | User reloads the shell repeatedly and PATH has zero duplicates while z, zi, zoxide, completions, and the p10k prompt still work (SHEL-03 per D-09) | ✓ VERIFIED | `typeset -U path` at line 38 precedes first `export PATH` at line 40 (guard-on-top awk passes); convergent tail `path=( $path )` at line 445 (last PATH line). Behaviorally proven: plan's hermetic triple-source command re-run by verifier prints `reload-ok` (zero dupes after 3 sources); isolated zsh demo confirms scalar `export PATH=` bypasses `-U` at assignment (2 occurrences) and the tail re-assertion retro-dedupes (1 occurrence). zoxide/p10k/completions lines untouched; tools-confirm rides with the interactive human check. |
| 4 | User drops personal tweaks in HOME ~/.zshrc.local and the deployed nvim local.lua and they take effect without dirtying git; a fresh clone works with both files absent (SHEL-04, EDIT-04 per D-10/D-11) | ✓ VERIFIED | Shell: tail guard `[[ -f "$HOME/.zshrc.local" ]] && source` at :370 sits after `zoxide init` (:58) and before p10k apply (:371) — position load-bearing and correct; marker spot-check (`export PHASE3_VERIFY_MARKER`) sources ok. Editor: `pcall(require, "local")` tail at init.lua:91-94 after the colorscheme schedule block, silent-when-absent + WARN-only-when-broken; `nvim --headless -c 'qa!'` exits 0 with override absent; luafile marker mechanism proven. Git: `check-ignore` succeeds for `zsh/.zshrc.local`, `nvim/.config/nvim/lua/local.lua`, `zsh/.zsh_history`; fails (correctly) for both `*.example` templates; no real local/history file tracked. |
| 5 | User runs setup.sh --dry-run and sees the local-file preview with zero writes; a live run creates empty HOME files without truncating existing ones (SHEL-04, EDIT-04 per D-12) | ✗ FAILED (partial) | Live half PASSES: stub-HOME run creates both empty files; second run is a no-op; pre-existing content (`keepme`) never truncated; parent-dir + `$HOME` guards present. Preview half FAILS: full `bash setup.sh --mode server --shell zsh --dry-run` output contains no `zshrc.local`/`local.lua` Would-run lines — main's DRY_RUN branch (preview_selection + chsh preview + `return 0`) returns before `ensure_local_files` (live path only, ~line 2019). Function-level `DRY_RUN=true` sourced invocation prints the preview and writes nothing, but that is not the documented `setup.sh --dry-run` command. SUMMARY.md acknowledges this exact limitation as a future pass. |
| 6 | No per-app appearance file is modified and no theme token, installer theme function, or mismatch warning is added anywhere (THEM-01 closed as intended-drift per D-13) | ✓ VERIFIED | Change set across the 3 task commits is exactly the 7 plan paths + intended history index removal (`D zsh/.zsh_history`); zero appearance files (`alacritty/`, `starship/`, `colorschemes/`, `p10k`) touched. Grep for `apply_theme`, `THEME` token, mismatch warnings (excl. intended-drift comments) is empty. All 3 prohibitions hold: no theme code; HOME-only sourcing with no repo-side local file and no committed locals/history; fzf probes all `|| true`-guarded with no abort path. |

**Score:** 3/6 truths verified (2 present, behavior-unverified)

**This looks intentional (T5 wording vs plan instruction).** The plan explicitly instructed leaving the DRY_RUN early-return branch untouched, while the must-have truth promises a local-file preview under `setup.sh --dry-run`. If the developer accepts function-level preview as sufficient, add to VERIFICATION.md frontmatter:

```yaml
overrides:
  - must_have: "User runs setup.sh --dry-run and sees the local-file preview with zero writes"
    reason: "Preview proven at function level (DRY_RUN=true sourced invocation prints Would-run, writes nothing); full-run preview deferred per plan instruction to leave the DRY_RUN branch untouched — live bootstrap fully working"
    accepted_by: "{name}"
    accepted_at: "{ISO timestamp}"
```

Then re-run verification to apply. Otherwise the one-line fix is to call the already-DRY_RUN-safe `ensure_local_files` from the dry-run preview path before `return 0`.

### Roadmap Literal Deltas (user-approved reshapes, override candidates)

The plan documents three explicit deltas from ROADMAP.md Phase 3 text (03-01-PLAN.md objective + 03-CONTEXT.md D-01/D-10/D-13). Verified literally:

| Roadmap SC | Literal text | Implementation | Assessment |
|---|---|---|---|
| SC1 | one-history-plugin policy resolves autocomplete vs fzf-history-search | BOTH kept with split ownership (^R fzf, ^I autocomplete) per D-01 | Intentional deviation (user override); wiring correct for the reshaped intent |
| SC3 | `~/.zshrc.local` AND `zsh/.zshrc.local` auto-sourced | HOME-only `~/.zshrc.local` sourced; no repo-side file per D-10 | Intentional deviation (user verbatim "only stay at home"); implemented exactly as decided |
| SC5 | single `THEME` token + `setup.sh apply_theme()` warns | Zero theme code; closed as intended-drift per D-13 | Intentional deviation (user verbatim "intended drift"); zero-code proven |
| SC2 | `typeset -U path` dedupes PATH | Implemented + convergent tail; reload-ok re-run passes | ✓ Literal PASS |
| SC4 | `pcall(require,"local")` + gitignore + example | Implemented exactly; all gates pass | ✓ Literal PASS |

Suggested overrides if the developer wants the roadmap-literal trace to read green (each cites the CONTEXT decision that already records user approval):

```yaml
overrides:
  - must_have: "one history plugin policy resolves marlonrichert/zsh-autocomplete vs joshskidmore/zsh-fzf-history-search"
    reason: "Superseded by D-01 (user decision): keep BOTH with split ownership — Ctrl+R belongs to fzf-history-search, Tab belongs to autocomplete; load order + bindings verified"
    accepted_by: "{name}"
    accepted_at: "{ISO timestamp}"
  - must_have: "User creates ~/.zshrc.local and zsh/.zshrc.local and sees both auto-sourced"
    reason: "Superseded by D-10 (user verbatim HOME-only): only HOME ~/.zshrc.local is sourced; repo-side file intentionally never sourced so machine secrets never dirty git"
    accepted_by: "{name}"
    accepted_at: "{ISO timestamp}"
  - must_have: "single THEME token and setup.sh apply_theme() warns on mismatch"
    reason: "Dropped by D-13 (user verbatim intended drift): alacritty mocha / starship latte / nvim tokyodark / p10k mocha mapping left alone with zero theme code — change-set gate enforces it"
    accepted_by: "{name}"
    accepted_at: "{ISO timestamp}"
```

These are NOT applied (no human acceptance on record) and do NOT affect the score above; they exist so the next verification run can honor them.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `zsh/.zshrc` | PATH dedup guard, repaired plugin block, version-branched fzf init, unconditional Ctrl+R bind with warning, HOME-only local tail guard, portable bun source | ✓ VERIFIED | 445 lines; `typeset -U path` :38 pre-export; own `zi light` for fzf-history-search :308 before autocomplete-last :314; 3-rung ladder + WARN block :324-344; guard :370 correctly positioned; bun `$HOME` form :438; tail `path=( $path )` :445; `zsh -n` passes |
| `nvim/.config/nvim/init.lua` | Machine-local override load as last startup step, silent when absent, warning when broken | ✓ VERIFIED | `pcall(require, "local")` :91-94 after colorscheme schedule :84-87; absent→silent (match on `module 'local' not found`), broken→WARN, never ERROR/abort; headless start exits 0 |
| `.gitignore` | Machine-local gitignore section covering local overrides and shell history | ✓ VERIFIED | Lines 17-20: `*.local`, deployed `local.lua`, `zsh/.zsh_history` with header comment; existing entries byte-identical; check-ignore gates pass |
| `setup.sh` | DRY_RUN-safe post-stow bootstrap creating empty HOME local files only when absent | ✓ VERIFIED | `ensure_local_files` :779-793 (DRY_RUN preview branch, `[[ -d $HOME ]]` + `mkdir -p` guards, create-only-when-absent `|| touch` / `if ! -f`); called in live path after `post_verify`, before chsh offer (:2019); `bash -n` passes; live/idempotent/no-truncate proven |
| `zsh/.zshrc.local.example` | Documented shell template (PATH prepend, prompt tweak, alias) | ✓ VERIFIED | 23 lines; names HOME destination as only valid copy target; warns real file never committed; docs-only (nothing sources it); committable (not ignored) |
| `nvim/.config/nvim/lua/local.lua.example` | Documented editor template (option tweak, keymap) | ✓ VERIFIED | 17 lines; names deployed HOME path as only valid copy target; notes silent no-op when absent; docs-only; committable (not ignored) |
| `README.md` | Machine-local overrides docs with HOME-only paths and copy-from-template commands | ✓ VERIFIED | `## Machine-local overrides` section (:140-157): destination table, both `cp ...example` commands, absent-means-silent + git-stays-clean notes, `--dry-run` preview note |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| zsh/.zshrc plugin load order (fzf-history-search own light, autocomplete last) | bindkey Ctrl+R target widget | Widget exists only if its plugin actually loads; bare ice line loads nothing, so unconditional bind needs repaired load above it | ✓ WIRED | `zi light joshskidmore/zsh-fzf-history-search` :308 < `zi light marlonrichert/zsh-autocomplete` :314; `bindkey '^R' fzf-history-widget` :341; pattern `zi light joshskidmore/zsh-fzf-history-search` present |
| typeset -U path position near top | All later PATH exports (top five, polaris append, bun, fpath) | Unique attribute is forward-looking; anything above the guard keeps dupes, so placement above first export is what makes repeat sourcing converge | ✓ WIRED | Guard :38 < first export :40 (awk passes); tail `path=( $path )` :445 retro-dedupes scalar-assignment bypass (demonstrated: 2→1 occurrences); pattern `typeset -U path` present |
| HOME local guard position (after tool inits, before p10k apply) | User prompt and alias overrides rendering | Sourcing before zoxide init gets clobbered; after prompt apply never renders, so tail slot is load-bearing | ✓ WIRED | zoxide :58 < guard :370 < p10k source :371 < `apply_catppuccin` :374; pattern `.zshrc.local` present; marker sourcing proven |
| setup.sh ensure_local_files HOME-derived paths | Deployed ~/.zshrc.local and ~/.config/nvim/lua/local.lua | Paths derive from HOME at runtime and never under repo dir, keeping working tree clean | ✓ WIRED | `$HOME/.zshrc.local` + `$HOME/.config/nvim/lua/local.lua` (:780-782); zero `SCRIPT_DIR` refs in function; pattern `ensure_local_files` present with call in live path |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| zsh/.zshrc local guard | `$HOME/.zshrc.local` content → shell env | HOME-owned file sourced at tail | ✓ FLOWING (marker `PHASE3_VERIFY_MARKER=local-sourced-ok` round-trips through the exact guard line) | ✓ FLOWING |
| nvim init.lua local tail | `require("local")` → editor state | Deployed `~/.config/nvim/lua/local.lua` via stow | ✓ FLOWING (luafile marker round-trips; absent→silent no-op with exit 0; broken→WARN, startup continues) | ✓ FLOWING |
| setup.sh ensure_local_files | `$HOME` → two deployed files | Runtime `$HOME`, never repo dir | ✓ FLOWING (live stub-HOME run creates both empty files; second run no-op; existing content preserved) | ✓ FLOWING |
| fzf ladder | `fzf --version` → branch selection | System fzf binary when present | ✓ FLOWING (canned `0.44.1`→legacy / `0.49.0`→modern `sort -V` assertions pass; absent→WARN fallthrough, no abort) | ✓ FLOWING |

No hollow props, no static fallbacks masquerading as data, no disconnected renders found.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| zsh syntax | `zsh -n zsh/.zshrc` | `syntax-ok`, exit 0 | ✓ PASS |
| PATH guard on top | plan awk (`typeset -U` line < first `export PATH`) | `guard-on-top` | ✓ PASS |
| Plugin order (fzf before autocomplete-last) | grep line-number compare (308 < 314) | `order-ok` | ✓ PASS |
| Ctrl+R bind + sort -V + local guard present | 3 greps | `wiring-ok` | ✓ PASS |
| Version-branch numeric compare | canned `sort -V` head assertions | `probe-logic-ok` | ✓ PASS |
| Triple-source PATH convergence | plan hermetic `ZDOTDIR` triple-source pipe | `reload-ok` (re-run by verifier) | ✓ PASS |
| PATH mechanism (scalar bypass + tail retro-dedupe) | isolated `zsh -c` demo | 2 occurrences → 1 after `path=( $path )` | ✓ PASS |
| Shell local take-effect | marker file + exact guard line under stub HOME | `marker=local-sourced-ok` | ✓ PASS |
| Nvim override mechanism + silent-absent | `luafile` marker + `nvim --headless -c 'qa!'` | `marker=local-loaded-ok`; absent exit 0 | ✓ PASS |
| Locals ignored, templates committable | `git check-ignore` (3 must-ignore, 2 must-not) | all 5 as expected | ✓ PASS |
| setup.sh syntax | `bash -n setup.sh` | `setup-syntax-ok` | ✓ PASS |
| Function-level DRY_RUN preview, zero writes | sourced `DRY_RUN=true HOME=/tmp/... ensure_local_files` | Would-run line printed; nothing created | ✓ PASS |
| Live create + idempotent + no-truncate | stub-HOME live run ×2 with `keepme` seed | both files created; `keepme` preserved | ✓ PASS |
| Full `--dry-run` shows local-file preview | `bash setup.sh --mode server --shell zsh --dry-run` grep `zshrc.local\|local.lua` Would-run | no local-file Would-run lines (only `zshrc.local.example` stow symlink preview) | ✗ FAIL |
| README docs | greps `Machine-local` + `zshrc.local.example` | `docs-ok` | ✓ PASS |
| History untracked, working file intact | `git ls-files` + `ls -la` (68894 bytes) | `history-untracked-ok` | ✓ PASS |

### Probe Execution

SKIPPED — no probes declared or implied for this phase. No `scripts/*/tests/probe-*.sh` exist in the repo and neither the PLAN nor SUMMARY references any probe script (verification was specified as inline greps/smokes, all re-run above).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| SHEL-02 | 03-01 | Fuzzy history via fzf without conflicts (^R normalized, ^I not clobbered) | ✓ SATISFIED (code) + human feel pending | Bind + ladder + order + single-^I proven; fuzzy UI + auto-show feel in behavior items 1-2 |
| SHEL-03 | 03-01 | PATH deduped and stable (`typeset -U`, empty dupes after reload) | ✓ SATISFIED | reload-ok re-run passes; mechanism demo passes; guard position verified |
| SHEL-04 | 03-01 | Machine-local Zsh overrides via gitignored `~/.zshrc.local`, auto-sourced at tail | ✓ SATISFIED | Guard position correct; marker take-effect proven; ignored + templated + installer-bootstrapped (live); preview-reachability gap tracked as T5 |
| EDIT-04 | 03-01 | Machine-local Neovim overrides via gitignored `local.lua`, `pcall` at end of init.lua | ✓ SATISFIED (live half) | pcall tail correct; silent-absent exit 0; take-effect mechanism proven; preview-reachability gap tracked as T5 |
| THEM-01 | 03-01 | Theme consistency | ✓ SATISFIED as intended-drift closure | Zero theme code proven; change-set gate clean; roadmap-literal token/warn explicitly dropped per user D-13 (override suggestion recorded above) |

Orphaned requirements check: REQUIREMENTS.md maps exactly SHEL-02, SHEL-03, SHEL-04, EDIT-04, THEM-01 to Phase 3 — all five appear in 03-01-PLAN.md frontmatter `requirements:` and in SUMMARY `requirements-completed:`. Zero orphaned. No requirement ID is unaccounted for.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No `TBD`/`FIXME`/`XXX` in any phase-touched file | — | None — clean |
| — | — | No `TODO`/`HACK`/`PLACEHOLDER`/placeholder-prose in phase files or templates | — | None — clean |
| — | — | No stub returns (`return null`/`{}`/`[]`), no empty handlers, no `console.log`-only bodies | — | None — shell/Lua codebase, N/A patterns absent |
| — | — | No hardcoded empty data flowing to render; no `=[ ]/{}/null` unpopulated renders | — | None — local files correctly absent-means-no-op by design (guarded source + pcall), not stubs |

Commits verified present in git log: `15c1a9b` (tracer), `4466643` (editor+gitignore+templates, incl. history cached-untrack), `250aceb` (installer+docs). Production change set is exactly the 7 plan paths + intended `zsh/.zsh_history` index removal (working-tree file preserved, 68894 bytes).

### Gaps Summary

One partial gap blocks a clean pass, plus two interactive behaviors reserved for human eyes:

1. **T5 preview reachability (the gap):** the installer bootstrap works live (creates both empty HOME files exactly once, never truncates, HOME-derived, DRY_RUN-safe function) but a user running the documented `bash setup.sh --dry-run` never sees the local-file Would-run lines, because the DRY_RUN preview path returns before reaching `ensure_local_files`. The must-have truth promises the preview under that exact command. Fix is a one-liner (call the already-safe function from the preview path) or accept the function-level-preview override quoted above. Nothing else in the phase needs rework.
2. **T1 Ctrl+R feel + T2 auto-show feel (not gaps):** code is present, substantive, and correctly wired (including the two genuine bug-fixes the executor found: own `zi light` line for the silently-never-loading plugin, and the tail `path=( $path )` re-assertion for scalar-export bypass on zsh 5.9, plus the Debian legacy fzf rung). What remains is the plan's own end-of-phase human check — open one interactive shell, watch completions auto-show, press Ctrl+R, confirm the prompt — recorded above as behavior items so it survives this gaps_found round and can be confirmed alongside the T5 fix.

No deferred items: Phase 4 (EDIT-01/02/03, HLTH-01) does not cover installer dry-run preview text or shell interactive feel, so T5 is a real gap, not future work. (The full history/secret purge stays deferred to v2 SECR-02 by design and was never attempted here.)

---
_Verified: 2026-09-17T13:30:00Z_
_Verifier: the agent (gsd-verifier)_
