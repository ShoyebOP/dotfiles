# Implementation Plan: Unified Bootstrapper & Documentation Consolidation

## Phase 1: Foundation & OS Detection
- [x] Task: Create `setup.nu` skeleton with Nushell check (0042517)
- [ ] Task: Implement OS detection for Arch/CachyOS and Ubuntu
- [ ] Task: Implement graceful exit for unsupported OSs
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Foundation & OS Detection' (Protocol in workflow.md)

## Phase 2: Mode Selection & Dependency Matrix
- [ ] Task: Implement interactive mode selection (Local vs. Server)
- [ ] Task: Define dependency maps for each module per OS
- [ ] Task: Implement dependency verification logic
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Mode Selection & Dependency Matrix' (Protocol in workflow.md)

## Phase 3: Deployment Logic (Stowing)
- [ ] Task: Implement automated `stow` logic for core modules (Nvim, Nushell, Starship)
- [ ] Task: Implement GUI-specific `stow` logic for Local Mode (Hyprland, Alacritty, Wofi)
- [ ] Task: Implement privileged `stow` logic for `keyd` configuration
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Deployment Logic (Stowing)' (Protocol in workflow.md)

## Phase 4: Documentation & Cleanup
- [ ] Task: Create `README.md` based on `usage.md` and new bootstrap instructions
- [ ] Task: Verify all `usage.md` information is captured
- [ ] Task: Remove `usage.md`
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Documentation & Cleanup' (Protocol in workflow.md)
