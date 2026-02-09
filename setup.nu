#!/usr/bin/env nu

def main [] {
    # The existence of $nu is a strong indicator we are in Nushell
    if (not ($nu | is-not-empty)) {
        print "Error: This script must be run with Nushell (nu)."
        print "Please install Nushell and run: nu setup.nu"
        exit 1
    }

    print "Starting Unified Bootstrapper..."

    let distro = (get-distro)
    print $"Detected distribution: ($distro)"

    if ($distro not-in ["arch", "cachyos", "ubuntu"]) {
        print "Error: This script only supports Arch Linux (CachyOS) and Ubuntu."
        print "Please refer to README.md for manual installation instructions."
        exit 1
    }
    
    print "OS validation passed."

    let mode = (get-mode)
    print $"Selected mode: ($mode)"

    let deps = (get-deps $distro $mode)
    print $"Dependencies for ($distro) in ($mode) mode defined."

    verify-deps $deps

    run-stow $mode
}

def run-stow [mode] {
    print "\nStarting deployment (GNU Stow)..."
    
    # Core modules for all modes
    let core_modules = ["nvim" "nushell" "starship"]
    
    # GUI modules for local mode
    let gui_modules = ["hyprland" "alacritty" "wofi"]
    
    print "Stowing core modules..."
    $core_modules | each { |it|
        print $" - Stowing ($it)..."
        stow --restow $it
    }
    
    if ($mode == "local") {
        print "Stowing GUI modules..."
        $gui_modules | each { |it|
            print $" - Stowing ($it)..."
            stow --restow $it
        }
        
        print "Stowing system modules (keyd)..."
        # Special case for keyd as per usage.md: sudo stow --adopt -t / keyd
        # We'll use a confirm prompt for sudo operations
        if (input "Stow keyd configuration to /etc/keyd? (y/n): ") == "y" {
            sudo stow --adopt -t / keyd
            print "keyd stowed. Reloading keyd..."
            sudo keyd reload
        }
    }
    
    print "\nDeployment complete!"
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

def get-mode [] {
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
    # Core dependencies found in config/scripts
    let common = ["stow" "nvim" "starship" "git" "zoxide" "uv" "rg"]
    
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
        print "\nPlease install them using your package manager."
        
        if ("stow" in $missing) {
            print "CRITICAL: 'stow' is required to continue."
            exit 1
        }
    } else {
        print "All dependencies are satisfied."
    }
}
