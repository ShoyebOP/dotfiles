# Phase 02: Safe, Reversible & Server-Safe Deployment - Pattern Map

**Mapped:** 2026-09-12
**Files analyzed:** 8 (4 modified, 1 header-edit, 2 deleted, 1 conditional)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `setup.sh` (MODIFY — add `--uninstall`/`--remove` + keyd privileged gate + `chsh` offer + system-deps removal offer) | utility (installer entry-point) | batch + file-I/O + request-response | `teardown.zsh` + `teardown.nu` (uninstall verb), `setup.sh` itself (DRY_RUN/quarantine/post-verify/stow ladder) | exact (self-extension) |
| `zsh/.zprofile` (MODIFY — delete Hyprland `exec start-hyprland` block) | config (shell login profile) | event-driven (login-shell source) | `zsh/.zprofile` itself (4 lines) | exact |
| `README.md` (MODIFY — flip to `Default: Zsh | Backup: Nushell`, keyd least-privilege sudoers, staged teardown mentions) | config (docs) | transform | `README.md` itself | exact |
| `AGENTS.md` (MODIFY — if shell-guidance comments exist, flip to Zsh canonical) | config (docs) | transform | `AGENTS.md` itself | exact |
| `zsh/.zshrc` (MODIFY — header/inline comments reflect Zsh default; leave self-clone untouched) | config (shell runtime) | event-driven | `zsh/.zshrc` itself (lines 1-6, 134-164) | exact |
| `teardown.zsh` (DELETE — staged after `--uninstall` ships) | utility (teardown) | batch + file-I/O | self | exact |
| `teardown.nu` (DELETE — staged after `--uninstall` ships) | utility (teardown) | batch + file-I/O | self | exact |
| `nvim/.config/nvim/README.md` (CONDITIONAL — only if reappears; audit in same commit) | config (docs) | transform | itself (absent pre-Phase-2, Phase 1 verified no-op) | exact |

Reference-only (KEEP, not modified — cited for diff target):
`keyd/etc/keyd/default.conf` (privileged target `→ /etc/keyd/default.conf`, 6 lines), `setup.sh` `ALL_PACKAGES`/`ALL_TOOLCHAIN` constants.

## Pattern Assignments

### `setup.sh` (MODIFY — utility, batch + file-I/O + request-response)

Phase 2 extends the Phase-1-locked `setup.sh` spine (1162 lines). Every new flag/mutation must reuse the locked patterns verbatim: strict header, `${1-}` guards, `--help` wins, `DRY_RUN` early-return before every mutation, outside-repo-root guard, `detect_family` 4-tier, `verify→install→re-verify` lock, and `gum→whiptail→dialog→fzf→read` ladder shape.

**Analog for uninstall verb:** `teardown.zsh` + `teardown.nu`; **Analog for DRY_RUN/quarantine/stow/preview:** `setup.sh` itself.

**Strict-mode header + globals pattern** (`setup.sh` lines 1-14):
```bash
#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
MODE=""
SHELL_CHOICE=""
YES=false
FAMILY=""
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"
```
Copy: `#!/usr/bin/env bash` + `BASH_VERSION` guard + `set -Eeuo pipefail` + `shopt -s inherit_errexit` at lines 1-4 before any variable. Add `UNINSTALL=false` alongside `DRY_RUN`/`YES` (UPPER_SNAKE, `false` default). All expansions must use `${1-}`/`${2-}` guards under `set -u`.

**Arg-parsing `--help` wins + `${1-}` guard pattern** (`setup.sh` lines 50-137):
```bash
parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                usage
                exit 0
                ;;
        esac
    done
    while [[ $# -gt 0 ]]; do
        case "${1-}" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes)
                YES=true
                shift
                ;;
            --uninstall|--remove)
                echo "Note: uninstall/remove is deferred to Phase 2." >&2
                echo "Use teardown scripts for now:" >&2
                echo "  bash teardown.zsh --help  or  nu teardown.nu --help" >&2
                exit 0
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            --*)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}
```
Copy: `for arg in "$@"; do case "$arg" in --help)` **must stay before** the `while` so `--help` wins anywhere. Inside `while`, every `case` uses `${1-}` and every arg consumption validates `[[ $# -lt 2 ]]` before reading `${2-}`. Phase 2 fix: replace the deferred `--uninstall|--remove` branch (lines 106-111) with `UNINSTALL=true; shift` and capture `--remove` as alias. Keep `--help` exit 0 branch after. `--yes` and `--dry-run` stay boolean. The `usage()` heredoc (lines 26-48) must add ` --uninstall, --remove` to OPTIONS and update examples to `bash setup.sh --mode local --dry-run`.

**Outside-repo-root guard pattern** (`setup.sh` lines 1036-1045):
```bash
main() {
    parse_args "$@"
    if [[ ! -f "$SCRIPT_DIR/setup.sh" ]]; then echo "Error: run from the dotfiles repo root (setup.sh not found in $SCRIPT_DIR)." >&2; exit 1; fi
    if [[ ! -f ./setup.sh ]]; then
        echo "Error: setup.sh must be run from the dotfiles repo root." >&2
        echo "This installer uses stow --dir=\"\$SCRIPT_DIR\" and expects to be run from the clone root." >&2
        echo "Please cd to the dotfiles clone and run: bash setup.sh [OPTIONS]" >&2
        echo "Current directory: $PWD (./setup.sh not found) — run-from-clone required." >&2
        exit 1
    fi
```
Copy: `parse_args "$@"` **must be first** in `main` — so `--help` never triggers the `unbound variable` guard. Keep both `SCRIPT_DIR/setup.sh` and `./setup.sh` checks before any prompt or write. `UNINSTALL` path reuses this guard verbatim.

