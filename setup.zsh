#!/usr/bin/env zsh

# setup.zsh - Zsh Bootstrapper (equivalent to setup.nu)
# Deploys dotfiles using GNU Stow with dependency verification

set -euo pipefail

DRY_RUN=false
MODE=""
STOW_KEYD=""

SCRIPT_NAME="${0:t}"

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Zsh Dotfiles Bootstrapper

OPTIONS:
    --mode MODE          Deployment mode: 'local' (full GUI) or 'server' (headless)
    --dry-run           Show what would be done without making changes
    --stow-keyd Y/N     Whether to stow keyd configuration to /etc/keyd

EXAMPLES:
    $SCRIPT_NAME --mode local
    $SCRIPT_NAME --mode server --dry-run
    $SCRIPT_NAME --stow-keyd y

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                MODE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --stow-keyd)
                STOW_KEYD="$2"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

get_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

verify_command() {
    command -v "$1" &>/dev/null
}

get_deps() {
    local distro="$1"
    local mode="$2"

    local -a common=(
        "stow"
        "nvim"
        "starship"
        "git"
        "zoxide"
        "uv"
        "rg"
        "node"
        "npm"
    )

    local -a gui=()
    case "$distro" in
        arch|cachyos)
            gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy)
            ;;
        ubuntu)
            gui=(alacritty wofi waybar grim slurp wl-copy)
            ;;
    esac

    if [[ "$mode" == "local" ]]; then
        printf '%s\n' "${common[@]}" "${gui[@]}"
    else
        printf '%s\n' "${common[@]}"
    fi
}

verify_deps() {
    local deps=("$@")
    local -a missing=()
    local -a installed=()

    echo "\nVerifying dependencies..."
    for dep in "${deps[@]}"; do
        if ! verify_command "$dep"; then
            missing+=("$dep")
            echo "  - $dep (missing)"
        else
            installed+=("$dep")
            echo "  + $dep (installed)"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "\nMissing dependencies: ${missing[*]}"
    else
        echo "\nAll dependencies are satisfied."
    fi
}

install_deps() {
    local distro="$1"
    local -a missing=("$@")

    local -a install_cmd=()
    case "$distro" in
        arch|cachyos)
            install_cmd=(sudo pacman -S --needed)
            ;;
        ubuntu)
            install_cmd=(sudo apt install -y)
            ;;
        *)
            echo "Unsupported distro for auto-install."
            exit 1
            ;;
    esac

    echo "\nReady to install: ${missing[*]}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"
        return
    fi

    read -q "REPLY?Proceed with installation? (y/n): "
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed "${missing[@]}"
    else
        echo "Skipping installation."
    fi
}

