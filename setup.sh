#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
MODE=""
SHELL_CHOICE=""
YES=false
FAMILY=""
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"

# Global to capture missing deps from verify_deps
declare -a VERIFY_MISSING=()

# 01-02: stow orchestration constants
ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd)
GUI_STOW_PACKAGES=(alacritty wofi keyd)
TERMUX_DISABLED_PACKAGES=(alacritty wofi keyd)
declare -a SELECTED_PACKAGES=()

usage() {
    local prog
    prog="$(basename -- "${BASH_SOURCE[0]}")"
    cat << EOF
Usage: $prog [OPTIONS]

Unified Dotfiles Installer (Bash) — Zsh default, Nushell backup

OPTIONS:
    --mode MODE         Deployment mode: 'local' (full GUI) or 'server' (headless)
    --shell SHELL       Shell choice: 'zsh' (default) or 'nushell' (backup)
    --dry-run           Show what would be done without making changes
    --yes               Assume yes for prompts (CI bypass, reserved for Phase 2)
    --help, -h          Show this help and exit
    --uninstall, --remove  Deferred: removal via teardown scripts until Phase 2

EXAMPLES:
    $prog --mode local
    $prog --mode server --shell zsh --dry-run
    $prog --help

EOF
}

parse_args() {
    # Help-wins-anywhere (D-08): scan all args first; if --help/-h present, print usage and exit 0 before any other validation or write
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
            --mode)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --mode requires an argument (local|server)" >&2
                    usage >&2
                    exit 1
                fi
                case "${2-}" in
                    local|server)
                        MODE="${2-}"
                        ;;
                    *)
                        echo "Error: --mode must be 'local' or 'server' (got '${2-}')" >&2
                        usage >&2
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --shell)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --shell requires an argument (zsh|nushell)" >&2
                    usage >&2
                    exit 1
                fi
                case "${2-}" in
                    zsh|nushell)
                        SHELL_CHOICE="${2-}"
                        ;;
                    *)
                        echo "Error: --shell must be 'zsh' or 'nushell' (got '${2-}')" >&2
                        usage >&2
                        exit 1
                        ;;
                esac
                shift 2
                ;;
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
            --)
                shift
                break
                ;;
            --*)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
            -*)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
            *)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}

detect_family() {
    # Tier 1 — Termux (env + pkg binary are ground truth; no reliable /etc/os-release)
    if [[ -n "${TERMUX_VERSION-}" ]] || [[ "${PREFIX-}" == *"com.termux"* ]] || command -v pkg >/dev/null 2>&1; then
        echo "termux"
        return 0
    fi

    local have_pacman=false
    local have_apt=false
    if command -v pacman >/dev/null 2>&1; then
        have_pacman=true
    fi
    if command -v apt >/dev/null 2>&1; then
        have_apt=true
    fi

    local id=""
    local id_like=""
    local os_file="${OS_RELEASE_FILE:-/etc/os-release}"
    if [[ -f "$os_file" ]]; then
        # shellcheck disable=SC1091
        if ! . "$os_file" 2>/dev/null; then
            id=""
            id_like=""
        else
            id="${ID:-}"
            id_like="${ID_LIKE:-}"
        fi
    fi

    local cand
    # Intentional word splitting for ID_LIKE (space-separated per os-release(5))
    # shellcheck disable=SC2086
    for cand in $id_like; do
        case "$cand" in
            arch|cachyos|manjaro|endeavouros|garuda)
                echo "arch"
                return 0
                ;;
            debian|ubuntu|linuxmint|mint|pop|elementary)
                echo "debian"
                return 0
                ;;
            termux)
                echo "termux"
                return 0
                ;;
        esac
    done

    case "$id" in
        arch|cachyos|manjaro|endeavouros|garuda)
            echo "arch"
            return 0
            ;;
        debian|ubuntu|linuxmint|mint|pop|elementary)
            echo "debian"
            return 0
            ;;
        termux)
            echo "termux"
            return 0
            ;;
    esac

    if [[ "$have_pacman" == true ]] && [[ "$have_apt" == false ]]; then
        echo "arch"
        return 0
    fi
    if [[ "$have_apt" == true ]] && [[ "$have_pacman" == false ]]; then
        echo "debian"
        return 0
    fi

    echo "Error: Unable to detect supported distribution." >&2
    echo "This installer supports Arch, Debian-family, and Termux." >&2
    echo "Please refer to README.md for manual installation instructions." >&2
    return 1
}

