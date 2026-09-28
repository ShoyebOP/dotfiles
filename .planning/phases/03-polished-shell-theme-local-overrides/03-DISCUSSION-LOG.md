# Phase 3: Polished Shell, Theme & Local Overrides - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 3-Polished Shell, Theme & Local Overrides
**Areas discussed:** Fzf history wiring, PATH dedup scope, Local overrides shape, Theme token + check

---

## Fzf history wiring

| Option | Description | Selected |
|--------|-------------|----------|
| fzf-search only | Keep joshskidmore Ctrl+R, drop marlonrichert autocomplete — simplest, loses type-ahead | |
| Both, split ownership | fzf-history-search owns Ctrl+R, autocomplete owns Tab/^I with fixed load order | ✓ |
| Autocomplete + native fzf | Drop joshskidmore, use fzf native widgets + autocomplete | |

**User's choice:** Both, split ownership — plus explicit priority ladder: autocomplete must work > fix fzf in zshrc (zinit plugin) > system-installed fzf > skip fzf. "fzf search is not a priority now so if there is any conflict with it we can remove it, the main thing need to work is the autocomplete."
**Notes:** Symptom is NOT keybinds — async find-as-you-type never auto-shows, user must press Tab. Fixed behavior: auto-show list as you type, Tab only enters menu-select. Always bind `^R` (overrode conditional-key recommendation); warn-if-missing when fzf absent. Keep autosuggestions + highlighting coexisting (overrode drop-autosuggestions option).

## PATH dedup scope

| Option | Description | Selected |
|--------|-------------|----------|
| Top-of-file dedup | `typeset -U path` at top so all later exports auto-dedupe | ✓ |
| Bottom dedup only | Dedup only at bottom — late appends could re-duplicate | |
| Rewrite PATH block | Single array block instead of scattered exports | |

**User's choice:** Top-of-file dedup covering ALL PATH lines "but make sure nothing breaks"; keep-first semantics; verify via repeated-reload dupe-check PLUS z/zi/completions/prompt smoke.
**Notes:** Covers 5 top exports + polaris/bin (~line 232) + bun/uv additions.

## Local overrides shape

| Option | Description | Selected |
|--------|-------------|----------|
| Both files | Repo `zsh/.zshrc.local` + `~/.zshrc.local`, repo-then-HOME precedence | initially picked, then overridden |
| HOME only | Only `~/.zshrc.local` sourced | ✓ (final) |

**User's choice:** HOME-only — "i want .zshrc.local to be only stay at home". Nvim `local.lua` via pcall at end of init.lua after colorscheme schedule. Gitignore both; setup.sh creates both empty local files in HOME deployed locations post-setup so they never enter the repo; ship `*.example` templates.
**Notes:** Overrides ROADMAP success criterion #3 dual-file text — planner must note the delta.

## Theme token + check

| Option | Description | Selected |
|--------|-------------|----------|
| Warn-only | setup.sh warns on mismatch without rewriting | rejected |
| Enforce + rewrite | Single token propagated by rewriting all 4 configs | rejected |

**User's choice:** Neither — "no need to warn or do anything it is intended drift". Drop all Phase 3 theme work; close THEM-01 as intentionally-drifted.
**Notes:** Mapping (alacritty mocha / starship latte / nvim tokyodark / p10k classic mocha) is intentional. Researcher/planner must not flag it as a bug.

---

## Agent's Discretion

None — user decided every option (including two explicit overrides: HOME-only sourcing, full theme drop). No "You decide" selections.

## Deferred Ideas

- **History + secret purge across all branches (user-requested, NOT Phase 3):** `zsh/.zsh_history` verified tracked in git and absent from `.gitignore`; key-name mentions in `nushell/.config/nushell/env.nu` + `AGENTS.md` (values never reproduced). Working-tree untrack+gitignore may ride Phase 3; full all-branches history rewrite + rotation is SECR-02 (v2, force-push coordination).
- **Debian keyd fully-automated git-build path** — carried from Phase 2.1 deferred.
- **AUTO-01/AUTO-02 backup snapshot + CI matrix** — v2 per REQUIREMENTS.md.
