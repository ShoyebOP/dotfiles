# Implementation Plan: Nushell Python Venv Commands

## Phase 1: Test-Driven Development Setup

- [x] Task: Create test file for venv commands [b079b1c]
    - [x] Create `nushell/.config/nushell/scripts/test-venv.nu`
    - [x] Add test for `venv-activate` when `.venv` exists
    - [x] Add test for `venv-activate` when `venv` exists
    - [x] Add test for `venv-activate` error when no venv found
    - [x] Add test for `venv-activate` error when both venvs exist
    - [x] Add test for `venv-activate` warning when already in venv
    - [x] Add test for `venv-deactivate` when venv is active
    - [x] Add test for `venv-deactivate` error when no venv active
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Implement venv-activate Command

- [x] Task: Create `venv-activate` function in `nushell/.config/nushell/scripts/venv.nu` [b079b1c, 7dc7042]
    - [x] Implement search logic for `.venv` and `venv` in current directory
    - [x] Add priority logic (`.venv` first, then `venv`)
    - [x] Implement error handling for no venv found
    - [x] Implement error handling for multiple venvs found
    - [x] Implement warning for already active venv
    - [x] Add verbose output (venv path + Python version)
    - [x] Source the nushell activation script from found venv
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Implement venv-deactivate Command

- [x] Task: Add `venv-deactivate` function to `nushell/.config/nushell/scripts/venv.nu` [b079b1c, 7dc7042]
    - [x] Implement deactivation logic using deactivate command
    - [x] Add error handling for no active venv
    - [x] Add success message with deactivated venv path
- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Integration and Testing

- [x] Task: Source venv.nu in config.nu [b079b1c]
    - [x] Add `source ($nu.default-config-dir | path join "scripts" "venv.nu")` to config.nu
    - [x] Run tests to verify both commands work correctly
    - [x] Manual testing in nushell session
- [x] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)

## Phase 5: Final Verification and Checkpointing

- [x] Task: Run full test suite and verify all tests pass [b079b1c, 7dc7042]
- [x] Task: Verify code coverage meets requirements
- [x] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)
