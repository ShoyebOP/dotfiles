# Phase 4: fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-22
**Phase:** 5-fix-marlonrichert-zsh-autocomplete-real-time-type-ahead-comp
**Areas discussed:** Stow .config containment, Ghost-accept vs Tab keys, Keybinding priority ladder, Expand change boundary
**Mode:** Update of existing 04-CONTEXT.md (user requested additions missed in 2026-09-17 discussion)

---

## Stow .config containment

| Option | Description | Selected |
|--------|-------------|----------|
| --no-folding always | Pass `stow --no-folding` on nvim (or all) stows | |
| mkdir ~/.config first | Installer `mkdir -p ~/.config` before stow | |
| Both defenses | mkdir guard + --no-folding belt-and-suspenders | ✓ |
| You decide | Agent picks guard; end state = only ~/.config/nvim linked | |

**User's choice (Q1):** Free-text first — "can you tell me if all the folder structure is same or not and why only the nvim one did this" — agent explained all XDG packages share `pkg/.config/...` shape; fold fired only because `~/.config` was missing/empty at the 2026-09-21 16:09 stow moment; nvim uniquely carries opencode/lazygit/context7 siblings. User then chose **Both defenses**.

| Option | Description | Selected |
|--------|-------------|----------|
| Evict from package | Move siblings to real ~/.config, delete from repo, package keeps only .config/nvim | ✓ |
| Gitignore only | Leave physically, gitignore (still stow-links siblings) | |
| Own packages | Promote opencode/lazygit/context7 to first-class stow packages | |
| You decide | Ensure nvim package only deploys ~/.config/nvim | |

**User's choice (Q2):** Evict from package.

| Option | Description | Selected |
|--------|-------------|----------|
| Repair in this phase | Break symlink, real mkdir, relocate, re-stow, verify | ✓ |
| Installer detects/repairs | Check on next setup.sh run | |
| Docs-only repair | Manual commands documented, no automation | |
| You decide | Real ~/.config, data intact, only nvim linked | |

**User's choice (Q3):** Repair in this phase — later amended: repair is **executor hand-work**, never installer code (see Expand change boundary notes).

**Notes:** Freeform structural analysis requested before deciding prevention; fold evidence: `~/.config -> dotfiles/nvim/.config` + `~/.zshrc -> dotfiles/zsh/.zshrc` same timestamp; dry-run shows `LINK: .config => .../nvim/.config`.

---

## Ghost-accept vs Tab keys

| Option | Description | Selected |
|--------|-------------|----------|
| Right-arrow + l, keep Ctrl | Ghost keys = Right-arrow + vi-normal l + Ctrl+Space/Ctrl+_; amends D-08 | ✓ |
| Right-arrow + l only | Strip Ctrl binds — minimal set | |
| Right-arrow only | Honor original D-08 drop of l | |
| You decide | Tab never ghost-accept; Right-arrow works; vi motions untouched | |

**User's choice (Q1):** Right-arrow + l, keep Ctrl.

| Option | Description | Selected |
|--------|-------------|----------|
| Actively unbind Tab | Trace hijack, unbind, Tab always menu-select, verified live | ✓ |
| Never bind only | Never add Tab ghost bind; report findings only | |
| Unbind + warn | Unbind + startup assertion if Tab resolves to autosuggest-accept | |
| You decide | Hard rule: Tab with ghost visible opens/navigates menu | |

**User's choice (Q2):** Actively unbind Tab.

| Option | Description | Selected |
|--------|-------------|----------|
| l accepts only if ghost | Conditional accept; stock motion when no suggestion | |
| l accepts + insert | Accept full ghost, switch to insert mode | |
| Drop l again | Revert to original D-08 drop | |
| You decide | Plain l motion must work when no ghost | |

**User's choice (Q3):** Free-text — "it works now as it is. so not modification needed just make sure nothing breaks it. same with right arrow" → preserve-as-is, protect only; researcher documents current providers.

---

## Keybinding priority ladder

| Option | Description | Selected |
|--------|-------------|----------|
| Autocomplete first | autocomplete > autosuggestions > fzf > stock vi/zle | ✓ |
| Vi motions win | Same + plugins claim motion keys only when suggestion/menu visible | |
| Only known keys | Document split ownership only; researcher invents rest | |
| You decide | Must place Tab, Ctrl+R, Right-arrow, l, Esc, Ctrl+C, Ctrl+Space, Ctrl+_, Shift-Tab | |

**User's choice (Q1):** Autocomplete first.

| Option | Description | Selected |
|--------|-------------|----------|
| Comment in .zshrc | Ladder comment block at plugin section top | |
| Planning docs only | CONTEXT/DISCUSSION-LOG only | |
| Comment + README | Comment block + README ownership table | ✓ |
| You decide | Ladder findable without re-asking | |

**User's choice (Q2):** Comment + README.

| Option | Description | Selected |
|--------|-------------|----------|
| Menu wins when open | menuselect Right-arrow navigates; ghost-accept only menu closed | ✓ |
| Ghost always wins | Right-arrow always accepts ghost; menu via Tab/arrows only | |
| Keep current feel | Plugin defaults; researcher documents actual behavior | |
| You decide | Unambiguous in ladder comment | |

**User's choice (Q3):** Menu wins when open.

---

## Expand change boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Full expansion | zshrc + setup.sh (guards/mkdir/post-verify/uninstall) + docs + nvim tree + one-time live repair | ✓ |
| Expansion, repair one-off | Same but repair never reusable installer code | |
| Minimal — defer rest | Keep D-18 tight; defer eviction/repair | |
| You decide | You define file/system surface | |

**User's choice (Q1):** Full expansion.

| Option | Description | Selected |
|--------|-------------|----------|
| Preview + yes gate | Repair shows plan, typed yes, --dry-run support | |
| Manual guided only | Executor talks user through; no automated mutation | ✓ (via freeform) |
| Preview, --yes bypass | Preview but --yes skips confirm | |
| You decide | You choose safety level | |

**User's choice (Q2):** Free-text — "repair should be done by hand not by the script so in future it never tries to repair at all" then "confirm but by hand i meant executor" → executor hand-repairs once; installer prevention-only, never auto-repairs.

**Notes:** Confirmed boundary + repair split explicitly before closing area.

---

## Post-area addition (user freeform at completion gate)

- "i don't completely belive the autocomplete menu not appearing is a keybind issue so the researcher must explore all the possibilites and based on it's research planner should have complete freedom on what to do" → captured as **D-34** (root cause open, planner freedom bounded only by locked outcomes).

## the agent's Discretion

- D-09 fzf/autocomplete clash resolution (fzf loses by default)
- D-22 completion list ordering (researcher picks; user judges live)
- D-16 thousands-scale cutoff number (researcher picks; user judges live)
- Exact widgets for D-27..D-29 (end-state behavior locked)
- Post-verify adjustments for --no-folding (D-33)
- Fix approach entirely per D-34 (root cause open)

## Deferred Ideas

None — stow containment explicitly pulled into phase by user; ladder/ghost work is in-scope keybinding ownership for the autocomplete fix.
