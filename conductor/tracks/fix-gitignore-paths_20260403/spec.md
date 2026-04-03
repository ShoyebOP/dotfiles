# Track: fix-gitignore-paths_20260403

## Overview
Fix incorrect `.gitignore` paths for nvim files that are still being tracked, untrack machine-specific files, and commit pending changes including nushell environment updates.

## Functional Requirements
1. Update `.gitignore` to use correct paths: `nvim/.config/nvim/` prefix instead of `nvim/`
2. Untrack `lazy-lock.json` and `.neoconf.json` from git (machine-specific, not needed for portability)
3. Keep `lazyvim.json` tracked (defines LazyVim extras, portable across machines)
4. Remove previously-tracked track directory `venv-commands_20260224` (deleted but still staged)
5. Commit pending `nushell/.config/nushell/env.nu` changes
6. Push all changes to remote

## Non-Functional Requirements
- `.gitignore` entries must match the actual directory structure under `nvim/.config/nvim/`
- Machine-specific files should not be tracked to maintain portability

## Acceptance Criteria
- [ ] `git status` shows no nvim runtime files (lazy-lock.json, .neoconf.json) as tracked
- [ ] `.gitignore` paths correctly prevent future tracking of machine-specific nvim files
- [ ] All pending changes committed and pushed to remote

## Out of Scope
- Fixing mini.ai keybind issues (LazyVim built-in dependency, not a manual install)
