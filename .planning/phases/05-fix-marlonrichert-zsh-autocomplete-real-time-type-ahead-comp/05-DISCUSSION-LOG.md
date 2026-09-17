# Phase 5: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 5-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp
**Areas discussed:** Auto-show trigger sensitivity, Menu key behavior, fzf coexistence boundary, How we prove it's fixed, Vi-mode interplay, List noise guard, Change boundary, Completion sources, Research method

---

## Auto-show trigger sensitivity

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate | List pops on the first typed character | ✓ |
| After 2 chars | Wait for 2+ characters before listing | |
| Small delay | Brief pause after typing stops | |

**User's choice:** Immediate (Recommended)
**Notes:** User challenged "are these even configurable?" — agent committed that D-01..D-04 are desired outcomes the researcher must map to real knobs, reporting back alternatives for anything unachievable.

| Option | Description | Selected |
|--------|-------------|----------|
| Stay quiet | No list on empty prompt until first char | ✓ |
| Suggest on empty line | Recent/common commands before typing | |

**User's choice:** Stay quiet (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Both coexist | Ghost inline + dropdown below, own accept keys | ✓ |
| Ghost yields to list | Ghost hides while dropdown open | |
| Ghost leads, list quieter | Ghost primary, dropdown minimal | |

**User's choice:** Both coexist (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Everywhere | All contexts: commands, args, paths, mid-word, sudo | ✓ |
| Commands first, args quiet | Aggressive at command position only | |
| You decide | Researcher picks per-context eagerness | |

**User's choice:** Everywhere (Recommended)

---

## Menu key behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Enter selects first | Highlighted item goes to buffer; second Enter runs | ✓ |
| Enter executes directly | Highlighted item runs immediately | |

**User's choice:** Enter selects first (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Esc cancels cleanly | Close dropdown, keep typed text | ✓ (superseded — see Vi-mode interplay) |
| Esc accepts then closes | Accept suggestion before closing | |

**User's choice:** Esc cancels cleanly — later refined: Esc stays 100% stock vi, Ctrl+C dismisses the list.

| Option | Description | Selected |
|--------|-------------|----------|
| Tab / Shift-Tab cycle | Forward/back cycling, arrows also work | ✓ |
| vi-style hjkl | hjkl navigate the open list | |

**User's choice:** Tab / Shift-Tab cycle (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current keys | Ctrl+Space accept, Ctrl+_ execute, no change | |
| Add Right-arrow accept | Right-arrow accepts ghost alongside current keys | ✓ |
| You decide | Researcher picks ghost-accept keys | |

**User's choice:** Add Right-arrow accept. Follow-up: user asked to also add `l` in vi normal mode to accept ghost; agent flagged it replaces cursor-right motion; user then withdrew it entirely ("no need to modify as it works now as it is").

---

## fzf coexistence boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Keep fzf extras | ** Tab, Ctrl+T, Alt+C alongside autocomplete | |
| Ctrl+R only | Strip fzf to history-only | |
| You decide on clash | Researcher decides what stays on conflict | ✓ |

**User's choice:** You decide on clash (agent discretion; fzf loses by default per D-02 ladder).

| Option | Description | Selected |
|--------|-------------|----------|
| Expendable | Drop fzf extras silently if deep conflict | ✓ |
| Must-keep extras | Researcher must preserve ** Tab, Ctrl+T, Alt+C | |

**User's choice:** Expendable (Recommended) — matches Phase-3 "fzf is not a priority".

| Option | Description | Selected |
|--------|-------------|----------|
| Don't touch fzf init | Phase-3 ladder frozen, fix autocomplete side only | |
| Free to rework fzf init | Researcher may rework fzf placement/loading | ✓ |

**User's choice:** Free to rework fzf init.

| Option | Description | Selected |
|--------|-------------|----------|
| Autocomplete stays last | D-01 load-order lock preserved | |
| Free to reorder all | Researcher may reorder plugin loads freely | ✓ |

**User's choice:** Free to reorder all — relaxes Phase-3 D-01 order lock; only keep-all-three + split ownership stay.

---

## How we prove it's fixed

| Option | Description | Selected |
|--------|-------------|----------|
| Your live check | User types in real terminal, verdict closes phase | |
| Scripted proof only | Scripted evidence alone, no terminal check | |
| Both | Scripted evidence plus live verdict | ✓ (free-text: "both?") |