**DRY_RUN early-return before every mutation pattern** (`setup.sh` lines 260-314 + 385-391 + 1132-1140):
```bash
# install_deps (lines 273-301):
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would run: sudo pacman -Sy"
            else
                if ! sudo pacman -Sy; then echo "Warning: pacman -Sy failed, continuing" >&2; fi
            fi
    # ...
    if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"; return 0; fi

# preview_selection (lines 380-391):
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then echo "[DRY RUN] Would skip keyd — privileged install lands in Phase 2 (no /etc writes in Phase 1)"; continue; fi
        echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if command -v stow >/dev/null 2>&1; then echo "[DRY RUN] stow --no --verbose preview for $pkg:"; stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
        else echo "  (stow not found — would install via package manager first)"; fi
    done

# DRY_RUN fast-path in main (lines 1113-1140):
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "=== Preview ==="
        # ...
        preview_selection
        echo ""
        echo "DRY RUN complete — no writes performed."
        return 0
    fi
```
Copy: banner `=== DRY RUN MODE: No changes will be applied ===` at startup (line 1059) prints once; every mutating function re-guards with `if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ..."; return 0; fi` **before** any `pacman`/`apt`/`pkg`/`stow`/`sudo stow`/`rm -rf`/`chsh`/`keyd reload`. Privileged dry-runs use `stow --no --verbose` (or `sudo stow --no --verbose -t / --delete` for uninstall) piped to `sed 's/^/  /' || true` so `diff` exit 1 never kills `set -e`.

**Typed `yes` guard pattern (donor for uninstall + privileged keyd)** (`teardown.zsh` lines 161-169; `teardown.nu` lines 32-41):
```zsh
# teardown.zsh:161-169
    read "REPLY?Are you sure you want to continue? Type 'yes' to confirm: "
    if [[ "$REPLY" != "yes" ]]; then
        echo "Teardown cancelled."
        exit 0
    fi
```
```nu
# teardown.nu:32-41
    let confirm = if $dry_run {
        "n"
    } else {
        input "Are you sure you want to continue? Type 'yes' to confirm: "
    }

    if ($confirm != "yes") {
        print "Teardown cancelled."
        exit 0
    }
```
Copy: exact case-sensitive `yes` (never `y`/`Y`/`YES`), prompt wording `Type 'yes' to confirm:` per CONTEXT D-03/D-08. Bash port for `setup.sh`:
```bash
local reply
printf "Type 'yes' to confirm: " >&2
if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
if [[ "$reply" != "yes" ]]; then echo "Uninstall cancelled (expected 'yes')." >&2; return 1; fi
```
Add `--yes` CI bypass: `if [[ "$YES" == true ]]; then confirmed=true; else <ladder>; fi` per D-03. `--dry-run --uninstall` must NOT prompt — print `[DRY RUN] Would run: stow --dir="$SCRIPT_DIR" --target="$HOME" --delete ...` + `sudo stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd` preview then `return 0` before the guard. `chsh` offer (D-13) explicitly does NOT honor `--yes` — still requires `Type 'yes'`.

**Stow deploy + preview + post-verify pattern** (`setup.sh` lines 380-391 + 442-482 + 562-773):
```bash
# run_stow (lines 475-482):
run_stow() {
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then echo "Notice: keyd privileged install lands in Phase 2 — skipping stow for 'keyd' (no /etc writes in Phase 1)." >&2; continue; fi
        echo "Stowing $pkg -> \$HOME via stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if ! stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"; then echo "Error: stow failed for package '$pkg'" >&2; return 1; fi
    done
}

# assert_linked + post_verify (lines 442-473):
assert_linked() {
    local rel="$1"
    local pkg="$2"
    local abs="$HOME/$rel"
    local got=""
    if [[ ! -e "$abs" ]]; then echo "MISSING: $rel (expected from package $pkg) -> $abs does not exist" >&2; echo "  Expected target: $SCRIPT_DIR/$pkg/$rel" >&2; return 1; fi
    if ! got=$(readlink -f "$abs" 2>/dev/null); then echo "UNRESOLVABLE: $rel -> $abs (readlink -f failed)" >&2; return 1; fi
    case "$got" in
        "$SCRIPT_DIR/$pkg/"*|"$SCRIPT_DIR/$pkg") echo "ok: $rel -> $got"; return 0 ;;
        *) echo "MISMATCH: $rel -> $got (expected under $SCRIPT_DIR/$pkg/)" >&2; echo "  Link: $abs -> $got" >&2; echo "  Expected target prefix: $SCRIPT_DIR/$pkg/" >&2; return 1 ;;
    esac
}
```
Copy: `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"` (never CWD-relative, never bare `stow --restow`), `stow --no --verbose` for preview, `assert_linked` folding-aware `readlink -f` prefix check for post-verify. Uninstall inversions: `stow --dir="$SCRIPT_DIR" --target="$HOME" -D "$pkg"` + `sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd` (only if `SELECTED_PACKAGES` contains `keyd`). Idempotence: `stow -D` is safe even if already unstowed but warn if nothing to remove (`|| echo "Warning: stow -D $pkg returned non-zero (already unstowed or not owned — continuing)" >&2`).

