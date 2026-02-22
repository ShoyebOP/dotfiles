# Track Specification: zoxide-cd-fix_20260222

## Overview
Fix zoxide integration with Nushell where directories are not being properly added to the zoxide index. The user relies solely on `cd` command (with zoxide integration) for navigation, but zoxide frequently reports "not found" for directories that should have been indexed.

## Functional Requirements
1. Zoxide must automatically add directories to its index when navigating via `cd` in Nushell
2. The `cd` command must leverage zoxide's smart navigation (frecency-based suggestions)
3. Zoxide's hook must be properly configured to track all directory changes in Nushell
4. Directories visited via `cd` must be immediately available for future `cd` completions/queries

## Non-Functional Requirements
1. The fix should not introduce noticeable latency to shell startup or directory navigation
2. Must be compatible with the existing Nushell configuration structure
3. Should follow the project's efficiency-first philosophy (no unnecessary bloat)

## Acceptance Criteria
1. After navigating to a new directory with `cd`, zoxide index is updated automatically
2. Running `cd <partial-path>` shows zoxide suggestions for previously visited directories
3. The zoxide hook is properly configured in Nushell configuration
4. No "not found" errors for directories that were recently visited via `cd`
5. No manual intervention required to maintain the index

## Out of Scope
1. Using the `z` command for navigation
2. Visual enhancements to zoxide output
3. Integration with other shells (Zsh, Bash, etc.)
4. Custom zoxide plugins or extensions
