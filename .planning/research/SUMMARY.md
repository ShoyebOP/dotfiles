# Project Research Summary

**Project:** Dotfiles — Unified Installer & Reliability Hardening
**Domain:** GNU Stow-based development environment bootstrapper (7 Stow packages, Neovim lazy.nvim + 14 languages, Zsh/Zinit/P10k, desktop primitives)
**Researched:** 2026-09-10
**Confidence:** HIGH (installer, Stow, distro detection, Neovim aggregator), MEDIUM (TUI ladder, fzf version drift, theme centralization)

## Executive Summary

This is a dotfiles reliability milestone, not a new product. The repo already delivers a working environment via GNU Stow (`nvim/`, `zsh/`, `starship/`, `alacritty/`, `wofi/`, `keyd/`) and a Neovim stack (lazy.nvim stable + 21 plugins + `lang/init.lua` aggregator for 14 languages), but the delivery layer is broken: four mirrored bootstrappers (`setup.nu`/`setup.zsh` + `teardown.*`) drift on core/GUI package lists, hard-code `["arch","cachyos","ubuntu"]` and crash on every derivative (Manjaro, EndeavourOS, Mint, Pop!_OS), run `sudo stow --adopt -t / keyd` without a diff gate, and provide no `--dry-run` preview or health gate that works without a VM. The Zsh path has a broken `Ctrl+R` (two history plugins fighting over `^R`/`^I`), an unconditional `exec start-hyprland` that kills headless logins, and duplicated PATH segments; Neovim needs manual `:MasonInstallAll` for every fresh clone.

Experts build this class of system as a **Stow monorepo with a single Bash canonical installer and a language-oriented plugin aggregator**. The recommended approach is: canonicalize on `bash setup.sh` (Bash 5.2 is the only shell guaranteed on every Arch/CachyOS/Ubuntu minimal image) with full strict-mode preamble + `shopt -s inherit_errexit` and `${1-}` guards, probe distro by `command -v pacman/apt` first then `ID_LIKE`, correct `common` to include `make`+`gcc`+`fzf`+`zsh`, add a `verify → install → re-verify` lock, gate every write behind `mode → shell (zsh default) → TUI checklist (gum → whiptail → dialog → fzf → read)` with `keyd` OFF by default, orchestrate Stow only from repo root with `stow --dir="$SCRIPT_DIR" --restow` and a privileged `diff + gum confirm` gate, self-install `zsh`+Zinit before stowing, persist `~/.config/dotfiles/mode` for the Hyprland guard, then harden Zsh init ordering (P10k top, `zoxide init` last) and Neovim (`mason-tool-installer` deferred auto-install + `which-key.nvim` v3 + `vim.uv or vim.loop` bootstrap). One file owns mutation; everything else is stowed and verified.