**Privileged keyd safety gate pattern (Phase 2 new — donors are `preview_selection` + `teardown` + RESEARCH)** (`setup.sh` lines 385/404/460/478 notices + `teardown.zsh` lines 86-101 privileged block):
```zsh
# teardown.zsh:86-101 privileged unstow:
        if [[ "$do_keyd" == "true" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo " - [DRY RUN] sudo stow -D -t / keyd"
            else
                sudo stow -D -t / keyd
                echo "keyd unstowed."
            fi
        fi
```
```bash
# setup.sh:380-391 preview shape to reuse for privileged preview:
        if command -v stow >/dev/null 2>&1; then echo "[DRY RUN] stow --no --verbose preview for $pkg:"; stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
```
Phase 2 privileged install must (D-06..D-09):
```bash
# Every keyd install shows preview before any /etc write:
echo ""
echo "=== Privileged keyd preview (no writes) ==="
echo "[PREVIEW] stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose keyd"
stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd 2>&1 | sed 's/^/  /' || true

local host_conf="/etc/keyd/default.conf"
local repo_conf="$SCRIPT_DIR/keyd/etc/keyd/default.conf"
local has_regular_conflict=false
if [[ -f "$host_conf" ]] && [[ ! -L "$host_conf" ]]; then
    has_regular_conflict=true
    echo ""
    echo "Conflict: $host_conf exists as a regular file (not a symlink) — showing diff:"
    diff -u "$host_conf" "$repo_conf" 2>&1 | sed 's/^/  /' || true
    # diff exits 1 when files differ — || true so strict mode doesn't abort
fi

# DRY_RUN prints [DRY RUN] Would run: sudo stow ... + diff preview + [DRY RUN] Would run: sudo keyd reload then return 0
# Confirmation ladder: gum confirm primary → Type 'yes' fallback (never y/n); --yes bypasses for CI per D-08
# Adopt only when has_regular_conflict==true AND explicit adopt confirmation (gum confirm adopt / Type 'adopt'); never force --adopt
# Success: sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true  (never kills session)
```
Copy `diff -u` unified preview only when host file is a regular file (not symlink) per D-06. `--adopt` path uses `sudo stow --dir="$SCRIPT_DIR" --target=/ --adopt keyd` only on explicit adopt confirm; otherwise plain `sudo stow --dir="$SCRIPT_DIR" --target=/ keyd` per D-07. Document least-privilege sudoers in README per D-09 (see README assignment).

**Quarantine immutability pattern** (`setup.sh` lines 393-440 + `.gitignore` line 14):
```bash
# quarantine_scan (lines 393-440):
    local ts
    if ! ts=$(date +%Y%m%d-%H%M%S-%N 2>/dev/null | cut -c1-19 2>/dev/null); then
        if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then ts="$(date +%s)"; fi
        ts="${ts}-$$"
    fi
    local qdir="$SCRIPT_DIR/.stow-conflicts/$ts"
    local manifest="$qdir/MANIFEST"
    # mv to .stow-conflicts/<ts>/ preserving relative paths + MANIFEST + restore hint
```
```gitignore
# .gitignore:14
.stow-conflicts/
```
Copy: quarantine uses `mv` only (never `rm -rf`, never `--adopt` unless confirmed), timestamped `.stow-conflicts/<ts>/` with `MANIFEST`, gitignored, never auto-deleted on uninstall per D-04. Uninstall `stow -D` needs no quarantine — just warn on missing target.

**Anti-patterns that must NOT be copied into `setup.sh` uninstall:**

- `teardown.zsh:137-152` / `teardown.nu:141-155` destructive `rm -rf "$stow_dir"` / `rm -rf $stow_dir` — D-01 forbids; uninstall uses only `stow -D` + Mason `rm -rf ~/.local/share/nvim/mason` when nvim deselected (below). Never `rm -rf ./nvim` etc.
- `setup.sh:385,404,460,478` Phase-1 `keyd` skip notices — replace with the full privileged gate above; do not leave `// Phase 2 — no /etc writes in Phase 1` stubs.
- `teardown.zsh:71-120` `core_modules=(nvim zsh)` + `gui_modules=(hyprland ...)` hard-coded mode split — `setup.sh` uses `SELECTED_PACKAGES` from the 7-package checklist (already `strip_termux_disabled` filtered); uninstall iterates `SELECTED_PACKAGES`, not a mode boolean.
- `setup.nu:149-152` `rm -rf` on stow dirs — same ban as above.

