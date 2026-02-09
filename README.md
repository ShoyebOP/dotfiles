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

### 2. Set as Default Shell (Optional)
To make Nushell your default shell:
```bash
# Add nu to valid shells
which nu | sudo tee -a /etc/shells
# Change shell for current user
chsh -s $(which nu)
```

### 3. Run the Bootstrapper
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

---

## 🛠 Manual Installation (No Script)

If you prefer to set things up manually, follow these steps:

### 1. Install Dependencies
Ensure you have the following installed based on your environment:
- **Core:** `stow`, `neovim`, `nushell`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`.
- **GUI (Arch/CachyOS):** `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-clipboard`.

### 2. Deploy Configurations
Use `GNU Stow` to symlink the configurations. Run these commands from the root of the cloned repository:

**CLI Tools:**
```bash
stow --restow nvim nushell starship
```

**GUI Tools (Local only):**
```bash
stow --restow hyprland alacritty wofi
```

**Privileged System Setup (keyd):**
```bash
sudo stow --adopt -t / keyd
sudo keyd reload
```

### 3. Sudoers Configuration
To allow starting/stopping `keyd` without a password, run `sudo EDITOR=nvim visudo` and add:
```
shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd
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
