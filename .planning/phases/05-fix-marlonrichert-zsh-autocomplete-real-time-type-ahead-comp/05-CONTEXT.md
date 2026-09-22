# Phase 5: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Context

**Gathered:** 2026-09-17
**Updated:** 2026-09-22 (scope expansion + keybinding amendments)
**Status:** Ready for planning

## Phase Boundary

Fix the deferred Phase-3 debt: typing 2–3 chars + pause shows no completion list — the user must press Tab to see anything. After this phase, the async find-as-you-type list auto-shows below the prompt with no keypress. Expected fix site is the `zsh/.zshrc` plugin block (~lines 290–344), but the fix may reach wherever needed (docs, `setup.sh`). Locked from Phase 3 and not re-asked: all three plugins stay (`zsh-autosuggestions` ghost + `fast-syntax-highlighting` + `marlonrichert/zsh-autocomplete`), Ctrl+R belongs to fzf-history-search, Tab belongs to autocomplete, autocomplete-first priority ladder (autocomplete > fzf fix > system fzf > skip fzf). **Expanded 2026-09-22 (user-directed):** Stow `.config` containment — prevent `stow nvim` from folding the whole `~/.config` into the repo, evict non-nvim siblings from the nvim package, and executor hand-repair this machine's broken `~/.config` symlink. New capabilities beyond autocomplete-fix + stow-containment belong in other phases.

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
- **D-08 (SUPERSEDED in part by D-27/D-28):** ~~Ghost-text accept keys are the existing Ctrl+Space (accept) / Ctrl+_ (execute), plus Right-arrow accept added in insert mode. Researcher picks the exact widget so plain cursor movement still works when no suggestion is shown. The vi-normal-mode `l`-to-accept idea was proposed and explicitly dropped — no normal-mode ghost-accept rebind.~~ Ctrl+Space/Ctrl+_ retention confirmed; Right-arrow confirmed; the `l`-drop is reversed — see D-27/D-28.

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
- **D-14:** The live regression covers the shell spine: auto-show works + Ctrl+R history + ghost text + Tab menu-select + clean reload with no errors. **Extended 2026-09-22:** also verifies Tab never ghost-accepts (D-29), `l`/Right-arrow ghost-accept still work (D-28), Right-arrow navigates menu when open (D-32), and `~/.config` is a real dir with only `nvim/` stow-linked (D-24..D-26).

### Vi-mode interplay

- **D-15:** All non-decided vi bindings stay stock. Core motions (`hjkl`, `w`/`b`, `gg`/`G`, etc.) are untouchable and must never be rebound. Non-motion vi keys may be rebound only if the fix needs it. **Note:** D-28's `l` ghost-accept is conditional existing behavior the user reports working today — protect it, do not treat it as a violation of D-15; researcher must document exactly what currently provides it so the fix doesn't clobber either side.

### List noise guard

- **D-16:** Show the full untruncated list by default, with a hard cutoff when the candidate count passes a threshold (thousands-scale completions lag). Researcher picks the cutoff number; user judges it live.
- **D-17:** Truncation always shows a visible hint (e.g. "…more — keep typing to narrow") — never a silent cut that looks like missing results.

### Change boundary

- **D-18 (EXPANDED 2026-09-22 by D-33):** Originally `zsh/.zshrc` + docs/comments + `setup.sh`. See D-33 for the full expanded surface. The Phase-1 atomic-docs rule applies (behavior change ships with its doc updates).

### Completion sources

- **D-20:** The auto-show list shows everything EXCEPT history — commands, files/paths, options/flags, variables. History stays exclusively behind Ctrl+R fzf (consistent with split ownership).
- **D-21:** Prefix-only matching — candidates must start with exactly what was typed. No fuzzy-anywhere matching.

### Plugin strategy

- **D-19:** A new plugin is allowed if it's the clean fix, but `marlonrichert/zsh-autocomplete` stays the engine. Swapping the completion engine entirely is allowed only if the researcher proves it unfixable.

### Research directive

- **D-23:** The researcher consults Context7 docs first for the plugin's current documentation, then falls back to GitHub CLI (issues/PRs/source) only if needed.

### Root cause is open (2026-09-22)

- **D-34:** The auto-show failure is **NOT presumed to be a keybind issue**. The researcher must explore ALL possibilities — `zstyle`/plugin config, the commented `zicompinit`/`zicdreplay` finalize block, async list timing, keymap-existence at bind time, load order, version quirks, upstream defaults — with no favored hypothesis. **The planner has complete freedom** to choose the approach research supports: free to restructure, rework init, or fix in ways the original discussion never imagined. Freedom is bounded only by the locked OUTCOMES in this file (auto-show feel D-01..D-04, key ownership D-05..D-08/D-27..D-32, stow decisions D-24..D-26/D-33, plugin keep-all D-12/D-19, completion sources D-20/D-21) — never by an assumed root cause. Keybind decisions are acceptance criteria, not the diagnosis.

