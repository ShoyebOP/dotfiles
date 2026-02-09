# Track Specification: Unified Bootstrapper & Documentation Consolidation

## Overview
This track focuses on creating a robust, intelligent bootstrap script (`setup.nu`) written in Nushell to automate the deployment of dotfiles across different environments and operating systems. It also includes the consolidation of existing usage instructions into a formal `README.md`.

## Requirements

### 1. `setup.nu` Bootstrapper
- **Shell Check:** Must detect if it's being executed by `nu`. If not, provide clear instructions for installing Nushell and restarting the script.
- **OS Detection:**
    - Support **Arch Linux (CachyOS)** and **Ubuntu**.
    - For other distributions, exit gracefully with a message directing the user to the manual installation steps in `README.md`.
- **Deployment Modes:**
    - Prompt the user to select between **Local Mode** and **Server Mode**.
    - **Local Mode:** Installs all configurations, including GUI components (Hyprland, keyd, Alacritty, Wofi).
    - **Server Mode:** Excludes GUI components; installs only CLI-based configurations (Nvim, Nushell, Starship).
- **Dependency Management:**
    - Map dependencies per module (e.g., `hyprland` requires `hyprland`, `waybar`, etc.).
    - **NEW:** Include `node` and `npm` as common dependencies for Neovim.
    - Check for missing dependencies based on the selected mode and OS.
    - **NEW:** Provide and execute actual installation commands (`pacman -S` for Arch/CachyOS, `apt install` for Ubuntu) after user confirmation.
- **Stowing & Cleanup Logic:**
    - Automate `stow` commands based on the current directory structure.
    - **NEW:** Pre-stow validation: If a target location contains a real file or folder (not a symlink), delete it to prevent `stow` conflicts.
    - **NEW:** If a symlink already exists, ensure `restow` is used.
    - Use `sudo stow --adopt -t / keyd` specifically for the `keyd` configuration.
- **NEW: Path Synchronization:**
    - Identify and maintain the global path defined in the current Nushell configuration during the setup process.

### 2. Documentation Migration
- **README.md:** Create a comprehensive `README.md` that replaces `usage.md`.
- **Content:** Include project vision, tech stack overview, bootstrapping instructions (how to run `setup.nu`), and manual fallback steps for unsupported OSs.
- **Cleanup:** Delete `usage.md` once the information is successfully migrated.

## Success Criteria
- `setup.nu` runs successfully on Arch and Ubuntu, correctly installing dependencies and stowing files.
- `setup.nu` handles existing files in target directories by removing them before stowing.
- `setup.nu` exits with a helpful message on unsupported OSs.
- `README.md` contains all necessary information from `usage.md`.
- No regression in existing tool configurations.