**Uninstall orchestration shape for `setup.sh` (compose from donors + RESEARCH Pattern 1/2):**
```bash
run_uninstall() {
    # DRY_RUN preview: stow --no --verbose -D for each SELECTED_PACKAGES (skip keyd in home loop, preview keyd separately with --target=/), then if DRY_RUN==true return 0
    # Typed yes gate: gum confirm → Type 'yes' fallback (case-sensitive), --yes bypass for CI per D-03
    # Idempotent unstow: for pkg in SELECTED_PACKAGES (skip keyd) { if [[ ! -d "$SCRIPT_DIR/$pkg" ]]; then warn skip; continue; fi; stow --dir="$SCRIPT_DIR" --target="$HOME" -D "$pkg" 2>&1 || warn; }
    # Privileged unstow: if keyd selected { sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd 2>&1 || warn; sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true; }
    # Mason cleanup only when nvim not selected (D-02): if ! printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then if [[ -d "$HOME/.local/share/nvim/mason" ]]; then echo "Removing Mason artefacts: ~/.local/share/nvim/mason (nvim deselected)"; if DRY_RUN then echo "[DRY RUN] Would run: rm -rf ~/.local/share/nvim/mason"; else rm -rf "$HOME/.local/share/nvim/mason"; rmdir "$HOME/.local/share/nvim" 2>/dev/null || true; fi; fi; fi
    # Legacy mode file (D-04): rm -f "$HOME/.config/dotfiles/mode" 2>/dev/null || true; rm -f "$SCRIPT_DIR/.dotfiles-mode" 2>/dev/null || true
    # System deps offer (D-05): offer_system_package_removal (same yes gate, DRY_RUN preview [DRY RUN] Would run: sudo pacman -Rns ... / sudo apt remove -y ... / pkg uninstall ..., never auto-remove)
    # Leave .stow-conflicts/<ts>/ intact — never delete
}
```

**Deps table + Termux guard for system-deps removal offer** (`setup.sh` lines 177-242 + 260-314):
```bash
# get_deps families arch/debian/termux (lines 177-221):
get_deps() {
    local family="${1-}"
    local mode="${2-}"
    local -a common=()
    local -a gui=()
    case "$family" in
        arch)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy)
            ;;
        debian)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=(alacritty wofi waybar grim slurp wl-copy)
            ;;
        termux)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=()
            ;;
    esac
    # filter via ALL_TOOLCHAIN / SELECTED_DEPS toggle
}

# install_deps per-family (lines 260-271):
    case "$family" in
        arch) install_cmd=(sudo pacman -S --needed --noconfirm) ;;
        debian) install_cmd=(sudo apt install -y) ;;
        termux) install_cmd=(pkg install -y) ;;
    esac
```
Uninstall offer reuses `get_deps` + `filter_deps_by_selection` to list `SELECTED_DEPS`/`toolchain` candidates, then offers `pacman -Rns` / `apt remove -y` / `pkg uninstall` (no sudo on Termux) only after the same typed `yes` guard per D-05. Preview with `[DRY RUN] Would run: sudo pacman -Rns ...` etc.

**Checklist ladder reusables for confirmation UX** (`setup.sh` lines 486-773 + 803-1034):
```bash
# checklist_gum pattern (lines 486-533):
    if ! command -v gum >/dev/null 2>&1; then return 1; fi
    out=$(printf '%s\n' "${items[@]}" | gum choose --no-limit --header "Toggle packages (Space to select, Enter to confirm):" 2>&1) || gum_status=$?
    if [[ $gum_status -ne 0 ]]; then echo "Checklist cancelled (gum)." >&2; return 2; fi

# cancel never cascades (lines 754-773):
    if checklist_gum; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if checklist_whiptail; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
```
Reuse the `gum confirm` → fallback shape for both uninstall and privileged keyd confirmations per D-03/D-08. Termux disabled-row emulation and `_toolchain_ensure_stow` (lines 779-801) stay untouched.

**`chsh` end-of-run offer pattern (no prior analog — per RESEARCH Pattern 4 + CONTEXT D-13):**
```bash
# Offer only after quarantine_scan + run_stow + post_verify succeed (or after run_uninstall on uninstall path — chsh is install-only)
offer_chsh() {
    local zsh_path
    if ! zsh_path=$(command -v zsh 2>/dev/null); then echo "Warning: zsh not found — cannot offer chsh." >&2; return 0; fi
    if [[ -n "${SHELL-}" ]] && [[ "$zsh_path" == "$SHELL" ]]; then echo "Default shell already zsh ($SHELL) — skipping chsh offer."; return 0; fi
    if [[ "${FAMILY:-}" == "termux" ]]; then echo "Termux detected — chsh not applicable; skipping default shell change."; return 0; fi
    if ! command -v chsh >/dev/null 2>&1; then echo "chsh not found — skipping. Run manually: chsh -s $zsh_path" >&2; return 0; fi
    if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: chsh -s $zsh_path"; return 0; fi
    # --yes does NOT bypass per D-13 — still require explicit yes
    local reply
    printf "Change default shell to zsh? Type 'yes' to run chsh -s %s: " "$zsh_path" >&2
    if ! read -r reply; then echo "Error: failed to read input" >&2; return 1; fi
    if [[ "$reply" != "yes" ]]; then echo "Skipping chsh (expected 'yes'). Manually run: chsh -s $zsh_path" >&2; return 0; fi
    if ! chsh -s "$zsh_path"; then echo "Warning: chsh failed (check /etc/shells contains $zsh_path, or use sudo chsh)." >&2; return 1; fi
    echo "Default shell changed to $zsh_path — relogin to take effect."
}
```
Installer patch point: insert `offer_chsh || true` after `post_verify` success, before final `echo "Setup complete. Deployed: ${SELECTED_PACKAGES[*]}"` (line 1159). `--yes` never auto-runs `chsh`.

---

### `zsh/.zprofile` (MODIFY — config, event-driven)

**Analog:** `zsh/.zprofile` itself (4 lines).