### Stow .config containment (2026-09-22)

- **D-24:** Stow fold prevention uses BOTH defenses on every stow: (1) `--no-folding` passed to all stow invocations in `setup.sh` (install AND uninstall paths), (2) `mkdir -p "$HOME/.config"` guard before any stow run. End state guaranteed: stowing `nvim` only ever links `~/.config/nvim` (leaf), never swallows `~/.config`. — **Reversibility:** reversible — removing flags restores prior stow behavior; no data migration.
- **D-25:** Evict `opencode/`, `lazygit/`, `context7/` from the `nvim/.config/` package tree: relocate them to real `~/.config/` locations (post-repair), delete from the repo working tree, never stow them. The nvim package keeps ONLY `.config/nvim/`. — **Reversibility:** reversible — files move back; they were untracked, so no git history impact.
- **D-26:** This machine's broken `~/.config -> dotfiles/nvim/.config` symlink is repaired **by hand by the executor** as a one-time in-phase step (break symlink → real `mkdir ~/.config` → move evicted siblings into place → re-stow nvim with D-24 guards → verify only `~/.config/nvim` linked). The installer NEVER auto-repairs, then or ever — `setup.sh` gains prevention only, with an explicit comment/docs rule that it must not attempt to detect or fix a broken `~/.config` symlink. — **Reversibility:** reversible — symlink can be recreated; sibling data preserved by the move plan; preview each step before mutation per PROJECT Safety constraint.

### Ghost-accept vs Tab (2026-09-22)

- **D-27:** Ghost-text accept key set after the fix: **Right-arrow + `l` in vi-normal mode + existing Ctrl+Space (accept) / Ctrl+_ (execute)**. Amends D-08 — the `l` idea is reinstated. Tab is never a ghost-accept key. — **Reversibility:** reversible — bindkey lines are local edits.
- **D-28:** `l` and Right-arrow ghost-accept **already work as-is on this machine — preserve, do not rebuild.** The fix must not modify their wiring; only verify they still function in the live regression. The researcher documents WHAT currently provides those binds (plugin default vs local config) so nothing clobbers them. — **Reversibility:** reversible — documentation + non-regression constraint, no structural change.
- **D-29:** **Actively unbind Tab from autosuggest-accept.** Researcher traces the observed Tab-accepts-ghost hijack (plugin default / widget chain / menuselect interaction), explicitly removes it, and ensures Tab always resolves to `menu-select`. Verified live — pressing Tab with ghost text visible must open/navigate the completion menu, never accept the ghost. — **Reversibility:** reversible — unbind is a local bindkey change.

### Keybinding priority ladder (2026-09-22)

- **D-30:** Overlap ladder, highest first: **autocomplete (Tab/menu) > autosuggestions (ghost-accept keys) > fzf (Ctrl+R + expendable extras) > stock vi/zle**. New/unknown clashes resolve downward. fzf still loses to autocomplete per Phase 3. — **Reversibility:** reversible — documentation contract; changes are config edits.
- **D-31:** The ladder ships as a comment block at the top of the plugin section in `zsh/.zshrc` PLUS a key-ownership table in `README.md`'s Zsh section (Phase-1 atomic-docs rule).
- **D-32:** With BOTH ghost text and the completion menu visible, **Right-arrow navigates the menu** (menuselect keymap wins — autocomplete-first per D-30). Ghost-accept via Right-arrow applies only when the menu is closed. — **Reversibility:** reversible — keymap-layer behavior, config-editable.

### Expanded change boundary (2026-09-22)

- **D-33:** D-18 expands to the full surface: `zsh/.zshrc` (autocomplete fix + ladder comment) + `setup.sh` (all-stow `--no-folding`, `mkdir -p ~/.config` guard, post-verify adjusted for `--no-folding` link shapes, uninstall path parity, prevention-only/no-auto-repair rule) + `README.md`/docs/comments (ladder table, atomic-docs) + nvim package tree (`nvim/.config/` sibling eviction per D-25) + executor one-time live `$HOME` repair steps (per D-26, hand-executed, never installer code). — **Reversibility:** reversible — each surface is independently revertable; the live repair preserves app data via move-not-delete.

### Agent's Discretion (2026-09-22 additions)

