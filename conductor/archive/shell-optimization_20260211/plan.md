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

## Phase 2: Starship Configuration & Dynamic Switching [checkpoint: 88e59ae]
Optimize Starship for performance and situational awareness using Nushell to manage state.

- [x] Task: Create a "minimal" Starship configuration 77d26d8
    - [x] Create `starship/home-quiet.toml` that disables language modules
- [x] Task: Implement SSH indicator in main Starship config e253b14
    - [x] Update `starship/.config/starship.toml` to show an SSH icon when `SSH_CONNECTION` is active
- [x] Task: Implement dynamic config switching in Nushell debc2de
    - [x] Update `nushell/.config/nushell/env.nu` or `config.nu` to update `$env.STARSHIP_CONFIG` based on the current directory
- [x] Task: Conductor - User Manual Verification 'Starship Configuration' (Protocol in workflow.md) 88e59ae
