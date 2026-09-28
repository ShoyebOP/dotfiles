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
- Strict post-verify (`test -e` + `readlink -f` prefix check, folding-aware) aborts with a link→expected-target report if any link is wrong. Selecting `keyd` previews with `stow --dir=. --target=/ --no-folding --no --verbose keyd` plus `diff -u` when `/etc/keyd/default.conf` exists as a regular file, requires `gum confirm` or `Type 'yes' to confirm privileged keyd install:` before `sudo stow --dir=. --target=/ --no-folding keyd` (or `sudo stow --dir=. --target=/ --no-folding --adopt keyd` only with explicit adopt confirmation), then `sudo keyd reload || sudo systemctl reload keyd || true`.

---

## Manual Installation (Alternative)

If you prefer to set things up manually without the unified installer:

#### Install Dependencies

- **Core:** `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`, `zsh`
- **GUI (Arch):** `alacritty`, `keyd`
- **GUI (Debian):** `alacritty`
- **Termux:** `stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `nodejs`, `npm`, `make`, `gcc`, `fzf`, `zsh` via `pkg install` (no `sudo`, no GUI packages)

#### Deploy Configurations

Use `GNU Stow` to symlink the configurations (explicit `--dir`/`--target` is what `bash setup.sh` does internally). All commands use `--no-folding` so stow creates leaf links only and never swallows the parent `~/.config` dir:

```bash
# Core (Zsh default)
stow --dir=. --target="$HOME" --no-folding --restow nvim zsh starship

# Nushell backup instead of Zsh
stow --dir=. --target="$HOME" --no-folding --restow nvim nushell starship

# GUI extras (local mode)
stow --dir=. --target="$HOME" --no-folding --restow alacritty
```

For a full local deploy with Zsh:

```bash
stow --dir=. --target="$HOME" --no-folding --restow nvim zsh starship alacritty
```

#### keyd Setup

Privileged `keyd` install (`/etc/keyd`) previews before any `/etc` write and requires explicit confirmation. The installer previews with `stow --dir=. --target=/ --no-folding --no --verbose keyd` plus `diff -u /etc/keyd/default.conf keyd/etc/keyd/default.conf` if `/etc/keyd/default.conf` exists as a regular file (not a symlink), then requires confirmation via `gum confirm` or `Type 'yes' to confirm privileged keyd install:` before any privileged write. On confirmation, it runs `sudo stow --dir=. --target=/ --no-folding keyd` (plain) or `sudo stow --dir=. --target=/ --no-folding --adopt keyd` only when a conflict file exists as a regular file and the user explicitly confirms the adopt path, then `sudo keyd reload || sudo systemctl reload keyd || true`. For `--dry-run`, it prints `[DRY RUN] Would run: sudo stow --dir=. --target=/ --no-folding keyd` plus diff preview without touching filesystem. Manual preview:

```bash
# Preview before privileged write (what installer shows):
stow --dir=. --target=/ --no-folding --no --verbose keyd
diff -u /etc/keyd/default.conf keyd/etc/keyd/default.conf 2>/dev/null || echo "(no host file or symlink — no diff needed)"
# After confirmation, installer runs: sudo stow --dir=. --target=/ --no-folding keyd && sudo keyd reload || sudo systemctl reload keyd || true
# With conflict and explicit adopt confirmation: sudo stow --dir=. --target=/ --no-folding --adopt keyd
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

#### Zsh Key Ownership

Key-ownership ladder, highest priority first (new clashes resolve downward):

| Priority | Owner | Keys | Behavior |
|----------|-------|------|----------|
| 1 | autocomplete (Tab/menu) | `Tab` / `Shift-Tab`, arrows in menu | Tab always enters menu-select and cycles items; arrows move selection |
| 2 | autosuggestions (ghost-accept) | `Right-arrow`, `l` in vi-normal, `Ctrl+Space`, `Ctrl+_` | Ghost-text accept keys; `l` and `Right-arrow` ghost-accept already work as-is — preserved, not rebuilt |
| 3 | fzf (history + extras) | `Ctrl+R`, expendable `**` / `Ctrl+T` / `Alt+C` | `Ctrl+R` opens fzf history search; extras are droppable and must never break autocomplete |
| 4 | stock vi/zle | everything undecided | Core motions (`hjkl`, `w`/`b`, `gg`/`G`) stay stock and untouchable |
| — | autocomplete wins | `Tab` | Tab never accepts ghost text — with ghost visible, Tab opens or navigates the menu, never inserts ghost |
| — | autocomplete wins | `Right-arrow` | Right-arrow navigates the open menu when the menu is open and accepts ghost only when the menu is closed |
| — | autocomplete | `Enter` | Enter selects the highlighted item into the buffer on first press and runs it on second press; first Enter never executes |
| — | autocomplete | `Ctrl+C` | Ctrl+C dismisses the completion list; `Esc` keeps stock vi behavior (insert→normal) |
| — | fzf | `Ctrl+R` | Ctrl+R history ownership belongs to fzf-history-search, never to the auto-show list (the list shows everything except history) |

> **Troubleshooting — first prompt needs network:** the async backend (`marlonrichert/zasync`) auto-clones at the first prompt, so the first prompt needs network plus git for the async backend clone or the list silently never starts while Tab keeps working.
>
> **Troubleshooting — stale backend registration (typing shows nothing while manual Tab works):** if typing never auto-shows the list but Tab still completes, and `~/.local/state/zsh-autocomplete/log/` stays empty, the `zasync` backend is likely registered from its directory instead of its file (upstream #907/#905). Check with `whence -v zasync` in a real interactive terminal — it must print the cache file path (`.../.cache/zsh/zasync/zasync`); a bare directory means the stale stub is present. The fix is the one-shot precmd hook inside `zsh/.zshrc` just after the `marlonrichert/zsh-autocomplete` load (it clears the stub at first precmd and registers the cached file, then removes itself). Retire after a manager update past the upstream fix removes the hook.

#### Tool Completions

```bash
# Generate uv zsh completions
mkdir -p ~/.config/zsh/completions
uv generate-shell-completion zsh > ~/.config/zsh/completions/_uv
```

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
