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
        # --- 1. COMPLETION MENU (Tab) ---
        

        # --- 2. HISTORY MENU (Ctrl+R) ---
        {
            name: history_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: cyan
                selected_text: { fg: "magenta" attr: "b" }
                description_text: yellow
            }
        }

        # --- 3. HELP MENU (F1) ---
        {
            name: help_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: description
                columns: 4  # <--- FIXED: Must be an Integer, not a list
                col_width: 20
                col_padding: 2
                selection_rows: 4
                page_size: 10
            }
            style: {
                text: cyan
                selected_text: { fg: "magenta" attr: "b" }
                description_text: yellow
            }
        }

        # --- 4. SMART HISTORY (Ctrl+Shift+Up) ---
        {
            name: smart_history
            only_buffer_difference: false
            marker: "? " 
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: cyan
                selected_text: { fg: "magenta" attr: "b" }
                description_text: yellow
            }
            source: { |buffer, position|
                let raw_parts = ($buffer | str trim | split row " ")
                let main_cmd = if ($raw_parts | get 0) == "sudo" { 
                    $raw_parts | get 1? 
                } else { 
                    $raw_parts | get 0 
                }

                if ($main_cmd | is-empty) { 
                    history | get command | reverse | uniq | first 10 | each { {value: $in} }
                } else {
                    history
                    | get command
                    | where { |line| 
                        let clean_line = if ($line | str starts-with "sudo ") { 
                            $line | str substring 5.. 
                        } else { 
                            $line 
                        }
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