get_deps() {
    local family="${1-}"
    local mode="${2-}"
    local -a common=()
    local -a gui=()

    case "$family" in
        arch)
            # pacman package names; neovim provides nvim, ripgrep provides rg, nodejs provides node
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy)
            ;;
        debian)
            # apt package names; same mapping as arch (neovim, ripgrep, nodejs)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=(alacritty wofi waybar grim slurp wl-copy)
            ;;
        termux)
            # Termux distinct table using pkg names (best-effort per A2/A3)
            # stow: best-effort — name 'stow' assumed in Termux repos (A2)
            # neovim: Termux package 'neovim' provides 'nvim' (best-effort per A3)
            # ripgrep: 'ripgrep' provides 'rg' (best-effort per A3)
            # nodejs: 'nodejs' provides 'node' (best-effort per A3)
            # starship: 'starship' best-effort per A3
            # zoxide: 'zoxide' best-effort per A3
            # uv: 'uv' best-effort per A3 — if missing, per-package graceful message will guide manual retry
            # fzf, git, zsh, make, gcc assumed available as named (best-effort per A3, toolchain for telescope-fzf-native)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            # No GUI packages selectable on Termux (keyd/hyprland/wofi disabled per D-12)
            # Termux branch stays sudo-free with no privileged packages (T-01-04)
            gui=()
            ;;
        *)
            echo "Error: unknown family '$family'" >&2
            return 1
            ;;
    esac

    if [[ "$mode" == "local" ]]; then
        printf '%s\n' "${common[@]}" "${gui[@]}"
    else
        printf '%s\n' "${common[@]}"
    fi
}

verify_command() {
    command -v "${1-}" >/dev/null 2>&1
}

verify_deps() {
    local deps=("$@")
    local -a missing=()
    local -a installed=()

    echo ""
    echo "Verifying dependencies..."
    local dep
    local cmd
    for dep in "${deps[@]}"; do
        case "$dep" in
            neovim) cmd="nvim" ;;
            ripgrep) cmd="rg" ;;
            nodejs) cmd="node" ;;
            *) cmd="$dep" ;;
        esac
        if ! verify_command "$cmd"; then
            missing+=("$dep")
            echo "  - $dep (missing, need '$cmd')"
        else
            installed+=("$dep")
            echo "  + $dep (installed)"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        echo "Missing dependencies: ${missing[*]}"
    else
        echo ""
        echo "All dependencies are satisfied."
    fi

    VERIFY_MISSING=("${missing[@]}")
}

install_deps() {
    local family="${1-}"
    shift || true
    local -a missing=("$@")

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo "All dependencies are satisfied."
        return 0
    fi

    local -a install_cmd=()
    case "$family" in
        arch)
            install_cmd=(sudo pacman -S --needed --noconfirm)
            ;;
        debian)
            install_cmd=(sudo apt install -y)
            ;;
        termux)
            # No sudo on Termux branch (T-01-04 mitigate)
            install_cmd=(pkg install -y)
            ;;
        *)
            echo "Unsupported family for auto-install: $family" >&2
            return 1
            ;;
    esac

    echo ""
    echo "Ready to install: ${missing[*]}"
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"
        return 0
    fi

    echo "Installing via: ${install_cmd[*]} ${missing[*]}"
    if [[ "$family" == "termux" ]]; then
        local pkg
        for pkg in "${missing[@]}"; do
            if ! "${install_cmd[@]}" "$pkg"; then
                echo "Warning: failed to install '$pkg' via '${install_cmd[*]} $pkg'." >&2
                echo "  Try manually: ${install_cmd[*]} $pkg" >&2
                echo "  (Package name may differ in Termux repos — check 'pkg search $pkg')" >&2
            fi
        done
    else
        if ! "${install_cmd[@]}" "${missing[@]}"; then
            echo "Error: package install failed." >&2
            return 1
        fi
    fi
}

