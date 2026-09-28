# Phase 1: Universal Installer + Platform Foundations - Context

**Gathered:** 2026-09-10
**Status:** Ready for planning

## Phase Boundary

A fresh clone can run `bash setup.sh` on Arch, Debian-family, or Termux and get a correct deployment with no manual `stow` and no preinstalled Zsh. Phase 1 delivers the universal Bash entry-point (strict mode + arg parsing), Termux-aware distro/deps resolution with a verify → install → re-verify lock, and Stow orchestration (dry-run + package checklist before any write + post-verify). Privileged keyd safety, `--uninstall`, Hyprland server guard, and Zsh provisioning docs are Phase 2; shell/theme/local polish is Phase 3; Mason auto-install, which-key, and self-test gates are Phase 4.

## Implementation Decisions

### Installer entry + old scripts migration
- **D-01:** Canonical entry is `setup.sh` (not `install.sh`). ROADMAP + success criteria already name `bash setup.sh`; PROJECT.md's `install.sh` alternative is rejected. — **Reversibility:** costly — ROADMAP success criteria, REQUIREMENTS traceability, README/docs, and user muscle memory all name `setup.sh`; renaming touches every reference.
- **D-02:** Staged delete of legacy bootstrappers in Phase 1: delete `setup.nu` + `setup.zsh` now; keep `teardown.nu` + `teardown.zsh` until Phase 2 ships `bash setup.sh --uninstall`, then delete them.
- **D-03:** No compatibility shims. Deleted scripts are gone outright (recoverable via git history), not thin wrappers.
- **D-04:** Atomic docs fix inside the Phase 1 deletion commit: every README, `nvim/README.md`, and in-code comment reference to the deleted scripts is updated in the same commit — no dangling pointers left for Phase 2's DOCS-01 rewrite to clean up later.

### Invocation + missing-flag behavior
- **D-05:** Bare `bash setup.sh` on a TTY starts the interactive flow (mode → shell → checklist). No-arg never just prints usage when a terminal is present.
- **D-06:** No TTY (piped/CI) without a complete flag set aborts with usage + non-zero exit and performs zero writes. No silent default run in automation.
- **D-07:** Partial flags: given flags stand, missing ones prompt on TTY or abort with usage when no TTY. Missing `--shell` never silently defaults; missing `--mode` never silently defaults.
- **D-08:** `--help` wins wherever it appears: prints usage, changes nothing, exits 0. Unknown flags abort with usage + non-zero exit before any prompt or write. Parsing must hold under `set -Eeuo pipefail` with `${1-}`-style guards (no `unbound variable` crash).

### Package checklist shape + preselection
- **D-09:** Checklist lists all 7 packages individually toggleable (`nvim`, `zsh`, `nushell`, `alacritty`, `starship`, `wofi`, `keyd`). No core-locked tier — maximum user override, per the user's manual select/deselect requirement. Checklist backend ladder stays `gum → whiptail → dialog → fzf → read` (already locked by ROADMAP).
- **D-10:** `server` mode pre-unchecks GUI packages (`hyprland`-adjacent extras, `alacritty`, `wofi`, `waybar`-family) but the user can re-check any of them before any write happens.
- **D-11:** Shell choice pre-checks only the chosen shell (`--shell zsh` checks `zsh`, unchecks `nushell` and vice versa). User can override to both or neither in the checklist.
- **D-12:** Termux shows `keyd`/`hyprland`/`wofi` as visible-but-disabled entries with a reason note (user explicitly overrode the hide+note recommendation). They can never be selected on Termux; `nvim`/`zsh`/`starship` remain selectable and link correctly.

### Conflict policy + verification strictness
- **D-13:** Existing non-symlink targets are quarantined, never overwritten in place and never cause a bare abort: moved to a repo-root gitignored `.stow-conflicts/<timestamp>/` directory preserving relative paths (user verbatim: "create a gitignored conflicts directory and move all the conflicting folders in a separate timestamped folder", location: repo root).
- **D-14:** Quarantine writes a `MANIFEST` mapping original path → quarantined path and prints the restore procedure. `.gitignore` gains the `.stow-conflicts/` entry in Phase 1.
- **D-15:** `stow < 2.4.1` is auto-upgraded via the platform package manager (`pacman -S --needed` / `apt install -y` / `pkg install`) as part of the deps lock. Current host has stow 2.3.1, so this path will execute on real machines; abort-until-2.4.1 and warn-and-continue were both rejected.
- **D-16:** Post-stow verification is strict: `test -L` + `readlink -f` over the linked set (including `~/.config/nvim` and `~/.config/starship.toml` folding) must all pass or the run aborts with an exact link → expected-target report. Warn-and-pass was rejected — no silent half-linked state.

### the agent's Discretion
None — every presented option was decided by the user (no "You decide" selections).

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + requirements (locked scope)
- `.planning/ROADMAP.md` Phase 1 section — goal, 5 success criteria, and the two-plan split (01-01 distro/deps resolver, 01-02 stow orchestration + checklist ladder) that bound this phase.
- `.planning/REQUIREMENTS.md` §§ Installer (INST-01, INST-02, INST-04, INST-05), Distro & Dependencies (DEPS-01, DEPS-02, DEPS-03), Stow (STOW-01) — the 8 Phase 1 requirements; Out-of-Scope table (no custom `ln -sf` engine, no blind `--adopt`, no TUI frameworks) constrains the solution space.
- `.planning/PROJECT.md` — Core Value, Constraints (Bash, Zsh-default, `ID_LIKE` + manager probing, reversibility, safety), and Key Decisions table (mode → shell → checklist flow).

