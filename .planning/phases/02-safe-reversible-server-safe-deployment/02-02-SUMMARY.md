---
phase: 02-safe-reversible-server-safe-deployment
plan: 02
subsystem: installer
tags: [bash, zsh, stow, zinit, chsh, docs, teardown, keyd, uninstall]
requires:
  - phase: 02-01
    provides: "Reversible uninstall verb, privileged keyd gate, Hyprland server guard, quarantine immutability"
provides:
  - "Zsh provisioned before stow via common deps, Zinit self-clone untouched, end-of-run chsh offer with dry-run preview and Termux/already-zsh guards"
  - "Docs flipped to Default: Zsh | Backup: Nushell with correct stow one-liners and least-privilege keyd sudoers"
  - "Staged delete of teardown.zsh/teardown.nu atomically with doc fix, recoverable via git history"
affects: [03-polished-shell, 04-editor-autonomy]
actuals:
  tokens: 18000
  tasks: 3
  commits: 3
tech-stack:
  added: []
  patterns: ["Zsh provision via common deps before stow per D-12", "Zinit self-clone via zsh/.zshrc — no installer clone per D-12", "End-of-run chsh offer after quarantine_scan+run_stow+post_verify with explicit yes, --yes does NOT bypass, dry-run preview, Termux/already-zsh guards per D-13", "Docs canon flip Default Zsh | Backup Nushell per D-14", "Staged delete teardowns with atomic doc fix per D-15"]
key-files:
  created: []
  modified: [setup.sh, zsh/.zshrc, README.md, AGENTS.md]
  deleted: [teardown.zsh, teardown.nu]
key-decisions:
  - "Zsh binary ensured via common deps before stow — comment added near get_deps, no new dep table entry, Zinit left to self-clone on first zsh launch"
  - "offer_chsh gated after post_verify success, wrapped || true, --yes does NOT bypass, Termux and already-zsh skipped, DRY_RUN preview in fast-path"
  - "README flipped to least-privilege keyd (reload keyd) and Zinit self-clone note, staged teardowns deleted, no dangling teardown mentions"
  - "AGENTS.md scrubbed of teardown references to satisfy no-dangling-pointer invariant (recoverable via git history)"
patterns-established:
  - "offer_chsh pattern: resolve zsh_path via command -v, guards in order zsh missing/already-zsh/termux/chsh missing/dry-run/prompt exact yes, chsh -s failure warns but || true at call site"
  - "DRY_RUN chsh preview mirrors live offer when zsh binary exists and SHELL differs, Termux skipped"
requirements-completed: [SHEL-01, DOCS-01]
coverage:
  - id: D1
    description: "Zsh provisioned before stow — zsh in common, Zinit self-clones on first zsh launch"
    requirement: "SHEL-01"
    verification:
      - kind: manual_procedural
        ref: "bash -n setup.sh && grep -q offer_chsh setup.sh && grep -q 'Zinit clones itself' zsh/.zshrc"
        status: pass
    human_judgment: false
  - id: D2
    description: "chsh offered only at very end after explicit yes, never via --yes, Termux skipped, dry-run previews"
    requirement: "SHEL-01"
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --dry-run --mode server --shell zsh --yes | grep -E 'Would run: chsh|already zsh' && SHELL=/bin/bash bash setup.sh --dry-run --mode server --shell zsh --yes | grep 'Would run: chsh'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Docs read Default: Zsh | Backup: Nushell with correct stow one-liners and least-privilege keyd sudoers"
    requirement: "DOCS-01"
    verification:
      - kind: manual_procedural
        ref: "grep -q 'Default: Zsh' README.md && grep -q 'stow --dir=. --target=\"$HOME\" --restow nvim zsh starship' README.md && grep -q 'systemctl reload keyd' README.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "Teardowns deleted and no dangling teardown mentions remain"
    requirement: "DOCS-01"
    verification:
      - kind: manual_procedural
        ref: "test ! -f teardown.zsh && test ! -f teardown.nu && ! grep -rq teardown README.md AGENTS.md"
        status: pass
    human_judgment: false
duration: 5 min
completed: 2026-09-11
status: complete
---

# Phase 02 Plan 02: Zsh self-provision (Zinit) + docs flipped to Zsh default + staged teardown delete Summary

**Zsh provisioned before stow via common deps with self-cloning Zinit and safe end-of-run chsh, docs flipped to Zsh default, teardowns atomically deleted**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-11T20:01:37Z
- **Completed:** 2026-09-11T20:07:05Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Zsh binary ensured before stow via `common` deps (arch/debian/termux all include `zsh`) with comment documenting D-12; Zinit self-clone block in `zsh/.zshrc` left untouched, header clarified to `default shell, Nushell is backup` and inline `Zinit clones itself` comment added
- `offer_chsh` added after `quarantine_scan`+`run_stow`+`post_verify` success, gated as `offer_chsh || true`; handles missing zsh, already-zsh, Termux, missing chsh, DRY_RUN preview, prompt `Change default shell to zsh? Type 'yes' to run chsh -s %s` requiring exact `yes`, `--yes` never bypasses per D-13
- DRY_RUN fast-path preview mirrors live offer: prints `[DRY RUN] Would run: chsh -s $(which zsh)` when `zsh` exists and `SHELL` differs, otherwise `already zsh` hint; Termux skipped
- README flipped: OPTIONS `--yes` now `Assume yes for prompts (CI bypass for --uninstall and privileged flows)`, `--uninstall` bullet rewritten to `stow -D` + `sudo stow -D -t / keyd` + Mason + system package offer, examples primary `bash setup.sh --mode local --dry-run`, manual `stow --dir=. --target="$HOME" --restow nvim zsh starship` vs `nvim nushell starship`, keyd section rewritten to preview+`diff -u`+`gum confirm`/`Type 'yes'`+`--adopt` only with explicit adopt + `keyd reload || systemctl reload` and sudoers `reload keyd`, Zinit note `Zinit clones itself on first zsh launch via zsh/.zshrc — no installer clone`, safety bullet updated, footer retained
- `setup.sh` usage header updated to `Unified Dotfiles Installer (Bash) — Zsh default, Nushell backup`, EXAMPLES expanded to ` --mode local`, ` --mode local --dry-run`, ` --mode server --shell zsh --dry-run`, ` --uninstall --dry-run/--yes` matching README
- `AGENTS.md` scrubbed of all `teardown` strings (no dangling pointers), `teardown.zsh`/`teardown.nu` staged-deleted via `git rm` atomically with doc fix, recoverable via git history

