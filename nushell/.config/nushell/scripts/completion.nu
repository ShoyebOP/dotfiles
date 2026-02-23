# completion.nu
# Custom external completer for nushell
# Provides command-priority completion:
# - First word (no space): shows matching commands/aliases
# - After space: shows command-specific flags and arguments
# - Fallback: file/directory picker

# Fish-based external completer
def fish_completer [spans: list<string>] {
    if ($spans | length) == 0 {
        return null
    }

    # Build the fish complete command
    let escaped_spans = ($spans | each { |s| $s | str replace --all "'" "'\\''" } | str join ' ')
    
    # Run fish completion and capture output
    let result = (fish --command $"complete '--do-complete=($escaped_spans)'" | complete)
    
    if $result.exit_code != 0 {
        return null
    }
    
    let parsed = ($result.stdout | from tsv --flexible --noheaders --no-infer | rename value description)
    
    if ($parsed | is-empty) {
        return null
    }
    
    return $parsed
}

# Main external completer function called by nushell's completion system
export def external_completer [spans: list<string>] {
    # For first word completion (single span), let nushell handle it
    # Return null to fall back to nushell's built-in command/alias completion
    if ($spans | length) == 1 {
        return null
    }
    
    # For multi-span input (command + args), use fish completer
    let fish_result = (fish_completer $spans)
    
    if ($fish_result != null) {
        return $fish_result
    }
    
    # Fallback to file completion
    return null
}