### Existing implementation to port (logic source, not to preserve)
- `setup.zsh` — `get_distro`, `get_deps`, `verify_command`, `install_deps`, `run_stow`, `get_mode_interactive`, `DRY_RUN` guards; the closest syntactic donor for `setup.sh` (Bash-family).
- `setup.nu` — `get-distro`, `get-deps`, `verify-deps`, `install-deps`, `run-stow`; second logic source, esp. where Zsh path drifted (core `[nvim,nushell,starship]` vs Zsh `[nvim,zsh]`).
- `teardown.zsh` + `teardown.nu` — `read REPLY` / `Type 'yes'` confirmation pattern; kept until Phase 2, reference for the future `--uninstall` guard (`yes` + `--yes` bypass).
- `README.md` — current manual `stow --restow` sections and shell-path table; all references to deleted scripts must be fixed atomically (D-04).

### Codebase maps (scouted 2026-09-10)
- `.planning/codebase/CONCERNS.md` — mirrored-bootstrapper drift, distro-coupling (`manjaro`/`endeavouros` rejection), no-lock system installs, stow folding fragility (`starship.toml`), and test gaps (bootstrapper matrix, symlink correctness) this phase directly answers.
- `.planning/codebase/ARCHITECTURE.md` — Stow data-flow (`get-distro → get-deps → verify → install → run-stow`), stow-package bounded contexts, `keyd -t /` privilege note.
- `.planning/codebase/STACK.md` — core dep set (`stow`, `neovim`, `starship`, `git`, `zoxide`, `uv`, `ripgrep`, `node`/`npm`) + GUI extras, `make`+`gcc` toolchain requirement, `stow ≥2.4.1` expectation vs installed 2.3.1.

## Existing Code Insights

### Reusable Assets
- `setup.zsh:get_distro` + `setup.nu:get-distro` (`/etc/os-release` ID parsing): port and generalize to probe `command -v pacman` / `apt` / `pkg` first, then space-split `ID_LIKE`, then `ID` (covers `ID=termux`, `manjaro`, `endeavouros`, `garuda`, `mint`, `pop`).
- `setup.zsh:get_deps` + `setup.nu:get-deps` (common vs GUI dep tables): merge into one `arch` / `debian` / `termux` family table; `common` must include `make`+`gcc`+`fzf`+`zsh`; `termux` list uses `pkg` names, no `sudo`, no `keyd`.
- `verify-deps` missing-collection pattern (`verify_command || missing+=`): keep, but partition output into `core_missing` vs `gui_missing` and re-run after install, aborting with `Still missing` on residue (idempotent second run = no-op via `pacman -S --needed` / `apt install -y` / `pkg install`).
- `run_stow` mode → module mapping + `stow --restow` + `stow --no --verbose` dry-run preview (`[DRY RUN] Would run:`): keep, switching to `stow --dir="$SCRIPT_DIR"` with repo-root guard (`[[ -f ./setup.sh ]]` else abort).
- `teardown` typed-`yes` confirmation: reference pattern for Phase 2 `--uninstall`; not implemented in Phase 1 beyond staged-delete awareness.

### Established Patterns
- `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards: mandatory in `setup.sh` so `--help` / missing-arg / no-TTY paths never crash with `unbound variable`.
- `DRY_RUN` early-return before every filesystem mutation, including package installs, `chsh`-adjacent steps (none in Phase 1), and privileged paths (none in Phase 1).
- Starship folding (`starship/.config/starship.toml` → `~/.config/starship.toml`) only resolves from repo root — the outside-repo-root abort exists because of this.

### Integration Points
- `stow --dir="$SCRIPT_DIR"` + `test -L` + `readlink -f` post-verify over `~/.config/nvim`, `~/.config/starship.toml` (folding), shell configs; quarantine hook (D-13) fires before any `stow --restow` on collision.
- Platform package managers: `pacman -S --needed` / `apt install -y` / `pkg install` (Termux, no `sudo`); `stow` self-upgrade flows through the same lock.
- Interactive ladder `gum → whiptail → dialog → fzf → read` for mode/shell/checklist prompts; `--dry-run` prints `stow --no --verbose` output for the exact post-checklist selection.

## Specific Ideas

- Quarantine (user verbatim): "create a gitignored conflicts directory and move all the conflicting folders in a separate timestamped folder" — location pinned to repo root in follow-up (`.stow-conflicts/<timestamp>/` + `MANIFEST` + restore hint, D-13/D-14).
- Termux checklist (user override): show `keyd`/`hyprland`/`wofi` as disabled with reason text rather than hiding them.
- Staged delete (user refinement of "delete outright"): setups go in Phase 1, teardowns survive until Phase 2 `--uninstall` lands.
- No other "like X" references — no TUI frameworks, no custom symlink engine, no chezmoi/yadm (all rejected in REQUIREMENTS Out of Scope).

## Deferred Ideas

None — discussion stayed within phase scope. (`--uninstall` reversibility, keyd `--adopt` gate, Hyprland server guard belong to Phase 2 by roadmap, not raised as new asks; backup/snapshot restore `AUTO-01` stays v2.)

---

*Phase: 1-Universal Installer + Platform Foundations*
*Context gathered: 2026-09-10*
