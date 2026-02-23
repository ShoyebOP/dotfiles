# Track Implementation Plan: Nushell Completion Fix & Unstow Script

## Phase 1: Research & Analysis

- [ ] Task: Analyze current nushell completion configuration
    - [ ] Read existing nushell config files in `nushell/` directory
    - [ ] Identify current completion settings and plugins
    - [ ] Document how aliases are defined (especially `v` for nvim)
- [ ] Task: Analyze `setup.nu` stow operations
    - [ ] Read `setup.nu` to understand all stow commands
    - [ ] List all directories that are stowed
    - [ ] Document the stow targets and destinations
- [ ] Task: Research nushell completion documentation
    - [ ] Review nushell completion engine capabilities
    - [ ] Find examples of command-priority completion configurations

## Phase 2: Nushell Completion Fix

- [ ] Task: Write tests for completion behavior
    - [ ] Create test scenarios for first-word completion
    - [ ] Create test scenarios for post-space completion
    - [ ] Document expected behavior for each scenario
- [ ] Task: Implement completion configuration
    - [ ] Configure nushell completion engine to prioritize command matching
    - [ ] Set up proper flag/argument completion after space
    - [ ] Configure file picker as fallback
    - [ ] Test with `git`, `v`, and other commands
- [ ] Task: Verify completion behavior
    - [ ] Manual verification of all acceptance criteria
    - [ ] Document any edge cases or limitations

## Phase 3: Unstow Script

- [ ] Task: Write teardown script
    - [ ] Create `teardown.nu` in repository root
    - [ ] Implement unstow logic for all directories from `setup.nu`
    - [ ] Add symlink removal functionality
    - [ ] Add stow directory deletion with confirmation prompt
    - [ ] Support both pacman and apt systems
- [ ] Task: Test teardown script
    - [ ] Run script in test environment
    - [ ] Verify all symlinks are removed
    - [ ] Verify stow directories are deleted
    - [ ] Confirm no unintended files are deleted

## Phase 4: Verification & Checkpointing

- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)
