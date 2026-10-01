# Phase 4: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Research

**Researched:** 2026-09-22 (refresh: upstream-led root-cause pass per D-23/D-34)
**Domain:** Zsh interactive completion (marlonrichert/zsh-autocomplete + zsh-autosuggestions + fzf) + GNU Stow deployment containment
**Confidence:** HIGH (Gap 1 root cause — upstream-issue-grounded + locally corroborated); HIGH (keybindings, stow semantics); MEDIUM (Gap 2 mechanism — ranked hypotheses, live adjudication required)

## Summary

This phase fixes deferred Phase-3 debt (SHEL-02 half: typing shows no completion list) plus Stow `.config` containment (STOW-01 latent fold defect — **already VERIFIED closed, do not replan**), ghost-vs-Tab key ownership, and a documented keybinding priority ladder. The prior research pass leaned on local plugin-code reading and left the auto-show root cause open (H-1..H-7, flat per D-34). This refresh was conducted upstream-first per binding directive: `ctx7` docs fetches for `marlonrichert/zsh-autocomplete`, then `gh` CLI over the upstream repo (issues, PRs, commits), with local code only as tertiary confirmation. Each finding below is labeled `[ctx7]` / `[gh-repo]` / `[local-confirm]` so the planner sees provenance.

The refresh **closes the Gap 1 root-cause question**: three converging upstream reports identify a regression in the exact installed commit (`77706d4`, which is also upstream `main` HEAD as of 2026-09-22) where the `zasync` async backend never loads, so the `line-pre-redraw` → async worker pipeline silently never runs — while synchronous Tab completion keeps working. That is byte-for-byte the live FAIL signature (static `min-input 1`/`delay 0`/`list-lines 300` present but inert; Tab still does something). Two upstream fix PRs exist but are both still OPEN (unmerged), so the planner must ship a local workaround (or version pin), not `zinit update`.

For Gap 2 (Tab glitches ghost), a live probe run this session shows `bindkey '^I'` already resolves to `menu-select` — so Gap 2 is **not** a wrong-bind problem. The planner should fix Gap 1 first and re-test D-29 before building a separate Tab theory, plus add the one upstream README recipe line this repo lacks (`menuselect ^I → menu-complete`).

**Primary recommendation:** Ship the upstream workaround for the `zasync` stale-stub bug via a one-shot `precmd` fixup hook in `zsh/.zshrc` (a plain `unfunction` at load time is a no-op — timing trap documented below); live-verify with `whence -v zasync` + typing auto-show; then re-run the D-29 Tab check (Gap 2 may resolve as a downstream symptom); add the missing `menuselect ^I` bind regardless. Keep all shipped 04-01 static work (zstyle baseline, fzf preset + Tab re-assert, `zsh/.zshenv` guard, ladder comment) and all STOW-01 work untouched.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The completion list auto-shows immediately on the first typed character — no keypress, no char-count threshold, no delay.
- **D-02:** Quiet on an empty prompt — nothing pops up until the first character is typed.
- **D-03:** Ghost autosuggestion text and the dropdown list coexist on screen simultaneously, each with its own accept key.
- **D-04:** Auto-show applies in every typing context — command names, arguments, paths, mid-word, after `sudo`.
- **Feasibility caveat (binding on researcher):** D-01..D-04 are recorded as desired outcomes, not verified plugin capabilities. The researcher MUST map each to real knobs/plugin defaults and report back the closest achievable alternative for anything not configurable.
- **D-05:** Enter on a highlighted item selects it into the buffer for further editing; a second Enter runs it. First Enter never executes.
- **D-06:** Esc keeps 100% stock vi behavior (untouched, insert→normal). Ctrl+C is the explicit list-dismiss key.
- **D-07:** Tab cycles forward / Shift-Tab cycles back inside the menu (existing `kcbt` wiring kept); arrow keys also work.
- **D-08 (SUPERSEDED in part by D-27/D-28):** Ctrl+Space/Ctrl+_ retention confirmed; Right-arrow confirmed; the `l`-drop is reversed — see D-27/D-28.
- **D-09:** On any widget clash between fzf and autocomplete, the researcher decides what stays; fzf loses by default per the Phase-3 priority ladder.
- **D-10:** fzf extras (`**` Tab fuzzy file find, Ctrl+T, Alt+C) are expendable — they may be dropped to save autocomplete. Ctrl+R history ownership is not negotiable.
- **D-11:** The Phase-3 fzf init ladder (version branch, Debian rung, warn-if-missing) is NOT frozen — researcher may rework fzf init placement/loading as part of the fix.
- **D-12:** Plugin load order is free to reorder — relaxes the Phase-3 D-01 order lock. Locked from D-01: keep all three plugins, and the Ctrl+R-vs-Tab split ownership.
- **D-13:** The user's live terminal verdict closes the phase, backed by ad-hoc commands run during verification. Zero new harness/probe files.
- **D-14:** Live regression covers shell spine (auto-show + Ctrl+R + ghost + Tab menu-select + clean reload, no errors), extended 2026-09-22: Tab never ghost-accepts (D-29), `l`/Right-arrow ghost-accept still work (D-28), Right-arrow navigates menu when open (D-32), `~/.config` is a real dir with only `nvim/` stow-linked (D-24..D-26).
- **D-15:** All non-decided vi bindings stay stock. Core motions untouchable. D-28's `l` ghost-accept is conditional existing behavior — protect it; researcher documents what provides it.
- **D-16:** Full untruncated list by default, hard cutoff at thousands-scale (researcher picks number; user judges live).
- **D-17:** Truncation always shows a visible hint — never a silent cut.
- **D-18 (EXPANDED by D-33):** Change surface per D-33. Phase-1 atomic-docs rule applies.
- **D-20:** Auto-show list shows everything EXCEPT history. History stays behind Ctrl+R fzf.
- **D-21:** Prefix-only matching — candidates must start with exactly what was typed. No fuzzy-anywhere.
- **D-19:** New plugin allowed if clean fix, but `marlonrichert/zsh-autocomplete` stays the engine. Engine swap only if researcher proves unfixable.
- **D-23:** Researcher consults Context7 first, then GitHub CLI only if needed.
- **D-34:** Auto-show failure is NOT presumed a keybind issue. Researcher explores ALL possibilities with no favored hypothesis. Planner has complete freedom bounded only by locked OUTCOMES.
- **D-24:** Fold prevention = BOTH `--no-folding` on all stows (install AND uninstall) + `mkdir -p "$HOME/.config"` guard. Reversible.
- **D-25:** Evict `opencode/`, `lazygit/`, `context7/` (plus observed `gh/`) from `nvim/.config/` to real `~/.config/` locations; delete from repo tree; never stow them; nvim package keeps ONLY `.config/nvim/`. Reversible.
- **D-26:** Broken `~/.config` symlink repaired BY HAND by executor (break symlink → mkdir → move siblings → re-stow with D-24 guards → verify). Installer NEVER auto-repairs, then or ever. Preview each step per Safety constraint.
- **D-27:** Ghost-accept keys after fix: Right-arrow + `l` in vi-normal + Ctrl+Space (accept) / Ctrl+_ (execute). Tab is never ghost-accept.
- **D-28:** `l` and Right-arrow ghost-accept already work — preserve, do not rebuild; verify in regression; researcher documents WHAT provides them.
- **D-29:** Actively unbind Tab from autosuggest-accept. Researcher traces the Tab-accepts-ghost hijack, removes it, Tab always resolves to `menu-select`. Verified live.
- **D-30:** Ladder, highest first: autocomplete (Tab/menu) > autosuggestions (ghost-accept) > fzf (Ctrl+R + extras) > stock vi/zle. New clashes resolve downward.
- **D-31:** Ladder ships as comment block at top of `zsh/.zshrc` plugin section PLUS key-ownership table in `README.md` Zsh section (atomic-docs).
- **D-32:** With ghost + menu both visible, Right-arrow navigates the menu (menuselect wins, autocomplete-first). Ghost-accept via Right-arrow only when menu closed.
- **D-33:** Full surface: `zsh/.zshrc` (fix + ladder comment) + `setup.sh` (all-stow `--no-folding`, mkdir guard, post_verify link-shape adjustment, uninstall parity, prevention-only rule) + README/docs/comments + nvim tree eviction + executor one-time live `$HOME` repair (hand-executed, never installer code).

