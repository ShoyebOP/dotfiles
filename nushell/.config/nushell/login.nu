# Check if we are on TTY1 and Hyprland isn't running
if ($env.TTY? == "/dev/tty1") {
    # 'exec' replaces the shell process with Hyprland (saves RAM)
    exec start-hyprland
}
