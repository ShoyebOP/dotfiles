# env.nu
#
# Installed by:
# version = "0.110.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# Only run if we are in an interactive session and on TTY1
if ($env.LAST_EXIT_CODE? == 0) and ((tty) == "/dev/tty1") {
    print "🚀 Launching Hyprland..."
    exec start-hyprland
}

# XDG Paths (Standard)
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")

# History (Nu manages its own history file, usually sqlite or plain text)
# You don't need to manually set HISTSIZE, it handles it efficiently.

# Add Local Bin to Path
$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.HOME | path join ".local" "bin"))
$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.HOME | path join ".local" "sbin"))

# Editor
$env.EDITOR = "nvim"


