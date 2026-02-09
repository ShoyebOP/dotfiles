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
    - Check for missing dependencies based on the selected mode and OS.
    - Provide a summary of missing packages before attempting installation (or provide instructions).
- **Stowing Logic:**
    - Automate `stow` commands based on the current directory structure.
    - Use `sudo stow --adopt -t / keyd` specifically for the `keyd` configuration as per `usage.md`.
    - Handle `~/.config` target directories.

### 2. Documentation Migration
- **README.md:** Create a comprehensive `README.md` that replaces `usage.md`.
- **Content:** Include project vision, tech stack overview, bootstrapping instructions (how to run `setup.nu`), and manual fallback steps for unsupported OSs.
- **Cleanup:** Delete `usage.md` once the information is successfully migrated.

## Success Criteria
- `setup.nu` runs successfully on Arch and Ubuntu, correctly stowing files based on the selected mode.
- `setup.nu` exits with a helpful message on unsupported OSs.
- `README.md` contains all necessary information from `usage.md`.
- No regression in existing tool configurations.