**User's choice:** Both — scripted evidence plus live terminal verdict.

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone probe now | Small probe pluggable into Phase-4 harness later | |
| Manual commands only | Documented manual commands, no files | |
| Full harness in Phase 5 | Build --self-test now | |

**User's choice:** Free-text: "phase 4 hasn't been executed so don't need the harness right now" — resolved to live verdict with ad-hoc checks, zero new files (D-13).

| Option | Description | Selected |
|--------|-------------|----------|
| Live verdict, no files | Live check + ad-hoc commands, no new files | ✓ |
| Leave a probe for Phase 4 | Commit standalone probe for later wiring | |

**User's choice:** Live verdict, no files (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Shell spine check | Auto-show + Ctrl+R + ghost + Tab + clean reload | ✓ |
| Auto-show only | Only the auto-show behavior re-verified | |
| You decide | Verifier picks regression list | |

**User's choice:** Shell spine check (Recommended)

---

## Vi-mode interplay

| Option | Description | Selected |
|--------|-------------|----------|
| Dual-action Esc | One Esc closes list AND enters normal mode | |
| Cancel first, mode second | First Esc closes list, second enters normal | |

**User's choice:** Neither — free-text: "no need for conflicts ctrl+c will close it". Esc stays 100% stock vi; Ctrl+C dismisses the list (D-06).

| Option | Description | Selected |
|--------|-------------|----------|
| Fully stock vi | Zero custom vi rebinds beyond decided keys | |
| Allow minor vi extras | Researcher may add harmless vi conveniences | ✓ (qualified) |

**User's choice:** Free-text: "if needed it is allowed to modified but not the main motion should be modified" — core motions untouchable, non-motion keys rebindable only if needed (D-15).

---

## List noise guard

| Option | Description | Selected |
|--------|-------------|----------|
| Raw full list | Full untruncated list, scroll as needed | |
| Cap visible rows | Cap rows with scrolling | |

**User's choice:** Neither as offered — free-text: "it should show full list but if the actual list is more than a certain threshold it should stop as sometimes when there is thousands of possible completions it lags abit" (D-16).

| Option | Description | Selected |
|--------|-------------|----------|
| Researcher picks | Researcher sets cutoff, user judges live | ✓ |
| I name the number | User names max candidate count now | |

**User's choice:** Researcher picks (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Show truncated hint | Visible "…more — keep typing to narrow" | ✓ |
| Silent cut | Truncate without notice | |

**User's choice:** Show truncated hint (Recommended)

---

## Change boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Wherever needed | zshrc + docs + setup.sh if the fix needs it | ✓ |
| zshrc only, frozen rest | Installer and docs frozen | |

**User's choice:** Wherever needed (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| No new plugins | Fix with today's plugin set only | |
| New plugin allowed | Researcher may add a plugin if clean fix | ✓ |

**User's choice:** New plugin allowed.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the engine | zsh-autocomplete stays the engine | |
| Swap allowed if needed | Different engine if proven unfixable | ✓ |

**User's choice:** Swap allowed if needed — engine swap only if researcher proves autocomplete unfixable (D-19).

---

## Completion sources

| Option | Description | Selected |
|--------|-------------|----------|
| Everything at once | Commands, history, files, flags, variables | |
| Commands first, rest later | Commands + history first | |

**User's choice:** Neither — free-text: "it should show everything but not history". History exclusive to Ctrl+R (D-20).

| Option | Description | Selected |
|--------|-------------|----------|
| Researcher orders | Researcher picks ranking, user judges live | ✓ |
| Fixed priority order | Commands, files, flags fixed order | |

**User's choice:** Researcher orders (Recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Fuzzy anywhere | Typed chars match anywhere in candidates | |
| Prefix only | Candidates must start with typed text | ✓ |

**User's choice:** Prefix only.

---

## Research method (user directive, no options presented)

**User's words:** "the researcher should first use ctx7, then if needed github-cli" — recorded as D-23: Context7 docs first, GitHub CLI (issues/source) fallback only if needed.

---

## the agent's Discretion

- D-09 fzf-vs-autocomplete clash resolution (fzf loses by default).
- D-16 thousands-scale cutoff number (user judges live).
- D-22 result ordering in the combined list (user judges live).

## Deferred Ideas

None — discussion stayed within phase scope.