reverify_deps() {
    local family="${1-}"
    local mode="${2-}"
    local -a deps=()
    if ! mapfile -t deps < <(get_deps "$family" "$mode"); then
        echo "Error: failed to get deps for re-verify" >&2
        return 1
    fi
    verify_deps "${deps[@]}"
    local -a still_missing=("${VERIFY_MISSING[@]}")
    if [[ ${#still_missing[@]} -gt 0 ]]; then
        echo ""
        echo "Error: Still missing dependencies after install: ${still_missing[*]}" >&2
        echo "Please install manually:" >&2
        case "$family" in
            arch) echo "  sudo pacman -S --needed --noconfirm ${still_missing[*]}" >&2 ;;
            debian) echo "  sudo apt install -y ${still_missing[*]}" >&2 ;;
            termux) echo "  pkg install -y ${still_missing[*]}" >&2 ;;
        esac
        return 1
    fi
    echo "Re-verify passed: all dependencies present."
    return 0
}

prompt_mode() {
    echo "" >&2
    echo "Select Deployment Mode:" >&2
    echo "1. Local Mode (Full GUI: Hyprland, Alacritty, keyd, etc.)" >&2
    echo "2. Server Mode (Headless: Nvim, Zsh, Starship only)" >&2
    local reply
    while true; do
        if ! read -r -p "Enter choice (1 or 2): " reply; then
            echo "Error: failed to read input" >&2
            exit 1
        fi
        case "$reply" in
            1) echo "local"; return 0 ;;
            2) echo "server"; return 0 ;;
            *) echo "Invalid choice. Please enter 1 or 2." >&2 ;;
        esac
    done
}

prompt_shell() {
    echo "" >&2
    echo "Select Shell:" >&2
    echo "1. Zsh (default)" >&2
    echo "2. Nushell (backup)" >&2
    local reply
    while true; do
        if ! read -r -p "Enter choice (1 or 2) [1]: " reply; then
            echo "Error: failed to read input" >&2
            exit 1
        fi
        if [[ -z "$reply" ]]; then
            reply="1"
        fi
        case "$reply" in
            1) echo "zsh"; return 0 ;;
            2) echo "nushell"; return 0 ;;
            *) echo "Invalid choice. Please enter 1 or 2." >&2 ;;
        esac
    done
}

# ──────────────────────────────────────────────
# 01-02: checklist ladder + stow orchestration
# ──────────────────────────────────────────────

strip_termux_disabled() {
    if [[ "${FAMILY:-}" != "termux" ]]; then
        return 0
    fi
    local -a filtered=()
    local pkg
    local is_disabled
    local d
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]]; then
                is_disabled=true
                break
            fi
        done
        if [[ "$is_disabled" == true ]]; then
            echo "Warning: '$pkg' is not available on Termux — skipping." >&2
        else
            filtered+=("$pkg")
        fi
    done
    SELECTED_PACKAGES=("${filtered[@]}")
}

preview_selection() {
    echo ""
    echo "=== DRY RUN: Preview of selected packages ==="
    echo "Selection: ${SELECTED_PACKAGES[*]:-<none>}"
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            echo "[DRY RUN] Would skip keyd — privileged install lands in Phase 2 (no /etc writes in Phase 1)"
            continue
        fi
        echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if command -v stow >/dev/null 2>&1; then
            echo "[DRY RUN] stow --no --verbose preview for $pkg:"
            stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
        else
            echo "  (stow not found — would install via package manager first)"
        fi
    done
    echo "[DRY RUN] No changes made. Re-run without --dry-run to apply."
}