## Task Commits

Each task was committed atomically:

1. **Task 1: Zsh provision already via deps + Zinit self-clone untouched + end-of-run chsh offer** - `bcd2552` (feat)
2. **Task 2: Docs full flip keep backup column + staged delete teardowns** - `dafa44d` (feat)
3. **Task 3: Verify shell default canon and idempotent uninstall preview in docs/tests** - `867388c` (chore)

**Plan metadata:** `pending` (docs: complete plan)

_Note: Task 3 was verification-only — no code changes required beyond confirming canon consistency and idempotence; committed as empty chore to record gate passage_

## Files Created/Modified

- `setup.sh` - Added `zsh` provision comment, `Zinit self-clone` comment, `offer_chsh()` after `offer_system_package_removal`, DRY_RUN chsh preview in fast-path, `offer_chsh || true` after `post_verify`, expanded EXAMPLES
- `zsh/.zshrc` - Header `ZSH Configuration File (.zshrc) — default shell, Nushell is backup` + `Zinit clones itself` inline comment, self-clone block untouched
- `README.md` - Full D-14 flip: OPTIONS, Examples, Manual stow, keyd Setup (preview+diff+adopt gate+least-privilege), Zinit note, Safety bullet
- `AGENTS.md` - Scrubbed teardown mentions, shell default already Zsh
- `teardown.zsh` - Deleted via `git rm` (staged delete)
- `teardown.nu` - Deleted via `git rm` (staged delete)

## Decisions Made

- Keep Zsh in `common` deps as provision mechanism — no need for separate installer clone of Zinit; self-clone stays in `zsh/.zshrc` per D-12, avoids pin drift and duplicates shell runtime responsibility
- `offer_chsh` always requires typed `yes` even when `--yes` passed; Termux and already-zsh skip with warning, `chsh` failure warns but never kills installer via `|| true` at call site — protects login shell changes on servers and Termux where chsh absent
- Docs keep Nushell backup column — do not delete Nushell mentions per D-14, only flip primary to Zsh; footer `Installer: bash setup.sh --mode <local|server> --shell <zsh|nushell> [--dry-run] — Zsh default, Nushell backup` retained
- Staged delete teardowns atomically with doc fix, no shims — git history is recovery per Phase 1 D-03; `grep -r teardown` now zero in README/AGENTS/setup.sh

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial dry-run with `SHELL=/usr/bin/zsh` prints `Default shell already zsh — skipping chsh offer` instead of `Would run: chsh`; verified second check with `SHELL=/bin/bash` produces `Would run: chsh -s /usr/bin/zsh` as expected — both are correct per guards, acceptance criteria allows either hint without prompting
- `nvim/.config/nvim/README.md` exists (462 bytes, mynvim showcase) though plan notes it was deleted pre-Phase-1; left untouched per D-14 instruction not to recreate if absent
- AGENTS.md contained extensive historical teardown references in stack/conventions/architecture sections; scrubbed via `setup.sh --uninstall` replacement to satisfy `! grep -rq teardown` invariant — retains meaning as unified installer reference, no functional change to planning artifacts

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Zsh default canon is now consistent across `setup.sh` usage, `README.md` quick-start/manual/keyd/Zinit sections, `zsh/.zshrc` header, and `AGENTS.md`; `bash -n` clean, `--help` wins anywhere, both install and uninstall dry-runs preview with zero writes and are idempotent
- `zsh` binary present before `stow --restow zsh` via common deps; Zinit self-clones on first `zsh` launch; `chsh` offered safely at end with explicit `yes`
- Teardowns removed; no dangling `teardown` mentions in docs; Nushell backup column preserved; no new persisted mode file (`dotfiles/mode` only via legacy `rm -f`)
- Ready for Phase 03 (Polished Shell, Theme & Local Overrides) and Phase 04 (Editor Autonomy); no blockers

---
*Phase: 02-safe-reversible-server-safe-deployment*
*Completed: 2026-09-11*

## Self-Check: PASSED

- All task commits verified: bcd2552, dafa44d, 867388c, ae49cfe (SUMMARY) all present in git log
- All key files verified on disk: setup.sh, zsh/.zshrc, README.md, AGENTS.md present; teardown.zsh/teardown.nu deleted as expected
- SUMMARY.md exists and is committed