- Researcher picks exact widgets/keys implementation for D-27..D-29 as long as end-state behavior matches (Tab protected, `l`/Right-arrow/Ctrl preserved).
- Researcher picks post-verify adjustments needed for `--no-folding` under D-33 (planner wires them into `setup.sh` tasks).
- Planner has complete freedom on fix approach per D-34 (root cause open).

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + requirements (locked scope)

- `.planning/ROADMAP.md` — Phase 5 is recorded via STATE.md Roadmap Evolution ("Phase 5 added: fix marlonrichert/zsh-autocomplete…") and Phase-3 cross-cutting constraint line 114 (auto-show target feel, Tab-only menu-select, ghost still renders); ROADMAP's Phase Details table currently lists Phases 1–4 only — treat this CONTEXT.md + STATE.md Deferred Items as the Phase 5 scope anchor until ROADMAP is updated. Note Phase 3 declares debt deferred here; plan Phase 5 standalone (D-13 — no Phase-4 harness dependency).
- `.planning/REQUIREMENTS.md` SHEL-02 — fuzzy history without conflicts, plugin-order fix, `bindkey '^R'` normalization (Ctrl+R half live-passed in Phase 3; do not regress). STOW-01 — stow correctness contract that D-24..D-26/D-33 repair (the fold bug is a latent STOW-01 defect).
- `.planning/PROJECT.md` — Core Value, Constraints (Zsh default; no destructive writes without preview — binds the D-26 hand-repair steps; machine-local gitignored; reversibility), Context (Zsh pain: `^I` conflict, autocomplete vs fzf-history-search).

### Prior context (carry-forward)

- `.planning/phases/03-polished-shell-theme-local-overrides/03-CONTEXT.md` — D-01..D-13 locked (split ownership, priority ladder, unconditional `^R` bind + warn, auto-show target feel, keep-all-three, `typeset -U`, HOME-only `.local`, intended theme drift). Deltas from THIS discussion: D-12 relaxes 03/D-01 load-order lock; D-06/D-15 refine Esc/vi handling; D-20 removes history from the auto-show list; D-30 restates the ladder with autosuggestions inserted above fzf. Planner must apply the deltas, not blind 03 text.
- `.planning/STATE.md` Deferred Items — the verbatim deferred debt this phase fixes: "Typing auto-show feel (SHEL-02 half): typing 2–3 chars + pause shows no completion list despite correct zsh-autocomplete wiring; Tab menu-select + ghost text unverified."

### Existing implementation to change (logic source)

- `zsh/.zshrc` (445 lines) — primary edit site. Key regions: vi mode `bindkey -v` (line 65); plugin block lines 290–314 (autosuggestions with `atload _zsh_autosuggest_start`, binds at 291–296: `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50`, `^_` autosuggest-execute, `^ ` autosuggest-accept; fast-syntax-highlighting; fzf-history-search; autocomplete LAST with `^I menu-select` atload); fzf ladder lines 324–344 (`source <(fzf --zsh)` AFTER autocomplete at line 327, unconditional `bindkey '^R'` at 341 + widget-missing warn); commented-out `zicompinit`/`zicdreplay` finalize block (lines 353–359) — prime suspect per D-34; `.local` sourcing (line 370); tail PATH retro-dedupe `path=( $path )` (line 445 — must stay the last PATH line). Zero `zstyle` tuning for autocomplete exists today. Ladder comment block (D-31) goes at top of this plugin section.
- `setup.sh` (90KB) — stow orchestration: constants ~line 19; dry-run stow preview ~lines 437–439 (`stow --dir="$SCRIPT_DIR" --target="$HOME" --restow $pkg` + `--no --verbose` preview); privileged keyd path ~lines 413–437; `post_verify` via `readlink -f` (must be adjusted per D-33 for `--no-folding` link shapes); `ensure_local_files` ~line 776+. D-24 guards (mkdir + `--no-folding`) wire into every stow call site here, install AND uninstall.
- `.planning/codebase/CONCERNS.md` — Zsh pain section (`zsh-autocomplete` vs `zsh-fzf-history-search` + `^I` remap), shell init ordering (zoxide position, p10k instant prompt at top), stow folding fragility notes (starship fold, lines 118–120; untested `stow --restow nvim` correctness, lines 197–199).

## Existing Code Insights

### Reusable Assets

