#!/usr/bin/env nu

def main [
    --mode: string      # Deployment mode: 'local' or 'server'
    --dry-run           # Show what would be done without making changes
    --stow-keyd: string # Whether to stow keyd: 'y' or 'n'
] {
    # The existence of $nu is a strong indicator we are in Nushell
    if (not ($nu | is-not-empty)) {
        print "Error: This script must be run with Nushell (nu)."
        print "Please install Nushell and run: nu setup.nu"
        exit 1
    }

    if $dry_run { print "=== DRY RUN MODE: No changes will be applied ===" }

    print "Starting Unified Bootstrapper..."

    let distro = (get-distro)
    print $"Detected distribution: ($distro)"

    if ($distro not-in ["arch", "cachyos", "ubuntu"]) {
        print "Error: This script only supports Arch Linux (CachyOS) and Ubuntu."
        print "Please refer to README.md for manual installation instructions."
        exit 1
    }
    
    print "OS validation passed."

    # Sync Path from current config
    let current_path = $env.PATH
    print "Global path captured."

    let selected_mode = if ($mode | is-not-empty) {
        $mode
    } else {
        get-mode-interactive
    }
    print $"Selected mode: ($selected_mode)"

    let deps = (get-deps $distro $selected_mode)
    print $"Dependencies for ($distro) in ($selected_mode) mode defined."

    let missing = (verify-deps $deps)
    if ($missing | is-not-empty) {
        install-deps $distro $missing $dry_run
    } else {
        print "All dependencies are satisfied."
    }

    run-stow $selected_mode $dry_run $stow_keyd
}

def get-distro [] {
    if ("/etc/os-release" | path exists) {
        let release_data = (open /etc/os-release | lines)
        let id_line = ($release_data | where { $in =~ "^ID=" } | first)
        let id = ($id_line | str replace "ID=" "" | str replace -a '"' "")
        return $id
    }
    return "unknown"
}

def get-mode-interactive [] {
    print "\nSelect Deployment Mode:"
    print "1. Local Mode (Full setup including GUI: Hyprland, Alacritty, keyd, etc.)"
    print "2. Server Mode (Headless setup: Nvim, Nushell, Starship only)"
    
    loop {
        let input = (input "Enter choice (1 or 2): ")
        if ($input == "1") { return "local" }
        if ($input == "2") { return "server" }
        print "Invalid choice. Please enter 1 or 2."
    }
}

def get-deps [distro, mode] {
    # Core dependencies found in config/scripts + node/npm for nvim
    let common = ["stow" "nvim" "starship" "git" "zoxide" "uv" "rg" "node" "npm"]
    
    # GUI dependencies verified on system and in use
    let gui = match $distro {
        "arch" | "cachyos" => ["hyprland" "alacritty" "wofi" "keyd" "waybar" "grim" "slurp" "wl-copy"]
        "ubuntu" => ["alacritty" "wofi" "waybar" "grim" "slurp" "wl-copy"]
        _ => []
    }

    if ($mode == "local") {
        return ($common | append $gui)
    } else {
        return $common
    }
}

def verify-deps [deps] {
    print "\nVerifying dependencies..."
    let missing = ($deps | where { (which $in | is-empty) })
    
    if ($missing | is-not-empty) {
        print "The following dependencies are missing:"
        $missing | each { print $" - ($in)" }
        return $missing
    }
    return []
}

def install-deps [distro, missing, dry_run] {
    let install_cmd = match $distro {
        "arch" | "cachyos" => ["sudo" "pacman" "-S" "--needed"]
        "ubuntu" => ["sudo" "apt" "install" "-y"]
        _ => { print "Unsupported distro for auto-install."; exit 1 }
    }

    print $"\nReady to install missing packages: ($missing | str join ' ')"
    let confirm = if $dry_run { "n" } else { (input "Proceed with installation? (y/n): ") }

    if ($confirm == "y") {
        run-external ($install_cmd | first) ...($install_cmd | skip 1) ...$missing
    } else if $dry_run {
        print $"[DRY RUN] Would run: ($install_cmd | str join ' ') ($missing | str join ' ')"
    } else {
        print "Skipping installation. Note: Setup might fail if critical tools are missing."
        if ("stow" in $missing) {
            print "CRITICAL: 'stow' is required to continue."
            exit 1
        }
    }
}

def run-stow [mode, dry_run, stow_keyd_arg] {
    print "\nStarting deployment (GNU Stow)..."
    
    let core_modules = ["nvim" "nushell" "starship"]
    let gui_modules = ["hyprland" "alacritty" "wofi"]
    
    print "Stowing core modules..."
    $core_modules | each { |it|
        stow-module $it $dry_run
    }
    
    if ($mode == "local") {
        print "Stowing GUI modules..."
        $gui_modules | each { |it|
            stow-module $it $dry_run
        }
        
        print "Stowing system modules (keyd)..."
        let do_keyd = if ($stow_keyd_arg | is-not-empty) {
            $stow_keyd_arg == "y"
        } else {
            (input "Stow keyd configuration to /etc/keyd? (y/n): ") == "y"
        }

        if $do_keyd {
            if $dry_run {
                print " - [DRY RUN] sudo stow --adopt -t / keyd"
                print " - [DRY RUN] sudo keyd reload"
            } else {
                sudo stow --adopt -t / keyd
                print "keyd stowed. Reloading keyd..."
                sudo keyd reload
            }
        }
    }
    
    print "\nDeployment complete!"
}

def stow-module [module, dry_run] {
    print $" - Processing ($module)..."
    
    # Pre-stow cleanup: check target locations
    # For simplicity, we check common targets like ~/.config/module
    let home = $env.HOME
    let target = $"($home)/.config/($module)"
    
    if ($target | path exists) {
        # Check if it's a symlink
        let is_link = (ls -ld $target | get 0.type) == "symlink"
        
        if (not $is_link) {
            print $"   ! WARNING: ($target) is a real file/folder. Deleting..."
            if $dry_run {
                print $"   [DRY RUN] rm -rf ($target)"
            } else {
                rm -rf $target
            }
        }
    }

    let stow_cmd = if $dry_run { ["stow" "--no" "-v" "--restow" $module] } else { ["stow" "--restow" $module] }
    run-external ($stow_cmd | first) ...($stow_cmd | skip 1)
}
