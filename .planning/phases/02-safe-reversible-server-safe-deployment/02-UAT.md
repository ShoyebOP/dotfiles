---
status: complete
phase: 02-safe-reversible-server-safe-deployment
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md]
started: 2026-09-12T02:45:00Z
updated: 2026-09-12T02:46:00Z
---

## Current Test

[testing complete]

## Tests

### 1. User runs bash setup.sh --uninstall/--remove and must type yes (bypass with --yes) before stow -D + sudo stow -D -t / keyd removes links, Mason artefacts cleaned when nvim deselected — second uninstall and re-install idempotent
expected: User runs bash setup.sh --uninstall/--remove and must type yes (bypass with --yes) before stow -D + sudo stow -D -t / keyd removes links, Mason artefacts cleaned when nvim deselected — second uninstall and re-install idempotent
result: pass
source: automated
coverage_id: D1
requirement: INST-03

### 2. User who selects keyd sees stow --no --verbose -t / keyd preview and diff -u if /etc/keyd/default.conf exists as regular file; installer requires gum confirm / Type 'yes' before sudo stow --adopt -t / keyd, otherwise plain stow then reload with || true
expected: User who selects keyd sees stow --no --verbose -t / keyd preview and diff -u if /etc/keyd/default.conf exists as regular file; installer requires gum confirm / Type 'yes' before sudo stow --adopt -t / keyd, otherwise plain stow then reload with || true
result: pass
source: automated
coverage_id: D2
requirement: STOW-02

### 3. User on server mode can log in on tty1 without session death — zsh/.zprofile Hyprland exec block is deleted, no persisted ~/.config/dotfiles/mode file written or read, legacy mode file removed silently if present
expected: User on server mode can log in on tty1 without session death — zsh/.zprofile Hyprland exec block is deleted, no persisted ~/.config/dotfiles/mode file written or read, legacy mode file removed silently if present
result: pass
source: automated
coverage_id: D3
requirement: STOW-03

### 4. System package removal offer lists all SELECTED_DEPS toolchain names, previews with [DRY RUN] Would run: sudo pacman -Rns / apt remove -y / pkg uninstall, requires same yes gate, never auto-removes, Termux uses no sudo
expected: System package removal offer lists all SELECTED_DEPS toolchain names, previews with [DRY RUN] Would run: sudo pacman -Rns / apt remove -y / pkg uninstall, requires same yes gate, never auto-removes, Termux uses no sudo
result: pass
source: automated
coverage_id: D4
requirement: INST-03

### 5. Zsh provisioned before stow — zsh in common, Zinit self-clones on first zsh launch
expected: Zsh provisioned before stow — zsh in common, Zinit self-clones on first zsh launch
result: pass
source: automated
coverage_id: D1
requirement: SHEL-01

### 6. chsh offered only at very end after explicit yes, never via --yes, Termux skipped, dry-run previews
expected: chsh offered only at very end after explicit yes, never via --yes, Termux skipped, dry-run previews
result: pass
source: automated
coverage_id: D2
requirement: SHEL-01

### 7. Docs read Default: Zsh | Backup: Nushell with correct stow one-liners and least-privilege keyd sudoers
expected: Docs read Default: Zsh | Backup: Nushell with correct stow one-liners and least-privilege keyd sudoers
result: pass
source: automated
coverage_id: D3
requirement: DOCS-01

### 8. Teardowns deleted and no dangling teardown mentions remain
expected: Teardowns deleted and no dangling teardown mentions remain
result: pass
source: automated
coverage_id: D4
requirement: DOCS-01

### 9. Confirm auto-verified deliverables
expected: |
  All 8 Phase 2 deliverables were auto-verified via passing procedural checks (02-01 D1-D4 + 02-02 D1-D4) plus VERIFICATION.md 6/6 must-haves live. Confirm that reality matches — does bash setup.sh flow work as described?

  Covered:
  - [02-01 D1] uninstall/--remove with typed yes + --yes bypass, stow -D + sudo stow -D -t / keyd, Mason cleanup when nvim deselected (verified: --dry-run --uninstall preview + bash -n)
  - [02-01 D2] keyd privileged gate: stow --no -v -t / preview + diff -u on regular file, gum/Type yes before --adopt else plain stow then reload || true (verified: --dry-run local preview + grep diff/gum)
  - [02-01 D3] server-safe: zsh/.zprofile deleted Hyprland exec, no ~/.config/dotfiles/mode persisted, legacy rm -f (verified: ! grep exec + ! mkdir mode)
  - [02-01 D4] system package removal offer: SELECTED_DEPS list, [DRY RUN] sudo pacman -Rns/apt/pkg preview, yes gate, Termux no sudo (verified: dry-run apt remove + triple grep)
  - [02-02 D1] Zsh provisioned before stow via common deps, Zinit self-clones on first zsh launch (verified: bash -n + grep Zinit)
  - [02-02 D2] chsh offered only at very end after explicit yes, never via --yes, Termux/skipped, dry-run previews (verified: Would run: chsh / already zsh)
  - [02-02 D3] Docs flipped Default: Zsh | Backup: Nushell, stow one-liners, least-privilege reload keyd (verified: grep Default/Zsh + stow line + systemctl reload)
  - [02-02 D4] Teardowns deleted, no dangling mentions (verified: ! -f teardown.* + ! grep teardown)

  Try: bash setup.sh --dry-run --mode server --shell zsh --yes | head -n 60
       bash setup.sh --dry-run --uninstall --mode server --shell zsh --yes | head -n 60
       cat zsh/.zprofile; grep -c teardown README.md AGENTS.md setup.sh || true
result: pass

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
