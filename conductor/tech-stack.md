# Tech Stack

## Core Tools
- **Shells:**
  - **Nushell:** Primary shell and automation language for the `setup.nu` bootstrapper.
- **Editor:**
  - **Neovim:** Central development environment, configured using Lua with a focus on high-performance plugins.
- **Window Management & System UI:**
  - **Hyprland:** Tiling Wayland compositor for a keyboard-centric window management workflow.
  - **Wofi:** Wayland-native application launcher and menu system.
- **Terminal & Prompt:**
  - **Alacritty:** Fast, GPU-accelerated terminal emulator.
  - **Starship:** Cross-shell prompt for a consistent and informative command-line experience.

## Infrastructure & Management
- **Configuration Management:**
  - **GNU Stow:** Used for managing symlinks and deploying dotfiles to the home directory and system paths.
- **System Utilities:**
  - **keyd:** System-wide keyboard remapping daemon to enable a custom, efficiency-focused layout.
- **System Utilities:**
  - **Node.js & npm:** Required for Neovim plugin ecosystem and development tools.

## Legacy / Unused
- **Zsh:** Maintained only as a deep-storage backup; not used in active workflows.
