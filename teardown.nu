#!/usr/bin/env nu

# ============================================
# Teardown Script - Reverse of setup.nu
# ============================================
# This script unstows all directories managed by setup.nu
# and deletes the stow directories.
# 
# WARNING: This is a destructive operation!
# ============================================

def main [
    --dry-run           # Show what would be done without making changes
    --unstow-keyd: string # Whether to unstow keyd: 'y' or 'n' (default: ask)
] {
    # Verify we're running in Nushell
    if (not ($nu | is-not-empty)) {
        print "Error: This script must be run with Nushell (nu)."
        print "Please install Nushell and run: nu teardown.nu"
        exit 1
    }

    if $dry_run { 
        print "=== DRY RUN MODE: No changes will be applied ===" 
    }

    print "⚠️  WARNING: Starting Teardown Process ⚠️"
    print "This will remove all stowed configurations and delete the stow directories."
    print ""

    # Confirm before proceeding
    let confirm = if $dry_run {
        "n"
    } else {
        input "Are you sure you want to continue? Type 'yes' to confirm: "
    }

    if ($confirm != "yes") {
        print "Teardown cancelled."
        exit 0
    }

    print ""
    print "Starting teardown..."

    # Get deployment mode (needed to know which modules to unstow)
    let selected_mode = get-mode-interactive

    run-unstow $selected_mode $dry_run $unstow_keyd

    print ""
    print "=== Teardown Complete ==="
    print "All stowed configurations have been removed."
    print "Stow directories have been deleted."
}

def get-mode-interactive [] {
    print "\nSelect Deployment Mode to Unstow:"
    print "1. Local Mode (Full setup including GUI: Hyprland, Alacritty, keyd, etc.)"
    print "2. Server Mode (Headless setup: Nvim, Nushell, Starship only)"

    loop {
        let input = (input "Enter choice (1 or 2): ")
        if ($input == "1") { return "local" }
        if ($input == "2") { return "server" }
        print "Invalid choice. Please enter 1 or 2."
    }
}

def run-unstow [mode, dry_run, unstow_keyd_arg] {
    print "\nStarting unstow process (GNU Stow)..."

    let core_modules = ["nvim" "nushell" "starship"]
    let gui_modules = ["hyprland" "alacritty" "wofi"]

    # Unstow GUI modules first (if local mode)
    if ($mode == "local") {
        print "Unstowing GUI modules..."
        $gui_modules | each { |it|
            unstow-module $it $dry_run
        }

        # Handle keyd (system-wide)
        print "Unstowing system modules (keyd)..."
        let do_keyd = if ($unstow_keyd_arg | is-not-empty) {
            $unstow_keyd_arg == "y"
        } else {
            (input "Unstow keyd configuration from /etc/keyd? (y/n): ") == "y"
        }

        if $do_keyd {
            if $dry_run {
                print " - [DRY RUN] sudo stow -D -t / keyd"
            } else {
                sudo stow -D -t / keyd
                print "keyd unstowed."
            }
        }
    }

    # Unstow core modules
    print "Unstowing core modules..."
    $core_modules | each { |it|
        unstow-module $it $dry_run
    }

    # Delete stow directories
    print "\nDeleting stow directories..."
    let all_modules = if ($mode == "local") {
        ($core_modules | append $gui_modules | append ["keyd"])
    } else {
        $core_modules
    }

    $all_modules | each { |it|
        delete-stow-directory $it $dry_run
    }
}

def unstow-module [module, dry_run] {
    print $" - Unstowing ($module)..."

    let unstow_cmd = if $dry_run { 
        ["stow" "-D" "-v" $module] 
    } else { 
        ["stow" "-D" $module] 
    }

    if $dry_run {
        print $"   [DRY RUN] Would run: (run-external --redirect-stderr ($unstow_cmd | first) ...($unstow_cmd | skip 1) | complete | get stderr)"
    } else {
        let result = (run-external --redirect-stderr ($unstow_cmd | first) ...($unstow_cmd | skip 1) | complete)
        if $result.exit_code != 0 {
            print $"   ! Warning: stow returned non-zero exit code for ($module)"
        } else {
            print $"   ✓ ($module) unstowed successfully"
        }
    }
}

def delete-stow-directory [module, dry_run] {
    let stow_dir = $"($nu.cwd)/($module)"
    
    if not ($stow_dir | path exists) {
        print $"   - ($module): Stow directory does not exist, skipping"
        return
    }

    if $dry_run {
        print $"   [DRY RUN] Would delete: ($stow_dir)"
    } else {
        rm -rf $stow_dir
        print $"   ✓ ($module) stow directory deleted"
    }
}