quarantine_scan() {
    local ts
    if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then
        ts="$(date +%s)"
    fi
    local qdir="$SCRIPT_DIR/.stow-conflicts/$ts"
    local manifest="$qdir/MANIFEST"
    local quarantined_count=0
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            continue
        fi
        local pkg_dir="$SCRIPT_DIR/$pkg"
        if [[ ! -d "$pkg_dir" ]]; then
            continue
        fi
        while IFS= read -r -d '' src; do
            local rel="${src#$pkg_dir/}"
            local home_target="$HOME/$rel"
            if [[ ! -e "$home_target" ]]; then
                continue
            fi
            # Check if already correctly linked/folded (canonical resolves under repo pkg)
            local canon=""
            if canon=$(readlink -f "$home_target" 2>/dev/null); then
                if [[ "$canon" == "$pkg_dir/"* ]] || [[ "$canon" == "$pkg_dir" ]]; then
                    continue
                fi
            fi
            # If it's a symlink already pointing elsewhere, still quarantine the symlink itself (mv moves link)
            # For regular files/dirs, move to quarantine preserving relative path
            local q_target="$qdir/$rel"
            if [[ -e "$q_target" ]]; then
                echo "Warning: quarantine target already exists: $q_target — skipping duplicate" >&2
                continue
            fi
            if [[ "$quarantined_count" -eq 0 ]]; then
                mkdir -p "$qdir"
                {
                    echo "# Stow quarantine manifest"
                    echo "# Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "$ts")"
                    echo "# Restore: mv <quarantined-path> <original-path>"
                    echo "# Or: cat $manifest | while read line; do src=\$(echo \"\$line\" | cut -d'>' -f1); dst=\$(echo \"\$line\" | cut -d'>' -f2); mv \"\$dst\" \"\$src\"; done"
                    echo ""
                } > "$manifest"
            fi
            mkdir -p "$(dirname "$q_target")"
            # Use mv to relocate (never rm)
            if mv "$home_target" "$q_target"; then
                echo "$home_target -> $q_target" >> "$manifest"
                echo "Quarantined: $home_target -> $q_target"
                quarantined_count=$((quarantined_count + 1))
            else
                echo "Warning: failed to quarantine $home_target" >&2
            fi
        done < <(find "$pkg_dir" -type f -print0 2>/dev/null || true)
    done
    if [[ "$quarantined_count" -gt 0 ]]; then
        echo ""
        echo "Quarantine complete: $quarantined_count item(s) moved to $qdir"
        echo "Restore with: mv <quarantined-path> <original-path>"
        echo "See manifest: $manifest"
        echo "Manifest contents:"
        cat "$manifest" 2>/dev/null | sed 's/^/  /' || true
    fi
}

assert_linked() {
    local rel="$1"
    local pkg="$2"
    local abs="$HOME/$rel"
    local got=""
    if [[ ! -e "$abs" ]]; then
        echo "MISSING: $rel (expected from package $pkg) -> $abs does not exist" >&2
        echo "  Expected target: $SCRIPT_DIR/$pkg/$rel" >&2
        return 1
    fi
    if ! got=$(readlink -f "$abs" 2>/dev/null); then
        echo "UNRESOLVABLE: $rel -> $abs (readlink -f failed)" >&2
        return 1
    fi
    case "$got" in
        "$SCRIPT_DIR/$pkg/"*|"$SCRIPT_DIR/$pkg")
            echo "ok: $rel -> $got"
            return 0
            ;;
        *)
            echo "MISMATCH: $rel -> $got (expected under $SCRIPT_DIR/$pkg/)" >&2
            echo "  Link: $abs -> $got" >&2
            echo "  Expected target prefix: $SCRIPT_DIR/$pkg/" >&2
            return 1
            ;;
    esac
}

post_verify() {
    echo ""
    echo "Post-verify: checking deployed symlinks..."
    local failed=0
    local total=0
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            continue
        fi
        local pkg_dir="$SCRIPT_DIR/$pkg"
        if [[ ! -d "$pkg_dir" ]]; then
            echo "Warning: package dir not found: $pkg_dir — skipping verify" >&2
            continue
        fi
        while IFS= read -r -d '' src; do
            local rel="${src#$pkg_dir/}"
            total=$((total + 1))
            if ! assert_linked "$rel" "$pkg"; then
                failed=$((failed + 1))
            fi
        done < <(find "$pkg_dir" -type f -print0 2>/dev/null || true)
    done
    if [[ "$total" -eq 0 ]]; then
        echo "Post-verify: no files to verify (empty selection or keyd-only)."
        # Not a failure if selection intentionally empty? But checklist should have at least nvim?
        # Still report ok
        echo "Post-verify passed."
        return 0
    fi
    if [[ "$failed" -gt 0 ]]; then
        echo "Post-verify FAILED: $failed/$total links bad" >&2
        return 1
    fi
    echo "Post-verify passed: all $total links verified"
    return 0
}

run_stow() {
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            echo "Notice: keyd privileged install lands in Phase 2 — skipping stow for 'keyd' (no /etc writes in Phase 1)." >&2
            continue
        fi
        echo "Stowing $pkg -> \$HOME via stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if ! stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"; then
            echo "Error: stow failed for package '$pkg'" >&2
            return 1
        fi
    done
}

