# Implementation Plan: fix-gitignore-paths_20260403

## Phase 1: Fix .gitignore paths
- [x] Task: Update `.gitignore` nvim entries to use correct paths (`nvim/.config/nvim/` prefix)
    - [x] Replace `nvim/lazy-lock.json` with `nvim/.config/nvim/lazy-lock.json`
    - [x] Replace `nvim/.neoconf.json` with `nvim/.config/nvim/.neoconf.json`
    - [x] Replace `nvim/undo/` with `nvim/.config/nvim/undo/`
    - [x] Replace `nvim/shada/` with `nvim/.config/nvim/shada/`
    - [x] Replace `nvim/state/` with `nvim/.config/nvim/state/`
    - [x] Replace `nvim/cache/` with `nvim/.config/nvim/cache/`
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Untrack machine-specific files
- [x] Task: Remove tracked files from git index while keeping them locally
    - [x] `git rm --cached nvim/.config/nvim/lazy-lock.json`
    - [x] `git rm --cached nvim/.config/nvim/.neoconf.json`
- [x] Task: Verify `git status` shows correct state
    - [x] Confirm lazy-lock.json and .neoconf.json no longer tracked
    - [x] Confirm lazyvim.json remains tracked
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Commit and push all pending changes
- [x] Task: Stage all changes
    - [x] `.gitignore` updates
    - [x] Deleted `venv-commands_20260224` track files
    - [x] Modified `nushell/.config/nushell/env.nu`
    - [x] Untracked file removals
- [x] Task: Commit with message: `fix(dotfiles): Correct .gitignore paths, untrack machine-specific nvim files`
- [x] Task: Push to remote
- [x] Task: Verify push succeeded
- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
