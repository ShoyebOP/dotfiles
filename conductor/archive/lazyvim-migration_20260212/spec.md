# Specification: LazyVim Migration and Synchronization

## Overview
This track involves migrating the existing Neovim configuration to a LazyVim-based setup and ensuring that the configuration is correctly tracked in the dotfiles repository. The goal is to provide a consistent Neovim experience across multiple machines while excluding device-specific or ephemeral files.

## Functional Requirements
- **Configuration Migration:** Transition from the previous custom Neovim config to the LazyVim starter structure.
- **Repository Synchronization:**
    - Include all core configuration files in `nvim/lua/config/` (`options.lua`, `keymaps.lua`, `autocmds.lua`, `lazy.lua`).
    - Include all custom plugin configurations and overrides in `nvim/lua/plugins/`.
    - Include the main entry point `nvim/init.lua`.
- **Exclusion Management:**
    - Remove the local `nvim/.gitignore`.
    - Centralize all Neovim exclusions in the root `.gitignore`.
    - Exclude `lazy-lock.json` to allow per-device plugin version management.
    - Exclude `.neoconf.json` to keep local LSP/project settings private.
    - Exclude standard Neovim ephemeral directories (e.g., `undo`, `shada`, `state`, `cache`).

## Non-Functional Requirements
- **Consistency:** The core editor behavior and custom keymaps must be identical across all devices after the plugins are installed by LazyVim.
- **Maintainability:** Using the root `.gitignore` simplifies the management of the entire dotfiles repository.

## Acceptance Criteria
- [ ] `nvim/.gitignore` is deleted.
- [ ] Root `.gitignore` contains rules to exclude `lazy-lock.json` and `.neoconf.json` inside the `nvim` directory.
- [ ] `git status` shows that `lua/config/` and `lua/plugins/` files are tracked (unless they were already).
- [ ] The repository is clean of local Neovim cache or state files.

## Out of Scope
- Migrating old custom snippets or complex logic not already present in the new LazyVim setup.
- Configuring machine-specific environment variables for Neovim.
