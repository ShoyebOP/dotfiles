# Plan: shell-optimization_20260211

## Phase 1: Repository Hygiene [checkpoint: 055946c]
Ensure the repository is clean of machine-specific and ephemeral files.

- [x] Task: Update `.gitignore` to exclude Nushell history and Neovim lock files 791165b
    - [x] Add `nvim/.config/nvim/lazy-lock.json` to `.gitignore`
    - [x] Add Nushell history patterns to `.gitignore`
- [x] Task: Remove tracked ephemeral files from Git index dedf9ea
    - [x] Use `git rm --cached` on `nvim/.config/nvim/lazy-lock.json`
    - [x] Identify and remove any committed Nushell history files
- [x] Task: Conductor - User Manual Verification 'Repository Hygiene' (Protocol in workflow.md) 055946c

## Phase 2: Starship Configuration & Dynamic Switching
Optimize Starship for performance and situational awareness using Nushell to manage state.

- [ ] Task: Create a "minimal" Starship configuration
    - [ ] Create `starship/home-quiet.toml` that disables language modules
- [ ] Task: Implement SSH indicator in main Starship config
    - [ ] Update `starship/.config/starship.toml` to show an SSH icon when `SSH_CONNECTION` is active
- [ ] Task: Implement dynamic config switching in Nushell
    - [ ] Update `nushell/.config/nushell/env.nu` or `config.nu` to update `$env.STARSHIP_CONFIG` based on the current directory
- [ ] Task: Conductor - User Manual Verification 'Starship Configuration' (Protocol in workflow.md)
