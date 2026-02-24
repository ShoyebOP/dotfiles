# venv.nu
# Python virtual environment activation/deactivation commands for Nushell

def "venv find" [] {
    """
    Find a Python virtual environment in the current directory.
    Returns the path to the venv if found, or errors if ambiguous/not found.
    """
    let current_dir = $env.PWD
    let hidden_venv = ($current_dir | path join ".venv")
    let normal_venv = ($current_dir | path join "venv")
    
    let hidden_exists = ($hidden_venv | path exists)
    let normal_exists = ($normal_venv | path exists)
    
    if $hidden_exists and $normal_exists {
        error make {
            msg: "Ambiguous virtual environment: both '.venv' and 'venv' folders exist",
            label: {
                text: "Remove one or specify explicitly",
                span: (metadata $current_dir).span
            },
            help: "Delete one of the folders or rename to avoid ambiguity"
        }
    } else if $hidden_exists {
        return $hidden_venv
    } else if $normal_exists {
        return $normal_venv
    } else {
        error make {
            msg: "No virtual environment found in current directory",
            label: {
                text: "Neither '.venv' nor 'venv' folder exists",
                span: (metadata $current_dir).span
            },
            help: "Create a venv with 'python -m venv .venv' or 'uv venv'"
        }
    }
}

def "venv get-python-version" [venv_path: string] {
    """
    Get the Python version from a virtual environment.
    """
    let python_exe = if ($nu.os-info.name == "windows") {
        ($venv_path | path join "Scripts" "python.exe")
    } else {
        ($venv_path | path join "bin" "python")
    }
    
    if ($python_exe | path exists) {
        try {
            let version_output = (^$python_exe --version | str trim)
            return ($version_output | str replace "Python " "")
        } catch {
            return "unknown"
        }
    } else {
        return "unknown"
    }
}

def "venv get-activate-script" [venv_path: string] {
    """
    Get the path to the activation script for a virtual environment.
    Returns a record with the script path and whether it's a nushell script.
    """
    let is_windows = ($nu.os-info.name == "windows")
    
    # Check for nushell activation script first (uv creates these)
    let nu_activate = if $is_windows {
        ($venv_path | path join "Scripts" "activate.nu")
    } else {
        ($venv_path | path join "bin" "activate.nu")
    }
    
    if ($nu_activate | path exists) {
        return { path: $nu_activate, is_nu: true }
    }
    
    # Fall back to standard POSIX activate script
    let posix_activate = if $is_windows {
        ($venv_path | path join "Scripts" "activate")
    } else {
        ($venv_path | path join "bin" "activate")
    }
    
    if ($posix_activate | path exists) {
        return { path: $posix_activate, is_nu: false }
    }
    
    return { path: null, is_nu: false }
}

def "venv parse-activate-nu" [script_path: string] {
    """
    Parse a nushell activate.nu script to extract environment changes.
    Returns a record with VIRTUAL_ENV and PATH modifications.
    """
    let script_content = (open $script_path)
    
    # Look for VIRTUAL_ENV assignment
    let virtual_env = ($script_content 
        | lines 
        | where ($it | str contains "VIRTUAL_ENV")
        | where ($it | str contains "=")
        | first
        | str replace '.*\$env\.VIRTUAL_ENV\s*=\s*' ""
        | str replace "'" ""
        | str replace '"' ""
        | str trim)
    
    return { virtual_env: $virtual_env }
}

def "venv parse-activate-posix" [script_path: string] {
    """
    Parse a POSIX shell activate script to extract VIRTUAL_ENV.
    Returns a record with the virtual env path.
    """
    let script_content = (open $script_path)
    
    # Extract VIRTUAL_ENV from the script
    let virtual_env = ($script_content 
        | lines 
        | where ($it | str contains "VIRTUAL_ENV=")
        | first
        | str replace ".*VIRTUAL_ENV=" ""
        | str replace "'" ""
        | str replace '"' ""
        | str replace '`' ""
        | str trim)
    
    return { virtual_env: $virtual_env }
}

export def --env venv-activate [] {
    """
    Activate a Python virtual environment in the current directory.

    Searches for '.venv' first (hidden folder convention), then 'venv'.
    Shows verbose output including the venv path and Python version.

    Examples:
        > venv-activate
    """
    
    # Check if already in a virtual environment
    if "VIRTUAL_ENV" in $env {
        print $"⚠️  Warning: Already inside a virtual environment: ($env.VIRTUAL_ENV)"
        print "  Use 'venv-deactivate' first, or 'deactivate' to exit the current venv"
        return
    }
    
    # Find the venv
    let venv_path = (venv find)
    
    # Get activation script info
    let activate_info = (venv get-activate-script $venv_path)
    
    if $activate_info.path == null {
        error make {
            msg: "No activation script found in virtual environment",
            label: {
                text: $"Expected activate script in ($venv_path)",
                span: (metadata $venv_path).span
            },
            help: "The venv may be corrupted or incomplete. Try recreating it."
        }
    }
    
    # Get Python version for verbose output
    let python_version = (venv get-python-version $venv_path)

    # Print verbose activation message
    print $"● Activating virtual environment..."
    print $"  Path: ($venv_path)"
    print $"  Python version: ($python_version)"
    
    # Determine bin directory
    let venv_bin = if ($nu.os-info.name == "windows") {
        ($venv_path | path join "Scripts")
    } else {
        ($venv_path | path join "bin")
    }
    
    # Activate by setting environment variables
    $env.VIRTUAL_ENV = $venv_path
    $env.VIRTUAL_ENV_PROMPT = (basename $venv_path)
    $env.PATH = ($env.PATH | prepend $venv_bin)

    # Create a deactivate function in the current scope
    # Store original PATH for restoration
    $env._VENV_OLD_PATH = ($env.PATH | where $it != $venv_bin | str join (char esep))

    print $"✓ Virtual environment activated successfully"
}

export def --env venv-deactivate [] {
    """
    Deactivate the currently active Python virtual environment.

    Shows a confirmation message with the deactivated venv path.

    Examples:
        > venv-deactivate
    """
    
    # Check if we're in a virtual environment
    if "VIRTUAL_ENV" not-in $env {
        error make {
            msg: "No virtual environment is currently active",
            label: {
                text: "VIRTUAL_ENV not set",
                span: (metadata $env.PWD).span
            },
            help: "Use 'venv-activate' to activate a virtual environment first"
        }
    }
    
    let venv_path = $env.VIRTUAL_ENV
    
    # Determine bin directory
    let venv_bin = if ($nu.os-info.name == "windows") {
        ($venv_path | path join "Scripts")
    } else {
        ($venv_path | path join "bin")
    }
    
    # Remove venv bin from PATH
    $env.PATH = ($env.PATH | where $it != $venv_bin)
    
    # Remove VIRTUAL_ENV variables
    hide-env VIRTUAL_ENV
    hide-env VIRTUAL_ENV_PROMPT
    
    # Clean up old path if it exists
    if "_VENV_OLD_PATH" in $env {
        hide-env _VENV_OLD_PATH
    }

    print $"✓ Virtual environment deactivated: ($venv_path)"
}
