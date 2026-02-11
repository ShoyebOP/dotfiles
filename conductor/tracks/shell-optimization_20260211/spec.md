# Specification: shell-optimization_20260211

## Overview
This track focuses on optimizing the shell experience by refining the Starship prompt configuration and cleaning up repository noise. It addresses performance and visual clutter in the home directory via dynamic configuration switching, adds situational awareness for SSH sessions, and ensures machine-specific files are excluded from version control.

## Functional Requirements
- **Starship: Context-Aware Configuration**
  - Implement a mechanism in Nushell to dynamically switch the `$env.STARSHIP_CONFIG` variable.
  - **Minimal Mode:** Activated when the current working directory is exactly the user's home directory (`~`). This mode will use a configuration that suppresses language-specific modules (Node.js, etc.).
  - **Standard Mode:** Activated in all other directories, preserving existing language indicators for development projects.
- **Starship: SSH Indicator**
  - Add a visible indicator (icon or text) to the prompt that only appears when the shell is accessed via an active SSH session.
- **Repository Maintenance: Git Hygiene**
  - Update `.gitignore` to exclude the Nushell history file and the Neovim `lazy-lock.json` file.
  - Remove any existing tracked instances of these files from the repository's index without deleting them from the local filesystem.

## Non-Functional Requirements
- **Performance:** The dynamic switching logic in Nushell must be extremely lightweight to avoid slowing down directory changes.
- **Minimalism:** Indicators should be clear but unobtrusive, adhering to the project's minimalist aesthetic.

## Acceptance Criteria
- [ ] Navigating to `~` in Nushell switches Starship to a quiet mode (no Node.js version displayed).
- [ ] Navigating into any subdirectory of `~` (e.g., `~/projects`) restores the language indicators.
- [ ] Connecting to a machine via SSH displays a unique icon or "SSH" label in the prompt.
- [ ] `git status` no longer shows Nushell history or Neovim lock files as untracked or modified.
- [ ] `lazy-lock.json` and Nushell history files are removed from the remote repository index.

## Out of Scope
- Major restructuring of the Starship prompt layout.
- Permanent global disabling of language modules.
