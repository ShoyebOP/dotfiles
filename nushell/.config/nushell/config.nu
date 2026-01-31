# ============================================
# PART 1: COMMANDS & ALIASES
# ============================================

# 1. Load Scripts from your Dotfiles Repo
# $nu.default-config-dir points to ~/.config/nushell (which is symlinked to your repo)
source ($nu.default-config-dir | path join "scripts" "uv.nu")
source ($nu.default-config-dir | path join "scripts" "zoxide.nu")
source ($nu.default-config-dir | path join "scripts" "catppuccin.nu")

# 2. Aliases
alias c = clear
alias v = nvim
alias cd = z

# ============================================
# PART 2: CONFIGURATION
# ============================================
$env.config = {
    # 1. UI & BEHAVIOR
    show_banner: false
    edit_mode: "vi" # <--- CHANGED TO VI MODE

    # Optional: Visual cues for Vim modes (Block = Normal, Line = Insert)
    cursor_shape: {
        vi_insert: line
        vi_normal: block
    }

    # VIM MODE INDICATORS
    # These appear to the right of your prompt character
    render_right_prompt_on_last_line: false # Keeps it clean

    # 2. COMPLETIONS
    completions: {
        case_sensitive: false 
        quick: true
        partial: true 
        algorithm: "fuzzy" 
        external: {
            enable: true 
            max_results: 100
        }
    }

    # 3. SMART HISTORY MENU
    menus: [
        {
            name: smart_history
            # CRITICAL FIX: Disable auto-filtering so our custom logic applies 100%
            only_buffer_difference: false 
            marker: "? " 
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: cyan
                selected_text: cyan_reverse
                description_text: yellow
            }
            source: { |buffer, position|
                # 1. PARSE INPUT: Get the "Main Command" from what you typed
                let raw_parts = ($buffer | str trim | split row " ")
                let main_cmd = if ($raw_parts | get 0) == "sudo" { 
                    $raw_parts | get 1? 
                } else { 
                    $raw_parts | get 0 
                }

                # 2. QUERY: If buffer is empty, show nothing (or recent history)
                if ($main_cmd | is-empty) { 
                    history | get command | reverse | uniq | first 10 | each { {value: $in} }
                } else {
                    # 3. FILTER: Strict check against history
                    history
                    | get command
                    | where { |line| 
                        # Strip 'sudo' from the history entry to compare apples-to-apples
                        let clean_line = if ($line | str starts-with "sudo ") { 
                            $line | str substring 5.. 
                        } else { 
                            $line 
                        }
                        # Does this line start with the command we are typing?
                        $clean_line | str starts-with $main_cmd
                    }
                    | reverse
                    | uniq
                    | first 20
                    | each { |it| {value: $it} }
                }
            }
        }
    ]

    # 4. KEYBINDINGS
    keybindings: [
        # Keep Ctrl+Up working (updated for vi modes)
        {
            name: smart_history_up
            modifier: control
            keycode: up
            mode: [vi_insert vi_normal] 
            event: { send: menu name: smart_history }
        }
        
        # --- NEW BINDINGS ---
        
        # Ctrl+J in Normal Mode
        {
            name: smart_history_j
            modifier: alt
            keycode: char_j
            mode: [vi_normal vi_insert] 
            event: { send: menu name: smart_history }
	}
        # Ctrl+K in Normal Mode
        {
            name: smart_history_k
            modifier: alt
            keycode: char_k
            mode: [vi_normal vi_insert] 
            event: { send: menu name: smart_history }
        }
    ]
}


mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
