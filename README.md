# Dotfiles: Efficiency-First Development Environment

Highly optimized, minimalist dotfiles for a consistent and high-performance development environment across machines.

## 🚀 Quick Start (Unified Bootstrapper)

The easiest way to set up this environment is using the automated `setup.nu` script. It automatically detects your OS, installs missing dependencies, and manages your configuration symlinks.

### 📜 What it does:
- **OS Support:** Arch Linux (CachyOS) and Ubuntu.
- **Dependency Management:** Automatically identifies and installs missing packages (via `pacman` or `apt`).
- **Smart Stowing:** Uses `GNU Stow` to manage symlinks. If a real file or folder exists where a symlink should be, it automatically removes the conflict.
- **Safety First:** Includes a `--dry-run` flag to preview all changes.

### 1. Prerequisite: Nushell
If you don't have Nushell installed, please install it first:
- **Arch/CachyOS:** `sudo pacman -S nushell`
- **Ubuntu:** `sudo apt install nushell`

### 2. Run the Bootstrapper
Clone this repository and run:
```bash
nu setup.nu
```

**Options:**
- `--mode`: Select `local` (Full GUI) or `server` (Headless CLI).
- `--dry-run`: Preview changes without applying them.
- `--stow-keyd`: Pass `y` or `n` to automate the privileged `keyd` setup.

Example (Non-interactive Server Setup):
```bash
nu setup.nu --mode server
```

## 🛠 Tech Stack

- **Shell:** [Nushell](https://www.nushell.sh/) (Primary)
- **Editor:** [Neovim](https://neovim.io/) (Lua-based)
- **WM:** [Hyprland](https://hyprland.org/) (Wayland Compositor)
- **Terminal:** [Alacritty](https://alacritty.org/)
- **Prompt:** [Starship](https://starship.rs/)
- **Management:** [GNU Stow](https://www.gnu.org/software/stow/)
- **Utilities:** `keyd`, `wofi`, `zoxide`, `rg`, `uv`

## ⌨️ Manual privileged setup (keyd)

If you prefer to handle `keyd` manually or need to troubleshoot:

1. Stow the configuration:
   ```bash
   sudo stow --adopt -t / keyd
   ```
2. Reload the daemon:
   ```bash
   sudo keyd reload
   ```
3. (Optional) Enable passwordless control for `keyd`:
   Run `sudo EDITOR=nvim visudo` and add:
   ```
   shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd
   ```

## 📐 Philosophy

- **Extreme Efficiency:** Prioritizing functional utility and low latency.
- **Modular Minimalism:** Only essential, high-utility plugins and tools.
- **Portability:** Machine-agnostic core with local-only paths.
- **Consistent Keybindings:** Unified interaction language across all tools.

---
*Managed with Conductor*
