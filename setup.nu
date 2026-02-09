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
}

def verify-deps [deps] {
    print "\nVerifying dependencies..."
    let missing = ($deps | where { (which $in | is-empty) })
    
    if ($missing | is-not-empty) {
        print "The following dependencies are missing:"
        $missing | each { print $" - ($in)" }
        print "\nPlease install them using your package manager."
        # For now, we just warn and proceed, or we could exit.
        # Given the "efficiency" goal, let's exit if critical ones are missing.
        if ("stow" in $missing) {
            print "CRITICAL: 'stow' is required to continue."
            exit 1
        }
    } else {
        print "All dependencies are satisfied."
    }
}

def get-deps [distro, mode] {
    let common = ["stow" "nvim" "starship" "git" "zoxide" "fzf" "ripgrep" "bat" "eza"]
    
    let gui = match $distro {
        "arch" | "cachyos" => ["hyprland" "alacritty" "wofi" "keyd" "waybar" "swww" "mako" "grim" "slurp" "wl-clipboard"]
        "ubuntu" => ["alacritty" "wofi" "waybar" "mako" "grim" "slurp" "wl-clipboard"] # keyd/hyprland often need special handling on Ubuntu
        _ => []
    }

    if ($mode == "local") {
        return ($common | append $gui)
    } else {
        return $common
    }
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

def get-distro [] {
    if ("/etc/os-release" | path exists) {
        let release_data = (open /etc/os-release | lines)
        let id_line = ($release_data | where { $in =~ "^ID=" } | first)
        let id = ($id_line | str replace "ID=" "" | str replace -a '"' "")
        return $id
    }
    return "unknown"
}