install_deps_interactive() {
    local distro="$1"
    shift
    local -a all_deps=("$@")

    local -a core_deps=()
    local -a gui_deps=()

    for dep in "${all_deps[@]}"; do
        if verify_command "$dep"; then
            continue
        fi
        case "$dep" in
            stow|nvim|starship|git|zoxide|uv|rg|node|npm)
                core_deps+=("$dep")
                ;;
            *)
                gui_deps+=("$dep")
                ;;
        esac
    done

    if [[ ${#core_deps[@]} -eq 0 && ${#gui_deps[@]} -eq 0 ]]; then
        echo "\nAll dependencies are satisfied."
        return 0
    fi

    echo "\n========================================"
    echo "Dependency Status"
    echo "========================================"
    if [[ ${#core_deps[@]} -gt 0 ]]; then
        echo "Missing CORE deps: ${core_deps[*]}"
    else
        echo "Core deps: OK"
    fi
    if [[ ${#gui_deps[@]} -gt 0 ]]; then
        echo "Missing GUI deps: ${gui_deps[*]}"
    else
        echo "GUI deps: OK"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "\n[DRY RUN] Skipping interactive installation prompt."
        if [[ ${#core_deps[@]} -gt 0 ]]; then
            echo "[DRY RUN] Would install core deps: ${core_deps[*]}"
        fi
        if [[ ${#gui_deps[@]} -gt 0 ]]; then
            echo "[DRY RUN] Would install GUI deps: ${gui_deps[*]}"
        fi
        return 0
    fi

    if [[ ! -t 0 ]]; then
        echo "\nNon-interactive terminal detected. Installing core deps automatically..."
        if [[ ${#core_deps[@]} -gt 0 ]]; then
            install_deps "$distro" "${core_deps[@]}"
        fi
        if [[ ${#gui_deps[@]} -gt 0 ]]; then
            echo "GUI deps not installed in non-interactive mode. Install manually if needed."
        fi
        return 0
    fi

    echo "\n========================================"
    echo "Select Installation Option"
    echo "========================================"
    echo "1. Install ALL missing dependencies"
    echo "2. Install CORE deps only (skip GUI)"
    echo "3. Skip installation (force stow without deps)"
    echo "4. Select specific packages to skip"
    echo "5. View package info in pacman"

    read -q "REPLY?Choose (1-5): "
    echo

    case "$REPLY" in
        1)
            if [[ ${#core_deps[@]} -gt 0 ]]; then
                install_deps "$distro" "${core_deps[@]}"
            fi
            if [[ ${#gui_deps[@]} -gt 0 ]]; then
                install_deps "$distro" "${gui_deps[@]}"
            fi
            ;;
        2)
            if [[ ${#core_deps[@]} -gt 0 ]]; then
                install_deps "$distro" "${core_deps[@]}"
            else
                echo "Core deps already satisfied."
            fi
            echo "Skipping GUI deps installation."
            ;;
        3)
            echo "Skipping installation. Running stow anyway..."
            ;;
        4)
            select_skip_packages "$distro" "${core_deps[@]}" "${gui_deps[@]}"
            ;;
        5)
            echo "Checking packages in pacman..."
            for dep in "${core_deps[@]}" "${gui_deps[@]}"; do
                pacman -Qi "$dep" 2>/dev/null || echo "$dep: not found in pacman"
            done
            install_deps_interactive "$distro" "${all_deps[@]}"
            ;;
        *)
            echo "Invalid option."
            exit 1
            ;;
    esac
}

select_skip_packages() {
    local distro="$1"
    shift
    local -a all_missing=("$@")

    echo "\nAvailable packages to skip:"
    local -a to_install=()
    for dep in "${all_missing[@]}"; do
        read -q "REPLY?Install $dep? (y/n): " && echo && to_install+=("$dep") || echo " [skipped]"
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        install_deps "$distro" "${to_install[@]}"
    fi
}

get_mode_interactive() {
    echo "\nSelect Deployment Mode:"
    echo "1. Local Mode (Full setup including GUI: Hyprland, Alacritty, keyd, etc.)"
    echo "2. Server Mode (Headless setup: Nvim, Zsh, Starship only)"

    while true; do
        read "REPLY?Enter choice (1 or 2): "
        case "$REPLY" in
            1) echo "local" && return ;;
            2) echo "server" && return ;;
            *) echo "Invalid choice. Please enter 1 or 2." ;;
        esac
    done
}

run_stow() {
    local mode="$1"
    local stow_keyd_arg="${2:-}"

    echo "\nStarting deployment (GNU Stow)..."

    local -a core_modules=(nvim zsh)
    local -a gui_modules=(hyprland alacritty wofi)

    echo "Stowing core modules..."
    for module in "${core_modules[@]}"; do
        stow_module "$module"
    done

    if [[ "$mode" == "local" ]]; then
        echo "Stowing GUI modules..."
        for module in "${gui_modules[@]}"; do
            stow_module "$module"
        done

        echo "Stowing system modules (keyd)..."
        local do_keyd=false
        if [[ -n "$stow_keyd_arg" ]]; then
            [[ "$stow_keyd_arg" == "y" ]] && do_keyd=true
        else
            read -q "REPLY?Stow keyd configuration to /etc/keyd? (y/n): " && do_keyd=true && echo
        fi

        if [[ "$do_keyd" == "true" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo " - [DRY RUN] sudo stow --adopt -t / keyd"
                echo " - [DRY RUN] sudo keyd reload"
            else
                sudo stow --adopt -t / keyd
                echo "keyd stowed. Reloading keyd..."
                sudo keyd reload
            fi
        fi
    fi

    echo "\nDeployment complete!"
}

stow_module() {
    local module="$1"
    echo " - Processing $module..."

    local target="$HOME/.config/$module"

    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        echo "   ! WARNING: $target is a real file/folder."
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "   [DRY RUN] Would delete: rm -rf $target"
        else
            rm -rf "$target"
            echo "   Deleted: $target"
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "   [DRY RUN] Would run: stow --restow $module"
    else
        stow --restow "$module"
    fi
}

main() {
    parse_args "$@"

    if [[ -z "$MODE" ]]; then
        MODE=$(get_mode_interactive)
    fi

    echo "Starting Zsh Bootstrapper..."
    echo "Detected distribution: $(get_distro)"
    echo "Selected mode: $MODE"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "=== DRY RUN MODE: No changes will be applied ==="
    fi

    local distro
    distro=$(get_distro)

    if [[ "$distro" != "arch" && "$distro" != "cachyos" && "$distro" != "ubuntu" ]]; then
        echo "Error: This script only supports Arch Linux (CachyOS) and Ubuntu."
        echo "Please refer to README.md for manual installation instructions."
        exit 1
    fi

    echo "OS validation passed."

    local -a deps
    deps=($(get_deps "$distro" "$MODE"))

    verify_deps "${deps[@]}"

    install_deps_interactive "$distro" "${deps[@]}"

    run_stow "$MODE" "$STOW_KEYD"
}

main "$@"