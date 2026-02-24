# Track: Nushell Python Venv Commands

## Overview
Add two new Nushell commands (`venv-activate` and `venv-deactivate`) to manage Python virtual environments, since Python does not provide a native Nushell activation script. The commands will dynamically search for virtual environment folders in the current directory.

## Functional Requirements

### 1. `venv-activate` Command
- **Search Scope**: Current working directory only (no recursive search)
- **Search Pattern**: Look for both `venv` and `.venv` folder names
- **Search Priority**: Check `.venv` first, then `venv` (hidden folder convention takes priority)
- **Activation**: Source the Nushell activation script from the found virtual environment
- **Output on Success**: 
  - Display which venv was activated (path)
  - Show Python version of the activated environment
- **Error Handling**:
  - Error if no venv found in current directory
  - Error if both `venv` and `.venv` exist (ambiguous - user must specify)
  - Warning if already inside an active virtual environment

### 2. `venv-deactivate` Command
- **Deactivation**: Deactivate the currently active Python virtual environment
- **Output on Success**: Display confirmation message showing deactivated venv path
- **Error Handling**:
  - Error if no virtual environment is currently active

## Non-Functional Requirements
- Commands must be added to the Nushell configuration (`nushell/` directory)
- Commands should follow existing Nushell coding conventions in the repository
- Commands must be efficient and not introduce noticeable shell startup delay
- Error messages should be clear and actionable

## Acceptance Criteria
1. `venv-activate` successfully activates a Python venv when exactly one of `venv` or `.venv` exists in current directory
2. `venv-activate` shows verbose output (venv path + Python version) on success
3. `venv-activate` errors appropriately when no venv exists, multiple venvs exist, or already in a venv
4. `venv-deactivate` successfully deactivates an active venv
5. `venv-deactivate` errors appropriately when no venv is active
6. Both commands are available after sourcing the Nushell configuration

## Out of Scope
- Recursive search through subdirectories
- Support for custom venv folder names beyond `venv` and `.venv`
- Automatic venv creation
- Integration with tools like `pyenv` or `poetry` (unless explicitly added later)
