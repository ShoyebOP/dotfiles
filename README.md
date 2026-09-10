# Dotfiles: Efficiency-First Development Environment

Highly optimized, minimalist dotfiles for a consistent and high-performance development environment across machines.

## Overview

Choose your shell path (unified Bash installer handles both):

| Feature | Zsh (Default) | Nushell (Backup) |
|---------|-------------|----------|
| Shell | Zsh + Zinit | Nushell |
| Prompt | Powerlevel10k | Starship |
| Setup | `bash setup.sh --shell zsh` | `bash setup.sh --shell nushell` |
| Completion | Generated via `uv generate-shell-completion zsh` | External stub |
| keyd | Yes (Phase 2 privileged) | Yes (Phase 2 privileged) |

**Default: Zsh** | **Backup: Nushell** — the unified Bash installer provisions the chosen shell before stowing configs.

---

## Unified Bash Installer

Canonical entry: `bash setup.sh` — replaces the legacy bootstrappers. Works on Arch, Debian-family, and Termux via `ID_LIKE` + `pacman`/`apt`/`pkg` probing. No preinstalled Zsh or Nushell required.

### Quick Start

Clone and run from the clone root:

```bash
git clone <repo> dotfiles && cd dotfiles
bash setup.sh
```

Interactive flow (before any write): **mode** (`local` full GUI vs `server` headless) → **shell** (`zsh` default / `nushell` backup) → **package checklist** (7 toggleable: `nvim`, `zsh`, `nushell`, `alacritty`, `starship`, `wofi`, `keyd`). Server mode pre-unchecks GUI (`alacritty`, `wofi`, `keyd`); shell choice pre-checks only the chosen shell — you can toggle any before any write.

**Options:**

- `--mode local|server` — deployment mode
- `--shell zsh|nushell` — Zsh default, Nushell backup
- `--dry-run` — preview every write (`[DRY RUN] Would run:` + `stow --no --verbose` for the exact post-checklist selection) with zero writes
- `--help, -h` — show usage (wins anywhere, exits 0 before any write)
- `--yes` — reserved for Phase 2 `--uninstall` CI bypass
- `--uninstall, --remove` — deferred to Phase 2; use teardown scripts for now

Examples:

```bash
# Interactive (TTY prompts for missing mode/shell, then checklist)
bash setup.sh

# Non-interactive server with Zsh, preview first
bash setup.sh --mode server --shell zsh --dry-run
bash setup.sh --mode server --shell zsh

# Local full GUI with Zsh
bash setup.sh --mode local --shell zsh --dry-run
bash setup.sh --mode local
```

Safety:

- Must be run from the clone root (`./setup.sh` must exist in CWD alongside `SCRIPT_DIR` resolution for `stow --dir`); outside-root aborts with a `run-from-clone` message before any prompt or write.
- Checklist uses a five-backend ladder `gum → whiptail → dialog → fzf → read` (probed, skipped silently) with Termux `keyd`/`wofi`/`alacritty` rendered as visible-but-disabled and never selectable.
- Existing non-symlink targets are quarantined (never deleted, never force-adopted) to `.stow-conflicts/<timestamp>/` preserving relative paths with a `MANIFEST` and restore hint.
- Strict post-verify (`test -e` + `readlink -f` prefix check, folding-aware) aborts with a link→expected-target report if any link is wrong. Selecting `keyd` in Phase 1 prints a privileged-install-lands-in-Phase-2 notice and is skipped — no `/etc` writes in Phase 1.

---

## Manual Installation (Alternative)

If you prefer to set things up manually without the unified installer:

#### Install Dependencies

- **Core:** `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`, `zsh`
- **GUI (Arch):** `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-copy`
- **GUI (Debian):** `alacritty`, `wofi`, `waybar`, `grim`, `slurp`, `wl-copy`
- **Termux:** `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`, `zsh` via `pkg install` (no `sudo`, no GUI packages)

#### Deploy Configurations

Use `GNU Stow` to symlink the configurations (explicit `--dir`/`--target` is what `bash setup.sh` does internally):

```bash
# Core (Zsh default)
stow --dir=. --target="$HOME" --restow nvim zsh starship

# Nushell backup instead of Zsh
stow --dir=. --target="$HOME" --restow nvim nushell starship

# GUI extras (local mode)
stow --dir=. --target="$HOME" --restow alacritty wofi
```

For a full local deploy with Zsh:

```bash
stow --dir=. --target="$HOME" --restow nvim zsh starship alacritty wofi
```

#### keyd Setup (Phase 2)

Privileged `keyd` install (`/etc/keyd`) is gated to Phase 2. In Phase 1, `bash setup.sh` will skip `keyd` with a notice and perform no `/etc` writes. When Phase 2 lands, the installer will preview with `stow --no --verbose -t / keyd` and require explicit confirmation before any privileged write. For now, manual keyd setup remains:

```bash
# Phase 2 will handle this with confirmation; manual preview:
stow --dir=. --target=/ --no --verbose keyd
# After confirmation, Phase 2 will run: sudo stow --target=/ keyd && sudo keyd reload
```

To allow starting/stopping `keyd` without a password (Phase 2 will document least-privilege handling), run `sudo EDITOR=nvim visudo` and add:

```
shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd
```

#### Zsh Plugin Manager

```bash
# Install Zinit (will be cloned automatically on first shell start via bash setup.sh in Phase 2)
git clone https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git
```

#### Tool Completions

```bash
# Generate uv zsh completions
mkdir -p ~/.config/zsh/completions
uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv
```

---

## Tech Stack

| Shell | Zsh (Default) | Nushell (Backup) |
|-------|--------|-----|
| Prompt | Powerlevel10k | Starship |
| Manager | Zinit | Built-in |
| Utilities | keyd, wofi, zoxide, rg, uv | keyd, wofi, zoxide, rg, uv |

Installer: `bash setup.sh` (Bash 5.2+, GNU Stow ≥2.4.1 auto-upgraded, `gum`/`whiptail`/`dialog`/`fzf`/`read` ladder, `mv`-only quarantine, `readlink -f` post-verify)

---

## Philosophy

- **Extreme Efficiency:** Prioritizing functional utility and low latency.
- **Modular Minimalism:** Only essential, high-utility plugins and tools.
- **Portability:** Machine-agnostic core with local-only paths.
- **Consistent Keybindings:** Unified interaction language across all tools.

---

*Managed with Conductor*
*Installer: `bash setup.sh --mode <local|server> --shell <zsh|nushell> [--dry-run]` — Zsh default, Nushell backup*