**Current content to delete** (`zsh/.zprofile` lines 1-4):
```zsh
# Auto-start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec start-hyprland
fi
```
Copy: delete the entire conditional `exec start-hyprland` block per CONTEXT D-10 — no guard, no `command -v Hyprland`, no `|| true`, no persisted mode file. The fix is deletion, not branching. Result: file becomes empty or contains only a comment:
```zsh
# zsh/.zprofile — no Hyprland autostart (removed Phase 2, D-10)
# Zsh login profile — intentionally empty; Hyprland is launched manually via display manager or `Hyprland` command.
```
Reversible via git history (`git restore zsh/.zprofile`). Installer must NOT contain any `mkdir -p ~/.config/dotfiles; echo "$MODE" > ~/.config/dotfiles/mode` or `if [[ -f ~/.config/dotfiles/mode ]]` branches per D-11. On uninstall, optionally `rm -f "$HOME/.config/dotfiles/mode" 2>/dev/null || true` and `rm -f "$SCRIPT_DIR/.dotfiles-mode" 2>/dev/null || true` for legacy cleanup (no error if absent), per D-04.

---

### `zsh/.zshrc` (MODIFY — config, event-driven)

**Analog:** `zsh/.zshrc` itself (391 lines).

**Header to update** (`zsh/.zshrc` lines 1-6):
```zsh
#!/usr/bin/env zsh

# =============================================================================
# ZSH Configuration File (.zshrc)
# A modern, clean setup with Zinit plugin manager and Powerlevel10k theme
# =============================================================================
```
Edit target per D-14: clarify Zsh as default, e.g. `# ZSH Configuration File (.zshrc) — default shell, Nushell is backup`. No functional change to the bootstrap below.

**Zinit self-clone to leave untouched** (`zsh/.zshrc` lines 134-164):
```zsh
# -----------------------------------------------------------------------------
# ZINIT PLUGIN MANAGER INSTALLATION
# -----------------------------------------------------------------------------
# Auto-install Zinit if not present
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    # Only show output if not using instant prompt
    if [[ -z "$P9K_INSTANT_PROMPT" ]]; then
        print -P "%F{33}Installing %F{220}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager...%f"

        # Create directory structure
        if command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"; then
            # Try to clone the repository
            if command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"; then
                print -P "%F{33}Installation successful.%f"
            else
                print -P "%F{160}Git clone failed. Please check your internet connection and try again.%f"
                return 1
            fi
        else
            print -P "%F{160}Failed to create zinit directory.%f"
            return 1
        fi
    else
        # Silent installation during instant prompt
        command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
        command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" >/dev/null 2>&1
    fi
fi

# Load Zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
```
Do NOT modify, do NOT add commit pinning, do NOT move cloning into `setup.sh` per D-12. Installer comment where Zinit would have been cloned must say `Zinit self-clones on first zsh launch via zsh/.zshrc:138-164 — no installer pin per D-12.` The installer only ensures `zsh` binary present via `common` deps (already `setup.sh:183-184` + `ALL_TOOLCHAIN` includes `zsh`) before `stow --restow zsh`.

**Tool wiring stays:** `zoxide init zsh` (line 53), `bindkey '^R'` FZF wiring (lines 269-303 — Phase 3 owns conflict fix, not Phase 2), `typeset -gAH ZINIT` (lines 183-194).

---

### `README.md` (MODIFY — config/docs, transform)

**Analog:** `README.md` itself (156 lines).

**Shell-path table pattern** (`README.md` lines 7-18):
```markdown
Choose your shell path (unified Bash installer handles both):

| Feature | Zsh (Default) | Nushell (Backup) |
|---------|-------------|----------|
| Shell | Zsh + Zinit | Nushell |
| Prompt | Powerlevel10k | Starship |
| Setup | `bash setup.sh --shell zsh` | `bash setup.sh --shell nushell` |
| Completion | Generated via `uv generate-shell-completion zsh` | External stub |
| keyd | Yes (Phase 2 privileged) | Yes (Phase 2 privileged) |

**Default: Zsh** | **Backup: Nushell** — the unified Bash installer provisions the chosen shell before stowing configs.
```
Keep the `| Feature | Zsh (Default) | Nushell (Backup) |` pipe-table shape and the `**Default: Zsh** | **Backup: Nushell**` callout. Phase 2 deepens the flip — do NOT delete the Nushell column (keep backup). No wording drift: `Zsh (Default)` / `Nushell (Backup)` casing exactly.

**Unified installer intro + quick-start pattern** (`README.md` lines 22-59):
```markdown
Canonical entry: `bash setup.sh` — replaces the legacy bootstrappers. Works on Arch, Debian-family, and Termux via `ID_LIKE` + `pacman`/`apt`/`pkg` probing. No preinstalled Zsh or Nushell required.

### Quick Start

Clone and run from the clone root:

```bash
git clone <repo> dotfiles && cd dotfiles
bash setup.sh
```

**Options:**

- `--mode local|server` — deployment mode
- `--shell zsh|nushell` — Zsh default, Nushell backup
- `--dry-run` — preview every write (`[DRY RUN] Would run:` + `stow --no --verbose` for the exact post-checklist selection) with zero writes
- `--help, -h` — show usage (wins anywhere, exits 0 before any write)
- `--yes` — reserved for Phase 2 `--uninstall` CI bypass
- `--uninstall, --remove` — deferred to Phase 2; use teardown scripts for now
```
Phase 2 edit target (D-14):
- `--yes` bullet: drop `reserved for Phase 2` qualifier → `--yes` — assume yes for prompts (CI bypass for `--uninstall` and privileged flows)
- `--uninstall, --remove` bullet: rewrite from `deferred to Phase 2; use teardown scripts for now` → `cleanly unstows (`stow -D` + `sudo stow -D -t / keyd` when selected) + removes Mason artefacts when nvim deselected + offers system package removal; typed `yes` required (bypass with --yes).` Keep the `teardown.zsh`/`teardown.nu` fallback mentions only until `bash setup.sh --uninstall` ships (D-15), then delete them and the bullet's fallback in one atomic commit.
- Examples block (lines 45-58): primary example must stay `bash setup.sh --mode local` / `bash setup.sh --mode local --dry-run` and `bash setup.sh --mode server --shell zsh --dry-run` per D-14. Non-interactive one-liner order: `--mode` before `--shell`, `--dry-run` trailing.

