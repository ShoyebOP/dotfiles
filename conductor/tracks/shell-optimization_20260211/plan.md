# Plan: shell-optimization_20260211

## Phase 1: Repository Hygiene
Ensure the repository is clean of machine-specific and ephemeral files.

- [x] Task: Update `.gitignore` to exclude Nushell history and Neovim lock files 791165b
    - [ ] Add `nvim/.config/nvim/lazy-lock.json` to `.gitignore`
    - [ ] Add Nushell history patterns to `.gitignore`
- [x] Task: Remove tracked ephemeral files from Git index dedf9ea
    - [ ] Use `git rm --cached` on `nvim/.config/nvim/lazy-lock.json`
    - [ ] Identify and remove any committed Nushell history files
- [~] Task: Conductor - User Manual Verification 'Repository Hygiene' (Protocol in workflow.md)

## Phase 2: Starship Configuration & Dynamic Switching
Optimize Starship for performance and situational awareness using Nushell to manage state.

- [ ] Task: Create a "minimal" Starship configuration
    - [ ] Create `starship/home-quiet.toml` that disables language modules
- [ ] Task: Implement SSH indicator in main Starship config
    - [ ] Update `starship/.config/starship.toml` to show an SSH icon when `SSH_CONNECTION` is active
- [ ] Task: Implement dynamic config switching in Nushell
    - [ ] Update `nushell/.config/nushell/env.nu` or `config.nu` to update `$env.STARSHIP_CONFIG` based on the current directory
- [ ] Task: Conductor - User Manual Verification 'Starship Configuration' (Protocol in workflow.md)
