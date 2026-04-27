# Dotfiles: Efficiency-First Development Environment

Highly optimized, minimalist dotfiles for a consistent and high-performance development environment across machines.

## Overview

Choose your shell path:

| Feature | Nushell Path | Zsh Path |
|---------|-------------|----------|
| Shell | Nushell | Zsh + Zinit |
| Prompt | Starship | Powerlevel10k |
| Setup | Auto (`nu setup.nu`) | Manual |
| Completion | External stub | Generated via `uv generate-shell-completion zsh` |
| keyd | Yes | Yes |

---

## Nushell Setup

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

### Nushell: Manual Installation (Alternative)

If you prefer to set things up manually without the bootstrapper:

#### Install Dependencies
- **Core:** `stow`, `neovim`, `nushell`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`.
- **GUI (Arch/CachyOS):** `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-clipboard`.

#### Deploy Configurations
Use `GNU Stow` to symlink the configurations:

```bash
stow --restow nvim nushell starship
```

```bash
stow --restow hyprland alacritty wofi
```

#### Nushell: keyd Setup
```bash
sudo stow --adopt -t / keyd
sudo keyd reload
```

To allow starting/stopping `keyd` without a password, run `sudo EDITOR=nvim visudo` and add:
```
shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd
```

---

## Zsh Setup

**Note:** Zsh path requires manual installation of all tools.

### 1. Prerequisites: Install Tools Manually

#### Core Tools
```bash
# Using pacman (Arch/CachyOS)
sudo pacman -S stow neovim git zoxide uv nodejs npm
```

#### Shell & Plugin Manager
```bash
# Install Zsh
sudo pacman -S zsh

# Install Zinit (will be cloned automatically on first shell start)
git clone https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git
```

#### Tool Completions
```bash
# Generate uv zsh completions
mkdir -p ~/.config/zsh/completions
uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv
```

### 2. Set as Default Shell (Optional)
To make Zsh your default shell:
```bash
# Add zsh to valid shells
which zsh | sudo tee -a /etc/shells
# Change shell for current user
chsh -s $(which zsh)
```

### 3. Deploy Configurations
Use `GNU Stow` to symlink the configurations from the repository root:

```bash
stow --restow nvim zsh starship
```

```bash
stow --restow hyprland alacritty wofi
```

### 4. Zsh: keyd Setup
```bash
sudo stow --adopt -t / keyd
sudo keyd reload
```

To allow starting/stopping `keyd` without a password, run `sudo EDITOR=nvim visudo` and add:
```
shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd
```

---

## Tech Stack

| Shell | Nushell | Zsh |
|-------|--------|-----|
| Prompt | Starship | Powerlevel10k |
| Manager | Built-in | Zinit |
| Utilities | keyd, wofi, zoxide, rg, uv | keyd, wofi, zoxide, rg, uv |

---

## Philosophy

- **Extreme Efficiency:** Prioritizing functional utility and low latency.
- **Modular Minimalism:** Only essential, high-utility plugins and tools.
- **Portability:** Machine-agnostic core with local-only paths.
- **Consistent Keybindings:** Unified interaction language across all tools.

---

*Managed with Conductor*