**Manual stow pattern** (`README.md` lines 82-99):
```bash
# Core (Zsh default)
stow --dir=. --target="$HOME" --restow nvim zsh starship

# Nushell backup instead of Zsh
stow --dir=. --target="$HOME" --restow nvim nushell starship

# GUI extras (local mode)
stow --dir=. --target="$HOME" --restow alacritty wofi
```
```bash
stow --dir=. --target="$HOME" --restow nvim zsh starship alacritty wofi
```
Keep `stow --dir=. --target="$HOME" --restow` explicit flags (what `setup.sh` does internally per line 479). Core lists `nvim zsh starship` (Zsh-default) vs `nvim nushell starship` (backup) — do not reorder. GUI list `alacritty wofi` (full local is `nvim zsh starship alacritty wofi`).

**keyd section pattern** (`README.md` lines 101-116):
```markdown
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
```
Phase 2 rewrite (D-09): replace `Phase 2 will handle…` future prose with installed behavior: `installer previews with stow --no --verbose -t / keyd + diff -u if /etc/keyd/default.conf is a regular file, requires gum confirm / Type 'yes' before sudo stow --adopt -t / keyd (plain sudo stow --target=/ keyd otherwise), then sudo keyd reload || sudo systemctl reload keyd || true`. Replace sudoers snippet from blanket `systemctl start|stop keyd` to least-privilege per D-09:
```
shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload keyd, /usr/bin/keyd reload
```
Never use `sudo stow --adopt -t / keyd` in docs without the confirmation gate.

**Zinit docs pattern** (`README.md` lines 117-122):
```markdown
#### Zsh Plugin Manager

```bash
# Install Zinit (will be cloned automatically on first shell start via bash setup.sh in Phase 2)
git clone https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git
```
```
Update comment per D-12: `(Zinit clones itself on first zsh launch via zsh/.zshrc — no installer clone, no commit pin)` — keep the `git clone ...` line as manual fallback, not as installer step.

**Footer pattern** (`README.md` lines 154-156):
```markdown
*Managed with Conductor*
*Installer: `bash setup.sh --mode <local|server> --shell <zsh|nushell> [--dry-run]` — Zsh default, Nushell backup*
```
Retain footer one-liner; no extra flags in footer.

---

### `AGENTS.md` (MODIFY — config/docs, transform)

**Analog:** `AGENTS.md` itself (331 lines, GSD project block).

**Project constraints block** (`AGENTS.md` lines 11-19):
```markdown
### Constraints

- **Shell default:** Zsh is default everywhere; Nushell is backup only — update all docs/comments to reflect this — why: user explicitly requested Zsh as canonical
- **Installer language:** Unified installer must be **Bash** — available by default — why: `bash` is preinstalled, avoids requiring Nushell/Zsh to bootstrap themselves
```
If AGENTS.md contains shell-guidance beyond the GSD block (e.g. Nushell vs Zsh default prose), flip it to `Zsh default | Nushell backup` mirroring README D-14. Do NOT edit the `<!-- GSD:project-start source:PROJECT.md -->` wrapper — update only human prose inside. No `package.json`/`Cargo.toml`/`pyproject.toml` admonition at top is docs-only — keep.

---

### `teardown.zsh` + `teardown.nu` (DELETE — utility, batch + file-I/O)

**Analog:** themselves.

**Deletion contract (CONTEXT D-15):** Keep fallback mentions in docs until `bash setup.sh --uninstall` ships, then staged-delete them and atomically fix docs — same pattern as Phase 1 D-02 staged delete (`setup.nu`/`setup.zsh` deleted in Phase 1, `teardown.*` survive until Phase 2). During Phase 2 transition, docs note `Use teardown scripts for now: bash teardown.zsh --help / nu teardown.nu --help` (already in `setup.sh:107-110`); final commit of this phase deletes both files:
```bash
git rm teardown.zsh teardown.nu
# + remove their mentions from README.md's --uninstall bullet and any AGENTS/R&D notes
```
No shims, no wrappers — direct delete, recoverable via git history per Phase 1 D-03.

**Per-file why they are the donor and what NOT to copy:**

- `teardown.zsh:71-120` `run_unstow` hard-codes `core_modules=(nvim zsh)` / `gui_modules=(hyprland ...)` and `delete_stow_directory` does `rm -rf "$stow_dir"` (lines 137-152):
```zsh
delete_stow_directory() {
    local module="$1"
    local stow_dir="$PWD/$module"

    if [[ ! -d "$stow_dir" ]]; then
        echo "   - $module: Stow directory does not exist, skipping"
        return
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "   [DRY RUN] Would delete: $stow_dir"
    else
        rm -rf "$stow_dir"
        echo "   ✓ $module stow directory deleted"
    fi
}
```
Never copy `rm -rf` into `setup.sh --uninstall` per CONTEXT D-01. `setup.sh` must use `stow -D` only.

