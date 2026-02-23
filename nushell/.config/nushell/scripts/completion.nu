# completion.nu
# Custom external completer for nushell
# Provides command-priority completion:
# - First word (no space): shows matching commands/aliases
# - After space: shows command-specific flags and arguments
# - Fallback: file/directory picker

# Fish-based external completer
# Uses fish shell's completion system which has built-in completions for many commands
def fish_completer [spans: list<string>] {
    # Handle empty or single-span (first word completion)
    if ($spans | length) == 0 {
        return null
    }

    # Build the fish complete command
    # Fish expects: complete --do-complete="cmd arg1 arg2"
    let escaped_spans = ($spans | each { |s| $s | str replace --all "'" "'\\''" } | str join ' ')
    
    # Run fish completion
    let result = (fish --command $"complete '--do-complete=($escaped_spans)'" 2> $nothing | from tsv --flexible --noheaders --no-infer | rename value description)
    
    # If fish returns nothing, return null to let nushell fall back to file completion
    if ($result | is-empty) {
        return null
    }
    
    return $result
}

# Main external completer function
# This is called by nushell's completion system
def external_completer [spans: list<string>] {
    # Get the first command (or expand alias)
    let first_cmd = if ($spans | length) > 0 { $spans | get 0 } else { "" }
    
    # For first word completion (no space yet), let nushell handle command/alias completion
    # by returning null - nushell will show built-in command completions
    if ($spans | length) == 1 {
        # Check if the span ends with a space (user pressed tab after space)
        # If so, we want command-specific completions
        # Otherwise, let nushell show command/alias completions
        return null
    }
    
    # For multi-span input (command + space + ...), use fish completer
    # This will show command-specific flags and arguments
    let fish_result = (fish_completer $spans)
    
    # If fish returned results, use them
    if ($fish_result != null and ($fish_result | is-not-empty)) {
        return $fish_result
    }
    
    # Fallback to file completion
    return null
}

# Export the completer for use in config.nu
export def main [] {
    $external_completer
}
