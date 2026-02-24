# Implementation Plan: Nushell Python Venv Commands

## Phase 1: Test-Driven Development Setup

- [ ] Task: Create test file for venv commands
    - [ ] Create `nushell/.config/nushell/scripts/test-venv.nu`
    - [ ] Add test for `venv-activate` when `.venv` exists
    - [ ] Add test for `venv-activate` when `venv` exists
    - [ ] Add test for `venv-activate` error when no venv found
    - [ ] Add test for `venv-activate` error when both venvs exist
    - [ ] Add test for `venv-activate` warning when already in venv
    - [ ] Add test for `venv-deactivate` when venv is active
    - [ ] Add test for `venv-deactivate` error when no venv active
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Implement venv-activate Command

- [ ] Task: Create `venv-activate` function in `nushell/.config/nushell/scripts/venv.nu`
    - [ ] Implement search logic for `.venv` and `venv` in current directory
    - [ ] Add priority logic (`.venv` first, then `venv`)
    - [ ] Implement error handling for no venv found
    - [ ] Implement error handling for multiple venvs found
    - [ ] Implement warning for already active venv
    - [ ] Add verbose output (venv path + Python version)
    - [ ] Source the nushell activation script from found venv
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Implement venv-deactivate Command

- [ ] Task: Add `venv-deactivate` function to `nushell/.config/nushell/scripts/venv.nu`
    - [ ] Implement deactivation logic using `deactivate` command
    - [ ] Add error handling for no active venv
    - [ ] Add success message with deactivated venv path
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Integration and Testing

- [ ] Task: Source venv.nu in config.nu
    - [ ] Add `source ($nu.default-config-dir | path join "scripts" "venv.nu")` to config.nu
    - [ ] Run tests to verify both commands work correctly
    - [ ] Manual testing in nushell session
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)

## Phase 5: Final Verification and Checkpointing

- [ ] Task: Run full test suite and verify all tests pass
- [ ] Task: Verify code coverage meets requirements
- [ ] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)