- `teardown.nu:141-155` same `rm -rf $stow_dir`:
```nu
def delete-stow-directory [module, dry_run] {
    let stow_dir = $"($nu.cwd)/($module)"
    ...
    rm -rf $stow_dir
}
```
Same ban.

---

## Shared Patterns

### Strict mode + Bash shebang
**Source:** `setup.sh` lines 1-6
**Apply to:** `setup.sh` (all new functions)
```bash
#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit
```
Bash-only (`#!/usr/bin/env bash`), never `sh`. Every new function must assume `set -e`/`-u` and quote expansions (`"$var"`), use `${1-}`/`${var:-}` guards, and avoid `local x=$(fallible)` masking (split `local x; x=$(...)`).

### Arg parsing: `--help` wins anywhere
**Source:** `setup.sh` lines 50-59 + 112-115
**Apply to:** `setup.sh` `parse_args` (new `--uninstall`/`--remove` must not break this)
```bash
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                usage
                exit 0
                ;;
        esac
    done
```
Pre-scan before `while`; `--help` exits 0 before any other handling, prompt, or write.

### Outside-repo-root guard + OS_RELEASE_FILE seam
**Source:** `setup.sh` lines 6, 13, 139-175, 1036-1045
**Apply to:** `setup.sh` `main` (both install and uninstall paths)
```bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"
# in detect_family:
    local os_file="${OS_RELEASE_FILE:-/etc/os-release}"
    if [[ -f "$os_file" ]]; then
        id="$(grep -E '^ID=' "$os_file" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")"
```
`SCRIPT_DIR` via `BASH_SOURCE` (never `$PWD`), `OS_RELEASE_FILE` env seam for tests.

### Detect family: Termux → manager → ID_LIKE → ID → manager fallback
**Source:** `setup.sh` lines 139-175
**Apply to:** `setup.sh` `detect_family` (reuse for uninstall system-deps offer)
```bash
detect_family() {
    if [[ -n "${TERMUX_VERSION-}" ]] || [[ "${PREFIX-}" == *"com.termux"* ]]; then
        echo "termux"
        return 0
    fi
    local have_pacman=false
    local have_apt=false
    if command -v pacman >/dev/null 2>&1; then have_pacman=true; fi
    if command -v apt >/dev/null 2>&1; then have_apt=true; fi
    # ... ID_LIKE token loop, then ID, then manager fallback
    if [[ "$have_pacman" == true ]] && [[ "$have_apt" == false ]]; then echo "arch"; return 0; fi
    if [[ "$have_apt" == true ]] && [[ "$have_pacman" == false ]]; then echo "debian"; return 0; fi
}
```
Do NOT hard-code `["arch","cachyos","ubuntu"]` — use `ID_LIKE` space-split tokens + manager probing.

### Deps tables + toolchain filter + per-family install cmds
**Source:** `setup.sh` lines 19-25, 177-242, 260-314
**Apply to:** `setup.sh` uninstall system-deps removal offer (reuse tables, invert to `pacman -Rns`/`apt remove -y`/`pkg uninstall`)
```bash
ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd)
GUI_STOW_PACKAGES=(alacritty wofi keyd)
TERMUX_DISABLED_PACKAGES=(alacritty wofi keyd)
ALL_TOOLCHAIN=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
declare -a SELECTED_PACKAGES=()
declare -a SELECTED_DEPS=()
# get_deps emits per family, then filter_deps_by_selection keeps only toolchain-toggleable
# install path:
        arch) install_cmd=(sudo pacman -S --needed --noconfirm) ;;
        debian) install_cmd=(sudo apt install -y) ;;
        termux) install_cmd=(pkg install -y) ;;
# uninstall offer inverts with same family mapping:
#   arch: sudo pacman -Rns <deps>   debian: sudo apt remove -y <deps>   termux: pkg uninstall <deps>  (no sudo on termux)
```
Reuse `ALL_PACKAGES`/`ALL_TOOLCHAIN`/`SELECTED_*` arrays (never re-declare). `strip_termux_disabled` already exists (lines 365-378) — uninstall filtering reuses it.

### DRY_RUN early-return before every mutation
**Source:** `setup.sh` lines 273-301, 385-391, 1113-1140; `teardown.zsh` lines 95-100, 126-134
**Apply to:** `setup.sh` every new mutation (`stow -D`, `sudo stow -D -t /`, `rm -rf ~/.local/share/nvim/mason`, `pacman -Rns`/`apt remove`, `keyd reload`, `chsh`, legacy `rm -f`)
```bash
    if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ..."; return 0; fi
    echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --delete $pkg"
    stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose --delete "$pkg" 2>&1 | sed 's/^/  /' || true
```
Preview prefix `[DRY RUN] Would run:` verbatim, `stow --no --verbose` for exact selection, `|| true` for `diff` exit 1.

### Five-backend ladder shape + cancel-never-cascades
**Source:** `setup.sh` lines 486-773, 754-773
**Apply to:** `setup.sh` privileged `gum confirm` → `Type 'yes'` ladder (reuse shape, not full checklist)
```bash
    if checklist_gum; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if checklist_whiptail; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
```
New privileged prompts reuse `gum confirm` primary → fallback, return `2` as cancel sentinel, never fall through silently.