checklist_read() {
    # Compute presets into associative map
    declare -A preset_state
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do
        preset_state["$pkg"]="ON"
    done
    # Server pre-unchecks GUI
    if [[ "$MODE" == "server" ]]; then
        for pkg in "${GUI_STOW_PACKAGES[@]}"; do
            preset_state["$pkg"]="OFF"
        done
    fi
    # Shell choice checks only chosen shell
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then
        preset_state["zsh"]="ON"
        preset_state["nushell"]="OFF"
    elif [[ "$SHELL_CHOICE" == "nushell" ]]; then
        preset_state["zsh"]="OFF"
        preset_state["nushell"]="ON"
    fi
    # Termux forced OFF (also used for disabled-row rendering)
    if [[ "${FAMILY:-}" == "termux" ]]; then
        for pkg in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            preset_state["$pkg"]="OFF"
        done
    fi

    # No-TTY fast path: zero prompts, use presets directly
    if [[ ! -t 0 ]]; then
        SELECTED_PACKAGES=()
        for pkg in "${ALL_PACKAGES[@]}"; do
            if [[ "${preset_state[$pkg]}" == "ON" ]]; then
                SELECTED_PACKAGES+=("$pkg")
            fi
        done
        # Termux strip pass (redundant but safe)
        strip_termux_disabled
        echo "Selected packages (non-interactive presets): ${SELECTED_PACKAGES[*]:-<none>}" >&2
        return 0
    fi

    # TTY: builtin numbered-read rung
    echo "" >&2
    echo "Package checklist — toggle packages before any write (Zsh default, Nushell backup):" >&2
    echo "All 7 packages are individually toggleable. Server mode pre-unchecks GUI; shell choice pre-checks only chosen shell." >&2
    echo "" >&2
    local i=1
    for pkg in "${ALL_PACKAGES[@]}"; do
        local state="${preset_state[$pkg]}"
        local marker="[x]"
        if [[ "$state" != "ON" ]]; then
            marker="[ ]"
        fi
        local note=""
        local is_disabled=false
        if [[ "${FAMILY:-}" == "termux" ]]; then
            for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
                if [[ "$pkg" == "$d" ]]; then
                    is_disabled=true
                    break
                fi
            done
        fi
        if [[ "$is_disabled" == true ]]; then
            marker="[ ]"
            note=" (not available on Termux — never selectable)"
        fi
        printf " %2d %s %s%s\n" "$i" "$marker" "$pkg" "$note" >&2
        i=$((i + 1))
    done
    echo "" >&2
    echo "Enter numbers to toggle (e.g., '1 3' or '1,3'), press Enter to keep presets, or 'c' to cancel:" >&2
    local reply
    if ! read -r -p "> " reply; then
        echo "Error: failed to read checklist input" >&2
        return 1
    fi
    # Trim
    reply="$(echo "$reply" | xargs 2>/dev/null || echo "$reply")"
    if [[ "$reply" == "c" ]] || [[ "$reply" == "C" ]] || [[ "$reply" == "cancel" ]]; then
        echo "Checklist cancelled by user." >&2
        return 1
    fi
    if [[ -z "$reply" ]]; then
        SELECTED_PACKAGES=()
        for pkg in "${ALL_PACKAGES[@]}"; do
            if [[ "${preset_state[$pkg]}" == "ON" ]]; then
                SELECTED_PACKAGES+=("$pkg")
            fi
        done
        # Ensure Termux disabled remain off even if presets had them ON (should already be OFF)
        strip_termux_disabled
        echo "Keeping presets: ${SELECTED_PACKAGES[*]:-<none>}" >&2
        return 0
    fi
    # Parse numbers to toggle
    # Start from presets, then toggle indices
    declare -A toggled
    for pkg in "${ALL_PACKAGES[@]}"; do
        toggled["$pkg"]="${preset_state[$pkg]}"
    done
    # Normalize separators: commas to spaces, then iterate
    local normalized="${reply//,/ }"
    local tok
    for tok in $normalized; do
        # Validate integer
        if ! [[ "$tok" =~ ^[0-9]+$ ]]; then
            echo "Warning: ignoring invalid token '$tok'" >&2
            continue
        fi
        if [[ "$tok" -lt 1 ]] || [[ "$tok" -gt ${#ALL_PACKAGES[@]} ]]; then
            echo "Warning: ignoring out-of-range selection '$tok'" >&2
            continue
        fi
        local idx=$((tok - 1))
        local target_pkg="${ALL_PACKAGES[$idx]}"
        # Check Termux disabled — never selectable
        local is_disabled=false
        if [[ "${FAMILY:-}" == "termux" ]]; then
            for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
                if [[ "$target_pkg" == "$d" ]]; then
                    is_disabled=true
                    break
                fi
            done
        fi
        if [[ "$is_disabled" == true ]]; then
            echo "Warning: '$target_pkg' is not available on Termux — cannot be selected." >&2
            continue
        fi
        if [[ "${toggled[$target_pkg]}" == "ON" ]]; then
            toggled["$target_pkg"]="OFF"
        else
            toggled["$target_pkg"]="ON"
        fi
    done
    SELECTED_PACKAGES=()
    for pkg in "${ALL_PACKAGES[@]}"; do
        if [[ "${toggled[$pkg]}" == "ON" ]]; then
            SELECTED_PACKAGES+=("$pkg")
        fi
    done
    strip_termux_disabled
    echo "Final selection: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    return 0
}

prompt_checklist() {
    # Tracer: builtin rung only (richer backends arrive in Task 2)
    if ! checklist_read; then
        return 1
    fi
    return 0
}

main() {
    parse_args "$@"

    # Repo-root guard (CWD-independent via SCRIPT_DIR, fixes donor CWD-relative defect)
    if [[ ! -f "$SCRIPT_DIR/setup.sh" ]]; then
        echo "Error: run from the dotfiles repo root (setup.sh not found in $SCRIPT_DIR)." >&2
        exit 1
    fi

    # Outside-repo-root guard (must be run from clone root; D-05 safety)
    if [[ ! -f ./setup.sh ]]; then
        echo "Error: setup.sh must be run from the dotfiles repo root." >&2
        echo "This installer uses stow --dir=\"\$SCRIPT_DIR\" and expects to be run from the clone root." >&2
        echo "Please cd to the dotfiles clone and run: bash setup.sh [OPTIONS]" >&2
        echo "Current directory: $PWD (./setup.sh not found) — run-from-clone required." >&2
        exit 1
    fi

    # TTY-gated mode/shell resolution (D-05..D-08)
    local is_tty=false
    if [[ -t 0 ]]; then
        is_tty=true
    fi

    if [[ -z "$MODE" ]] || [[ -z "$SHELL_CHOICE" ]]; then
        if [[ "$is_tty" == false ]]; then
            echo "Error: --mode and --shell are required in non-interactive mode." >&2
            echo "Provide: --mode local|server --shell zsh|nushell" >&2
            usage >&2
            exit 1
        else
            if [[ -z "$MODE" ]]; then
                # Split declaration from fallible substitution (Pitfall 2 fix)
                local prompted_mode
                if ! prompted_mode=$(prompt_mode); then
                    echo "Error: failed to prompt for mode" >&2
                    exit 1
                fi
                MODE="$prompted_mode"
            fi
            if [[ -z "$SHELL_CHOICE" ]]; then
                local prompted_shell
                if ! prompted_shell=$(prompt_shell); then
                    echo "Error: failed to prompt for shell" >&2
                    exit 1
                fi
                SHELL_CHOICE="$prompted_shell"
            fi
        fi
    fi

    if ! FAMILY=$(detect_family); then
        exit 1
    fi
    echo "Detected family: $FAMILY"
    echo "Selected mode: $MODE"
    echo "Selected shell: $SHELL_CHOICE"
    if [[ "$DRY_RUN" == true ]]; then
        echo "=== DRY RUN MODE: No changes will be applied ==="
    fi

    local -a deps=()
    if ! mapfile -t deps < <(get_deps "$FAMILY" "$MODE"); then
        echo "Error: failed to get dependencies for $FAMILY/$MODE" >&2
        exit 1
    fi

    verify_deps "${deps[@]}"
    local -a missing=("${VERIFY_MISSING[@]}")

    # Partitioned reporting: core_missing vs gui_missing (DEPS-02)
    local -a gui_list=()
    case "$FAMILY" in
        arch) gui_list=(hyprland alacritty wofi keyd waybar grim slurp wl-copy) ;;
        debian) gui_list=(alacritty wofi waybar grim slurp wl-copy) ;;
        termux) gui_list=() ;;
    esac
    local -a core_missing=()
    local -a gui_missing=()
    local m
    local g
    local is_gui
    for m in "${missing[@]}"; do
        is_gui=false
        for g in "${gui_list[@]}"; do
            if [[ "$m" == "$g" ]]; then
                is_gui=true
                break
            fi
        done
        if [[ "$is_gui" == true ]]; then
            gui_missing+=("$m")
        else
            core_missing+=("$m")
        fi
    done

    if [[ ${#core_missing[@]} -gt 0 ]] || [[ ${#gui_missing[@]} -gt 0 ]]; then
        echo ""
        echo "Dependency Status"
        echo "----------------------------------------"
        if [[ ${#core_missing[@]} -gt 0 ]]; then
            echo "Missing CORE deps: ${core_missing[*]}"
        else
            echo "Core deps: OK"
        fi
        if [[ ${#gui_missing[@]} -gt 0 ]]; then
            echo "Missing GUI deps: ${gui_missing[*]}"
        else
            echo "GUI deps: OK"
        fi
    fi

    # Stow minimum-version check via version-sort (D-15, never lexicographic)
    if command -v stow >/dev/null 2>&1; then
        local stow_ver_str=""
        local stow_ver=""
        local outdated=false
        if stow_ver_str=$(stow --version 2>/dev/null); then
            if stow_ver=$(printf '%s' "$stow_ver_str" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1); then
                if [[ -n "$stow_ver" ]]; then
                    local smallest=""
                    if smallest=$(printf '%s\n' "$stow_ver" "2.4.1" | sort -V | head -n 1); then
                        if [[ "$smallest" == "$stow_ver" ]] && [[ "$stow_ver" != "2.4.1" ]]; then
                            outdated=true
                        fi
                    fi
                fi
            fi
        fi
        if [[ "$outdated" == true ]]; then
            echo "Stow $stow_ver < 2.4.1 — will upgrade via $FAMILY manager."
            local found=false
            local p
            for p in "${missing[@]}"; do
                if [[ "$p" == "stow" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" == false ]]; then
                missing+=("stow")
                core_missing+=("stow")
            fi
        fi
    fi

    local deps_need_install=false
    if [[ ${#missing[@]} -gt 0 ]]; then
        deps_need_install=true
    fi

    if [[ "$deps_need_install" == true ]]; then
        install_deps "$FAMILY" "${missing[@]}"
        if [[ "$DRY_RUN" == true ]]; then
            echo ""
            echo "DRY RUN: Skipped re-verify (no changes made)."
            # Continue to checklist for stow preview even in dry-run (do not return early)
        else
            if ! reverify_deps "$FAMILY" "$MODE"; then
                exit 1
            fi
            echo ""
            echo "Dependencies verified and installed successfully."
        fi
    else
        echo ""
        echo "All dependencies are satisfied."
        if [[ "$DRY_RUN" == false ]]; then
            echo "No install needed — second run is a safe no-op for deps."
        fi
        echo ""
        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY RUN: deps already satisfied."
        fi
    fi

    # ── Checklist ladder (before any stow write) ──
    echo ""
    echo "=== Package Selection ==="
    if ! prompt_checklist; then
        echo "Installation cancelled at package checklist." >&2
        exit 1
    fi

    if [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then
        echo "No packages selected — nothing to stow. Exiting." >&2
        # Not an error if user deselected all? Treat as cancelled but clean exit
        # For now, exit 1 to signal cancel semantics; dry-run with empty keeps presets so this is rare
        # Keep as success no-op
        echo "No packages to deploy."
        exit 0
    fi

    echo ""
    echo "Final package selection: ${SELECTED_PACKAGES[*]}"

    if [[ "$DRY_RUN" == true ]]; then
        preview_selection
        echo ""
        echo "DRY RUN complete — no writes performed."
        return 0
    fi

    # Safety: quarantine before stow
    quarantine_scan

    # Deploy
    if ! run_stow; then
        echo "Error: stow deployment failed." >&2
        exit 1
    fi

    # Strict post-verify (folding-aware)
    if ! post_verify; then
        echo "Error: post-verify failed — deployment incomplete." >&2
        exit 1
    fi

    echo ""
    echo "Setup complete. Deployed: ${SELECTED_PACKAGES[*]}"
}

# Source-guard: sourcing for tests never executes main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
