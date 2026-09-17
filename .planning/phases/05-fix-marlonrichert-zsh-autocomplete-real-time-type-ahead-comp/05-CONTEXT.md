# Phase 5: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

## Phase Boundary

Fix the deferred Phase-3 debt: typing 2–3 chars + pause shows no completion list — the user must press Tab to see anything. After this phase, the async find-as-you-type list auto-shows below the prompt with no keypress. Expected fix site is the `zsh/.zshrc` plugin block (~lines 290–344), but the fix may reach wherever needed (docs, `setup.sh`). Locked from Phase 3 and not re-asked: all three plugins stay (`zsh-autosuggestions` ghost + `fast-syntax-highlighting` + `marlonrichert/zsh-autocomplete`), Ctrl+R belongs to fzf-history-search, Tab belongs to autocomplete, autocomplete-first priority ladder (autocomplete > fzf fix > system fzf > skip fzf). New capabilities belong in other phases.

## Implementation Decisions

### Auto-show trigger sensitivity

- **D-01:** The completion list auto-shows immediately on the first typed character — no keypress, no char-count threshold, no delay.
- **D-02:** Quiet on an empty prompt — nothing pops up until the first character is typed (no wall of commands on every fresh prompt).
- **D-03:** Ghost autosuggestion text and the dropdown list coexist on screen simultaneously, each with its own accept key.
- **D-04:** Auto-show applies in every typing context — command names, arguments, paths, mid-word, after `sudo`.
- **Feasibility caveat (binding on researcher):** D-01..D-04 are recorded as desired outcomes, not verified plugin capabilities. The researcher MUST map each to real knobs/plugin defaults and report back the closest achievable alternative for anything not configurable — the planner must not lock an impossible config.

### Menu key behavior

- **D-05:** Enter on a highlighted item selects it into the buffer for further editing; a second Enter runs it. First Enter never executes.
- **D-06:** Esc keeps 100% stock vi behavior (untouched, insert→normal). Ctrl+C is the explicit list-dismiss key.
- **D-07:** Tab cycles forward / Shift-Tab cycles back inside the menu (existing `kcbt` wiring kept); arrow keys also work.
- **D-08:** Ghost-text accept keys are the existing Ctrl+Space (accept) / Ctrl+_ (execute), plus Right-arrow accept added in insert mode. Researcher picks the exact widget so plain cursor movement still works when no suggestion is shown. The vi-normal-mode `l`-to-accept idea was proposed and explicitly dropped — no normal-mode ghost-accept rebind.

### fzf coexistence boundary

- **D-09:** On any widget clash between fzf and autocomplete, the researcher decides what stays; fzf loses by default per the Phase-3 priority ladder (fzf must never break autocomplete).
- **D-10:** fzf extras (`**` Tab fuzzy file find, Ctrl+T, Alt+C) are expendable — they may be dropped to save autocomplete. Ctrl+R history ownership is not negotiable.
- **D-11:** The Phase-3 fzf init ladder (version branch, Debian rung, warn-if-missing) is NOT frozen — researcher may rework fzf init placement/loading as part of the fix.
- **D-12:** Plugin load order is free to reorder — this relaxes the Phase-3 D-01 order lock. What stays locked from D-01: keep all three plugins, and the Ctrl+R-vs-Tab split ownership.

### Agent's Discretion

- D-09 clash resolution (which widget/config survives a conflict, fzf loses by default).
- D-22 result ordering inside the combined completion list (researcher picks from upstream defaults; user judges the feel live).
- D-16 threshold number for the thousands-scale cutoff (researcher picks; user judges live).

### Proof and regression

- **D-13:** The user's live terminal verdict closes the phase, backed by ad-hoc commands run during verification. Zero new harness/probe files — Phase 4 owns `--self-test` and hasn't started, so no dependency is taken on it.
- **D-14:** The live regression covers the shell spine: auto-show works + Ctrl+R history + ghost text + Tab menu-select + clean reload with no errors.

### Vi-mode interplay

- **D-15:** All non-decided vi bindings stay stock. Core motions (`hjkl`, `w`/`b`, `gg`/`G`, etc.) are untouchable and must never be rebound. Non-motion vi keys may be rebound only if the fix needs it.

### List noise guard

- **D-16:** Show the full untruncated list by default, with a hard cutoff when the candidate count passes a threshold (thousands-scale completions lag). Researcher picks the cutoff number; user judges it live.
- **D-17:** Truncation always shows a visible hint (e.g. "…more — keep typing to narrow") — never a silent cut that looks like missing results.

### Change boundary

- **D-18:** The fix may touch `zsh/.zshrc` + docs/comments + `setup.sh` installer wiring wherever needed. The Phase-1 atomic-docs rule applies (behavior change ships with its doc updates).
- **D-19:** A new plugin is allowed if it's the clean fix, but `marlonrichert/zsh-autocomplete` stays the engine. Swapping the completion engine entirely is allowed only if the researcher proves it unfixable.

### Completion sources

- **D-20:** The auto-show list shows everything EXCEPT history — commands, files/paths, options/flags, variables. History stays exclusively behind Ctrl+R fzf (consistent with split ownership).
- **D-21:** Prefix-only matching — candidates must start with exactly what was typed. No fuzzy-anywhere matching.

### Research directive

