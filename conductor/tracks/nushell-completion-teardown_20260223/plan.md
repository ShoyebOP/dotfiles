# Track Implementation Plan: Nushell Completion Fix & Unstow Script

## Phase 1: Research & Analysis [checkpoint: f4ec6b0]

- [x] Task: Analyze current nushell completion configuration
    - [x] Read existing nushell config files in `nushell/` directory
    - [x] Identify current completion settings and plugins
    - [x] Document how aliases are defined (especially `v` for nvim)
- [x] Task: Analyze `setup.nu` stow operations
    - [x] Read `setup.nu` to understand all stow commands
    - [x] List all directories that are stowed
    - [x] Document the stow targets and destinations
- [x] Task: Research nushell completion documentation
    - [x] Review nushell completion engine capabilities
    - [x] Find examples of command-priority completion configurations

## Phase 2: Nushell Completion Fix [checkpoint: f4ec6b0]

- [x] Task: Write tests for completion behavior [eb7bad6]
    - [x] Create test scenarios for first-word completion
    - [x] Create test scenarios for post-space completion
    - [x] Document expected behavior for each scenario
- [x] Task: Implement completion configuration [eb7bad6]
    - [x] Configure nushell completion engine to prioritize command matching
    - [x] Set up proper flag/argument completion after space
    - [x] Configure file picker as fallback
    - [x] Test with `git`, `v`, and other commands
- [x] Task: Verify completion behavior [78ccbd7]
    - [x] Manual verification of all acceptance criteria
    - [x] Document any edge cases or limitations

## Phase 3: Unstow Script [checkpoint: aab711e]

- [x] Task: Write teardown script [eb7bad6]
    - [x] Create `teardown.nu` in repository root
    - [x] Implement unstow logic for all directories from `setup.nu`
    - [x] Add symlink removal functionality
    - [x] Add stow directory deletion with confirmation prompt
    - [x] Support both pacman and apt systems
- [x] Task: Test teardown script [4786888]
    - [x] Run script in test environment
    - [x] Verify all symlinks are removed
    - [x] Verify stow directories are deleted
    - [x] Confirm no unintended files are deleted

## Phase 4: Verification & Checkpointing

- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
