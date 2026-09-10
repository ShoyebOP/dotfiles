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
            # neovim: Termux package 'neovim' provides 'nvim' (best-effort)
            # ripgrep: 'ripgrep' provides 'rg'
            # nodejs: 'nodejs' provides 'node'
            # starship, zoxide, fzf, git, zsh, make, gcc assumed available as named (best-effort per A3)
            # uv: best-effort — if missing, per-package graceful message will guide manual retry
            common=(stow neovim starship git zoxide ripgrep nodejs npm make gcc fzf zsh)
            # No GUI packages selectable on Termux (keyd/hyprland/wofi disabled per D-12)
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

main() {
    parse_args "$@"

    # Repo-root guard (CWD-independent via SCRIPT_DIR, fixes donor CWD-relative defect)
    if [[ ! -f "$SCRIPT_DIR/setup.sh" ]]; then
        echo "Error: run from the dotfiles repo root (setup.sh not found in $SCRIPT_DIR)." >&2
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

    local family
    if ! family=$(detect_family); then
        exit 1
    fi
    echo "Detected family: $family"
    echo "Selected mode: $MODE"
    echo "Selected shell: $SHELL_CHOICE"
    if [[ "$DRY_RUN" == true ]]; then
        echo "=== DRY RUN MODE: No changes will be applied ==="
    fi

    local -a deps=()
    if ! mapfile -t deps < <(get_deps "$family" "$MODE"); then
        echo "Error: failed to get dependencies for $family/$MODE" >&2
        exit 1
    fi

    verify_deps "${deps[@]}"
    local -a missing=("${VERIFY_MISSING[@]}")

    # Partitioned reporting: core_missing vs gui_missing (DEPS-02)
    local -a gui_list=()
    case "$family" in
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
            echo "Stow $stow_ver < 2.4.1 — will upgrade via $family manager."
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

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo ""
        echo "All dependencies are satisfied."
        echo "No install needed — second run is a safe no-op."
        echo ""
        echo "Setup deps complete (dry-run=$DRY_RUN)."
        return 0
    fi

    install_deps "$family" "${missing[@]}"

    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "DRY RUN: Skipped re-verify (no changes made)."
        return 0
    fi

    if ! reverify_deps "$family" "$MODE"; then
        exit 1
    fi

    echo ""
    echo "Dependencies verified and installed successfully."
}

# Source-guard: sourcing for tests never executes main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
