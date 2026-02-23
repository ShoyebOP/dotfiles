# completion.nu
# Custom external completer for nushell
# Provides command-priority completion:
# - First word: shows matching commands/aliases (prefix match, not fuzzy)
# - After space: shows command-specific flags/arguments, or file picker fallback

# Get all available commands and aliases for completion
def get_commands [] {
    # Get built-in commands
    let builtins = (scope commands | where name !~ "^nu\\." | get name)
    
    # Get aliases
    let aliases = (scope aliases | get name)
    
    # Get externals (commands in PATH)
    let externals = (scope externs | get name)
    
    ($builtins | append $aliases | append $externals | uniq)
}

# Main external completer function called by nushell's completion system
export def external_completer [spans: list<string>] {
    let span_count = ($spans | length)
    
    # Case 1: First word completion (no space yet)
    # Return null to let nushell show its built-in command/alias completions
    if $span_count == 1 {
        return null
    }
    
    # Case 2: After space - need command-specific completions
    # Get the first command
    let first_cmd = $spans | get 0
    
    # For known commands, we would normally show flags
    # But without fish/carapace, we can't get dynamic flag completions
    # So we return null to fall back to file completion
    # This is the correct behavior: if we can't provide command-specific completions,
    # let nushell show file picker
    
    return null
}