- `zsh/.zshrc` version-branched fzf probe (`fzf --version` + `sort -V` vs `0.48`, Debian `doc/examples` rung) — reuse the pattern if the fix needs any version-dependent autocomplete config.
- `zsh/.zshrc` conditional-source idiom (`[[ -f ... ]] && source ...`) — model for any optional config the fix adds.
- `setup.sh` `DRY_RUN` early-return + `[DRY RUN] Would run:` preview — mandatory wrapper for new installer-side code (D-24 guards previewable this way; also the pattern for any repair tooling — though D-26 repair stays hand-executed).
- `setup.sh` `post_verify` folding-aware `readlink -f` prefix check — extend, don't replace, for `--no-folding` shapes (D-33).

### Established Patterns

- `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards + `--help`-wins pre-scan — mandatory for any `setup.sh` code.
- Phase-1 atomic-docs rule: every behavior change ships with its README/AGENTS.md/in-code comment update in the same commit (explicitly invoked by D-31).
- `zsh/.zshrc` ordering constraints: p10k instant prompt stays at top; tail PATH retro-dedupe stays last.
- Stow packages mirror target paths from package root (`pkg/.config/...`) — all XDG packages share this shape; D-24's `--no-folding` applies uniformly.

### Integration Points

- `zsh/.zshrc:290-314` plugin block — primary edit site (load order free per D-12; ladder comment per D-31; ghost binds per D-27..D-29).
- `zsh/.zshrc:324-344` fzf ladder + `^R` bind — free to rework per D-11, except Ctrl+R ownership which stays.
- `zsh/.zshrc:353-359` commented `zicompinit` block — prime suspect for the auto-show failure; researcher investigates first (D-34, no assumption).
- `zsh/.zshrc:311-314` `bindkey -M menuselect` — keymap-existence timing suspect (fails silently if `menuselect` keymap doesn't exist yet at bind time).
- Ghost-accept wiring (`atinit` binds at 291–296 + stock Right-arrow/End defaults) — researcher documents current providers of `l`/Right-arrow (D-28), does not rebuild.
- `setup.sh` all `stow` call sites (install ~437, preview ~420–439, uninstall `-D` paths, keyd privileged path) — D-24 `--no-folding` + mkdir guard land here with uninstall parity.
- `nvim/.config/` package tree — currently contains stray `opencode/` (80MB untracked), `lazygit/`, `context7/` beside `nvim/`; D-25 eviction target.
- Live `~/.config` symlink (`-> dotfiles/nvim/.config`, created 2026-09-21 16:09 same instant as `~/.zshrc` fold evidence) — D-26 hand-repair target; confirm current children before moving.

## Specific Ideas

- User verbatim (configurability): "are these even configurable?" — answered: recorded as desired outcomes, researcher maps to real knobs and reports back alternatives (see feasibility caveat).
- User verbatim (dismiss): "no need for conflicts ctrl+c will close it" — Esc stays stock vi, Ctrl+C dismisses the list (D-06).
- User verbatim (threshold): "it should show full list but if the actual list is more than a certain threshold it should stop as sometimes when there is thousands of possible completions it lags abit" (D-16).
- User verbatim (sources): "it should show everything but not history" (D-20).
- User verbatim (research method): "the researcher should first use ctx7, then if needed github-cli" (D-23).
- User verbatim (stow bug, 2026-09-22): "while stowing neovim plugins it stows whole .config folder instead of the nvim folder inside .config which then gets all the new files and folder of the .config gets in the repo unintendly" (D-24..D-26).
- User verbatim (ghost Tab, 2026-09-22): "ghost text accept also has tab key support which might cause conflict so if needed remove tab key from ghost text accepting and keep only right arrow or pressing l on vim normal mode(current behavior)" (D-27..D-29; D-08 amended).
- User verbatim (stow fix choice): "no folding always in all stows and also the mkdir gaurd before stow" (D-24).
- User verbatim (siblings): chose "Evict from package" (D-25).
- User verbatim (repair): "repair should be done by hand not by the script so in future it never tries to repair at all" + "confirm but by hand i meant executor" (D-26).
- User verbatim (l/Right-arrow): "it works now as it is. so not modification needed just make sure nothing breaks it. same with right arrow" (D-28).
- User verbatim (root cause): "i don't completely belive the autocomplete menu not appearing is a keybind issue so the researcher must explore all the possibilites and based on it's research planner should have complete freedom on what to do" (D-34).

## Deferred Ideas

None — stow containment was explicitly pulled INTO this phase by user directive (scope expansion, not creep); ghost/ladder work is keybinding-ownership clarification for the autocomplete fix. Phase-4 `--self-test` harness integration is not deferred work for this phase by user directive (D-13) — Phase 4 may pick up the fixed behavior into its gates when it runs.

---

*Phase: 5-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp*
*Context gathered: 2026-09-17; updated 2026-09-22*
