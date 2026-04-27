#!/usr/bin/env zsh

# teardown.zsh - Reverse of setup.zsh
# Unstows all directories managed by setup.zsh and deletes the stow directories

set -euo pipefail

DRY_RUN=false
UNSTOW_KEYD=""

SCRIPT_NAME="${0:t}"

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Zsh Dotfiles Teardown Script

WARNING: This is a destructive operation!

OPTIONS:
    --dry-run           Show what would be done without making changes
    --unstow-keyd Y/N   Whether to unstow keyd configuration (default: ask)

EXAMPLES:
    $SCRIPT_NAME --dry-run
    $SCRIPT_NAME --unstow-keyd y

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --unstow-keyd)
                UNSTOW_KEYD="$2"
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

get_mode_interactive() {
    echo "\nSelect Deployment Mode to Unstow:"
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

run_unstow() {
    local mode="$1"
    local unstow_keyd_arg="${2:-}"

    echo "\nStarting unstow process (GNU Stow)..."

    local -a core_modules=(nvim zsh)
    local -a gui_modules=(hyprland alacritty wofi)

    if [[ "$mode" == "local" ]]; then
        echo "Unstowing GUI modules..."
        for module in "${gui_modules[@]}"; do
            unstow_module "$module"
        done

        echo "Unstowing system modules (keyd)..."
        local do_keyd=false
        if [[ -n "$unstow_keyd_arg" ]]; then
            [[ "$unstow_keyd_arg" == "y" ]] && do_keyd=true
        else
            read -q "REPLY?Unstow keyd configuration from /etc/keyd? (y/n): " && do_keyd=true && echo
        fi

        if [[ "$do_keyd" == "true" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo " - [DRY RUN] sudo stow -D -t / keyd"
            else
                sudo stow -D -t / keyd
                echo "keyd unstowed."
            fi
        fi
    fi

    echo "Unstowing core modules..."
    for module in "${core_modules[@]}"; do
        unstow_module "$module"
    done

    echo "\nDeleting stow directories..."
    local -a all_modules=()
    if [[ "$mode" == "local" ]]; then
        all_modules=("${core_modules[@]}" "${gui_modules[@]}" "keyd")
    else
        all_modules=("${core_modules[@]}")
    fi

    for module in "${all_modules[@]}"; do
        delete_stow_directory "$module"
    done
}

unstow_module() {
    local module="$1"
    echo " - Unstowing $module..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "   [DRY RUN] Would run: stow -D $module"
    else
        if stow -D "$module" 2>/dev/null; then
            echo "   ✓ $module unstowed successfully"
        else
            echo "   ! Warning: stow returned non-zero exit code for $module"
        fi
    fi
}

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

main() {
    parse_args "$@"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "=== DRY RUN MODE: No changes will be applied ==="
    fi

    echo "⚠️  WARNING: Starting Teardown Process ⚠️"
    echo "This will remove all stowed configurations and delete the stow directories."
    echo ""

    read "REPLY?Are you sure you want to continue? Type 'yes' to confirm: "
    if [[ "$REPLY" != "yes" ]]; then
        echo "Teardown cancelled."
        exit 0
    fi

    echo ""
    echo "Starting teardown..."

    local mode
    mode=$(get_mode_interactive)

    run_unstow "$mode" "$UNSTOW_KEYD"

    echo ""
    echo "=== Teardown Complete ==="
    echo "All stowed configurations have been removed."
    echo "Stow directories have been deleted."
}

main "$@"