### Agent's Discretion

- D-09 clash resolution (fzf loses by default).
- D-22 result ordering (researcher picks from upstream defaults; user judges live).
- D-16 threshold number (researcher picks; user judges live).
- Exact widgets/keys implementation for D-27..D-29 as long as end-state matches.
- Post-verify adjustments for `--no-folding` under D-33.
- Planner has complete freedom on fix approach per D-34.

### Deferred Ideas (OUT OF SCOPE)

None — stow containment was pulled INTO this phase; ghost/ladder work is keybinding-ownership clarification. Phase-4 `--self-test` harness integration is not this phase's work (D-13).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHEL-02 (auto-show half OPEN) | Typing auto-shows list; Tab menu-select | Gap 1 root cause closed upstream (§Upstream Root-Cause Findings) + fixup-hook prescription with timing trap + live diagnostics checklist; Gap 2 sequencing (§Gap 2 Analysis); `^R` ownership intact — Tab re-assert live-verified `menu-select` |
| STOW-01 (MET — do not replan) | Leaf-only stow, loud verify | Unchanged from prior pass: sandbox-verified `--no-folding` semantics; 04-VERIFICATION.md marks SATISFIED via live item 6 PASS. No further research. |

## Project Constraints (from AGENTS.md)

- **Shell default:** Zsh everywhere; Nushell backup only — no Nushell-side changes in this phase.
- **Installer language:** Unified installer is Bash — all `setup.sh` edits follow `set -Eeuo pipefail`, `${1-}` guards, `--help`-wins pre-scan.
- **Scope filter:** No Nushell-only fixes.
- **OS support:** `ID_LIKE` + manager probing (this machine: `ID=archarm`, `ID_LIKE=arch` [local-confirm: /etc/os-release]) — plus upstream `skip_global_compinit=1` needed for Ubuntu-family (shipped as `zsh/.zshenv` in 04-01).
- **Machine-local:** Gitignored overrides; repair moves preserve data, never delete.
- **Reversibility:** Every surface independently revertable (bindkey lines, stow flags, sibling moves of untracked dirs, fixup hook is 3 deletable lines).
- **Safety:** No destructive writes without preview/confirmation — binds the D-26 hand-repair and all `setup.sh` edits (DRY_RUN echo strings must show `--no-folding`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Async completion list render | Zsh line editor (ZLE hooks) | — | `line-pre-redraw` hook → zasync pty worker → `zle -R`; all inside the interactive shell process |
| Ghost autosuggestion text | ZLE (`POSTDISPLAY`) | — | zsh-autosuggestions renders via `POSTDISPLAY` highlight; coexists with list by upstream design [ctx7] |
| Tab/menu key ownership | ZLE keymaps (`viins`/`menuselect`) | — | `bindkey` layering order is the D-29/D-30 problem; live `^I` already `menu-select` [local-confirm] |
| fzf history search (Ctrl+R) | External binary + ZLE widgets | — | fzf 0.74.4 owns `^R` in all three keymaps; must not own `^I` (re-assert shipped) |
| Stow symlink deployment | Installer (Bash) + GNU Stow | Filesystem | Link shapes decided by stow flags; verified in sandbox, not by reading docs |
| Live `~/.config` repair | Executor hands (one-time) | — | Installer is explicitly forbidden from repairing (D-26) — DONE per live item 6 PASS |

## Upstream Root-Cause Findings (gap-closure refresh)

### Gap 1: auto-show dead — ROOT CAUSE CLOSED (upstream regression, not config)

**Finding R-1 [gh-repo]: the `zasync` backend never loads at the installed commit, so the async pipeline silently never runs.**
Three converging upstream reports, all against the same commit range we run:

- **Issue #907 (OPEN, 2026-09-18)** — "zasync is autoloaded from a directory, so real-time completion silently does nothing." Reporter環境 pinpoints our exact installed commit (`77706d4 Fix quoting bug in history completion`). `whence -v zasync` shows registration from the *directory* `$HOME/.cache/zsh/zasync` instead of the file; every `zasync` call returns 0 doing nothing; the `line-pre-redraw` → async worker pipeline never runs; `$HOME/.local/state/zsh-autocomplete/log/` stays empty with no error anywhere. Relevant line: `Functions/Init/.autocomplete__async:25` — `builtin autoload -Uz $zasync_dir/zasync`. Workaround (verified by reporter): `unfunction zasync` (required — plain `autoload` does not replace the bad registration) then `autoload -Uz $HOME/.cache/zsh/zasync/zasync`; real-time listing works immediately, no restart. Release tag `26.08.04` is unaffected (it vendors `z-async` via `fpath` + `autoload -Uz z-async`).
- **PR #905 (OPEN, 2026-09-12)** — "Fix stale zasync autoload stub." Precise mechanism: the `autoload -Uz +X zasync` availability probe (`.autocomplete__async:17`) fails when zasync is not on `$fpath`, but the failed probe *leaves `zasync` registered as an undefined autoload stub*; the later `builtin autoload -Uz "$zasync_dir/zasync"` (line 25) does not replace the stub, so `zasync` stays unresolved despite a successful clone. Reproduced in clean `zsh -f` with empty `XDG_CACHE_HOME`; live completion fails without / works with the cleanup; `./run-tests.zsh` 51/51 passed. Fix = remove the stale stub before loading the cached implementation.
- **PR #903 (OPEN, 2026-09-03)** — "Fix zasync and completion helper loading" (fixes #901). States the Gap 1 symptom verbatim: *"Manual completion still works, but the completion menu does not appear automatically while typing."* Reproduced on Fedora Linux 44 + zsh 5.9 and macOS Tahoe; `cd <TAB>`-style manual completion works, auto-show dead. Fix = temporarily scope the cloned dir onto `fpath`, force-load with `autoload -Uz +X`, and register internal `Completions/` helpers independently of `compinit` (second half fixes OMZ-ordering `command not found: _autocomplete__history_lines` errors).
- **Regression window [gh-repo]:** PR #894 "Un-vendor zasync and fetch it via git clone at init time" MERGED 2026-08-26 — this is the change that introduced clone-at-init. Tag `26.08.04` (2026-08-04, latest release) predates it and is unaffected. Issue #901 (OPEN, 2026-09-15, "Real time completion stop working after latest update") corroborates Sept-commit breakage from more users (macOS Tahoe, Ubuntu 24.04 + OMZ).

**Finding R-2 [gh-repo + local-confirm]: we run the broken tip; `zinit update` is a no-op.**
Upstream `main` HEAD is `77706d4` (2026-09-13) — byte-identical to the installed plugin's HEAD (`git log --oneline -5` locally shows `77706d4` on top). Both fix PRs (#903, #905) are still OPEN/unmerged as of 2026-09-22, and issue #907 is OPEN with no maintainer fix. Consequence for the planner: **no upstream update can fix this today** — the phase must ship a local workaround (R-3) or a version pin (R-4). A future `zinit update` *after* #903/#905 merge retires the workaround.

**Finding R-3 [gh-repo, mechanism from #905 + workaround from #907]: the fix is `unfunction` + re-`autoload` of the cached file — but placement has a timing trap.**
The stale stub is created at *first precmd* (inside `${0}:precmd()`, `.autocomplete__async:16-25` [local-confirm: grep-verified line numbers 16, 17, 25]). A bare `unfunction zasync` placed after `zi light marlonrichert/zsh-autocomplete` in `zsh/.zshrc` runs at *source time*, before any precmd has fired — it removes nothing and never re-runs. The robust zshrc-native shape is a **one-shot `precmd` fixup hook** (order-independent: whether it runs before or after the plugin's own precmd on a given prompt, the end state converges — after a correct file registration the plugin's own `+X` probe succeeds and loads it instead of re-entering the clone branch):

```zsh
# Workaround for upstream #907/#905 (stale zasync autoload stub kills async):
# remove after `zinit update` past the upstream fix. [gh-repo]
autoload -Uz add-zsh-hook
_fix_zasync_once() {
  unfunction zasync 2>/dev/null
  autoload -Uz ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zasync/zasync
  add-zsh-hook -d precmd _fix_zasync_once
}
add-zsh-hook precmd _fix_zasync_once
```

Placement reasoning above is [ASSUMED] (derived from the #905 mechanism + precmd semantics, not live-tested) — the planner MUST live-verify (`whence -v zasync` must show the *file* path; typing must auto-show). If the hook form fails live, fall back to R-4.

**Finding R-4 [gh-repo]: fallback = pin tag `26.08.04` (vendored backend, unaffected per #907).**
Trade-off: forfeits post-26.08.04 fixes (recent-dirs mkdir #893, async-timeout signaling #898, history quoting #906). Exact zinit pin ice syntax is [ASSUMED] — planner verifies via `zinit help` if this path is taken. Prefer R-3; keep R-4 as the documented fallback, not the default.

**Finding R-5 [local-confirm]: the dead-pipeline signature is present on this machine.**
`~/.cache/zsh/zasync/` clone present (with top-level `zasync` file: EXISTS) AND `~/.local/state/zsh-autocomplete/log/` exists but is EMPTY — exactly #907's "log directory exists and stays empty" dead-pipeline signature. (Headless `zsh -i -c 'whence -v zasync'` reports "not found" because no precmd fires in `-c` mode — inconclusive by design; the real check needs an interactive shell and is task #1 below.)

**Disposition of prior H-1..H-7 (D-34 closed for Gap 1):**
| Prior hypothesis | Disposition | Basis |
|---|---|---|
| H-2 zasync backend failure | **CONFIRMED as R-1** | #903/#905/#907 + local empty-log-dir signature |
| H-1 fzf/ladder interference | Demoted: real for Tab ownership (kept as fix), NOT the auto-show cause | #903: "manual completion still works" with fzf present; async death is stub-level |
| H-3 FSH conflict | Ruled out as primary | Upstream repros fail without FSH involvement; keep FSH where it is |
| H-4 compinit ordering | Partially alive as Gap-2 diagnostic only (helper registration, #903 second half) | Our user reported no `command not found` errors; OMZ-specific half does not apply (we use zinit, finalize block stays removed) |
| H-5 hook chain / H-6 still-typing gate | Ruled out as primary | Pipeline never starts (no log file ever created) — downstream gates never get a chance to misfire |
| H-7 Ubuntu global compinit | Unchanged: N/A on this machine, `zsh/.zshenv` guard already shipped for Ubuntu-family | [ctx7] install requirements |

### Gap 2: Tab glitches ghost — reframed, NOT a wrong-bind problem

**Finding R-6 [local-confirm]: live `bindkey '^I'` already reports `menu-select`.**
Probed via `timeout 25 zsh -i -c 'bindkey "^I"'` → `"^I" menu-select`, RC=0. So the 04-01 Tab re-assert (zshrc:369) is live-effective: Tab reaches `menu-select`, not `fzf-completion` and not `autosuggest-accept`. The D-29 static wiring is correct; the glitch happens *downstream* of a correct bind. Do not plan another rebind pass as the fix.

**Finding R-7 [ctx7]: upstream README Tab recipe has TWO lines; this repo ships only one-and-a-half.**
Upstream recipe (README, via ctx7 docs fetch): `bindkey '^I' menu-select` for entering the menu AND `bindkey -M menuselect '^I' menu-complete` (+ `kcbt → reverse-menu-complete`) for moving inside it. Our `zsh/.zshrc` binds main `^I → menu-select` (×2) and `menuselect kcbt → reverse-menu-complete`, but **no `menuselect ^I` bind** — in-menu Tab falls through to the stock menuselect default. Correction to prior research (which called the kcbt line "redundant-but-harmless"): the missing line is the gap, not the present one. Planner: add `bindkey -M menuselect '^I' menu-complete` (one line, reversible, upstream-canonical). Whether stock default already equals it is [ASSUMED] — verify live with `bindkey -M menuselect '^I'`.

**Finding R-8 (Gap 2 sequencing): treat Gap 2 as possibly downstream of Gap 1 until proven otherwise.**
Ranked candidates: (a) with async dead the menu state machine is abnormal — Tab → `menu-select` → synchronous complete against possibly-unregistered helpers (cf. #903 second half) produces the observed ghost-bold-then-vanish instead of a menu [ASSUMED]; (b) the missing menuselect-^I line (R-7); (c) helper-registration failure — live diagnostic `type -a _autocomplete__history_lines` / `whence -v _autocomplete__unambiguous` tells (if missing → #903-class problem; our user never reported the `command not found` errors, so expect present); (d) pure POSTDISPLAY perception (ghost-accept vs unambiguous-prefix insert look identical — prior A1, still [ASSUMED]). Planner order: fix Gap 1 (R-3) → re-run D-29 live check → only if still failing, work (b)→(c)→(d). Do not pre-build a Tab theory.

## Standard Stack

### Core (no new packages — config + one hook; possible version pin)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `marlonrichert/zsh-autocomplete` | main @77706d4 (2026-09-13) = upstream HEAD [gh-repo + local-confirm] | Real-time type-ahead list engine (locked per D-19) | Upstream plugin; broken-tip caveat: async dead until R-3 workaround or upstream merges #903/#905. Engine stays — fixable, no swap (D-19 bar not met). |
| `zsh-users/zsh-autosuggestions` | v0.7.1 [local-confirm: VERSION file, prior pass] | Ghost `POSTDISPLAY` text + accept keys | Fish-like suggestions; defaults already provide Right-arrow/`l` accept (D-28) |
| `zdharma-continuum/fast-syntax-highlighting` | @4672ad5 (2026-08-31) [local-confirm: prior pass] | Real-time syntax validation | Ruled out as auto-show cause (R-1 dispositions); keep as-is |
| GNU Stow | 2.4.1 [local-confirm: `stow --version`] | Symlink deployment | `--no-folding` verified working despite absence from `--help` text; STOW-01 closed |
| fzf (system binary) | 0.74.4 [local-confirm: `fzf --version`] | Ctrl+R history + `**` extras | ≥0.48 → native `fzf --zsh` rung; the same integration rebinds Tab (contained by shipped re-assert, live-verified) |
| zsh | 5.9.2 [local-confirm: `zsh --version`] | Interactive shell | Within plugin's tested range; PR #903 reproduced on zsh 5.9 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `marlonrichert/zasync` (git-cloned backend) | clone present at `~/.cache/zsh/zasync` (top-level `zasync` file EXISTS) [local-confirm] | Async worker backend for autocomplete | Already present; the bug is registration (stale stub), not absence |
| `joshskidmore/zsh-fzf-history-search` | installed | Owns Ctrl+R widget | Keep; `^R` re-assert stands |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| R-3 one-shot precmd fixup hook | Pin tag `26.08.04` (R-4) | Pin forfeits #893/#898/#906 fixes; hook keeps HEAD. Prefer hook, pin is fallback. |
| R-3 hook | `zinit update` | No-op today (HEAD == installed, fixes unmerged). Revisit after #903/#905 merge — the update then RETIRES the hook. |
| R-3 hook | Patch installed plugin file (add `unfunction` before line 25) | Works but evaporates on next `zinit update` with no marker; hook is visible, greppable, self-documenting. Do not patch the plugin. |
| Re-assert `^I menu-select` after fzf ladder (shipped) | Move fzf ladder before plugin block | Rejected (prior pass, still valid): moving changes `$fzf_default_completion` capture for the worse. Keep position, keep re-assert. |
| `--no-folding` on every stow | Per-package flag only on nvim | Rejected per D-24 (all stows); harmless and uniform. STOW-01 closed. |
| New completion engine (per D-19 allowance) | — | NOT justified: root cause found + workaround exists; engine stays. |

**Installation:** none — zero new packages. (Workaround is 6 lines of zshrc; fallback pin is a zinit ice change.)

**Version verification:** `zsh 5.9.2`, `fzf 0.74.4`, `stow 2.4.1` re-confirmed live this session; plugin HEAD == upstream HEAD verified via `gh api .../commits/main` vs local `git log`.

## Package Legitimacy Audit

No external packages are installed by this phase — all edits are to `zsh/.zshrc` (and possibly a zinit pin line), `README.md` troubleshooting note, zero new files except none (hook lives in existing zshrc). Audit table N/A by design.

**Supply-chain notes for planner:** (1) autocomplete auto-clones `marlonrichert/zasync` on first prompt if missing (present here — no action). (2) Do NOT patch files under `~/.local/share/zinit/plugins/` — unmanaged, overwritten by `zinit update`. (3) If R-4 pin is taken, it fetches tag `26.08.04` tarball/refs from GitHub — same trust domain as the existing clone.

## Architecture Patterns

### System Architecture Diagram

```text
Every keystroke (viins)
        │
        ▼
zle line-pre-redraw hook chain
  (.autocomplete:async:complete  ← registered at first precmd)
        │
        ├── KEYS_QUEUED_COUNT/PENDING? ──yes──▶ return (still typing)
        ├── LASTWIDGET in ignore set? ──yes──▶ return
        └── otherwise ──▶ zasync wait (delay, default 0.05s)
                                │
                    ╳ BREAKS HERE (R-1): zasync is an
                      unresolved stub → calls no-op (rc 0)
                      → worker never starts → no list,
                      no log file, no error
                                │
                     (when fixed: zasync complete in pty
                      worker → callback → ._list_choices
                      → zle -R + autosuggest POSTDISPLAY)

Tab key ownership chain (load order = layering) — LIVE-VERIFIED ^I=menu-select:
  zshrc:65  bindkey -v            (main aliases viins)
  plugin load  main[^I]=complete-word, menuselect populated
  zshrc:330  atload: ^I→menu-select (viins), kcbt→reverse-menu-complete
  zshrc:349  source <(fzf --zsh): ^I→fzf-completion  ← CLOBBERS atload
  zshrc:363  ^R re-assert (existing) + zshrc:369 ^I→menu-select re-assert
  live:      bindkey '^I' == menu-select ✓ (R-6)
  MISSING:   bindkey -M menuselect '^I' menu-complete (R-7, add it)

Stow shapes (target $HOME, package nvim) — CLOSED, unchanged:
  folded (bug):    ~/.config ──symlink──▶ repo/nvim/.config
  unfolded (fix):  ~/.config/ (real) ──▶ nvim/ (real) ──▶ *.lua symlinks
```

### Recommended Project Structure

No new files. All changes are in-place edits (prior 04-01 shipped `zsh/.zshenv`; nothing new needed):

```text
zsh/.zshrc            # R-3 fixup hook + R-7 menuselect-^I line (+ existing baseline kept)
README.md             # troubleshooting note: stale-stub workaround + `zinit update` retires it (atomic-docs)
setup.sh              # untouched this round (STOW-01 closed)
nvim/.config/         # untouched this round (eviction done)
```

### Pattern 1: fzf-ladder re-assert (shipped 04-01, live-verified this session)

**What:** Owned keys are re-bound after `source <(fzf --zsh)` because fzf 0.74.4 unconditionally binds `^I`. `^R` follows the pre-existing line-341 precedent; `^I` joins it at line 369.
**Status:** `bindkey '^I' == menu-select` confirmed live [local-confirm]. Keep; never "fix" by deleting the fzf ladder (Ctrl+R ownership depends on it).

### Pattern 2: one-shot precmd fixup hook (NEW — R-3 prescription)

**What:** Repair registrations that are only creatable at/after first precmd via a self-removing `precmd` hook — never via load-time lines (timing trap: load-time `unfunction` is a no-op).
**When to use:** Here for the zasync stub; generally for any first-precmd-created state.
**Example:** see R-3 snippet (6 lines, with upstream-issue comment + retire condition).

### Pattern 3: zstyle knobs are read dynamically — keybindings are load-ordered (unchanged)

`:autocomplete:*` styles are read at event time so they can live anywhere before first use; `bindkey` lines must come after plugin load (atload or later) AND after the fzf ladder for clobbered keys. Upstream: keybindings customized "after loading Autocomplete" [ctx7: CONFIGURATION.md keybindings].

### Pattern 4: Stow prevention = flag + guard + loud verify (CLOSED, unchanged)

`mkdir -p "$HOME/.config"` before any stow run; `--no-folding` on every `stow` invocation; `post_verify` intermediate-dir non-symlink assertion. STOW-01 verified; no further work.

### Anti-Patterns to Avoid

- **Bare `unfunction zasync` / `autoload` lines at zshrc load time "to fix" async:** no-op (stub doesn't exist until first precmd) and misleading. Use the one-shot precmd hook (R-3).
- **Patching `~/.local/share/zinit/plugins/...` directly:** evaporates on `zinit update`. Fix in `zsh/.zshrc` (hook) or pin the version (R-4).
- **`zinit update` as the fix today:** no-op (HEAD == installed, fixes unmerged). Schedule it as the hook-retirement step, not the repair step.
- **Uncommenting the `zicompinit`/`zicdreplay` finalize block "to fix" completion:** upstream requires *removing* compinit calls — autocomplete runs compinit itself at first precmd [ctx7: install requirements]. Keep the block removed with its why-it-stays-out comment.
- **Adding the "arrows always move cursor" override:** would break D-32 (Right-arrow must navigate the open menu — upstream default).
- **Adding the "Enter always submits" override:** would break D-05 (first Enter must select-into-buffer).
- **Setting `ZSH_AUTOSUGGEST_STRATEGY` to include `completion`:** its setup runs `bindkey '^I' autosuggest-capture-completion` — the one autosuggest-side Tab vector. Strategy stays default `(history)` (prior trace, still valid).
- **Overriding `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS`:** would clobber the D-28 `forward-char`/`vi-forward-char` defaults. Never set it.
- **Installer detecting/repairing a symlinked `~/.config`:** explicitly forbidden (D-26). Closed; no revisit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async backend loading | Custom zpty worker or `zle -R` loop | R-3 hook + upstream `delay`/`timeout`/`cooldown` knobs | pty worker, timeout accounting, retry-cooldown already implemented; the bug is one stale stub, fixed in 6 lines |
| Stale-stub removal logic | Custom `precmd` wrapper with ordering guards | `add-zsh-hook precmd` one-shot (order-independent per R-3 analysis) | Hook system handles ordering; self-removal keeps it one-shot |
| Truncation hint | Custom "(more)" marker widget | Upstream `(MORE)` marker (automatic on partial lists) | Zero code; satisfies D-17 |
| History exclusion | Custom completer filter | Default context (no `default-context` style set) | History enters only via toggle contexts [ctx7 + prior source read] |
| Menu navigation keys | Custom menuselect binds | Upstream menuselect defaults + R-7's one missing line | Any override risks D-07/D-32 regressions |
| Fold-safe symlinking | Custom `ln -sf` loop | `stow --no-folding` + `mkdir -p` guard | Closed (STOW-01); custom loops mishandle `-t /` (REQUIREMENTS Out-of-Scope) |
| Completion-system init | Eager `compinit`/`zicompinit` calls | Autocomplete's first-precmd compinit | Upstream: "Remove any calls to compinit" [ctx7] |

**Key insight:** Gap 1 is an upstream regression with an upstream workaround — the phase is now "apply + verify live," not "diagnose." Gap 2 is reframed as verify-after-Gap-1 plus one canonical bind line. The planner should sequence: diagnostics → hook → live auto-show check → D-29 re-check → menuselect line → full D-14 regression.

## D-01..D-04 Feasibility Map (binding caveat answered — unchanged, all achievable)

| Decision | Verdict | Real knob / default |
|----------|---------|---------------------|
| D-01 auto-show on first char, no delay | ACHIEVABLE (blocked only by R-1 bug) | `min-input 1` + `delay 0` baseline (shipped 04-01); unblocks when zasync loads [ctx7: delay/timeout/min-input] |
| D-02 quiet on empty prompt | DEFAULT, no config needed | Empty word (length 0 < min-input 1) suppresses the list (prior source read, still valid) |
| D-03 ghost + list coexist | DEFAULT, no config needed | Upstream "automatically handles compatibility with zsh-autosuggestions and fast-syntax-highlighting" [ctx7]; independent render paths |
| D-04 every context | EXPECTED from defaults, VERIFY LIVE | Fallback `setopt completeinword` if any context fails live (unchanged) |
| D-20 no history in list | DEFAULT | History only under toggle contexts; do NOT set `default-context` (unchanged) |
| D-21 prefix-only | LIKELY default, MUST VERIFY LIVE (open question, unchanged) | Default completer chain includes `_complete:-fuzzy`; live probe decides; narrowing knob documented in prior pass |
| D-16 thousands-scale cutoff | ACHIEVABLE via `list-lines` | Researcher pick stands: `zstyle -e ':autocomplete:*:*' list-lines 'reply=( 300 )'` (shipped 04-01) [ctx7: list-lines] |
| D-17 truncation hint | DEFAULT | `(MORE)` automatic (unchanged) |
| D-22 result ordering | KEEP UPSTREAM DEFAULT | `group-order` override only if user dislikes feel live (unchanged) |

## D-28 Provider Trace (unchanged — upstream defaults, zero local config)

`ZSH_AUTOSUGGEST_ACCEPT_WIDGETS` defaults include `forward-char` (Right-arrow, insert mode) and `vi-forward-char` (`l`, vi-normal mode); `zsh/.zshrc` never touches them (grep-verified prior pass, untouched since). Fix must not rebind those widgets and must never set `ZSH_AUTOSUGGEST_ACCEPT_WIDGETS`. (Prior pass, still true — no re-verification needed, files unchanged.)

## D-29 Trace Update (R-6 reframes: binds correct, glitch is downstream)

Prior trace verified: (1) fzf rebind is the primary Tab-hijack vector — CONTAINED by shipped preset + re-assert, now live-confirmed (`^I == menu-select`); (2) autosuggest self-bind absent under default strategy — still true. New: with binds proven correct live, the observed ghost-bold-then-vanish is NOT bind misownership. Ranked candidates in R-8; planner works them only after Gap 1 is fixed, in listed order.

## Key-Binding State Reference (planner's ground truth — one correction)

| Key | Context | Behavior | Change this round |
|-----|---------|----------|-------------------|
| Tab | menu closed | `menu-select` (live-verified) | none — keep re-assert |
| Tab / Shift-Tab | menu open | SHOULD be `menu-complete` / `reverse-menu-complete` per upstream README recipe [ctx7] | **ADD `bindkey -M menuselect '^I' menu-complete`** (missing; kcbt line stays) |
| ← → ↑ ↓ | menu open | move selection (upstream default) | none |
| Enter | menu open | select into buffer (default; verify second-Enter runs live) | none |
| Ctrl+C | menu open | exit menu | none |
| Esc | anywhere | untouched | none |
| Right-arrow | menu open → navigate; closed → ghost-accept | upstream default + D-32 | none (protect) |
| `l` (vicmd) | — | ghost-accept via stock `vi-forward-char` (D-28) | none (protect) |
| Ctrl+Space / Ctrl+_ | menu closed | ghost accept/execute (local atinit) | none (keep) |
| Ctrl+R | anywhere | fzf history (split ownership) | none |

Ordering invariants preserved: p10k instant prompt at top; `bindkey -v` before plugin loads; tail `path=( $path )` last; `.zshrc.local` after tool inits / before p10k apply.

## Live Diagnostics Checklist (ad-hoc commands, D-13-compliant — planner turns into tasks)

Run in a **real interactive terminal** (headless `-c` probes cannot fire precmd — verified inconclusive this session):

1. `whence -v zasync` — must show the **file** `…/.cache/zsh/zasync/zasync`. Shows the bare directory (or stale stub) → R-1 still present. [gh-repo #907]
2. `ls ~/.local/state/zsh-autocomplete/log/` — a dated log file must appear after typing. Empty → pipeline never started. [gh-repo #907 + local-confirm empty baseline]
3. `bindkey '^I'` → must report `menu-select`; `bindkey -M menuselect '^I'` → `menu-complete` after R-7. [local-confirm + ctx7]
4. `type -a _autocomplete__history_lines` — if missing → #903-class helper problem (expect present; user never saw the errors). [gh-repo #903]
5. Type-pause-observe in all D-04 contexts (command/arg/path/`sudo`/mid-word); empty-prompt quiet; ghost+list coexist. [D-14 item 2]
6. Tab-with-ghost → must open/navigate menu, never insert ghost (D-29 re-check AFTER Gap 1 fixed). [D-14 item 3]
7. Remainder of extended D-14 (items 1, 4, 5 already PASS — regression-guard them).

## Stow Findings (CLOSED — preserved verbatim from prior pass, still true)

1. **Bug reproduced:** empty target + `stow nvim` → folded `~/.config -> ../repo/nvim/.config` symlink (sandbox lab2).
2. **`--no-folding` accepted** despite missing from `stow --help` text; produces real dirs + leaf symlinks only (sandbox lab1).
3. **Uninstall parity:** `stow --no-folding -D nvim` on a legacy FOLDED tree removes the folded link cleanly (lab2) — `-R --no-folding` migrates folded→unfolded in one step.
4. **Prevention-only proven:** `--no-folding -S` with symlinked `~/.config` aborts loudly (`existing target is not owned by stow: .config`, rc=1, zero writes) — exactly D-26 behavior.
5. **Post-repair shape:** real `~/.config` with sibling dirs + `--no-folding -S nvim` links only leaves (lab4).
6. All `setup.sh` stow call sites + `post_verify` fold-detector design + D-25 eviction facts + D-26 runbook: unchanged from prior pass (04-VERIFICATION.md marks STOW-01 SATISFIED; live item 6 PASS). **Planner: no stow tasks.**

## Common Pitfalls

### Pitfall 1: fzf --zsh steals Tab AFTER autocomplete binds it (contained, live-verified)

Live `^I` = `menu-select` today (R-6). Keep preset + re-assert. Never "fix" by deleting the fzf ladder. **Warning sign:** `bindkey '^I'` reporting `fzf-completion` after reload.

### Pitfall 2 (NEW): load-time `unfunction zasync` is a silent no-op (timing trap)

The stub is born at first precmd; source-time lines run before that. Without the one-shot precmd hook the "fix" does nothing and looks applied. **Warning sign:** `whence -v zasync` still shows the directory after reload.

### Pitfall 3 (NEW): `zinit update` as the repair step

HEAD == installed and both fix PRs are OPEN — update changes nothing today. It is the hook-*retirement* step (post-merge), not the repair. **Warning sign:** planner task "update plugin" with no workaround alongside.

### Pitfall 4 (NEW): patching the installed plugin file instead of zshrc

`~/.local/share/zinit/plugins/...` is unmanaged; the edit evaporates on next update with no marker. Keep the fix in versioned `zsh/.zshrc`.

### Pitfall 5: "Fixing" completion by uncommenting zicompinit block

Eager double compinit fights autocomplete's first-precmd init. Keep removed with the why-it-stays-out comment. [ctx7]

### Pitfall 6: planning a rebind-only fix for auto-show (D-34 violation, now with evidence)

Auto-show death is stub-level (R-1), independent of binds. The H-1..H-7 checklist is retired for Gap 1 — replaced by the R-3/R-4 fix choice + live diagnostics.

### Pitfall 7: re-stowing before evicting strays / post_verify passing folded trees / Ubuntu double-init / offline-first-prompt (unchanged, closed with STOW-01)

See prior pass §Pitfalls 4–7 / Stow Findings. No action this round.

## Code Examples

### R-3 fixup hook (place AFTER the autocomplete `zi light` line, anywhere before first use)

```zsh
# Workaround: upstream #907/#905 — failed `autoload +X` probe leaves a stale
# `zasync` stub that silently kills real-time auto-show (Tab keeps working).
# Retire after `zinit update` past the upstream fix. [gh-repo]
autoload -Uz add-zsh-hook
_fix_zasync_once() {
  unfunction zasync 2>/dev/null
  autoload -Uz ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zasync/zasync
  add-zsh-hook -d precmd _fix_zasync_once
}
add-zsh-hook precmd _fix_zasync_once
```

### R-7 missing menuselect line (next to the existing kcbt line)

```zsh
# Upstream README recipe: Tab enters AND moves inside the menu. [ctx7]
bindkey -M menuselect '^I' menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete  # existing, keep
```

### D-01 baseline zstyle block (shipped 04-01 — keep as-is)

```zsh
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' delay 0
zstyle -e ':autocomplete:*:*' list-lines 'reply=( 300 )'
```

### Ladder comment block (shipped 04-01 — keep as-is; see zshrc:291-297)

Unchanged. Atomic-docs: any R-3/R-7 behavior change ships with its README troubleshooting note in the same commit (D-31/Phase-1 rule).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Diagnose auto-show via H-1..H-7 checklist | Apply R-3 hook (root cause closed upstream) | This refresh (upstream #903/#905/#907, Sept 2026) | Phase becomes apply+verify-live; D-34 freedom spent on fix *choice* (hook vs pin), not cause-hunting |
| Tab ownership assumed from atload order | Re-assert owned keys after fzf ladder (live-verified) | 04-01, confirmed this refresh | Tab deterministically `menu-select` |
| Commented zicompinit kept "just in case" | Removed + why-it-stays-out comment | 04-01 | Removes highest-risk well-meaning regression |
| Vendored z-async via fpath (26.08.04) | Clone-at-init (broken tip 77706d4) | Upstream #894, 2026-08-26 | Regression window; pin R-4 reverts to vendored behavior as fallback |
| In-menu Tab left to stock default | Explicit `menuselect ^I → menu-complete` | This refresh (R-7) | Matches upstream README recipe exactly |

**Deprecated/outdated:**
- The H-1..H-7 flat hypothesis checklist for Gap 1 (superseded by R-1 dispositions above).
- Prior "kcbt line is redundant" note (corrected by R-7: the kcbt line stays; the *missing* menuselect-`^I` line is added).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 (retired) | ~~Tab-accepts-ghost is fzf-wrapper fallback~~ — binds live-verified correct; reframed as R-6/R-8 | D-29 trace | — (resolved by live probe) |
| A2 | Upstream Enter-in-menu selects-into-buffer without executing | D-05 | MEDIUM — confirm in live regression; inverse override documented if it executes |
| A3 | D-04 mid-word/`sudo` contexts work from defaults | Feasibility map | LOW — `setopt completeinword` fallback documented |
| A4 | `list-lines 300` is a good thousands-scale cutoff | D-16 | LOW — discretion + user judges live; screen-fit binds anyway |
| A5 | Unset `$terminfo[kcbt]` won't break atload | Keybindings | LOW — alacritty/linux define kcbt; failure mode is Shift-Tab only |
| A6 (NEW) | R-3 hook placement reasoning (order-independent convergence) | R-3 | MEDIUM — derived, not live-tested; planner's FIRST live check (`whence -v zasync` = file) falsifies fast; fallback R-4 documented |
| A7 (NEW) | Stock menuselect `^I` default already equals `menu-complete` (R-7 line is belt-and-braces) | R-7 | LOW — line is upstream-canonical either way; live `bindkey -M menuselect` confirms |
| A8 (NEW) | Exact zinit tag-pin ice syntax for R-4 | R-4 | LOW — fallback path only; planner checks `zinit help` if taken |
| A9 (NEW) | `_autocomplete__history_lines` helpers ARE registered on this machine (no user-reported errors) | R-8(c) | LOW — one live `type -a` command confirms; failure routes to #903-class handling |

## Open Questions

1. **Does the R-3 hook converge live on this machine? (A6)**
   - What we know: mechanism from #905 (clean-`zsh -f` repro, 51/51 tests) + workaround from #907 (works immediately, no restart).
   - What's unclear: hook-vs-plugin-precmd interplay in our exact zinit/p10k stack.
   - Recommendation: planner's first live task is the `whence -v zasync` check; R-4 pin is the pre-approved fallback — no re-research needed either way.
2. **Does the auto-show list surface fuzzy (`_complete:-fuzzy`) matches? (D-21, carried)**
   - Unchanged from prior pass: live probe decides; narrowing knob documented.
3. **Gap 2 mechanism if it survives the Gap 1 fix? (R-8)**
   - Work candidates (b)→(c)→(d) in listed order after the D-29 re-check. No further research — all live-adjudicated.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| zsh | interactive shell | ✓ | 5.9.2 | — |
| GNU Stow | installer + repair | ✓ | 2.4.1 | — (STOW-01 closed) |
| fzf | Ctrl+R + extras | ✓ | 0.74.4 (native `--zsh` rung) | ladder degrades to warn-and-continue |
| git | zinit plugins, zasync, snippet updates | ✓ | (present) | — |
| `~/.cache/zsh/zasync` | async list backend | ✓ present (file EXISTS) | clone @Sep-21 | registration fix (R-3), not reinstall |
| `~/.local/state/zsh-autocomplete/log/` | async health signal | ✓ exists, EMPTY (dead-pipeline signature) | — | must gain dated log after R-3 |
| Upstream fix merge (#903/#905) | hook retirement | ✗ (both OPEN) | — | R-3 hook now, `zinit update` later |
| Live `bindkey '^I'` | D-29 static proof | ✓ `menu-select` | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** upstream merge (fallback: local hook — the plan).

## Security Domain

Applicable: phase touches only `zsh/.zshrc` lines + README note; no privileged paths, no installer changes this round.

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No (no keyd/setup.sh changes this round) | — |
| V5 Input Validation | Yes (minor) | Hook uses only `${XDG_CACHE_HOME:-$HOME/.cache}` expansion — no external input; `2>/dev/null` on `unfunction` |
| V6 Cryptography | No | — |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| zasync auto-clone executing remote code at first prompt | Supply-chain | Pre-existing upstream behavior, unchanged; clone already present so hook triggers no network |
| Version pin fetching a different tag (if R-4) | Supply-chain | Same GitHub trust domain as current clone; tag `26.08.04` is an official release |

## Sources

### Primary (HIGH confidence — upstream authoritative, fetched this session)

- [gh-repo] `marlonrichert/zsh-autocomplete` issue #907 (OPEN, 2026-09-18): stale/directory `zasync` autoload kills real-time silently; line `Functions/Init/.autocomplete__async:25`; `unfunction`+file-`autoload` workaround; `26.08.04` unaffected; empty log dir signature
- [gh-repo] PR #905 (OPEN, 2026-09-12): stale-stub mechanism (failed `+X` probe leaves undefined stub; absolute-path autoload doesn't replace); clean-`zsh -f` repro; 51/51 tests
- [gh-repo] PR #903 (OPEN, 2026-09-03; fixes #901): "Manual completion still works, but the completion menu does not appear automatically while typing"; fpath-scope + force-load `+X` + `Completions/` helper registration; tested Fedora zsh 5.9 + macOS
- [gh-repo] Issue #901 (OPEN, 2026-09-15) + PR #894 (MERGED 2026-08-26, un-vendored zasync): regression window + corroborating Sept-breakage reports
- [gh-repo] `gh api .../commits/main` HEAD = `77706d4` == installed plugin HEAD (local `git log`) — update-is-no-op proof
- [local-confirm] `~/.cache/zsh/zasync/zasync` file EXISTS; log dir exists-but-empty; `.autocomplete__async` lines 16/17/25 grep-verified; live `bindkey '^I'` = `menu-select` (`zsh -i -c` probe, RC=0)
- [ctx7] `/marlonrichert/zsh-autocomplete` docs: Tab recipes (`^I → menu-select` + `menuselect ^I → menu-complete`), install requirements (remove compinit, source before compdef, Ubuntu `skip_global_compinit=1`), delay/timeout/min-input/list-lines knobs, autosuggestions/FSH compatibility statement

### Secondary (MEDIUM — prior-pass sources, still true, files unchanged since)

- Installed plugin source read (`.autocomplete__{main,async,compinit,config,key-bindings,widgets}`), autosuggestions v0.7.1 defaults (`src/config.zsh` ACCEPT widgets, `completion.zsh` Tab vector), live fzf 0.74.4 integration (`^I` capture/rebind), stow 2.4.1 sandbox labs 1–4, `zsh/.zshrc` + `setup.sh` call-site greps

### Tertiary (LOW — marked [ASSUMED], for live adjudication)

- A2–A9 assumptions log; Gap 2 candidates (a)/(d); R-3 convergence reasoning; R-4 pin syntax

## Metadata

**Confidence breakdown:**
- Gap 1 root cause: HIGH — three converging upstream reports on the exact installed commit + matching local dead-pipeline signature (gsd confidence seam unavailable in this env; tier reasoned from source hierarchy: upstream primary sources)
- Gap 2 mechanism: MEDIUM — binds proven correct live, candidates ranked, needs post-Gap-1 live adjudication
- Standard stack: HIGH — versions verified live; HEAD-equality verified via gh api + local git
- Architecture (hook/async pipeline with break point, Tab layering): HIGH — upstream-issue-grounded + live bindkey probe
- Pitfalls: HIGH (timing trap, update-no-op, no-plugin-patching all follow directly from R-1/R-2)
- Feasibility map D-01..D-04/D-16/D-20/D-22: HIGH except D-21 (MEDIUM — live probe required, unchanged)
- Stow: HIGH, closed — no change this round

**Research date:** 2026-09-22 (refresh)
**Valid until:** ~30 days, EXCEPT re-check upstream PRs #903/#905 on every planner run — either merging retires the R-3 hook via `zinit update`. If auto-show still fails after R-3+R-4, re-open: the next suspect is helper registration (#903 second half), diagnosable by Open Question 3's `type -a` probe.