### Step logging + quote-to-copy stow commands
**Source:** `setup.sh` lines 379-482, 1055-1060
**Apply to:** `setup.sh` new log lines (`Detected family:`, `Selected mode:`/`shell:`, `Final package selection:`, `Quarantine complete:`)
```bash
    if ! FAMILY=$(detect_family); then exit 1; fi
    echo "Detected family: $FAMILY"
    echo "Selected mode: $MODE"
    if [[ "$DRY_RUN" == true ]]; then echo "=== DRY RUN MODE: No changes will be applied ==="; fi
    echo "Stowing $pkg -> \$HOME via stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
```
Keep `echo` per-step, `--dir="$SCRIPT_DIR" --target="$HOME"` quoted, `stow --no --verbose` preview indented via `sed`.

### Quarantine MANIFEST + never-delete contract
**Source:** `setup.sh` lines 393-440, `.gitignore:14`
**Apply to:** `setup.sh` `quarantine_scan` (leave behavior unchanged; uninstall must never touch `.stow-conflicts/`)
```gitignore
# .gitignore:14
.stow-conflicts/
```
Uninstall prints `Warning:` on missing targets (skip, continue) and never runs `rm -rf` on `.stow-conflicts/`.

### Post-verify folding-aware prefix check
**Source:** `setup.sh` lines 442-473
**Apply to:** `setup.sh` `post_verify` (reuse for re-install path; uninstall skips verification for removed pkgs)
```bash
    if ! got=$(readlink -f "$abs" 2>/dev/null); then echo "UNRESOLVABLE: $rel -> $abs (readlink -f failed)" >&2; return 1; fi
    case "$got" in
        "$SCRIPT_DIR/$pkg/"*|"$SCRIPT_DIR/$pkg") echo "ok: $rel -> $got"; return 0 ;;
        *) echo "MISMATCH: $rel -> $got (expected under $SCRIPT_DIR/$pkg/)" >&2; return 1 ;;
    esac
```

## No Analog Found

| File / Capability | Role | Data Flow | Reason |
|-------------------|------|-----------|--------|
| `setup.sh` privileged `diff -u` + `--adopt` gate + `keyd reload || true` (STOW-02) | utility | batch + file-I/O (privileged `/etc`) | No `/etc` write code exists in Phase 1 `setup.sh` (all keyd paths are `continue` notices at lines 385/404/460/478); the only privileged analog is `teardown.zsh:98` `sudo stow -D -t / keyd` which has no preview/diff/adopt ladder. Planner must use RESEARCH.md Pattern 2 (`stow --no --verbose -t / keyd` + `diff -u` + `gum confirm → Type 'yes'` + `--adopt` only on explicit `adopt` + `sudo keyd reload \|\| sudo systemctl reload keyd \|\| true`). |
| `setup.sh` `offer_chsh` end-of-run gate (SHEL-01) | utility | batch | No `chsh` invocation exists in repo (grep: `chsh` only in `02-CONTEXT.md`/`02-RESEARCH.md`). RESEARCH Pattern 4 is the only source; Phase 1 `setup.sh` has no `which zsh != $SHELL` guard. |
| `setup.sh` system package removal offer (`pacman -Rns`/`apt remove -y`/`pkg uninstall` listing `SELECTED_DEPS`) (INST-03 D-05) | utility | batch (OS package manager) | Install analog `install_deps` exists but no removal listing exists; `get_deps`/`filter_deps_by_selection` must be inverted to offer removal only after same typed `yes`, with `--dry-run` preview `[DRY RUN] Would run: sudo pacman -Rns ...`. |
| `setup.sh` Mason artefact cleanup `rm -rf ~/.local/share/nvim/mason` only when nvim deselected (INST-03 D-02) | utility | file-I/O | No Mason path removal in repo (Mason installs via `nvim --headless -c "MasonInstallAll"` in `nvim/.config/nvim/lua/utils/mason-install-all.lua`; uninstall path is new). |

All other capabilities reuse exact analogs above.

## Metadata

**Analog search scope:** repo root (`setup.sh` 1162 lines, `zsh/.zprofile` 4 lines, `zsh/.zshrc` 391 lines, `README.md` 156 lines, `AGENTS.md` 331 lines, `.gitignore` 15 lines, `keyd/etc/keyd/default.conf` 6 lines, `teardown.zsh` 185 lines, `teardown.nu` 155 lines); grep for `stow`, `gum`, `DRY_RUN`, `inherit_errexit`, `BASH_SOURCE`, `keyd`, `chsh`, `zprofile`.
**Files scanned:** 8 donor/target reads + 2 prior planning reads + 1 discussion log; grep 100+ hits (all `setup.*` refs are docs/planning).
**Pattern extraction date:** 2026-09-12
**Conventions observed:** 4-space indent, `snake_case` funcs / `UPPER_SNAKE` globals, `local var="$1"` quoting, `local -a` arrays + `declare -a`, heredoc `usage()`, `set -Eeuo pipefail` + `shopt -s inherit_errexit`, `${1-}`/`${2:-}` guards, `[DRY RUN] Would run:` prefix, `✓`/`!` per-module status, `stow --dir="$SCRIPT_DIR" --target="$HOME"` always, `readlink -f` folding-aware, `# Section` gitignore headers, pipe-table + `stow --restow` one-liners in README, `prompt_toolchain_checklist` ladder shape.
