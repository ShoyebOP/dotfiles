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

Interactive flow (before any write): **mode** (`local` desktop extras vs `server` headless) → **shell** (`zsh` default / `nushell` backup) → **single-page checklist** shown once (16 toggleable rows: `nvim`, `zsh`, `nushell`, `alacritty`, `starship`, `keyd` plus toolchain `stow`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`; `zsh`/`starship` shared rows, `nvim` covers `neovim`). Mode and shell only set pre-selection defaults — server mode pre-unchecks GUI (`alacritty`, `keyd`), shell choice pre-checks only the chosen shell. Strict tick semantics: tick installs the binary and stows its config when one exists; untick never installs and never stows. The same single page appears once on `--uninstall` before any removal.

**Options:**

- `--mode local|server` — deployment mode
- `--shell zsh|nushell` — Zsh default, Nushell backup
- `--dry-run` — preview every write (`[DRY RUN] Would run:` + `stow --no --verbose` for the exact post-checklist selection) with zero writes
- `--help, -h` — show usage (wins anywhere, exits 0 before any write)
- `--yes` — Use mode/shell/family presets with zero prompts (identical to the non-interactive no-TTY path, NOT all-ON: server keeps GUI rows OFF, Termux keeps disabled rows OFF); also CI bypass for `--uninstall` and privileged flows
- `--uninstall, --remove` — cleanly unstows selected configs via `stow -D` plus privileged `sudo stow -D -t / keyd` when keyd selected plus Mason artefacts when `nvim` deselected plus offers system package removal; typed `yes` required (bypass with `--yes`)

Examples:

```bash
# Interactive (TTY prompts for missing mode/shell, then checklist)
bash setup.sh

# Primary: local mode with Zsh (default), preview first
bash setup.sh --mode local --dry-run
bash setup.sh --mode local

# Non-interactive server with Zsh, preview first
bash setup.sh --mode server --shell zsh --dry-run
bash setup.sh --mode server --shell zsh

# Local desktop extras with Zsh
bash setup.sh --mode local --shell zsh --dry-run
```

Safety:

- Must be run from the clone root (`./setup.sh` must exist in CWD alongside `SCRIPT_DIR` resolution for `stow --dir`); outside-root aborts with a `run-from-clone` message before any prompt or write.
- Single-page checklist uses a five-backend ladder `gum → whiptail → dialog → fzf → read` in locked order (probed, missing tools skipped silently; cancel never cascades to the next backend) with Termux `keyd`/`alacritty` rendered as visible-but-disabled and never selectable.
- Existing non-symlink targets are quarantined (never deleted, never force-adopted) to `.stow-conflicts/<timestamp>/` preserving relative paths with a `MANIFEST` and restore hint.
- Strict post-verify (`test -e` + `readlink -f` prefix check, folding-aware) aborts with a link→expected-target report if any link is wrong. Selecting `keyd` previews with `stow --dir=. --target=/ --no --verbose keyd` plus `diff -u` when `/etc/keyd/default.conf` exists as a regular file, requires `gum confirm` or `Type 'yes' to confirm privileged keyd install:` before `sudo stow --dir=. --target=/ keyd` (or `sudo stow --dir=. --target=/ --adopt keyd` only with explicit adopt confirmation), then `sudo keyd reload || sudo systemctl reload keyd || true`.

---

## Manual Installation (Alternative)

If you prefer to set things up manually without the unified installer:

#### Install Dependencies

- **Core:** `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`, `zsh`
- **GUI (Arch):** `alacritty`, `keyd`
- **GUI (Debian):** `alacritty`
- **Termux:** `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`, `zsh` via `pkg install` (no `sudo`, no GUI packages)

#### Deploy Configurations

Use `GNU Stow` to symlink the configurations (explicit `--dir`/`--target` is what `bash setup.sh` does internally):

```bash
# Core (Zsh default)
stow --dir=. --target="$HOME" --restow nvim zsh starship

# Nushell backup instead of Zsh
stow --dir=. --target="$HOME" --restow nvim nushell starship

# GUI extras (local mode)
stow --dir=. --target="$HOME" --restow alacritty
```

For a full local deploy with Zsh:

```bash
stow --dir=. --target="$HOME" --restow nvim zsh starship alacritty
```

#### keyd Setup

Privileged `keyd` install (`/etc/keyd`) previews before any `/etc` write and requires explicit confirmation. The installer previews with `stow --dir=. --target=/ --no --verbose keyd` plus `diff -u /etc/keyd/default.conf keyd/etc/keyd/default.conf` if `/etc/keyd/default.conf` exists as a regular file (not a symlink), then requires confirmation via `gum confirm` or `Type 'yes' to confirm privileged keyd install:` before any privileged write. On confirmation, it runs `sudo stow --dir=. --target=/ keyd` (plain) or `sudo stow --dir=. --target=/ --adopt keyd` only when a conflict file exists as a regular file and the user explicitly confirms the adopt path, then `sudo keyd reload || sudo systemctl reload keyd || true`. For `--dry-run`, it prints `[DRY RUN] Would run: sudo stow --dir=. --target=/ keyd` plus diff preview without touching filesystem. Manual preview:

```bash
# Preview before privileged write (what installer shows):
stow --dir=. --target=/ --no --verbose keyd
diff -u /etc/keyd/default.conf keyd/etc/keyd/default.conf 2>/dev/null || echo "(no host file or symlink — no diff needed)"
# After confirmation, installer runs: sudo stow --dir=. --target=/ keyd && sudo keyd reload || sudo systemctl reload keyd || true
# With conflict and explicit adopt confirmation: sudo stow --dir=. --target=/ --adopt keyd
```

To allow reloading `keyd` without a password (least-privilege), run `sudo EDITOR=nvim visudo` and add:

```
shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload keyd, /usr/bin/keyd reload
```

#### Zsh Plugin Manager

```bash
# Zinit clones itself on first zsh launch via zsh/.zshrc — no installer clone, no commit pin per D-12
# Manual fallback if needed:
git clone https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git
```

#### Tool Completions

```bash
# Generate uv zsh completions
mkdir -p ~/.config/zsh/completions
uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv
```

#### Zsh completion behavior (Phase 5)

- Type one character and the completion list auto-shows below the prompt with no keypress; an empty prompt stays quiet with no popup.
- `Tab` belongs to autocomplete (enters and cycles the menu; `Shift-Tab` cycles back, arrows also navigate) while `Ctrl+R` belongs to fzf history search.
- Matching is prefix-only — candidates must start with what was typed; typo-correction is intentionally off.
- The full list shows by default; past the line cutoff the engine appends a visible `(MORE)` marker — never a silent cut.
- `Ctrl+G` dismisses the menu keeping the buffer; `Ctrl+C` keeps stock whole-line abort (SIGINT) and `Esc` keeps stock vi insert-to-normal.

---

## Machine-local overrides

Machine-specific tweaks live in HOME-only files that are auto-sourced when present and never enter git:

| File | Destination | Sourced/Loaded |
|------|-------------|----------------|
| Shell | `~/.zshrc.local` | Sourced at the tail of `~/.zshrc` (after tool inits, before the p10k prompt apply) |
| Editor | `~/.config/nvim/lua/local.lua` | Loaded last at the end of `init.lua`, so machine tweaks win |

Copy from the documented templates (the only valid destinations):

```bash
cp zsh/.zshrc.local.example ~/.zshrc.local
cp nvim/.config/nvim/lua/local.lua.example ~/.config/nvim/lua/local.lua
```

- **Absent means silent:** a fresh clone works with both files missing — no error, no warning.
- **Git stays clean:** the real files are gitignored (`*.local`, the deployed `local.lua`, shell history); only the `*.example` templates are committed. `bash setup.sh` creates both empty HOME files after a successful deploy (previewed, never written, under `--dry-run`) without touching existing content.

---

## Tech Stack

| Shell | Zsh (Default) | Nushell (Backup) |
|-------|--------|-----|
| Prompt | Powerlevel10k | Starship |
| Manager | Zinit | Built-in |
| Utilities | keyd, zoxide, rg, uv | keyd, zoxide, rg, uv |

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