- **D-23:** The researcher consults Context7 docs first for the plugin's current documentation, then falls back to GitHub CLI (issues/PRs/source) only if needed.

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + requirements (locked scope)

- `.planning/ROADMAP.md` Phase 5 section — goal "[To be planned]" for the autocomplete fix; note it declares `Depends on: Phase 4`, but the user explicitly directed no Phase-4 harness dependency (D-13) — plan Phase 5 standalone.
- `.planning/REQUIREMENTS.md` SHEL-02 — fuzzy history without conflicts, plugin-order fix, `bindkey '^R'` normalization (Ctrl+R half live-passed in Phase 3; do not regress).
- `.planning/PROJECT.md` — Core Value, Constraints (Zsh default; no destructive writes without preview), Context (Zsh pain: `^I` conflict, autocomplete vs fzf-history-search).

### Prior context (carry-forward)

- `.planning/phases/03-polished-shell-theme-local-overrides/03-CONTEXT.md` — D-01..D-13 locked (split ownership, priority ladder, unconditional `^R` bind + warn, auto-show target feel, keep-all-three, `typeset -U`, HOME-only `.local`, intended theme drift). Deltas from THIS discussion: D-12 relaxes 03/D-01 load-order lock; D-06/D-15 refine Esc/vi handling; D-20 removes history from the auto-show list. Planner must apply the deltas, not blind 03 text.
- `.planning/STATE.md` Deferred Items — the verbatim deferred debt this phase fixes: "Typing auto-show feel (SHEL-02 half): typing 2–3 chars + pause shows no completion list despite correct zsh-autocomplete wiring; Tab menu-select + ghost text unverified."

### Existing implementation to change (logic source)

- `zsh/.zshrc` (445 lines) — the single edit site. Key regions: vi mode `bindkey -v` (line 65); plugin block lines 290–314 (autosuggestions with `atload _zsh_autosuggest_start`, fast-syntax-highlighting, fzf-history-search, autocomplete LAST with `^I menu-select` atload); fzf ladder lines 324–344 (`source <(fzf --zsh)` AFTER autocomplete at line 327, unconditional `bindkey '^R'` at 341 + widget-missing warn); commented-out `zicompinit`/`zicdreplay` finalize block (lines 353–359); `.local` sourcing (line 370); tail PATH retro-dedupe `path=( $path )` (line 445 — must stay the last PATH line). Zero `zstyle` tuning for autocomplete exists today.
- `.planning/codebase/CONCERNS.md` — Zsh pain section (`zsh-autocomplete` vs `zsh-fzf-history-search` + `^I` remap) and shell init ordering (zoxide position, p10k instant prompt at top).

## Existing Code Insights

### Reusable Assets

- `zsh/.zshrc` version-branched fzf probe (`fzf --version` + `sort -V` vs `0.48`, Debian `doc/examples` rung) — reuse the pattern if the fix needs any version-dependent autocomplete config.
- `zsh/.zshrc` conditional-source idiom (`[[ -f ... ]] && source ...`) — model for any optional config the fix adds.
- `setup.sh` `DRY_RUN` early-return + `[DRY RUN] Would run:` preview — mandatory wrapper if the fix touches the installer (D-18).

### Established Patterns

- `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards + `--help`-wins pre-scan — mandatory for any new `setup.sh` code.
- Phase-1 atomic-docs rule: every behavior change ships with its README/AGENTS.md/in-code comment update in the same commit.
- `zsh/.zshrc` ordering constraints: p10k instant prompt stays at top; tail PATH retro-dedupe stays last.

### Integration Points

- `zsh/.zshrc:290-314` plugin block — primary edit site (load order now free per D-12, all three plugins stay).
- `zsh/.zshrc:324-344` fzf ladder + `^R` bind — free to rework per D-11, except Ctrl+R ownership which stays.
- `zsh/.zshrc:353-359` commented `zicompinit` block — prime suspect for the auto-show failure; researcher investigates first.
- `zsh/.zshrc:311-314` `bindkey -M menuselect` — keymap-existence timing suspect (fails silently if `menuselect` keymap doesn't exist yet at bind time).
- Ghost-accept wiring (`atinit` binds at 291–296 + new Right-arrow per D-08) — researcher picks exact widgets.

## Specific Ideas

- User verbatim (configurability): "are these even configurable?" — answered: recorded as desired outcomes, researcher maps to real knobs and reports back alternatives (see feasibility caveat).
- User verbatim (dismiss): "no need for conflicts ctrl+c will close it" — Esc stays stock vi, Ctrl+C dismisses the list (D-06).
- User verbatim (vi normal mode): "actually no need to modify as it works now as it is" — dropped the `l`-to-accept idea entirely (D-08).
- User verbatim (threshold): "it should show full list but if the actual list is more than a certain threshold it should stop as sometimes when there is thousands of possible completions it lags abit" (D-16).
- User verbatim (sources): "it should show everything but not history" (D-20).
- User verbatim (research method): "the researcher should first use ctx7, then if needed github-cli" (D-23).

## Deferred Ideas

None — discussion stayed within phase scope. (Phase-4 `--self-test` harness integration is not deferred work for this phase by user directive — Phase 4 may pick up the fixed behavior into its gates when it runs.)

---

*Phase: 5-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp*
*Context gathered: 2026-09-17*
