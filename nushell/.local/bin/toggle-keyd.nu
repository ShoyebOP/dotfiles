#!/usr/bin/env nu

# Check status
let status = (systemctl is-active keyd | str trim)

if $status == "active" {
    # Stop Keyd (Gaming Mode)
    sudo systemctl stop keyd
    notify-send -u critical -t 2000 "🎮 Normal Mode" "Keyd Stopped (j+k = jk)"
} else {
    # Start Keyd (Vim Mode)
    sudo systemctl start keyd
    notify-send -u low -t 2000 "🦁 Vim Mode" "Keyd Active (j+k = Esc)"
}
