# Implementation Plan: Unified Bootstrapper & Documentation Consolidation

## Phase 1: Foundation & OS Detection [checkpoint: 6d7c9ad]
- [x] Task: Create `setup.nu` skeleton with Nushell check (0042517)
- [x] Task: Implement OS detection for Arch/CachyOS and Ubuntu (8e5e33c)
- [x] Task: Implement graceful exit for unsupported OSs (8e5e33c)
- [x] Task: Conductor - User Manual Verification 'Phase 1: Foundation & OS Detection' (Protocol in workflow.md) (6d7c9ad)

## Phase 2: Mode Selection & Dependency Matrix
- [x] Task: Implement interactive mode selection (Local vs. Server) (4eaaed5)
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
