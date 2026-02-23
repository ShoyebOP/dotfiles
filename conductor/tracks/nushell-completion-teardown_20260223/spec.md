# Track Specification: Nushell Completion Fix & Unstow Script

## Overview
This track addresses two distinct enhancements to the dotfiles repository:

1. **Nushell Command Completion Behavior**: Fix the tab completion behavior in Nushell to properly show matching commands/aliases on first-word Tab, then show command-specific flags/arguments after space+Tab, with file picker as fallback.

2. **Unstow Script**: Create a reverse script (`teardown.nu`) that unstows all directories managed by `setup.nu` and deletes the stow directories.

## Functional Requirements

### FR-1: Nushell Completion Priority
- **First word completion (no space)**: When typing a partial command and pressing Tab, show all matching commands and aliases (e.g., `git` + Tab shows `git`, `lazygit`, `gitui`, etc.; `v` + Tab shows `v` and other aliases starting with `v`)
- **After space completion**: After typing a command + space + Tab, show only flags and arguments specific to that command (e.g., `git ` + Tab shows git subcommands and flags like `status`, `commit`, `--help`; `v ` + Tab shows file picker since nvim accepts file arguments)
- **Fallback behavior**: If no matching flags/arguments exist or input doesn't match any flag, fall back to file/directory picker
- Apply this behavior to all commands and aliases

### FR-2: Unstow Script
- Create a new script (`teardown.nu`) in the repository root
- Script must reverse all stow operations performed by `setup.nu`
- Remove all stowed symlinks from the home directory and system paths
- Delete the entire stow directories after unstowing
- Support both pacman and apt-based systems (matching setup.nu)

## Non-Functional Requirements
- **Portability**: Script must work across different machines without machine-specific configuration
- **Safety**: Include confirmation prompts before destructive operations (deleting stow directories)
- **Consistency**: Follow the same coding style and structure as `setup.nu`

## Acceptance Criteria

### Nushell Completion
- [ ] Typing `g` + Tab shows all commands/aliases containing `g` (git, lazygit, gitui, etc.)
- [ ] Typing `git` + Tab shows git and related commands
- [ ] Typing `git ` + Tab shows git subcommands and flags only (status, commit, push, --help, etc.)
- [ ] Typing `v` + Tab shows `v` alias and other matching commands
- [ ] Typing `v ` + Tab shows file picker (nvim accepts file arguments)
- [ ] Typing unknown command + Tab shows file picker by default

### Unstow Script
- [ ] Script successfully unstows all directories managed by `setup.nu`
- [ ] Script deletes stow directories after unstowing
- [ ] Script includes safety confirmation before deletion
- [ ] Script handles both pacman and apt package managers
- [ ] Manual verification confirms symlinks are removed and stow directories deleted

## Out of Scope
- Changes to existing `setup.nu` functionality
- Visual/theme changes to nushell
- Adding new aliases or commands
