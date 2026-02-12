# Implementation Plan: LazyVim Migration and Synchronization

This plan outlines the steps to correctly track the new LazyVim configuration while ensuring device-specific files are ignored.

## Phase 1: Cleanup and Centralized Ignoring
Focuses on removing local git configurations and setting up global ignore rules.

- [x] Task: Remove local Neovim gitignore e070417
    - [ ] Delete `nvim/.gitignore`
- [x] Task: Update root `.gitignore` ec7d51f
    - [ ] Add `nvim/lazy-lock.json` to the root `.gitignore`
    - [ ] Add `nvim/.neoconf.json` to the root `.gitignore`
    - [ ] Ensure standard Neovim temp folders are ignored (if not already): `*.swp`, `nvim/.repro/`, etc.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Cleanup and Centralized Ignoring' (Protocol in workflow.md)

## Phase 2: Configuration Tracking and Verification
Ensures the core LazyVim files are staged and ready for synchronization.

- [x] Task: Stage core configuration files d455085
    - [ ] Add `nvim/init.lua`
    - [ ] Add all files in `nvim/lua/config/`
    - [ ] Add all files in `nvim/lua/plugins/`
- [x] Task: Verify tracked vs ignored files d455085
    - [ ] Run `git status` to ensure `lazy-lock.json` and `.neoconf.json` are NOT staged
    - [ ] Ensure `lua/config/` and `lua/plugins/` are fully tracked
- [x] Task: Conductor - User Manual Verification 'Phase 2: Configuration Tracking and Verification' (Protocol in workflow.md)

## Phase 3: Finalization
Committing the changes and pushing to the remote.

- [~] Task: Commit migration changes
    - [ ] Create a commit with the message `feat(nvim): Migrate to LazyVim and update sync rules`
- [ ] Task: Verify and Push to remote
    - [ ] Check for a configured remote (`git remote -v`)
    - [ ] Push the current branch to the remote (`git push`)
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Finalization' (Protocol in workflow.md)