The key risks are crash-before-preview (`set -euo pipefail` + `inherit_errexit` without `${1-}` guard kills `--help` itself), derivative rejection (the #1 support ticket), `whiptail 3>&1 1>&2 2>&3` fd-swap emptiness under `set -e`, Stow folding silently deploying to the wrong path when invoked from a subdirectory, `--adopt` pollution moving the live `/etc/keyd/default.conf` into the repo, and Mason headless async that exits before `pyright`/`ruff` finish. Every risk is mitigated by a single invariant: **TUI checklist runs before any `pacman -S`/`apt install`/`stow`/`chsh`, every mutating path has a `[DRY RUN] Would run:` + `stow --no --verbose` preview, and `--self-test` (TAP: `test -L` + `readlink -f` + `checkhealth` zero errors + `bindkey '^R'` + Mason + PATH dedup) is runnable headless without a VM.**

## Key Findings

### Recommended Stack

GNU Bash 5.2 + GNU Stow 2.4.1 are the foundation; everything else is orchestrated around them. The repo already runs on the right versions (host: Bash 5.2.21, Zsh 5.9, Neovim 0.12.2, Starship 1.24.2) except for Stow (host 2.3.1 — must upgrade to 2.4.1 for `find_stowed_path` + `--dotfiles` fixes) and fzf (host 0.44.1 on Ubuntu 24.04 — needs `≥0.48` for `source <(fzf --zsh)` embedded integration, with legacy `/usr/share/fzf/key-bindings.zsh` fallback). Starship + gum/whiptail + zoxide + ripgrep + uv + Mason form the supporting toolchain. Development gates are ShellCheck 0.10.x + shfmt 3.10+ on every change.

**Core technologies:**
- **GNU Bash 5.2.x** — canonical `setup.sh` entry (install + `--uninstall`/`--remove` + `--dry-run`) — only shell preinstalled on every minimal image; 5.1+ needed for `inherit_errexit` + associative arrays.
- **GNU Stow 2.4.1** — dotfile deployment (`--restow`/`-D`/`--adopt -t /`) — 2.3.1 has spurious `BUG in find_stowed_path` on unstow; 2.4.1 is the fix.
- **Zsh 5.9 + Zinit (commit-pinned) + Starship 1.24.2** — default interactive shell + prompt; P10k frozen in life-support (keep, don't adopt new) while Starship is the active cross-shell successor.
- **Neovim ≥0.10 (0.12.2) + lazy.nvim stable + mason-org/mason.nvim + mason-tool-installer + which-key.nvim v3** — editor runtime; `vim.uv or vim.loop` + `vim.v.shell_error` bootstrap, `ensure_installed = require("lang").mason_packages` deferred `start_delay=3000`.
- **charmbracelet/gum (≥0.15 primary) → whiptail 0.52.24 / dialog / fzf --multi / plain read** — TUI checklist ladder; gum absent on fresh Ubuntu so whiptail fd-swap `3>&1 1>&2 2>&3` fallback must be proven.
- **fzf ≥0.48 (host 0.44.1 → upgrade)** — `Ctrl+R` history; 0.48+ uses `source <(fzf --zsh)`, older uses legacy `/usr/share/fzf/key-bindings.zsh`; Zoxide 0.9.8+ `zi` needs 0.51+.
- **zoxide 0.9.8+ / ripgrep / uv / Tree-sitter CLI + gcc/make** — `zoxide init zsh` last in `.zshrc`, `make`+`gcc` in `common` so `telescope-fzf-native` `cond` never silently falls back.

*Details: [STACK.md](./STACK.md) — 249 lines, HIGH/MEDIUM confidence, with installation matrix for Arch/CachyOS and Ubuntu and full Alternatives/What-NOT-to-Use tables.*

### Expected Features

Users expect a one-command `bash setup.sh` that works on derivatives, previews before writing, reverses cleanly, and leaves no manual `stow` or `:MasonInstallAll` step. The checklist-plus-safety flow is the differentiator; secrets/CI/snapshots are explicitly deferred.

**Must have (table stakes) — P1, blocks VM validation:**
- **Unified Bash single-binary `setup.sh --install/--uninstall/--remove --dry-run`** — replaces 4-script drift; the spine every downstream feature depends on.
- **Non-crashing distro detection (`ID` + `ID_LIKE` + `command -v pacman/apt` probe, families not IDs)** — #1 crash, blocks Manjaro/EndeavourOS/Mint/Pop!_OS at step 1.
- **Verify → install → re-verify lock (partition core vs gui, handle `[[ ! -t 0 ]]`)** — partial `pacman -S`/`apt install` without re-verify silently breaks `telescope-fzf-native`/`zoxide`/`starship`.
- **Shell self-install before stow (ensure `zsh` binary + Zinit clone, offer `chsh` last never auto)** — bootstrap paradox on minimal images.
- **Mode → shell (zsh default) → TUI checklist override before any write** — PROJECT.md safety invariant; `gum choose --no-limit --selected` primary → `whiptail --checklist` (fd swap + `tr -d '"'`) → `dialog` → `fzf --multi` → plain `read`; `keyd` OFF by default, `gui` ON only if `local`.
- **Stow symlink correctness + conflict preview (`stow --no --verbose`, repo-root assert `[[ -f ./setup.sh ]]`, real-file guard, `readlink -f` post-verify)** — folding (`starship/.config/starship.toml → ~/.config/starship.toml`) silently wrong if invoked from subdir.
- **Privileged `/etc/keyd` safety (`stow --no -t /` preview + `diff -u` + `gum confirm` before `--adopt`, least-privilege sudoers, plain `stow -t /` otherwise)** — only privileged write in repo.
- **Hyprland `zsh/.zprofile` guard (reads `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true`)** — kills login on headless `server` otherwise.
- **PATH dedup (`typeset -U path` in Zsh)** — grows unbounded on reload, slows completions, risks `ARG_MAX`.
- **Docs flipped to Zsh-default + Bash entry (`README.md` table `Default: Zsh | Backup: Nushell` + `bash setup.sh --mode local` primary)** — current README still advertises `nu setup.nu` as primary.

**Should have (competitive) — P2, add once P1 is VM-proven:**
- **Zsh `Ctrl+R` fzf history conflict-free (native `source <(fzf --zsh)` ≥0.48, one history plugin policy, `bindkey '^R' fzf-history-widget` normalized, `^I` not clobbered)** — most visible shell QoL.
- **Neovim Mason auto-install + cleanup lifecycle (`mason-tool-installer` deferred + `setup.sh` headless `check_install(false,true)` or `MasonInstallAll + sleep 12`, remove `~/.local/share/nvim/mason` on uninstall)** — "python works out-of-box".
- **which-key leader popup `folke/which-key.nvim` v3 `preset=modern delay=200 triggers={"<auto>"}`** — discoverability for 14 languages + 21 plugins.
- **Machine-local gitignored overrides (`~/.zshrc.local` tail + `nvim/lua/local.lua` `pcall` + `.gitignore` + `*.example` templates)** — multi-machine without dirty git.
- **Self-test / health gates (`--self-test` TAP: stow folding, `z`/`zi`, `checkhealth` zero errors, Mason, starship/zoxide hooks, PATH dedup)** — VM-less validation, CI-ready.
- **Theme duplication validation (`THEME` token + `apply_theme()` warns on `alacritty mocha` vs `starship latte` mismatch)** — minimal v1 is validation not templating.
- **`telescope-fzf-native` `make`+`gcc` already in core + editor `vim.notify WARN` on `executable("make")==0`** — surfacing not silent fallback.
- **`init.lua` lazy.nvim official bootstrap (`vim.uv or vim.loop` + `shell_error` + `getchar()+os.exit`) + `lazy-lock.json` HEAD verification** — reproducibility.

**Defer (v2+) — explicitly anti-features for this milestone:**
- **Secrets manager (`sops`/`age`/`pass`, `MISTRAL_API_KEY` history purge via `filter-repo`/`BFG`)** — PROJECT.md scopes Nushell secret handling to docs only; rotation is out-of-band; full purge rewrites history + breaks clones — HIGH cost.
- **Automated snapshot/rollback before `teardown` (`tar` + `setup.sh --restore`)** — `Type 'yes'` + `--dry-run` is sufficient safety for now; document `tar -czf ~/dotfiles-backup-$(date +%F).tar.gz …` one-liner.
- **CI matrix (GitHub Actions Arch/Ubuntu × local/server)** — self-test is CI-ready (TAP + `nvim --headless`), orchestration deferred.
- **Nushell QoL re-parity (zoxide double-hook, `uv.nu` lazy-load, `MISTRAL_API_KEY`)** — backup shell per PROJECT.md; keep `setup.nu` as `exec bash setup.sh` shim.
- **Chezmoi/yadm templating, new desktop envs/WMs, macOS/Brew, `starship` micro-tuning, Bubbletea/textual TUI frameworks** — overkill at 7 packages; solve with `*.local` + THEME token.

*Details: [FEATURES.md](./FEATURES.md) — P1/P2/P3 matrix, dependency graph, competitor analysis (Stow raw vs chezmoi/yadm vs dotbot vs mirrored scripts), MVP slice definition.*

### Architecture Approach

The system is a **Stow monorepo** where each top-level directory is a bounded context mirroring its deployment target, orchestrated by a **Bash strict-mode preview-first delivery layer**. Neovim is layered as a language-oriented aggregator (`settings.languages` single toggle → `lang/init.lua` `deduplicate()` → `mason_packages`/`treesitter`/`formatters`/`lsp`), Zsh as a strict init-ordering contract (P10k instant prompt top, Zinit, fzf after Zinit before `bindkey`, `zoxide init` last, `~/.zshrc.local` tail).

**Major components:**
1. **Unified Bash Installer (`setup.sh`)** — canonical install+uninstall with `set -Eeuo pipefail; shopt -s inherit_errexit` preamble, `SCRIPT_DIR`, `die/info/warn/confirm` (gum-styled), `get_distro`/`get_pm_family` (`ID_LIKE`+pm probe), `get_deps( distro×mode×shell )`/`verify`/`install`/`verify_strict`, `prompt_mode`/`prompt_shell`/`build_package_list`/`tui_checklist` ladder, `stow_module`/`run_stow`/`run_unstow`, `setup_shell`/`maybe_chsh`, `apply_theme`, `self_test`, `main` arg parser with `${1-}` guard.
2. **Stow Orchestrator** — deploys 7 packages from repo root only (`stow --dir="$SCRIPT_DIR" --restow/-D/--no --verbose --adopt -t /`), respects folding (`starship`), gates privileged `keyd` (`preview + diff + confirm`), asserts `test -L` + `readlink -f` post-stow.
3. **Dependency Resolver + Interactive Flow Controller** — per-distro `common` (adds `make`+`gcc`+`zsh`/`fzf`) + `gui` lists, `verify_deps` `command -v` loop with `core_missing` vs `gui_missing` partition, `tui_checklist` producing the `selected` set **before any write** and persisting `~/.config/dotfiles/mode`.
4. **Shell Runtime — Zsh (default)** — `zsh/.zshrc` ordering contract (P10k top → XDG/PATH dedup `typeset -U` → Zinit → P10k theme → plugins → fzf `source <(fzf --zsh)` → `zoxide init` last → `bindkey -v` → `~/.zshrc.local` tail → `.p10k.zsh`), `zsh/.zprofile` Hyprland guarded exec.
5. **Editor Runtime — Neovim** — `init.lua` official bootstrap + `lang/init.lua` aggregator (`pcall WARN` + silent `plugins.lua`) + `lazy.nvim` 44 pins in `lazy-lock.json` + `mason-tool-installer` deferred `ensure_installed` + `which-key` v3 + `telescope-fzf-native` `cond` WARN.
6. **Presentation / Theme + Health Gate** — `alacritty`/`starship`/`wofi`/`keyd` packages, `THEME` token validated at install, `--self-test` TAP that reuses `--dry-run` + headless `nvim --headless -c "checkhealth"` + `bindkey`/`zoxide`/`starship` asserts.

**Key patterns:**
- Stow Packages as Bounded Contexts (never hand-roll `ln -sf`; one package per target, `keyd -t /` privileged).
- Language-Oriented Plugin Composition (add a language = new file + one entry in `settings.languages`, dedup handles the rest).
- Bash Strict-Mode Single-Source Preview-First (every mutating path guarded by `DRY_RUN` + `stow --no --verbose`; `${1-}` for `set -u`).
- Zsh Init Ordering Contract (two load-bearing comments: P10k top, zoxide last — keep them).
- Theme Single Token (validate `alacritty import` vs `starship palette` vs `nvim`/`nushell` now; template later).

**Repo shape:** `setup.sh` at root as stow directory, `setup.zsh`/`setup.nu`/`teardown.*` as one-release shims `exec bash setup.sh`, optional `manifest.toml` (`tag: core|gui|arch-only`) and `theme.toml` (`flavor=mocha`), `zsh/.zshrc.local.example` + `nvim/lua/local.lua.example` + `nushell/secrets.nu.example`, `nvim/lua/plugins/which-key.lua` new, no `.github/workflows/` this milestone.

*Details: [ARCHITECTURE.md](./ARCHITECTURE.md) — 1074 lines with skeleton code, full data flows (install/uninstall/DRY_RUN/derivatives/editor), 6 anti-patterns, scaling table (7 → 12+ packages), and Suggested Build Order Phases 1–7.*

### Critical Pitfalls

Fourteen pitfalls were documented; the top 6 are entry-point or privileged-filesystem correctness and must be gated before QoL. All are validated by `shellcheck -S warning` + `shfmt` + specific `--self-test` TAP lines and Bats-style probes.

1. **Bash strict-mode crash (`set -euo pipefail` + `inherit_errexit` + SIGPIPE 141 + `${1}` unbound)** — copy-pasted `set -e` crashes `--help` before usage prints, `yes | head -1` RC 141 trips `pipefail`, bare `$1` aborts under `set -u`. Avoid: full BCS preamble, `${1-}`/`${2-}` in arg parsing, `|| true` on intentional SIGPIPE, `PIPESTATUS` checks, `shellcheck` + `shfmt` in pre-commit and `--self-test`.
2. **Distro allowlist rejects derivatives** — hard-coded `["arch","cachyos","ubuntu"]` rejects Manjaro/EndeavourOS/Garuda/Mint/Pop!_OS even though `pacman`/`apt` works. Avoid: probe `command -v pacman`/`apt-get` first, then `ID_LIKE` space-separated, then `ID`; map to families (`arch` vs `debian`) not IDs; Bats mock `ID=manjaro ID_LIKE=arch → arch`.
3. **Whiptail/dialog fd-swap & exit-code mishandling** — `whiptail` writes chosen tags to **stderr**; capturing needs `3>&1 1>&2 2>&3` inside `$()`, returns quoted `"nvim" "zsh"` (or `--separate-output` one-per-line), exit `1`/`255` = Cancel/ESC which must abort not continue; missing `|| true` under `set -e` kills the installer with no message. Avoid: canonical wrapper with `|| true`, handle `1`/`255` as abort, prefer `--separate-output`, test stubbed `whiptail` writing to stderr.
4. **Stow `--adopt` repo pollution & privileged overwrite** — `sudo stow --adopt -t / keyd` moves live `/etc/keyd/default.conf` into `keyd/etc/keyd/default.conf`, dirtying git and hijacking input if stale; `NOPASSWD: /usr/bin/systemctl *` widens privilege. Avoid: preview `stow --no --verbose -t / keyd`, `diff -u` if `/etc/keyd/default.conf` exists and is not a symlink, `gum confirm` before `--adopt` else plain `stow -t / keyd`; least-privilege sudoers `start|stop|reload keyd` only; `keyd` OFF by default in checklist.
5. **Stow folding & half-stow (wrong stow directory, Stow 2.3.1 bugs, two-phase conflict)** — invoking from subdir breaks `starship/.config/starship.toml` folding (`→ ~/.config/starship.toml`), half-linked packages leave `target is not owned by stow` on retry, Stow 2.3.1 emits `BUG in find_stowed_path`. Avoid: lock `stow ≥2.4.1`, always `stow --dir="$SCRIPT_DIR" --restow` with `[[ -f ./setup.sh ]]` repo-root assert, `stow --no --verbose` preview, `test -L` + `readlink -f` post-verify, keep packages non-overlapping.
6. **Mason headless not auto-installing + Hyprland exec kills server login + fzf version drift** — bundled: `mr.refresh(async)` + `p:install()` is non-blocking so `nvim --headless -c "MasonInstallAll" -c "qa"` exits before `pyright` installs; `zsh/.zprofile` `exec start-hyprland` on `tty1` without mode check kills headless logins when Hyprland missing; `fzf 0.44.1` `fzf --zsh` flag doesn't exist while `0.51+` needed for `zi`. Avoid: `mason-tool-installer` `check_install(false,true)` sync or `MasonInstallAll + sleep 12` + `checkhealth mason` zero errors; persist `~/.config/dotfiles/mode` and guard `.zprofile` with `DOTFILES_MODE != server && command -v Hyprland && || true`; branch fzf integration `fzf_version_ge 0.48 → source <(fzf --zsh)` else legacy + remove one of `joshskidmore/zsh-fzf-history-search` vs `marlonrichert/zsh-autocomplete` and normalize `bindkey '^R'`.

*Details: [PITFALLS.md](./PITFALLS.md) — 734 lines covering 14 pitfalls + technical debt table, security/UX/integration sections, and the definitive "Looks Done But Isn't" 15-point checklist plus recovery strategies.*

## Implications for Roadmap

Based on combined research, this is a **fix-the-pipe-before-polish** project: crash gates first (nothing else is testable if `--help` itself aborts), then safety-before-writes, then filesystem correctness, then shell/editor QoL, with the health gate strictly last as the acceptance test. Phases 1–4 are sequential (each is a prerequisite), Phases 5 and 6 are parallel after Phase 4 (Zsh vs Neovim touch disjoint packages), Phase 7 is the release gate that fails if any upstream is missing.

### Phase 1: Installer Foundation & Safe Flags
**Rationale:** Every later phase depends on a non-crashing entry point; `set -euo` and distro probe are the first crash users hit on a derivative, before any feature can run. Also establishes `SCRIPT_DIR` + `DRY_RUN` plumbing that `starship` folding and `keyd` gates need.
**Delivers:** `setup.sh` preamble (`set -Eeuo pipefail; shopt -s inherit_errexit failglob extglob nullglob; SCRIPT_DIR; die/info/warn/confirm` gum-styled), `usage` + `parse_args` with `${1-}` guard for `set -u`, `--dry-run` short-circuit on every mutating path (`pacman`/`apt`/`stow`/`chsh`/`systemctl`), repo-root assertion `[[ -f ./setup.sh ]]`, `stow --version ≥2.4.1` check, `shellcheck -S warning` + `shfmt -i 4 -ci` gate.
**Addresses:** P1 unified Bash entry replacing 4-script drift, reversibility foundation, safety preview.
**Avoids:** Pitfall 1 strict-mode crash, Pitfall 6 wrong stow directory.
**Uses:** Bash 5.2, ShellCheck 0.10.x, shfmt 3.10+.

### Phase 2: Distro · Deps · TUI Checklist (before any write)
**Rationale:** Derivatives crash at step 1 and package-override is a PROJECT.md safety invariant — checklist must precede any write (can't add it after `stow` without re-stowing). Combining distro+deps+TUI into one phase enforces that invariant.
**Delivers:** `get_distro`/`get_pm_family` (pm probe → `ID_LIKE` → `ID`, lowercase normalize), corrected `get_deps(distro×mode×shell)` (`common` adds `make`+`gcc`+`zsh`/`fzf`; per-pm `gui` un-diverged), `verify_deps` (`command -v` loop `+`/`-` echo, partition `core_missing` vs `gui_missing`), `install_deps` (`pacman -S --needed` / `apt-get install -y`) + **`verify_deps_strict` re-run aborting on `Still missing`** (the lock), `prompt_mode`/`prompt_shell` (gum primary → `read` fallback, zsh default), `build_package_list` (core ON, gui ON only if `local`, `keyd` OFF), `tui_checklist` ladder `gum choose --no-limit --selected` → `whiptail --checklist 20 78 10 3>&1 1>&2 2>&3` → `dialog` → `fzf --multi` → plain `read "numbers or all"`, mode marker `mkdir -p ~/.config/dotfiles && echo "$MODE" > ~/.config/dotfiles/mode`, `--yes` bypass for CI. Also fixes `telescope-fzf-native` silent fallback at the root.
**Addresses:** P1 distro fix, dep re-verify, shell-before-stow dependency, mode→shell→checklist flow, `make`+`gcc` in common.
**Avoids:** Pitfall 2 derivative rejection, Pitfall 7 no-post-install lock, Pitfall 3 checklist missing, Pitfall 4 whiptail fd-swap.
**Implements:** Dependency Resolver + Interactive Flow Controller.

### Phase 3: Stow Orchestration + Shell Self-Install + Shims
**Rationale:** Symlink correctness is the most user-visible "succeeded but broken" failure (folding, moved repo), and `keyd` is the only privileged write; shell self-install fixes bootstrap paradox on minimal images. Shims preserve `zsh setup.zsh`/`nu setup.nu` muscle memory for one release.
**Delivers:** `stow_module`/`run_stow`/`run_unstow` (`stow --dir="$SCRIPT_DIR" --restow/-D`, `--no --verbose` dry-run, real-file guard `[[ -e ~/.config/starship.toml && ! -L ]]` → WARNING+confirm before `rm -rf`), `keyd` privileged gate (`stow --no --verbose -t / keyd` preview → `diff -u` if conflict → typed `yes` before `--adopt`, otherwise plain `stow -t / keyd` → `keyd reload`/`systemctl reload` fallback, `keyd` OFF by default), `setup_shell` (ensure `zsh` binary, Zinit commit-pinned clone, `stow --restow zsh`, `maybe_chsh` offer last never auto), `apply_theme` consistency check (warn on `alacritty mocha` vs `starship latte` mismatch — no templating yet), thin shims `setup.zsh`/`setup.nu`/`teardown.*` → `exec bash setup.sh`.
**Addresses:** P1 stow correctness, keyd safety, shell self-install, idempotent re-runs.
**Avoids:** Pitfall 5 `--adopt` pollution, Pitfall 6 folding/half-stow.
**Implements:** Stow Orchestrator + Shell Self-Installer.

### Phase 4: Shell Runtime Hardening + Docs Flip
**Rationale:** Once `setup.sh` correctly deploys files, pure-file edits (init order, bindkeys, PATH, guard) become safe to land — shipping them without the installer that stows them would be inconsistently tested. Docs must wait until `bash setup.sh` actually works.
**Delivers:** `zsh/.zshrc` PATH dedup (`typeset -U path`), preserved init order (P10k instant prompt top, Zinit, fzf after Zinit before `bindkey`/`zoxide last` with load-bearing comments), fzf history conflict resolution (remove one of `joshskidmore/zsh-fzf-history-search` vs `marlonrichert/zsh-autocomplete`, version-branch `fzf_version_ge 0.48 → source <(fzf --zsh)` else legacy `/usr/share/fzf/key-bindings.zsh`, normalize `bindkey '^R' fzf-history-widget` + `FZF_CTRL_R_OPTS`, never rebind `^R`/`^I` after), `zsh/.zprofile` Hyprland guarded `exec` reading `~/.config/dotfiles/mode` + `command -v Hyprland` + `|| true`, machine-local `[[ -f ~/.zshrc.local ]] && source` tail + `.gitignore` (`zsh/.zshrc.local`, `zsh/.zprofile.local`, `nushell/secrets.nu`, `.env.local`) + `*.example` templates, docs flipped (`README.md` `Default: Zsh | Backup: Nushell`, `bash setup.sh --mode local/server --dry-run` primary, `nvim/README.md` + in-code comments).
**Addresses:** P1 Hyprland guard + PATH dedup + docs Zsh-default, P2 machine-local (first half) + fzf integration.
**Avoids:** Pitfall 10 Hyprland kills login, Pitfall 8 fzf drift, Pitfall 9 `Ctrl+R`/`Ctrl+I` war, Pitfall 13 secrets (first half — `.gitignore`).
**Implements:** Shell Runtime contract — Zsh ordering.

### Phase 5: Editor Runtime Hardening
**Rationale:** Editor lifecycle depends on `stow nvim` being correct (Phase 3) and `make`+`gcc` already in `common` (Phase 2). Installing 14 LSPs before distro/deps are stable hammers the registry on a half-broken install; which-key + headless hook are low-risk once stow is proven. Independent of Phase 4 — they touch disjoint packages, so Phase 4 and 5 can run in parallel after Phase 3.
**Delivers:** `lua/plugins/which-key.lua` v3 `preset=modern delay=200 triggers={"<auto>"} spec` for `f/s/g/e/t/q` groups (auto-discovers `desc` in `base/keymaps.lua`), `WhoIsSethDaniel/mason-tool-installer.nvim` (`ensure_installed = require("lang").mason_packages, run_on_start=true, start_delay=3000, debounce_hours=24`) or enhanced `utils/mason-install-all.lua` + `mason.lua build=":MasonInstallAll"`, `setup.sh` post-stow headless hook `nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"` or `check_install(false,true)` sync + `checkhealth mason` zero errors, `telescope.lua` WARN toast on `executable("make")==0`, `init.lua` official `vim.uv or vim.loop` + `shell_error` bootstrap + `lazy-lock.json` HEAD vs `85c7ff3` verification, `lua/local.lua` (`pcall(require,"local")` + gitignored + `local.lua.example`), stale Mason cleanup on `--uninstall` when `nvim` deselected.
**Addresses:** P1 Neovim LSPs work without manual step, P2 Mason lifecycle + which-key + lazy pin + telescope guard.
**Avoids:** Pitfall 11 Mason headless not auto-installing, Pitfall 12 bootstrap drift, Pitfall 14 silent language loss (`pcall WARN` visible via noice).
**Implements:** Editor Runtime — Language Aggregator hardening.

### Phase 6: Health Gates & Polish Capstone
**Rationale:** Self-test validates everything and is meaningless until every upstream phase exists; it is also the PROJECT.md VM validation plan that lets the agent prove reliability without a VM. Theme validation and secrets docs are polish that only matters once the core is solid.
**Delivers:** `setup.sh --self-test`/`--verify` headless gates (TAP `ok/not ok`): `stow --no --verbose --restow nvim zsh starship` preview, `test -L ~/.config/nvim && readlink -f ~/.config/nvim/init.lua` + `test -L ~/.config/starship.toml` folding check, `zoxide --version && starship --version && fzf --version && stow --version ≥2.4.1`, `nvim --headless -c "checkhealth" -c "qa"` zero WARN/ERROR parse, `mason_packages` installed list, `zsh -i -c 'which zoxide; which starship; bindkey "^R"'` + `zle -l | grep fzf`, `PATH` dedup `tr : '\n' | sort | uniq -d` empty, `--dry-run` preview of all writes (including privileged `keyd`); completes `apply_theme()` mismatch WARN and remaining polish (`nvim/.config/nvim/.ignore` for `rg`, `secrets.nu` placeholder `$env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""` + `gitleaks` pre-commit docs, README `tar -czf ~/dotfiles-backup-$(date +%F).tar.gz …` one-liner). CI-ready without adding `.github/workflows/` this milestone.
**Addresses:** P1 self-test VM-less validation, P2 theme centralization + machine-local docs, deferred anti-feature documentation.
**Avoids:** Pitfall 13 secrets (capstone verification `gitleaks detect` zero + `git log -p -S MISTRAL_API_KEY` empty post-rotation), cross-cutting "looks done but isn't" checklist.
**Implements:** Self-Test / Health Gate.

### Phase Ordering Rationale

- **Crash gates first, polish last.** If `bash setup.sh --help` aborts on `unbound variable` or Manjaro hits `Error: only supports…`, no checklist/stow/Mason feature ever runs — so Phase 1 (strict-mode + stow dir) and Phase 2 (derivative probe + re-verify) must precede everything.
- **Safety invariant drives Phase 2 → Phase 3.** PROJECT.md requires `mode → shell → checklist override before any writes`; putting TUI after `install_deps`/`run_stow` would already have written to disk before the user could veto `keyd`/`hyprland`. Hence TUI ladder ships with distro/deps, and stow consumes its `selected` set.
- **Filesystem correctness before shell/editor.** Symlink folding (`starship`) and privileged `/etc/keyd` determine where `~/.config/nvim`/`~/.zshrc` actually resolve; `~/.config/dotfiles/mode` written in Phase 2/3 is read by `.zprofile` in Phase 4 — so Phase 3 → Phase 4.
- **Shell ordering before QoL, editor parallel with shell.** P10k-top / zoxide-last is the contract that `Ctrl+R` fzf branching and `bindkey` asserts depend on, so ordering lands before `Ctrl+R` fix (Phase 4 precedes its own tail). Zsh and Neovim touch disjoint packages (`zsh/` vs `nvim/`), so Phase 4 (Zsh) and Phase 5 (Neovim) run in parallel after Phase 3 to reduce calendar time.
- **Health gate strictly last.** TAP gates for `stow --no`, `checkhealth`, Mason, `bindkey`, PATH dedup are tautological before those features exist; building them last makes them the release acceptance test ("if `--self-test` passes in `bash setup.sh --dry-run`, the VM fresh install will pass").

### Research Flags

Phases likely needing deeper research during planning (`--research-phase`):
- **Phase 5 (Editor):** Mason headless semantics — `mason-org` registry vs legacy `williamboman`, `nvim --headless` blocking only with no UIs (`mason.txt`), `mr.refresh` async vs `mason-tool-installer check_install(false,true)` sync timeout + `sleep 12` tuning, `nvim-treesitter main` (4916d65) requires NVIM 0.10+ `vim.uv` + `gcc`/`make` toolchain.
- **Phase 4 (Shell QoL tail):** fzf version coupling — host Ubuntu 24.04 `0.44.1` vs Arch `0.51+` and installer `≥0.48` `fzf --zsh` embedded vs legacy script; `gum --selected` pre-check comma semantics and Charm apt repo availability on Ubuntu.
- **Phase 3 (Stow privileged):** `stow --adopt` semantics + `-t /` + tree folding nuances only surface on moved-repo or overlapping `~/.config` packages; verify `stow --no --verbose --adopt -t / keyd` preview vs real with a temp `/etc/keyd` overlay.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Installer skeleton):** Bash BCS preamble + `shellcheck` + `shfmt` + `SCRIPT_DIR` idiom is well-documented — just enforce literally.
- **Phase 2 distro probe (family mapping):** `man os-release(5)` `ID_LIKE` space-separated + `command -v pacman/apt` — reference man page covers it; only gotcha is quoting for ShellCheck.
- **Phase 4 PATH/Hyprland/docs:** `typeset -U path`, `command -v Hyprland` + `DOTFILES_MODE` guard, `.gitignore` `*.local` — two-line fixes with `echo $PATH | tr : '\n' | sort | uniq -d` / `cat ~/.config/dotfiles/mode` probes.
- **Phase 5 which-key + lazy pin:** Copy verified `folke/which-key.nvim` v3 spec (`preset=modern delay=200`) and official `vim.uv or vim.loop` snippet — no invention needed.
- **Phase 6 self-test harness (skeleton):** `stow --no --verbose`, `test -L`/`readlink -f`, `nvim --headless -c "checkhealth"` parsing, `bindkey` asserts — standard, but fragile across Neovim versions so allow tuning time.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** (core), **MEDIUM** (TUI) | Bash 5.2.21 / Stow 2.4.1 / Neovim 0.12.2 / Zsh 5.9 / Starship 1.24.2 / zoxide 0.9.3 pinned from host probes + GNU manuals + lazy.nvim contextual HIGH; MEDIUM for gum (not on host, only validated via Charm repo docs) and fzf 0.48/0.51 boundary (Ubuntu 24.04 baseline 0.44.1). |
| Features | **HIGH** (table stakes + installer), **MEDIUM** (differentiators) | P1 table stakes validated against PROJECT.md + 6 codebase maps + live `setup.nu`/`setup.zsh` drift — HIGH. P2 polish (which-key preset, gum vs fzf native preference, theme `THEME` vs `sed`) is inferred from 44-plugin + 391-line `zshrc` — MEDIUM, needs `gum --version`/`fzf --version` + `nvim --startuptime` probe during planning. |
| Architecture | **HIGH** (installer/Stow/aggregator/Zsh order), **MEDIUM** (TUI ladder/theme) | Delivery layer, Stow bounded contexts, `lang/init.lua` aggregator, Zsh P10k-top/zoxide-last validated against live repo + maps — HIGH. Whiptail fd-swap quoted-tag parsing and theme token validation-only are cross-checked with man pages/BCS but not live-tested on fresh Ubuntu VM — MEDIUM. |
| Pitfalls | **HIGH** | 14 pitfalls grounded in GNU Stow/mason/zsh manuals + host probes + codebase CONCERNS.md crashes; whiptail/fzf/Mason async corroborated across 2+ web sources + live file anchors; recovery costs and phase mapping provided. |

**Overall confidence:** **HIGH** — the stack, feature slice, and architecture are anchored in PROJECT.md constraints + 6 codebase maps + live reads + host probes. TUI fallback nuance and fzf version branching are the only MEDIUM items and both have prescribed detection + fallback ladders.

### Gaps to Address

- **fzf upgrade path on Ubuntu 24.04 (0.44.1 → 0.48+/0.51+):** host ships 0.44.1 but Zoxide `zi` needs 0.51+ and `source <(fzf --zsh)` needs 0.48+. Installer must detect `fzf --version`, warn if `<0.48`, and document Charm apt repo / `go install github.com/junegunn/fzf@latest` / cargo fallback. Validate on a fresh Ubuntu container before Phase 4 lands.
- **gum absent on fresh Arch live ISO and Ubuntu server:** primary `gum choose` is not preinstalled; the ladder must degrade to `whiptail --checklist 3>&1 1>&2 2>&3` (Ubuntu has it) → `dialog` → `fzf --multi` → plain `read`. Test `whiptail 0.52.24` quoted-tag parsing and Cancel/ESC 1/255 handling under `set -e` on both distros.
- **Stow 2.4.1 upgrade not present on host (2.3.1):** document `sudo pacman -S stow` / GNU FTP `stow-2.4.1.tar.gz` upgrade and add `stow --version ≥2.4.1` gate in `--self-test`; verify `BUG in find_stowed_path` is gone after upgrade.
- **Starship `scan_timeout=1000` per-mode tuning:** local powerline wants 1000ms rich scan, server wants 200ms minimal. Minimal v1 is a consistency WARN via `apply_theme()` + docs `starship timings`; auto-switch `starship.toml` vs `starship-minimal.toml` is deferred — decide threshold from `starship timings` on a large repo.
- **Mason headless sync timing:** `MasonInstallAll` via `mr.refresh(async)` needs `sleep 12` cover vs `mason-tool-installer check_install(false,true)` sync (`sync=true`). Tune timeout (12s may be short for 14 langs on slow network) and verify `checkhealth mason` zero errors in `--self-test` after headless call; currently no Bats fixture for fake Mason registry.
- **Theme centralization generation deferred:** this milestone only validates `alacritty mocha` vs `starship latte` mismatch. If users request flavor switch before 5th manual edit, `THEME=mocha/latte` → `envsubst`/`sed` generation will need a follow-up — don't invent chezmoi templating now.
- **Secrets hygiene scope cut:** `MISTRAL_API_KEY` committed in `nushell/env.nu:48` is documented as P6 placeholder `$env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""` + ignored `secrets.nu` + `gitleaks` docs only. No `git filter-repo`/`BFG` history purge or key rotation is performed in this milestone (PROJECT.md scope filter) — rotation must be done out-of-band via Mistral dashboard and communicated to clones; plan the force-push separately.
- **No runner/VM in scope:** all gates are VM-less (`--dry-run` + `nvim --headless` + `bindkey` probes). Validation needs a one-time manual fresh-container run (`bash setup.sh --dry-run --mode server` then real `--mode local` on an Arch live ISO and Ubuntu 24.04 VM) — not automated in CI this milestone.
- **Language scaling linear cost:** `settings.languages` 14 → 30 linear `mason_packages` + parsers (~500MB) + `mr.refresh` O(n). Mitigate later with `core` vs `opt-in` tiers and `mason-tool-installer` debounce — not needed at 7 packages.

## Sources

### Primary (HIGH confidence)
- `/home/shoyeb/dotfiles/.planning/codebase/*` — ARCHITECTURE.md, CONCERNS.md (22 concerns), STRUCTURE.md, STACK.md, CONVENTIONS.md, INTEGRATIONS.md (2026-09-10 local maps — Stow monorepo, lang aggregator, delivery layer, 7 packages/14 langs/21 plugins).
- `setup.nu` / `setup.zsh` / `teardown.zsh` / `zsh/.zshrc` (391 lines) / `zsh/.zprofile` / `nvim/.config/nvim/init.lua` / `lua/lang/init.lua` / `lua/settings.lua` / `lua/utils/mason-install-all.lua` / `lua/plugins/telescope.lua` / `starship.toml` / `alacritty.toml` — live repo reads 2026-09-10 anchoring drift, hard-coded allowlist, `vim.loop` bootstrap, `cond executable make`, Hyprland exec, `keyd --adopt`.
- `PROJECT.md` — active requirements (unified Bash entry, mode→shell→checklist, shell self-install, hazards, Neovim/Zsh QoL, self-test VM gate, Arch/CachyOS/Ubuntu+derivatives, reversibility), constraints (Bash preinstalled, Zsh default/Nushell backup), out-of-scope (secrets full fix, CI, snapshot, new DEs).
- **GNU Stow 2.4.1 manual** — https://www.gnu.org/software/stow/manual/stow.html — `--adopt` warning, tree folding §5.1, two-phase conflict check — official.
- **GNU Stow 2.4.0/2.4.1 NEWS** — https://lists.gnu.org/archive/html/info-gnu/2024-04/msg00000.html / 2024-09 — `--dotfiles` + `find_stowed_path` + Perl 5.40 fixes — official.
- **systemd `os-release(5)` / man7.org** — `ID_LIKE` space-separated, `[ "${ID_LIKE#*debian*}" != "${ID_LIKE}" ]` probe — official.
- **Bash Reference Manual — The Set Builtin + BashFAQ 105** — `set -e`/`pipefail`/`nounset` semantics, `inherit_errexit` — official.
- Host probes (ground truth) — `bash 5.2.21`, `stow 2.3.1`, `zsh 5.9`, `nvim v0.12.2`, `fzf 0.44.1`, `whiptail 0.52.24`, `starship 1.24.2`, `zoxide 0.9.3`, `ID=ubuntu ID_LIKE=debian` — local execution.

### Secondary (MEDIUM confidence)
- Context7 `/folke/lazy.nvim` — `vim.uv or vim.loop` + `filter=blob:none --branch=stable` + `vim.v.shell_error` + `getchar`/`os.exit` bootstrap — verified.
- Context7 `/mason-org/mason.nvim` + `/mason-org/mason-lspconfig` + `/WhoIsSethDaniel/mason-tool-installer` — `ensure_installed` + `run_on_start` + `check_install(false,true)` sync — verified; cross-checked with `mason.txt` headless-blocking + issues #467/#1618.
- Context7 `/folke/which-key.nvim` v3 — `preset=modern` + `spec`/`triggers={"<auto>"}` + `delay=200` + `event=VeryLazy` — verified; v2 `register()` removal noted.
- Context7 `/charmbracelet/gum` — `gum choose --no-limit --header/--selected`, `confirm` exit codes — verified.
- Context7 `/websites/starship_rs` + `/junegunn/fzf` — `starship init zsh/nu`, `source <(fzf --zsh)` / `eval "$(fzf --bash)"` — verified.
- fzf CHANGELOG 0.48.0–0.52.0 + issues #1304/#1639/#4211/#4294 — `fzf --zsh` embedded 0.48+, `HEIGHT required` mismatch when script/binary versions diverge — cross-checked.
- zoxide CHANGELOG 0.9.8/0.10.0 — `doctor`, `import`, `fzf ≥0.51` minimum — cross-checked with docs.rs.
- P10k life-support #2690 (2024-05-23, updated 2026-01-05) + HyDE #491 Starship migration + Zinit Turbo benchmark — verified via primary issues.
- Shell TUI cheat-sheet (cdocsa) + `man whiptail(8)`/`man dialog(1)` — `3>&1 1>&2 2>&3`, `--separate-output`, exit `0/1/255` — cross-checked with Debian/Ubuntu man pages.

### Tertiary (LOW confidence — needs validation during planning)
- Bash strict-mode blog snippets (imrekoszo/mohanpedala/linuxize 2026) — BCS preamble `IFS=$'\n\t'` + `inherit_errexit` — LOW→MEDIUM after cross-check with Arch BBS dissent ("Don't trust blogs, use shellcheck…").
- Dotfiles community patterns — Aman1337g/FluxxField `adopt-dry` + `~/.local/state/dotfiles/backups/` (5 recent), `superhighfives` allowlist `.gitignore`, `mshuffett` gum bootstrap, `iatosh` `~/dotfiles/.secrets` — MEDIUM as pattern validation, not spec.
- Pure MPC `Checked-In Secret Exposure` (2024) — 73.6% dotfiles leak API keys — academic scan, cross-checks `MISTRAL_API_KEY` committed finding.

---
*Research completed: 2026-09-10*
*Ready for roadmap: yes*
